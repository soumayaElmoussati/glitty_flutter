import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'services/MockApiService.dart';

class AdminValidationPage extends StatefulWidget {
  const AdminValidationPage({Key? key}) : super(key: key);

  @override
  _AdminValidationPageState createState() => _AdminValidationPageState();
}

class _AdminValidationPageState extends State<AdminValidationPage> {
  List<dynamic> _pendingWashers = [];
  bool _isLoading = true;

  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'https://glitty.fr';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchPendingWashers();
  }

  Future<void> _fetchPendingWashers() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/washers/pending'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _pendingWashers = data['washers'] ?? [];
          _isLoading = false;
        });
      } else {
        _showError("Erreur lors du chargement des washers en attente");
      }
    } catch (e) {
      _showError("Erreur réseau: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _validateWasher(int washerId, bool approved) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/admin/washers/validate/$washerId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'approved': approved}),
      );

      if (response.statusCode == 200) {
        _showSuccess(approved
            ? "Washer approuvé avec succès !"
            : "Washer rejeté avec succès !");
        await _fetchPendingWashers(); // Rafraîchir la liste
      } else {
        throw Exception('Erreur lors de la validation');
      }
    } catch (e) {
      _showError("Erreur: $e");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkColor = Color(0xFF022519);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Validation des Washers',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingWashers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchPendingWashers,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingWashers.length,
                    itemBuilder: (context, index) {
                      return _buildWasherCard(_pendingWashers[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun washer en attente',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les washers ont été traités',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasherCard(Map<String, dynamic> washer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec avatar
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0xFF022519),
                  child: Text(
                    '${washer['nom']?[0] ?? ''}${washer['prenom']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${washer['nom']} ${washer['prenom']}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'En attente de validation',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Informations personnelles
            _buildInfoSection('Informations personnelles', [
              _buildInfoRow('Email', washer['email']),
              _buildInfoRow('Téléphone', washer['telephone']),
              _buildInfoRow('Adresse', washer['adresse']),
              _buildInfoRow(
                  'Date d\'inscription',
                  washer['date_creation']?.toString().substring(0, 10) ??
                      'N/A'),
            ]),

            const SizedBox(height: 20),

            // Documents soumis
            _buildInfoSection('Documents soumis', [
              _buildDocumentRow('Pièce d\'identité', washer['piece_identite']),
              _buildDocumentRow(
                  'Justificatif domicile', washer['justificatif_domicile']),
              _buildDocumentRow(
                  'Permis de conduire', washer['permis_conduire']),
              _buildDocumentRow(
                  'Certificats formation', washer['certificats_formation']),
            ]),

            const SizedBox(height: 24),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(washer),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text('Rejeter',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(washer),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Approuver',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF022519),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non renseigné',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(String label, String? fileName) {
    final hasDocument = fileName != null && fileName.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  hasDocument ? Icons.check_circle : Icons.cancel,
                  color: hasDocument ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasDocument ? fileName : 'Non fourni',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: hasDocument ? Colors.black : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveDialog(Map<String, dynamic> washer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer l\'approbation'),
        content: Text(
          'Voulez-vous approuver ${washer['nom']} ${washer['prenom']} comme washer ?\n\n'
          'Cette action enverra une notification de validation et activera son compte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child:
                const Text('Approuver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _validateWasher(washer['id'], true);
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> washer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le rejet'),
        content: Text(
          'Voulez-vous rejeter la candidature de ${washer['nom']} ${washer['prenom']} ?\n\n'
          'Cette action est définitive et enverra une notification de rejet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _validateWasher(washer['id'], false);
    }
  }
}
