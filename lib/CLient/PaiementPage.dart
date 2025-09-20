import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'ClientAccueil.dart';

class PaiementPage extends StatefulWidget {
  final String optionChoisie;
  final int prix;
  final double latitude;
  final double longitude;

  const PaiementPage({
    super.key,
    required this.optionChoisie,
    required this.prix,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  bool _isLoading = false;
  double _soldePortefeuille = 0.0;
  int? _clientId;
  String _selectedPaymentMethod = 'mixte'; // 'portefeuille', 'stripe', 'mixte'
  double _montantPortefeuille = 0.0; // Montant à utiliser du portefeuille
  double _montantStripe = 0.0; // Montant restant à payer avec Stripe

  // URL dynamique selon la plateforme
  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    final prefs = await SharedPreferences.getInstance();
    _clientId = prefs.getInt('client_id');
    
    if (_clientId != null) {
      await _loadWalletBalance();
    }
  }

  Future<void> _loadWalletBalance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/portefeuille/solde/$_clientId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _soldePortefeuille = data['solde'].toDouble();
          _updatePaymentAmounts();
        });
      }
    } catch (e) {
      print('Erreur chargement solde: $e');
    }
  }

  void _updatePaymentAmounts() {
    switch (_selectedPaymentMethod) {
      case 'portefeuille':
        _montantPortefeuille = widget.prix.toDouble();
        _montantStripe = 0.0;
        break;
      case 'stripe':
        _montantPortefeuille = 0.0;
        _montantStripe = widget.prix.toDouble();
        break;
      case 'mixte':
        _montantPortefeuille = (_soldePortefeuille >= widget.prix) 
            ? widget.prix.toDouble() 
            : _soldePortefeuille;
        _montantStripe = widget.prix - _montantPortefeuille;
        break;
    }
  }

  Future<void> _processPayment() async {
    if (_clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur: Client non identifié'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('💰 Processing payment: Portefeuille: $_montantPortefeuille€, Stripe: $_montantStripe€');

      // 1. Si on utilise le portefeuille (tout ou partie)
      if (_montantPortefeuille > 0) {
        print('🏦 Deducting from wallet: $_montantPortefeuille€');
        await _deductFromWallet(_montantPortefeuille);
      }

      // 2. Si il reste un montant à payer avec Stripe
      if (_montantStripe > 0) {
        print('💳 Processing Stripe payment: $_montantStripe€');
        await _payWithStripe(_montantStripe);
      } else {
        // Si paiement 100% portefeuille, créer directement la réservation
        print('✅ 100% wallet payment, creating reservation directly');
        await _createReservation();
      }
    } catch (e) {
      print('❌ Payment process error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deductFromWallet(double montant) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/portefeuille/utiliser'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'clientId': _clientId,
        'montant': montant,
        'description': 'Paiement lavage: ${widget.optionChoisie} (${montant}€/${widget.prix}€)',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la déduction du portefeuille');
    }
  }

  Future<void> _payWithStripe(double montant) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement Stripe non disponible sur le web'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 1. Créer Payment Intent pour le montant restant
    final response = await http.post(
      Uri.parse('$baseUrl/api/payment/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': (montant * 100).round(), // Stripe utilise les centimes
        'currency': 'eur',
        'metadata': {
          'client_id': _clientId.toString(),
          'type_lavage': widget.optionChoisie,
          'montant_portefeuille': _montantPortefeuille.toString(),
          'montant_stripe': montant.toString(),
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      // 2. Initialiser Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: data['clientSecret'],
          merchantDisplayName: 'Glitty',
          style: ThemeMode.light,
        ),
      );

      // 3. Présenter Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Si succès, créer la réservation
      await _createReservation();
    } else {
      throw Exception('Erreur création Payment Intent');
    }
  }

  Future<void> _createReservation() async {
    try {
      print('🔄 Creating reservation with data:');
      print('Client ID: $_clientId, Type: ${widget.optionChoisie}, Prix: ${widget.prix}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/reservations/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'client_id': _clientId,
          'washer_id': 1, // On utilise le premier washer disponible pour l'instant
          'type_lavage': widget.optionChoisie,
          'prix': widget.prix,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'statut': 'validé', // Déjà payée !
          'paiement_portefeuille': _montantPortefeuille,
          'paiement_stripe': _montantStripe,
        }),
      );

      print('🌐 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        
        String message = 'Réservation créée avec succès ! ID: ${data['data']['id']}';
        if (_montantPortefeuille > 0 && _montantStripe > 0) {
          message += '\nPaiement mixte: ${_montantPortefeuille}€ (portefeuille) + ${_montantStripe}€ (carte)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ClientAccueil()),
          (route) => false,
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception('Erreur API: ${errorData['error'] ?? 'Erreur inconnue'}');
      }
    } catch (e) {
      print('❌ Reservation creation error: $e');
      throw Exception('Erreur lors de la création de la réservation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Paiement', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Résumé de la commande
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Résumé de votre commande',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(widget.optionChoisie),
                            Text('${widget.prix}€', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        
                        // Détail du paiement selon la méthode choisie
                        if (_selectedPaymentMethod == 'mixte' && _montantPortefeuille > 0 && _montantStripe > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Portefeuille', style: TextStyle(color: Colors.green)),
                              Text('-${_montantPortefeuille.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.green)),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Carte bancaire', style: TextStyle(color: Colors.blue)),
                              Text('${_montantStripe.toStringAsFixed(2)}€', style: const TextStyle(color: Colors.blue)),
                            ],
                          ),
                          const Divider(),
                        ],
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            Text('${widget.prix}€', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Solde portefeuille
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet, color: Colors.green),
                        const SizedBox(width: 12),
                        Text(
                          'Solde disponible: ${_soldePortefeuille.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Méthodes de paiement
                  const Text(
                    'Choisissez votre méthode de paiement',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Option 1: Tout avec le portefeuille
                  if (_soldePortefeuille >= widget.prix) ...[
                    _buildPaymentOption(
                      'portefeuille',
                      'Portefeuille uniquement',
                      'Payer ${widget.prix}€ avec vos crédits',
                      Icons.account_balance_wallet,
                      Colors.green,
                      primaryColor,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Option 2: Paiement mixte (portefeuille + carte)
                  if (_soldePortefeuille > 0) ...[
                    _buildPaymentOption(
                      'mixte',
                      'Paiement mixte',
                      _soldePortefeuille >= widget.prix 
                          ? 'Utilisez une partie de vos crédits'
                          : 'Portefeuille: ${_soldePortefeuille.toStringAsFixed(2)}€ + Carte: ${(widget.prix - _soldePortefeuille).toStringAsFixed(2)}€',
                      Icons.payments,
                      Colors.orange,
                      primaryColor,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Option 3: Carte bancaire uniquement
                  if (!kIsWeb) ...[
                    _buildPaymentOption(
                      'stripe',
                      'Carte bancaire uniquement',
                      'Paiement sécurisé via Stripe',
                      Icons.credit_card,
                      Colors.blue,
                      primaryColor,
                    ),
                  ],

                  const Spacer(),

                  // Bouton de paiement
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isLoading 
                            ? 'Traitement...' 
                            : _getPaymentButtonText(),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentOption(String value, String title, String subtitle, 
      IconData icon, Color iconColor, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = value;
          _updatePaymentAmounts();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedPaymentMethod == value ? primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedPaymentMethod == value ? primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: (val) {
                setState(() {
                  _selectedPaymentMethod = val!;
                  _updatePaymentAmounts();
                });
              },
              activeColor: primaryColor,
            ),
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (_selectedPaymentMethod == value)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  String _getPaymentButtonText() {
    switch (_selectedPaymentMethod) {
      case 'portefeuille':
        return 'Payer ${widget.prix}€ avec le portefeuille';
      case 'stripe':
        return 'Payer ${widget.prix}€ par carte';
      case 'mixte':
        if (_montantStripe > 0) {
          return 'Payer ${_montantStripe.toStringAsFixed(2)}€ par carte';
        } else {
          return 'Payer ${widget.prix}€ avec le portefeuille';
        }
      default:
        return 'Procéder au paiement';
    }
  }
} 