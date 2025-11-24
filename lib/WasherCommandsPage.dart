import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:glitty/ChecklistPreparationPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';
import 'package:intl/intl.dart';
import 'package:glitty/DashboardWasher.dart';

class WasherCommandsPage extends StatefulWidget {
  final String nom;
  final int washerId;

  const WasherCommandsPage(
      {Key? key, required this.nom, required this.washerId})
      : super(key: key);

  @override
  _WasherCommandsPageState createState() => _WasherCommandsPageState();
}

class _WasherCommandsPageState extends State<WasherCommandsPage> {
  List<Map<String, dynamic>> _commands = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  int _currentIndex =
      2; // Index pour la BottomNavigationBar (2 pour "Missions")

  @override
  void initState() {
    super.initState();
    _fetchCommands();
  }

  Future<void> _fetchCommands() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/washer/${widget.washerId}/commands'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _commands = List<Map<String, dynamic>>.from(data['data']);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showError('Aucune donnée reçue');
        }
      } else {
        setState(() => _isLoading = false);
        _showError('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur récupération commandes: $e');
      setState(() => _isLoading = false);
      _showError('Erreur de connexion');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Nouvelle méthode pour mettre à jour le statut de la commande
  Future<bool> _updateCommandeStatut(
      int commandeId, String nouveauStatut) async {
    try {
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId/statut'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statut': nouveauStatut}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccess('Commande terminée avec succès');
          return true;
        } else {
          _showError(data['message'] ?? 'Erreur lors de la mise à jour');
          return false;
        }
      } else {
        _showError('Erreur serveur: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Erreur mise à jour statut commande: $e');
      _showError('Erreur de connexion');
      return false;
    }
  }

  // Méthode pour terminer une commande
  void _terminerCommande(int commandeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la commande'),
        content: const Text(
            'Voulez-vous terminer cette commande ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer la dialog

              // Afficher un indicateur de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Mettre à jour le statut
              final success =
                  await _updateCommandeStatut(commandeId, 'terminee');

              // Fermer l'indicateur de chargement
              if (context.mounted) {
                Navigator.pop(context);
              }

              if (success && context.mounted) {
                // Rafraîchir la liste des commandes
                _fetchCommands();
              }
            },
            child: const Text(
              'Terminer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredCommands {
    switch (_selectedFilter) {
      case 'confirmed':
        return _commands.where((cmd) => cmd['statut'] == 'confirmee').toList();
      case 'in_progress':
        return _commands.where((cmd) => cmd['statut'] == 'en_cours').toList();
      case 'completed':
        return _commands.where((cmd) => cmd['statut'] == 'terminee').toList();
      case 'all':
      default:
        return _commands;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return Colors.blue;
      case 'en_cours':
        return Colors.green;
      case 'terminee':
        return Colors.grey;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  String _getCreneauDisplay(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin';
      case 'apres_midi':
        return 'Après-midi';
      case 'soir':
        return 'Soir';
      default:
        return creneau;
    }
  }

  Widget _buildCommandCard(Map<String, dynamic> commande, int index) {
    final status = commande['statut'] ?? 'en_attente';
    final prix = (commande['prix'] as num?)?.toDouble() ?? 0.0;
    final date = commande['date'] ?? '';
    final creneau = commande['creneau'] ?? '';
    final typeLavage = commande['type_lavage'] ?? '';
    final commandeId = commande['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            _showCommandDetails(commande);
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec référence et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF022519).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: const Color(0xFF022519),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Commande #${commande['reference'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF022519),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Informations client
                _buildInfoRow(
                  Icons.person_outline,
                  '${commande['client_first_name'] ?? ''} ${commande['client_last_name'] ?? ''}',
                ),
                const SizedBox(height: 8),

                // Véhicule
                _buildInfoRow(
                  Icons.directions_car_outlined,
                  '${commande['vehicle_type'] ?? ''} • ${commande['vehicle_immatriculation'] ?? ''}',
                ),
                const SizedBox(height: 8),

                // Type de lavage
                _buildInfoRow(
                  Icons.cleaning_services_outlined,
                  typeLavage,
                ),
                const SizedBox(height: 12),

                // Date et créneau
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${_formatDate(date)} • ${_getCreneauDisplay(creneau)}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Prix et actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF022519), Color(0xFF1A3A5F)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${prix.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Actions et indicateur de détails
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Détails',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Bouton d'action selon le statut
                        if (status == 'confirmee')
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChecklistPreparationPage(
                                    nom: widget.nom,
                                    washerId: widget.washerId,
                                    commande: commande,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF34C759),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Préparer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else if (status == 'en_cours')
                          ElevatedButton(
                            onPressed: () {
                              _terminerCommande(commandeId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Terminer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  void _showCommandDetails(Map<String, dynamic> commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCommandDetailsSheet(commande),
    );
  }

  Widget _buildCommandDetailsSheet(Map<String, dynamic> commande) {
    final status = commande['statut'] ?? 'en_attente';
    final commandeId = commande['id'];

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Détails Commande',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Référence', commande['reference'] ?? ''),
                    _buildDetailItem(
                        'Statut', _getStatusText(commande['statut'] ?? '')),
                    _buildDetailItem(
                        'Date', _formatDate(commande['date'] ?? '')),
                    _buildDetailItem('Créneau',
                        _getCreneauDisplay(commande['creneau'] ?? '')),
                    _buildDetailItem(
                        'Type de lavage', commande['type_lavage'] ?? ''),
                    _buildDetailItem('Prix',
                        '${((commande['prix'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}€'),
                    const SizedBox(height: 20),
                    const Text(
                      'Client',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022519),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailItem('Nom',
                        '${commande['client_first_name'] ?? ''} ${commande['client_last_name'] ?? ''}'),
                    _buildDetailItem('Téléphone',
                        commande['client_phone'] ?? 'Non renseigné'),
                    const SizedBox(height: 20),
                    const Text(
                      'Véhicule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022519),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailItem('Type', commande['vehicle_type'] ?? ''),
                    _buildDetailItem('Immatriculation',
                        commande['vehicle_immatriculation'] ?? ''),
                    _buildDetailItem(
                        'Description',
                        commande['vehicle_description'] ??
                            'Aucune description'),
                    const SizedBox(height: 20),
                    const Text(
                      'Localisation',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022519),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailItem(
                        'Adresse départ', commande['depart_adresse'] ?? ''),
                    if (commande['notes'] != null) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF022519),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        commande['notes'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Bouton Terminer dans les détails si la commande est en cours
                    if (status == 'en_cours') ...[
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context); // Fermer les détails
                            _terminerCommande(commandeId);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Terminer la commande',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'value': 'all', 'label': 'Toutes'},
      {'value': 'confirmed', 'label': 'Confirmées'},
      {'value': 'in_progress', 'label': 'En cours'},
      {'value': 'completed', 'label': 'Terminées'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter['value']!;
                });
              },
              label: Text(filter['label']!),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF022519),
                fontWeight: FontWeight.w500,
              ),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF022519),
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected ? const Color(0xFF022519) : Colors.grey[300]!,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // HEADER AMÉLIORÉ - Même style que CommandesAujourdhuiPage
  Widget _buildEnhancedHeader() {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF34C759);

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/menu-icone.png',
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Image.asset(
                'assets/logo-glitty.png',
                width: 130,
                height: 60,
              ),
              GestureDetector(
                onTap: () => _navigateToNotifications(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/notification-icone.png',
                        width: 20,
                        height: 20,
                        color: Colors.white,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Titre et statistiques
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Toutes les Commandes",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: "DM Sans",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Gestion des missions",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "DM Sans",
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.list_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_commands.length} commande(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Méthodes de navigation
  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(washerId: widget.washerId),
      ),
    );
  }

  // Bottom Navigation Bar CORRIGÉE - Version identique à votre exemple
  Widget _buildBottomNavigationBar() {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF34C759);

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          color: primaryColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(0, Icons.dashboard_rounded),
              _buildBottomNavItem(1, Icons.today_rounded),
              _buildBottomNavItem(2, Icons.cleaning_services_rounded),
              _buildBottomNavItem(3, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(int index, IconData icon) {
    final isActive = _currentIndex == index;
    const accentColor = Color(0xFF34C759);

    return GestureDetector(
      onTap: () => _onBottomNavItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 24,
          color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  void _onBottomNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardWasherPage(
              nom: widget.nom,
              washerId: widget.washerId,
            ),
          ),
        );
        break;
      case 1: // Aujourd'hui
        // Vous pouvez ajouter la navigation vers la page "Aujourd'hui" ici
        // Navigator.pushReplacement(...);
        break;
      case 2: // Missions (déjà sur cette page)
        // Ne rien faire, on est déjà sur cette page
        break;
      case 3: // Profil
        // Vous pouvez ajouter la navigation vers la page de profil ici
        // Navigator.pushReplacement(...);
        break;
    }
  }

  // Drawer amélioré avec la même structure que votre exemple
  Widget _buildModernDrawer(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF34C759);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Section header réduite
              Container(
                height: 130,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: accentColor,
                        child: Text(
                          widget.nom.isNotEmpty
                              ? widget.nom[0].toUpperCase()
                              : 'W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.nom.length > 12
                          ? '${widget.nom.substring(0, 12)}...'
                          : widget.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: const Text(
                        "Washer",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          _buildDrawerItem(
                            Icons.dashboard_rounded,
                            "Dashboard",
                            false,
                            primaryColor,
                            () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DashboardWasherPage(
                                  nom: widget.nom,
                                  washerId: widget.washerId,
                                ),
                              ),
                            ),
                          ),
                          _buildDrawerItem(
                            Icons.today_rounded,
                            "Aujourd'hui",
                            false,
                            primaryColor,
                            () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            Icons.list_alt_rounded,
                            "Mes Commandes",
                            true,
                            primaryColor,
                            () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            Icons.calendar_month_rounded,
                            "Planning",
                            false,
                            primaryColor,
                            () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            Icons.account_balance_wallet_rounded,
                            "Mes gains",
                            false,
                            primaryColor,
                            () => Navigator.pushNamed(
                                context, '/washer-earnings'),
                          ),
                          _buildDrawerItem(
                            Icons.location_on_rounded,
                            "Localisation",
                            false,
                            primaryColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WasherSetGPSPage(
                                  washerId: widget.washerId,
                                ),
                              ),
                            ),
                          ),
                          _buildDrawerItem(
                            Icons.lock_rounded,
                            "Sécurité",
                            false,
                            primaryColor,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WasherSetPasswordPage(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 5),
                            child: _buildDrawerItem(
                              Icons.logout_rounded,
                              "Déconnexion",
                              false,
                              Colors.red,
                              () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginWasherPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isActive,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.2) : Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: isActive ? color : Colors.grey[600],
            size: 16,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? color : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6),
        minLeadingWidth: 0,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF022519).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.list_alt_outlined,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune commande',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF022519),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Vous n\'avez aucune commande pour le moment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchCommands,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF022519),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'Actualiser',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildModernDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header amélioré
            _buildEnhancedHeader(),

            // Contenu principal
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Filtres
                      _buildFilterChips(),
                      const SizedBox(height: 20),

                      // Compteur
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF022519).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF022519).withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF022519),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${_filteredCommands.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${_filteredCommands.length} commande${_filteredCommands.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF022519),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _fetchCommands,
                              icon: Icon(
                                Icons.refresh,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Liste des commandes
                      Expanded(
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF022519),
                                ),
                              )
                            : _filteredCommands.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _fetchCommands,
                                    color: const Color(0xFF022519),
                                    child: ListView.builder(
                                      itemCount: _filteredCommands.length,
                                      itemBuilder: (context, index) {
                                        return _buildCommandCard(
                                            _filteredCommands[index], index);
                                      },
                                    ),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}

// Classe temporaire pour les notifications (à remplacer par votre vraie classe)
class NotificationsPage extends StatelessWidget {
  final int washerId;

  const NotificationsPage({Key? key, required this.washerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('Page des notifications'),
      ),
    );
  }
}
