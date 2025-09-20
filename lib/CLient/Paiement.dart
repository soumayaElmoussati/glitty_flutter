import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class PaiementPage extends StatefulWidget {
  final int reservationId;
  final int amount; // in cents
  final String currency;

  const PaiementPage({
    Key? key,
    required this.reservationId,
    required this.amount,
    this.currency = 'EUR',
  }) : super(key: key);

  @override
  _PaiementPageState createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
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
    // Pour le web, afficher simplement un message explicatif
    _showWebPaymentFallback();
  }

  void _showWebPaymentFallback() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paiement Web'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pour effectuer le paiement sur le web, veuillez:'),
            const SizedBox(height: 8),
            const Text('1. Contactez notre service client'),
            const Text('2. Ou utilisez l\'application mobile'),
            const SizedBox(height: 16),
            Text('Réservation: #${widget.reservationId}'),
            Text('Montant: ${(widget.amount/100).toStringAsFixed(2)} ${widget.currency}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleMobilePayment() async {
    // 1. Create Payment Intent
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/reservations/intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': (widget.amount / 100), // Convert back to euros
        'currency': widget.currency.toLowerCase(),
        'reservationId': widget.reservationId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create payment intent: ${response.body}');
    }

    final paymentIntent = json.decode(response.body);
    
    // 2. Confirm Payment
    await _confirmPaymentMobile(paymentIntent['clientSecret']);

    // 3. Confirm payment with backend
    await _confirmPaymentWithBackend(paymentIntent['paymentIntentId']);

    // 4. Show success
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paiement réussi!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _confirmPaymentWithBackend(String paymentIntentId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/api/reservations/confirm/${widget.reservationId}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'paymentIntentId': paymentIntentId,
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
            billingDetails: BillingDetails(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.blue,
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
                      'Détails de la réservation',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Réservation #${widget.reservationId}'),
                    Text('Montant: ${(widget.amount/100).toStringAsFixed(2)} ${widget.currency}'),
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
                      Icon(Icons.payment, size: 48, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Paiement sécurisé',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vous allez être redirigé vers notre page de paiement sécurisée.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (_cardController != null) ...[
              CardField(controller: _cardController!),
            ],
            
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _handlePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                      kIsWeb 
                        ? 'Procéder au paiement ${(widget.amount/100).toStringAsFixed(2)} €'
                        : 'Payer ${(widget.amount/100).toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            
            if (kIsWeb) ...[
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