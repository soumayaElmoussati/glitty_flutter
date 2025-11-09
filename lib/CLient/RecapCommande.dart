import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/ConfirmCommande.dart';
import 'package:glitty/CLient/LocationPage.dart' show LocationPage;
import 'package:glitty/services/commande_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:glitty/config/env.dart';

class RecapCommandePage extends StatefulWidget {
  final int clientId;
  final String selectedAddress;
  final double latitude;
  final double longitude;
  final String typeLavage;
  final Map<String, dynamic>? vehicleData;
  final List<dynamic>? photos;
  final String date;
  final String creneau;
  final String? heure;
  final double prix;
  final Map<String, dynamic>? clientData;

  const RecapCommandePage({
    super.key,
    required this.clientId,
    required this.selectedAddress,
    required this.latitude,
    required this.longitude,
    required this.typeLavage,
    this.vehicleData,
    this.photos,
    required this.date,
    required this.creneau,
    this.heure,
    required this.prix,
    this.clientData,
  });

  @override
  State<RecapCommandePage> createState() => _RecapCommandePageState();
}

class _RecapCommandePageState extends State<RecapCommandePage> {
  bool _useGlittyBalance = false;
  bool _showPaymentModal = false;
  String? _selectedPaymentMethod;
  bool _isLoading = false;
  bool _isProcessingStripe = false;
  bool _isLoadingBalance = false;
  double _glittyBalance = 0.0;
  bool _isProcessingSolde = false;

  // PALETTE DE COULEURS COHÉRENTE
  final Color _primaryColor = const Color(0xFF022519);
  final Color _accentColor = const Color(0xFF27AE60);
  final Color _cardColor1 = const Color(0xFF2ECC71);
  final Color _cardColor2 = const Color(0xFF16A085);
  final Color _cardColor3 = const Color(0xFF229954);
  final Color _backgroundColor = const Color(0xFFF8F9FA);

  // CONFIGURATION DES SERVICES DYNAMIQUES
  Map<String, Map<String, dynamic>> get _servicesConfig => {
        'Lavage Intérieur': {
          'title': 'Lavage Intérieur',
          'description': 'Nettoyage complet et détaillé de l\'habitacle',
          'color': _cardColor1,
          'icon': Icons.airline_seat_recline_normal_rounded,
          'features': [
            'Nettoyage intérieur complet',
            'Tableau de bord et plastiques',
            'Aspirateur professionnel',
            'Désinfection des surfaces'
          ],
        },
        'Lavage Extérieur': {
          'title': 'Lavage Extérieur',
          'description': 'Brillance et propreté extérieure optimale',
          'color': _cardColor2,
          'icon': Icons.car_repair_rounded,
          'features': [
            'Nettoyage extérieur complet',
            'Vitres cristallines',
            'Nettoyage des roues et jantes',
            'Séchage sans trace'
          ],
        },
        'Lavage Complet': {
          'title': 'Lavage Complet',
          'description': 'L\'excellence d\'un nettoyage intégral',
          'color': _cardColor3,
          'icon': Icons.diamond_rounded,
          'features': [
            'Intérieur et extérieur complet',
            'Traitement anti-poussière',
            'Produits écologiques premium',
            'Garantie satisfaction 48h'
          ],
        },
        'lavage_interieur': {
          'title': 'Lavage Intérieur',
          'description': 'Nettoyage complet et détaillé de l\'habitacle',
          'color': _cardColor1,
          'icon': Icons.airline_seat_recline_normal_rounded,
          'features': [
            'Nettoyage intérieur complet',
            'Tableau de bord et plastiques',
            'Aspirateur professionnel',
            'Désinfection des surfaces'
          ],
        },
        'lavage_exterieur': {
          'title': 'Lavage Extérieur',
          'description': 'Brillance et propreté extérieure optimale',
          'color': _cardColor2,
          'icon': Icons.car_repair_rounded,
          'features': [
            'Nettoyage extérieur complet',
            'Vitres cristallines',
            'Nettoyage des roues et jantes',
            'Séchage sans trace'
          ],
        },
        'lavage_complet': {
          'title': 'Lavage Complet',
          'description': 'L\'excellence d\'un nettoyage intégral',
          'color': _cardColor3,
          'icon': Icons.diamond_rounded,
          'features': [
            'Intérieur et extérieur complet',
            'Traitement anti-poussière',
            'Produits écologiques premium',
            'Garantie satisfaction 48h'
          ],
        },
      };

  @override
  void initState() {
    super.initState();
    print('=== RECAP COMMANDE PAGE DEBUG ===');
    print('Service sélectionné: ${widget.typeLavage}');
    print('Prix reçu: ${widget.prix}');
    print('ClientId reçu: ${widget.clientId}');
    print('==============================');

    _fetchClientBalance();
  }

  // NOUVELLES MÉTHODES: Calculs pour le solde
  double get _montantApresSolde {
    if (_useGlittyBalance && _glittyBalance > 0) {
      final montantFinal = widget.prix - _glittyBalance;
      return montantFinal > 0 ? montantFinal : 0.0;
    }
    return widget.prix;
  }

  double get _soldeUtilise {
    if (_useGlittyBalance && _glittyBalance > 0) {
      return _glittyBalance <= widget.prix ? _glittyBalance : widget.prix;
    }
    return 0.0;
  }

  bool get _soldeSuffisant {
    return _glittyBalance >= widget.prix;
  }

  Future<void> _fetchClientBalance() async {
    setState(() {
      _isLoadingBalance = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/solde/${widget.clientId}'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _glittyBalance = (data['solde'] is int)
              ? (data['solde'] as int).toDouble()
              : double.tryParse(data['solde'].toString()) ?? 0.0;
        });
        print('✅ Solde récupéré: $_glittyBalance€');
      } else {
        print('❌ Erreur récupération solde: ${response.statusCode}');
      }
    } catch (error) {
      print('❌ Erreur API solde: $error');
    } finally {
      setState(() {
        _isLoadingBalance = false;
      });
    }
  }

  // Fonction pour obtenir la configuration du service
  Map<String, dynamic> _getServiceConfig() {
    return _servicesConfig[widget.typeLavage] ??
        _servicesConfig['Lavage Complet']!;
  }

  // Fonction pour convertir les photos en XFile
  List<XFile>? _convertPhotosToXFiles() {
    if (widget.photos == null) return null;

    List<XFile> xFiles = [];

    for (var photo in widget.photos!) {
      if (photo is XFile) {
        xFiles.add(photo);
      } else if (photo is String) {
        xFiles.add(XFile(photo));
      } else {
        try {
          final path = photo.toString();
          if (path.isNotEmpty) {
            xFiles.add(XFile(path));
          }
        } catch (e) {
          print('Erreur conversion photo: $e');
        }
      }
    }

    return xFiles.isNotEmpty ? xFiles : null;
  }

  // MODIFIEZ la méthode _createCommande pour gérer le solde
  Future<void> _createCommande() async {
    if (_selectedPaymentMethod == null && !_useGlittyBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un mode de paiement"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Si paiement par solde Glitty
    if (_useGlittyBalance && _soldeSuffisant) {
      await _processSoldePayment();
    }
    // Si paiement mixte (solde + carte)
    else if (_useGlittyBalance &&
        _glittyBalance > 0 &&
        _montantApresSolde > 0 &&
        _selectedPaymentMethod == 'carte') {
      await _processMixedPayment();
    }
    // Si paiement par carte seul
    else if (_selectedPaymentMethod == 'carte') {
      await _processStripePayment();
    }
    // Pour les autres méthodes de paiement (espèces)
    else {
      await _createCommandeDirect();
    }
  }

  // NOUVELLE MÉTHODE: Paiement entièrement par solde
  Future<void> _processSoldePayment() async {
    setState(() {
      _isProcessingSolde = true;
    });

    try {
      final xPhotos = _convertPhotosToXFiles();

      final result = await CommandeService.createCommande(
        clientId: widget.clientId,
        vehicleId: null,
        vehicleData: widget.vehicleData,
        date: widget.date,
        creneau: widget.creneau,
        heure: widget.heure,
        departLat: widget.latitude,
        departLng: widget.longitude,
        departAdresse: widget.selectedAddress,
        arriveeLat: null,
        arriveeLng: null,
        arriveeAdresse: null,
        typeLavage: widget.typeLavage,
        prix: widget.prix,
        notes: null,
        dureeEstimee: null,
        methodPaiement: 'solde_glitty',
        photos: xPhotos,
        soldeUtilise: widget.prix,
      );

      setState(() {
        _isProcessingSolde = false;
      });

      if (result['success'] == true) {
        final commandeData = _extractCommandeData(result);

        if (commandeData != null) {
          print('🎉 Commande créée avec succès avec solde Glitty!');

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Paiement effectué avec votre solde Glitty'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmCommandePage(
                commandeData: commandeData,
              ),
            ),
          );
        } else {
          _showError("Erreur: Données de commande non disponibles");
        }
      } else {
        final errorMessage = result['error'] ?? 'Erreur inconnue';
        _showError(errorMessage);
      }
    } catch (error) {
      setState(() {
        _isProcessingSolde = false;
      });

      print('❌ Erreur paiement solde: $error');
      _showError('Erreur lors du paiement par solde: $error');
    }
  }

  // NOUVELLE MÉTHODE: Paiement mixte (solde + carte)
  Future<void> _processMixedPayment() async {
    setState(() {
      _isProcessingStripe = true;
    });

    try {
      print(
          '💰 Paiement mixte: ${_soldeUtilise}€ de solde + ${_montantApresSolde}€ par carte');

      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/create-payment-intent-commande'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientId': widget.clientId,
          'montant': _montantApresSolde,
          'commandeData': {
            'vehicleData': widget.vehicleData,
            'date': widget.date,
            'creneau': widget.creneau,
            'heure': widget.heure,
            'departLat': widget.latitude,
            'departLng': widget.longitude,
            'departAdresse': widget.selectedAddress,
            'typeLavage': widget.typeLavage,
            'prix': widget.prix,
            'soldeUtilise': _soldeUtilise,
            'methodPaiement': 'mixte',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await _setupPaymentSheet(data['clientSecret']);
        } else {
          throw Exception(data['message'] ?? 'Erreur création PaymentIntent');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isProcessingStripe = false;
      });
      _showError('Erreur paiement mixte: ${e.toString()}');
    }
  }

  // Fonction pour créer la commande directement (espèces, etc.)
  Future<void> _createCommandeDirect() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final xPhotos = _convertPhotosToXFiles();

      final methodPaiement = _useGlittyBalance && _glittyBalance > 0
          ? 'mixte_espece'
          : _selectedPaymentMethod;

      final result = await CommandeService.createCommande(
        clientId: widget.clientId,
        vehicleId: null,
        vehicleData: widget.vehicleData,
        date: widget.date,
        creneau: widget.creneau,
        heure: widget.heure,
        departLat: widget.latitude,
        departLng: widget.longitude,
        departAdresse: widget.selectedAddress,
        arriveeLat: null,
        arriveeLng: null,
        arriveeAdresse: null,
        typeLavage: widget.typeLavage,
        prix: widget.prix,
        notes: null,
        dureeEstimee: null,
        methodPaiement: methodPaiement,
        photos: xPhotos,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success'] == true) {
        final commandeData = _extractCommandeData(result);

        if (commandeData != null) {
          print('🎉 Commande créée avec succès!');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmCommandePage(
                commandeData: commandeData,
              ),
            ),
          );
        } else {
          _showError("Erreur: Données de commande non disponibles");
        }
      } else {
        final errorMessage = result['error'] ?? 'Erreur inconnue';
        _showError(errorMessage);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      print('❌ Erreur création commande: $error');
      _showError('Erreur: $error');
    }
  }

  // CORRECTION: Fonction pour extraire les données de commande de manière sécurisée
  Map<String, dynamic>? _extractCommandeData(Map<String, dynamic> result) {
    try {
      if (result['commande'] != null && result['commande'] is Map) {
        return result['commande'];
      } else if (result['data'] != null) {
        if (result['data'] is Map && result['data']['commande'] != null) {
          return result['data']['commande'];
        } else if (result['data'] is Map) {
          return result['data'];
        }
      }
      print('⚠️ Structure de réponse non reconnue: ${result.keys}');
      return null;
    } catch (e) {
      print('❌ Erreur extraction données commande: $e');
      return null;
    }
  }

  // Fonction utilitaire pour afficher les erreurs
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // Traitement du paiement Stripe
  Future<void> _processStripePayment() async {
    setState(() {
      _isProcessingStripe = true;
    });

    try {
      print('💳 Début paiement Stripe pour commande');

      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/create-payment-intent-commande'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientId': widget.clientId,
          'montant': widget.prix,
          'commandeData': {
            'vehicleData': widget.vehicleData,
            'date': widget.date,
            'creneau': widget.creneau,
            'heure': widget.heure,
            'departLat': widget.latitude,
            'departLng': widget.longitude,
            'departAdresse': widget.selectedAddress,
            'typeLavage': widget.typeLavage,
            'prix': widget.prix,
            'methodPaiement': 'carte',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          await _setupPaymentSheet(data['clientSecret']);
        } else {
          throw Exception(data['message'] ?? 'Erreur création PaymentIntent');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isProcessingStripe = false;
      });

      print('❌ Erreur paiement Stripe: $e');
      _showError('Erreur paiement: ${e.toString()}');
    }
  }

  // Configuration du Payment Sheet
  Future<void> _setupPaymentSheet(String clientSecret) async {
    try {
      print('🔄 Configuration Payment Sheet...');

      final paymentSheetParameters = SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Glitty',
        style: ThemeMode.light,
        primaryButtonLabel: 'Payer ${_montantApresSolde.toStringAsFixed(2)}€',
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF022519),
            background: Colors.white,
            componentBackground: Colors.white,
            componentBorder: Color(0xFFE5E5E5),
            componentDivider: Color(0xFFE5E5E5),
            primaryText: Colors.black,
            secondaryText: Color(0xFF6B7280),
            componentText: Colors.black,
            placeholderText: Color(0xFF9CA3AF),
          ),
        ),
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'FR',
          currencyCode: 'EUR',
          testEnv: true,
        ),
        customFlow: false,
        allowsDelayedPaymentMethods: false,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: paymentSheetParameters,
      );

      print('🚀 Affichage Payment Sheet...');
      await Stripe.instance.presentPaymentSheet();

      print('✅ Paiement Stripe réussi !');
      await _createCommandeAfterStripe();
    } on StripeException catch (e) {
      setState(() {
        _isProcessingStripe = false;
      });
      _handleStripeError(e);
    } catch (e) {
      setState(() {
        _isProcessingStripe = false;
      });
      print('❌ Erreur Payment Sheet: $e');
      _showError('Erreur lors du paiement: ${e.toString()}');
    }
  }

  // Créer la commande après paiement Stripe réussi
  Future<void> _createCommandeAfterStripe() async {
    try {
      final xPhotos = _convertPhotosToXFiles();

      final methodPaiement =
          _useGlittyBalance && _glittyBalance > 0 ? 'mixte' : 'carte';

      final result = await CommandeService.createCommande(
        clientId: widget.clientId,
        vehicleId: null,
        vehicleData: widget.vehicleData,
        date: widget.date,
        creneau: widget.creneau,
        heure: widget.heure,
        departLat: widget.latitude,
        departLng: widget.longitude,
        departAdresse: widget.selectedAddress,
        arriveeLat: null,
        arriveeLng: null,
        arriveeAdresse: null,
        typeLavage: widget.typeLavage,
        prix: widget.prix,
        notes: null,
        dureeEstimee: null,
        methodPaiement: methodPaiement,
        photos: xPhotos,
      );

      setState(() {
        _isProcessingStripe = false;
      });

      if (result['success'] == true) {
        final commandeData = _extractCommandeData(result);

        if (commandeData != null) {
          String message = '🎉 Commande créée avec succès!';
          if (_useGlittyBalance) {
            message +=
                ' (${_soldeUtilise.toStringAsFixed(2)}€ de solde + ${_montantApresSolde.toStringAsFixed(2)}€ par carte)';
          }

          print(message);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmCommandePage(
                commandeData: commandeData,
              ),
            ),
          );
        } else {
          throw Exception('Données de commande non disponibles après paiement');
        }
      } else {
        throw Exception(
            result['error'] ?? 'Erreur création commande après paiement');
      }
    } catch (e) {
      setState(() {
        _isProcessingStripe = false;
      });

      print('❌ Erreur création commande après paiement: $e');
      _showError('Erreur après paiement: $e - Contactez le support');
    }
  }

  // Fonction pour gérer les erreurs Stripe
  void _handleStripeError(StripeException e) {
    String errorMessage = 'Erreur de paiement';
    Color backgroundColor = Colors.red;

    switch (e.error?.code) {
      case FailureCode.Canceled:
        errorMessage = 'Paiement annulé';
        backgroundColor = Colors.orange;
        break;
      case FailureCode.Failed:
        errorMessage = 'Paiement échoué';
        break;
      case FailureCode.Timeout:
        errorMessage = 'Délai dépassé';
        backgroundColor = Colors.orange;
        break;
      default:
        errorMessage = 'Erreur: ${e.error?.message ?? "Veuillez réessayer"}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Fonctions utilitaires existantes
  Map<String, String> _parseAddress(String fullAddress) {
    try {
      if (fullAddress.contains(',')) {
        final parts = fullAddress.split(',');
        if (parts.length >= 2) {
          return {
            'street': parts[0].trim(),
            'city': parts.sublist(1).join(',').trim(),
          };
        }
      }
      return {
        'street': fullAddress,
        'city': '',
      };
    } catch (e) {
      print('Erreur parsing adresse: $e');
      return {
        'street': fullAddress,
        'city': '',
      };
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
      ];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatCreneau(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin (8h-12h)';
      case 'apres_midi':
        return 'Après-midi (12h-17h)';
      case 'soir':
        return 'Soir (17h-20h)';
      default:
        return creneau;
    }
  }

  String _formatHeure(String? heure) {
    if (heure == null || heure.isEmpty) return '';
    return 'à $heure';
  }

  // NOUVELLE MÉTHODE: Texte dynamique du bouton
  String _getButtonText() {
    if (_useGlittyBalance) {
      if (_soldeSuffisant) {
        return "Payer avec mon solde Glitty";
      } else if (_selectedPaymentMethod == 'carte') {
        return "Payer ${_montantApresSolde.toStringAsFixed(2)}€ par carte";
      } else if (_selectedPaymentMethod == 'espece') {
        return "Payer ${_montantApresSolde.toStringAsFixed(2)}€ en espèces";
      } else {
        return "Valider la commande";
      }
    } else {
      return "Valider la commande";
    }
  }

  // NOUVELLE FONCTION : Widget pour afficher le service sélectionné
  Widget _buildServiceDetails() {
    final serviceConfig = _getServiceConfig();
    final color = serviceConfig['color'] as Color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF949494).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône du service
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [color, color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                serviceConfig['icon'] as IconData,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Détails du service
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceConfig['title'] as String,
                  style: const TextStyle(
                    color: Color(0xFF1B1D21),
                    fontFamily: "DM Sans",
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  serviceConfig['description'] as String,
                  style: const TextStyle(
                    color: Color(0xFF797979),
                    fontFamily: "DM Sans",
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // Liste des caractéristiques
                ...(serviceConfig['features'] as List<String>)
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_rounded,
                              color: color,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature,
                                style: const TextStyle(
                                  color: Color(0xFF797979),
                                  fontFamily: "DM Sans",
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),

          // Prix
          Container(
            padding: const EdgeInsets.all(8),
            child: Text(
              "${widget.prix.toStringAsFixed(2)}€",
              style: TextStyle(
                color: color,
                fontFamily: "DM Sans",
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addressParts = _parseAddress(widget.selectedAddress);

    return Scaffold(
      backgroundColor: _primaryColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  height: 180,
                  width: double.infinity,
                  color: _primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          Image.asset(
                            'assets/logo-glitty.png',
                            width: 149,
                            height: 69,
                          ),
                          Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: _primaryColor, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8)),
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText:
                                      'Prêt à faire briller sans polluer!',
                                  hintStyle: const TextStyle(
                                      color: Color.fromRGBO(0, 0, 0, 0.5),
                                      fontFamily: "DM Sans",
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 12),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(40),
                          topRight: Radius.circular(40)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Section Départ - Arrivée
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFF949494)
                                        .withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 4))
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: _accentColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Lieu d'intervention",
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontFamily: "DM Sans",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(addressParts['street']!,
                                              style: const TextStyle(
                                                  color: Color(0xFF1B1D21),
                                                  fontFamily: "DM Sans",
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500)),
                                          if (addressParts['city']!.isNotEmpty)
                                            Text(addressParts['city']!,
                                                style: const TextStyle(
                                                    color: Color(0xFF1B1D21),
                                                    fontFamily: "DM Sans",
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w500)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // SECTION : Détails du service (dynamique)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF949494).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Détails de la commande",
                                  style: TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "Poppins",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Service sélectionné (dynamique)
                                _buildServiceDetails(),

                                const SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color:
                                      const Color(0xFF1B1D21).withOpacity(0.1),
                                ),
                                const SizedBox(height: 16),

                                // Informations du véhicule
                                if (widget.vehicleData != null) ...[
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Informations du véhicule",
                                        style: TextStyle(
                                          color: Color(0xFF1B1D21),
                                          fontFamily: "DM Sans",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                          "Type",
                                          widget.vehicleData!['type'] ??
                                              'Non spécifié'),
                                      _buildInfoRow(
                                          "Immatriculation",
                                          widget.vehicleData![
                                                  'immatriculation'] ??
                                              'Non spécifié'),
                                      if (widget.vehicleData!['description'] !=
                                          null)
                                        _buildInfoRow("Description",
                                            widget.vehicleData!['description']),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: const Color(0xFF1B1D21)
                                            .withOpacity(0.1),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),
                                ],

                                // Date du rendez-vous
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Date du rendez-vous",
                                      style: TextStyle(
                                        color: Color(0xFF1B1D21),
                                        fontFamily: "DM Sans",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "${_formatDate(widget.date)} - ${_formatCreneau(widget.creneau)} ${_formatHeure(widget.heure)}",
                                      style: const TextStyle(
                                        color: Color(0xFF797979),
                                        fontFamily: "DM Sans",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color:
                                      const Color(0xFF1B1D21).withOpacity(0.1),
                                ),
                                const SizedBox(height: 16),

                                // Total - VERSION AVEC DÉDUCTION DU SOLDE
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_useGlittyBalance &&
                                        _soldeUtilise > 0) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Sous-total",
                                            style: const TextStyle(
                                              color: Color(0xFF797979),
                                              fontFamily: "DM Sans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "${widget.prix.toStringAsFixed(2)}€",
                                            style: const TextStyle(
                                              color: Color(0xFF1B1D21),
                                              fontFamily: "DM Sans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Solde Glitty utilisé",
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontFamily: "DM Sans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "-${_soldeUtilise.toStringAsFixed(2)}€",
                                            style: TextStyle(
                                              color: _accentColor,
                                              fontFamily: "DM Sans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: const Color(0xFF1B1D21)
                                            .withOpacity(0.1),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Total final
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _useGlittyBalance && _soldeUtilise > 0
                                              ? "Reste à payer"
                                              : "Total",
                                          style: const TextStyle(
                                            color: Color(0xFF1B1D21),
                                            fontFamily: "DM Sans",
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        Text(
                                          "${_montantApresSolde.toStringAsFixed(2)}€",
                                          style: TextStyle(
                                            color: _accentColor,
                                            fontFamily: "DM Sans",
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Message informatif selon le cas
                                    if (_useGlittyBalance) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _soldeSuffisant
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _soldeSuffisant
                                                  ? Icons.check_circle
                                                  : Icons.info,
                                              color: _soldeSuffisant
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _soldeSuffisant
                                                    ? "Votre solde couvre l'intégralité de la commande"
                                                    : "Votre solde ne couvre que ${_soldeUtilise.toStringAsFixed(2)}€ sur ${widget.prix.toStringAsFixed(2)}€",
                                                style: TextStyle(
                                                  color: _soldeSuffisant
                                                      ? Colors.green
                                                      : Colors.orange,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section Moyens de paiement
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF949494).withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "Moyens de paiement",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: "DM Sans",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildPaymentCard(
                                      iconPath: 'assets/Bank-Card.svg',
                                      title: "Carte",
                                      isSelected:
                                          _selectedPaymentMethod == 'carte',
                                      onTap: () => setState(() {
                                        _selectedPaymentMethod = 'carte';
                                      }),
                                    ),
                                    _buildPaymentCard(
                                      iconPath: 'assets/especes-Card.svg',
                                      title: "Espèces",
                                      isSelected:
                                          _selectedPaymentMethod == 'espece',
                                      onTap: () => setState(() {
                                        _selectedPaymentMethod = 'espece';
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Section Utiliser mon solde Glitty - MODIFIÉE
                                GestureDetector(
                                  onTap: _glittyBalance > 0
                                      ? () {
                                          setState(() {
                                            _useGlittyBalance =
                                                !_useGlittyBalance;
                                          });
                                        }
                                      : null,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _glittyBalance > 0
                                          ? Colors.white
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _glittyBalance > 0
                                            ? (_useGlittyBalance
                                                ? _accentColor
                                                : const Color(0xFFE6E8EC))
                                            : const Color(0xFFE6E8EC),
                                        width: _useGlittyBalance ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            // Checkbox
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: _glittyBalance > 0
                                                      ? (_useGlittyBalance
                                                          ? _accentColor
                                                          : const Color(
                                                              0xFFE6E8EC))
                                                      : Colors.grey[400]!,
                                                  width: 1,
                                                ),
                                                color: _useGlittyBalance &&
                                                        _glittyBalance > 0
                                                    ? _accentColor
                                                    : Colors.transparent,
                                              ),
                                              child: _useGlittyBalance &&
                                                      _glittyBalance > 0
                                                  ? const Center(
                                                      child: Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),

                                            // Texte avec indicateur de chargement
                                            _isLoadingBalance
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                                  Color>(
                                                              Color(
                                                                  0xFF022519)),
                                                    ),
                                                  )
                                                : Text(
                                                    _glittyBalance > 0
                                                        ? "Utiliser mon solde Glitty"
                                                        : "Solde Glitty indisponible",
                                                    style: TextStyle(
                                                      color: _glittyBalance > 0
                                                          ? Colors.black
                                                          : Colors.grey[600],
                                                      fontFamily: "DM Sans",
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                          ],
                                        ),

                                        // Montant du solde avec indicateur de chargement
                                        _isLoadingBalance
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Color(0xFF022519)),
                                                ),
                                              )
                                            : Text(
                                                "${_glittyBalance.toStringAsFixed(2)}€",
                                                style: TextStyle(
                                                  color: _glittyBalance > 0
                                                      ? _accentColor
                                                      : Colors.grey[600],
                                                  fontFamily: "DM Sans",
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),

                                // Bouton Valider - VERSION AMÉLIORÉE
                                _isLoading ||
                                        _isProcessingStripe ||
                                        _isProcessingSolde
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF4FBF67),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _createCommande,
                                        child: Container(
                                          width: double.infinity,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                _accentColor,
                                                _cardColor1
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: _accentColor
                                                    .withOpacity(0.3),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              _getButtonText(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: "DM Sans",
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Modal de paiement
          if (_showPaymentModal)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Paiement",
                                  style: TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "DM Sans",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(19),
                                    color: const Color(0xFF8F92A1)
                                        .withOpacity(0.1),
                                  ),
                                  child: const Text(
                                    "Ajouter",
                                    style: TextStyle(
                                      color: Color(0xFF1B1D21),
                                      fontFamily: "DM Sans",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFF1B1D21).withOpacity(0.1),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/payment-card.svg',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(height: 32),
                                  const Text(
                                    "Ajouter une Carte",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF1B1D21),
                                      fontFamily: "DM Sans",
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      "Il semble que vous n'ayez ajouté aucune carte de crédit ou de débit. Ajoutez une carte pour un accès plus rapide.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF797979),
                                        fontFamily: "DM Sans",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _showPaymentModal = false;
                                      _useGlittyBalance = false;
                                    }),
                                    child: Container(
                                      width: 295,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF797979),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Retour",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "DM Sans",
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // FONCTION : Widget pour construire une ligne d'information
  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF797979),
              fontFamily: "DM Sans",
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: const Color(0xFF1B1D21),
                fontFamily: "DM Sans",
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour construire une carte de paiement
  Widget _buildPaymentCard({
    required String iconPath,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 157,
        height: 118,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF949494).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(color: _accentColor, width: 2)
              : Border.all(color: const Color(0xFFE6E8EC), width: 1),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                    color: isSelected ? _accentColor : const Color(0xFF8F92A1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          isSelected ? _accentColor : const Color(0xFF1B1D21),
                      fontFamily: "DM Sans",
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? _accentColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? _accentColor : const Color(0xFFE6E8EC),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
