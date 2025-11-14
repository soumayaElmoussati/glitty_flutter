// lib/WasherCommandeDetailPage.dart
import 'package:flutter/material.dart';
import 'package:glitty/services/commande_service.dart';
import 'package:glitty/services/notification_service.dart';

class WasherCommandeDetailPage extends StatefulWidget {
  final int commandeId;
  final int notificationId;
  final int washerId;

  const WasherCommandeDetailPage({
    Key? key,
    required this.commandeId,
    required this.notificationId,
    required this.washerId,
  }) : super(key: key);

  @override
  _WasherCommandeDetailPageState createState() =>
      _WasherCommandeDetailPageState();
}

class _WasherCommandeDetailPageState extends State<WasherCommandeDetailPage> {
  Map<String, dynamic>? _commandeData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCommandeDetail();
    _markNotificationAsRead();
  }

  Future<void> _loadCommandeDetail() async {
    // Implémentez cette méthode pour récupérer les détails de la commande
    // depuis votre API
    setState(() {
      _isLoading = false;
      _commandeData = {}; // Données simulées
    });
  }

  Future<void> _markNotificationAsRead() async {
    await NotificationService.markAsRead(widget.notificationId);
  }

  Future<void> _acceptCommande() async {
    final result = await NotificationService.acceptCommande(
      notificationId: widget.notificationId,
      commandeId: widget.commandeId,
      washerId: widget.washerId,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande acceptée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la commande'),
        backgroundColor: const Color(0xFF022519),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCommandeDetail(),
    );
  }

  Widget _buildCommandeDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ajoutez ici les détails de la commande similaires à RecapCommandePage
          // mais adaptés pour le washer
          _buildInfoCard('Adresse', '123 Rue Example, Paris'),
          _buildInfoCard('Type de lavage', 'Lavage Complet'),
          _buildInfoCard('Prix', '45.00€'),
          _buildInfoCard('Date', '15 Décembre 2024 - Matin'),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _acceptCommande,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Accepter la commande',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
