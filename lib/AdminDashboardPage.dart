import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({Key? key}) : super(key: key);

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _pendingWashers = [];
  List<dynamic> _approvedWashers = [];
  List<dynamic> _rejectedWashers = [];
  bool _isLoading = true;

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
    _tabController = TabController(length: 4, vsync: this);
    _fetchAllWashers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllWashers() async {
    setState(() => _isLoading = true);
    try {
      await _fetchPendingWashers();
      setState(() {
        _approvedWashers = [];
        _rejectedWashers = [];
      });
    } catch (e) {
      _showError("Erreur réseau: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchPendingWashers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/washers/pending'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _pendingWashers = data['washers'] ?? [];
      });
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
        await _fetchAllWashers();
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
    const primaryColor = Color(0xFF022519);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white),
            SizedBox(width: 8),
            Text('Dashboard Admin', 
                  style: TextStyle(color: Colors.white)),
          ],
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Vue d\'ensemble',
            ),
            Tab(
              icon: Icon(Icons.hourglass_empty),
              text: 'En attente (${_pendingWashers.length})',
            ),
            Tab(
              icon: Icon(Icons.check_circle),
              text: 'Approuvés (${_approvedWashers.length})',
            ),
            Tab(
              icon: Icon(Icons.cancel),
              text: 'Rejetés (${_rejectedWashers.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildWashersTab(_pendingWashers, 'pending'),
                _buildWashersTab(_approvedWashers, 'approved'),
                _buildWashersTab(_rejectedWashers, 'rejected'),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    const primaryColor = Color(0xFF022519);
    final totalWashers = _pendingWashers.length + _approvedWashers.length + _rejectedWashers.length;
    
    return RefreshIndicator(
      onRefresh: _fetchAllWashers,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Washers',
                    totalWashers.toString(),
                    Icons.people,
                    primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'En attente',
                    _pendingWashers.length.toString(),
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Approuvés',
                    _approvedWashers.length.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Rejetés',
                    _rejectedWashers.length.toString(),
                    Icons.cancel,
                    Colors.red,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Actions rapides
            Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_pendingWashers.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notification_important, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Text(
                          '${_pendingWashers.length} washers en attente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Des candidats attendent votre validation.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _tabController.animateTo(1),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir les candidatures'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Aucune candidature en attente',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                    Text(
                      'Toutes les demandes ont été traitées.',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWashersTab(List<dynamic> washers, String status) {
    if (washers.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _fetchAllWashers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: washers.length,
        itemBuilder: (context, index) {
          return _buildWasherCard(washers[index], status);
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String title, subtitle;
    IconData icon;
    Color color;

    switch (status) {
      case 'pending':
        title = 'Aucune candidature en attente';
        subtitle = 'Toutes les demandes ont été traitées';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case 'approved':
        title = 'Aucun washer approuvé';
        subtitle = 'Les washers approuvés apparaîtront ici';
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'rejected':
        title = 'Aucun washer rejeté';
        subtitle = 'Les washers rejetés apparaîtront ici';
        icon = Icons.cancel;
        color = Colors.red;
        break;
      default:
        title = 'Aucun élément';
        subtitle = '';
        icon = Icons.info;
        color = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: color.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWasherCard(Map<String, dynamic> washer, String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.hourglass_empty;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Approuvé';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejeté';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Inconnu';
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFF022519),
                  child: Text(
                    '${washer['nom']?[0] ?? ''}${washer['prenom']?[0] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${washer['nom']} ${washer['prenom']}',
                        style: const TextStyle(
                          fontSize: 18,
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
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Informations
            _buildInfoRow('Email', washer['email']),
            _buildInfoRow('Téléphone', washer['telephone']),
            _buildInfoRow('Date', 
                washer['date_creation']?.toString().substring(0, 10) ?? 'N/A'),
            
            // Actions pour les washers en attente
            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRejectDialog(washer),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApproveDialog(washer),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(Map<String, dynamic> washer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Approuver le washer'),
          ],
        ),
        content: Text(
          'Voulez-vous approuver ${washer['nom']} ${washer['prenom']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _validateWasher(washer['id'], true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> washer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Rejeter le washer'),
          ],
        ),
        content: Text(
          'Voulez-vous rejeter ${washer['nom']} ${washer['prenom']} ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _validateWasher(washer['id'], false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
} 