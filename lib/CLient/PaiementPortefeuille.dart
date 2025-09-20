import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class PaiementPortefeuillePage extends StatefulWidget {
  final double montant;
  final double bonus;

  const PaiementPortefeuillePage({
    Key? key,
    required this.montant,
    required this.bonus,
  }) : super(key: key);

  @override
  _PaiementPortefeuillePageState createState() => _PaiementPortefeuillePageState();
}

class _PaiementPortefeuillePageState extends State<PaiementPortefeuillePage> {
  CardEditController? _cardController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Only initialize CardEditController on mobile
    if (!kIsWeb) {
      _cardController = CardEditController();
    }
  }

  // Get the appropriate API base URL based on platform
  String get apiBaseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr'; // Web uses localhost
    } else {
      return 'http://10.0.2.2:3000'; // Mobile emulator uses 10.0.2.2
    }
  }

  Future<void> _handlePayment() async {
    setState(() => _isLoading = true);
    
    try {
      if (kIsWeb) {
        await _handleWebPayment();
      } else {
        await _handleMobilePayment();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleWebPayment() async {
    // Simulation de paiement pour Web
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Paiement simulé réussi sur Web!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _handleMobilePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final clientId = prefs.getInt('client_id');

    if (clientId == null) {
      throw Exception('Client ID non trouvé');
    }

    // 1. Create Payment Intent
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/payment/wallet/create-payment-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'amount': widget.montant,
        'clientId': clientId,
        'bonus': widget.bonus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create payment intent: ${response.body}');
    }

    final paymentIntent = json.decode(response.body);
    
    // 2. Confirm Payment
    await _confirmPaymentMobile(paymentIntent['client_secret']);

    // 3. Confirm payment with backend
    await _confirmPaymentWithBackend(paymentIntent['payment_intent_id'], clientId);

    // 4. Show success and return
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Paiement réussi! +${(widget.montant + widget.bonus).toStringAsFixed(2)}€ crédités'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmPaymentWithBackend(String paymentIntentId, int clientId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/payment/wallet/confirm-payment'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'paymentIntentId': paymentIntentId,
        'clientId': clientId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm payment with backend: ${response.body}');
    }
  }

  // Cette fonction ne sera compilée que sur mobile
  Future<void> _confirmPaymentMobile(String clientSecret) async {
    if (!kIsWeb && _cardController != null) {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(
              name: 'Client Glitty',
              email: 'client@glitty.com',
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    final total = widget.montant + widget.bonus;

    return Scaffold(
      appBar: AppBar(
        title: const Text('💳 Paiement sécurisé'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recharge de portefeuille',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Montant à payer:'),
                        Text(
                          '${widget.montant.toStringAsFixed(2)}€',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bonus offert:'),
                        Text(
                          '+${widget.bonus.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total crédité:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${total.toStringAsFixed(2)}€',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            if (kIsWeb) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.payment, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Paiement Web simulé',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Le paiement sera simulé sur cette plateforme.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_cardController != null) ...[
              const Text(
                'Informations de carte bancaire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CardField(controller: _cardController!),
            ],
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading 
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Traitement...'),
                      ],
                    )
                  : Text(
                      'Payer ${widget.montant.toStringAsFixed(2)}€',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Paiement sécurisé par Stripe',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardController?.dispose();
    super.dispose();
  }
} 