import 'package:flutter/material.dart';
import 'package:glitty/MissionSuiviPage.dart';
import 'package:glitty/WasherCommandsPage.dart' hide NotificationsPage;
import 'package:glitty/config/env.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/NotificationsPage.dart';
import 'package:glitty/WasherEarningsPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommandesAujourdhuiPage extends StatefulWidget {
  final int washerId;
  final String nom;

  const CommandesAujourdhuiPage({
    Key? key,
    required this.washerId,
    required this.nom,
  }) : super(key: key);

  @override
  _CommandesAujourdhuiPageState createState() =>
      _CommandesAujourdhuiPageState();
}

class _CommandesAujourdhuiPageState extends State<CommandesAujourdhuiPage> {
  List<dynamic> _commandes = [];
  Map<String, dynamic> _statistiques = {};
  bool _isLoading = true;
  bool _error = false;
  int _currentIndex =
      1; // Index pour la BottomNavigationBar (1 pour "Aujourd'hui")

  @override
  void initState() {
    super.initState();
    _fetchCommandesAujourdhui();
  }

  Future<void> _fetchCommandesAujourdhui() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/commande/washer/${widget.washerId}/commandes-aujourdhui'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _commandes = data['data']['commandes'] ?? [];
          _statistiques = data['data']['statistiques'] ?? {};
        });
      } else {
        setState(() {
          _error = true;
        });
        _showError('Erreur lors du chargement des commandes');
      }
    } catch (e) {
      setState(() {
        _error = true;
      });
      _showError('Erreur de connexion');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _showCommandeDetails(Map<String, dynamic> commande) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildCommandeDetails(commande),
    );
  }

  Widget _buildStatistiques() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aperçu du jour',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF022519),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _statistiques['total']?.toString() ?? '0',
                  Colors.blue),
              _buildStatItem('Confirmées',
                  _statistiques['confirmees']?.toString() ?? '0', Colors.green),
              _buildStatItem('En cours',
                  _statistiques['en_cours']?.toString() ?? '0', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildCommandeCard(Map<String, dynamic> commande) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (commande['statut']) {
      case 'en_cours':
        statusColor = Colors.orange;
        statusIcon = Icons.play_arrow_rounded;
        statusText = 'En cours';
        break;
      case 'confirmee':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'Confirmée';
        break;
      case 'en_attente':
        statusColor = Colors.grey;
        statusIcon = Icons.schedule_rounded;
        statusText = 'En attente';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_rounded;
        statusText = 'Inconnu';
    }

    String creneauText = _getCreneauText(commande['creneau']);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCommandeDetails(commande),
          borderRadius: BorderRadius.circular(16),
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
                      child: Text(
                        'Commande #${commande['reference']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF022519),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Type de lavage et prix
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF022519).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.local_car_wash,
                          size: 18, color: const Color(0xFF022519)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getLavageTitle(commande['type_lavage']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            creneauText,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${commande['prix']}€',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Informations client et véhicule
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  commande['client']['nom_complet'] ?? 'Client',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.directions_car,
                                  size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${commande['vehicule']['type'] ?? ''} • ${commande['vehicule']['immatriculation'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Adresse
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        commande['depart_adresse'] ?? 'Adresse non spécifiée',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Actions
                if ((commande['can_start'] == true) ||
                    (commande['is_en_cours'] == true))
                  const SizedBox(height: 16),
                if ((commande['can_start'] == true) ||
                    (commande['is_en_cours'] == true))
                  Row(
                    children: [
                      if (commande['can_start'] == true)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _demarrerCommande(commande['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.play_arrow, size: 18),
                                SizedBox(width: 8),
                                Text('Démarrer'),
                              ],
                            ),
                          ),
                        ),
                      if (commande['is_en_cours'] == true)
                        const SizedBox(width: 12),
                      if (commande['is_en_cours'] == true)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _terminerCommande(commande['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 18),
                                SizedBox(width: 8),
                                Text('Terminer'),
                              ],
                            ),
                          ),
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

  Widget _buildCommandeDetails(Map<String, dynamic> commande) {
    String statusText = _getStatusText(commande['statut']);
    String creneauText = _getCreneauText(commande['creneau']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Détails de la commande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF022519),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailItem('Référence', commande['reference']),
          _buildDetailItem(
              'Type de lavage', _getLavageTitle(commande['type_lavage'])),
          _buildDetailItem('Prix', '${commande['prix']}€'),
          _buildDetailItem('Créneau', creneauText),
          if (commande['heure'] != null)
            _buildDetailItem(
                'Heure', commande['heure'].toString().substring(0, 5)),
          _buildDetailItem('Statut', statusText),
          const SizedBox(height: 16),
          const Text(
            'Informations client',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          _buildDetailItem('Nom', commande['client']['nom_complet']),
          _buildDetailItem(
              'Téléphone', commande['client']['telephone'] ?? 'Non renseigné'),
          _buildDetailItem(
              'Email', commande['client']['email'] ?? 'Non renseigné'),
          const SizedBox(height: 16),
          const Text(
            'Informations véhicule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          _buildDetailItem(
              'Type', commande['vehicule']['type'] ?? 'Non spécifié'),
          _buildDetailItem('Immatriculation',
              commande['vehicule']['immatriculation'] ?? 'Non renseignée'),
          const SizedBox(height: 16),
          const Text(
            'Adresse',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          _buildDetailItem(
              'Lieu', commande['depart_adresse'] ?? 'Non spécifiée'),
          const SizedBox(height: 20),
          if ((commande['can_start'] == true) ||
              (commande['is_en_cours'] == true))
            Row(
              children: [
                if (commande['can_start'] == true)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _demarrerCommande(commande['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow),
                          SizedBox(width: 8),
                          Text('Démarrer la mission'),
                        ],
                      ),
                    ),
                  ),
                if (commande['is_en_cours'] == true) const SizedBox(width: 12),
                if (commande['is_en_cours'] == true)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _terminerCommande(commande['id']);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check),
                          SizedBox(width: 8),
                          Text('Terminer la mission'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF022519),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLavageTitle(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return "Lavage Intérieur";
      case 'lavage_exterieur':
        return "Lavage Extérieur";
      case 'lavage_complet':
        return "Lavage Premium";
      default:
        return typeLavage;
    }
  }

  String _getCreneauText(String creneau) {
    switch (creneau) {
      case 'matin':
        return "Matin (8h-12h)";
      case 'apres_midi':
        return "Après-midi (12h-17h)";
      case 'soir':
        return "Soir (17h-21h)";
      default:
        return "Non spécifié";
    }
  }

  String _getStatusText(String statut) {
    switch (statut) {
      case 'en_cours':
        return "En cours";
      case 'confirmee':
        return "Confirmée";
      case 'en_attente':
        return "En attente";
      case 'terminee':
        return "Terminée";
      case 'annulee':
        return "Annulée";
      default:
        return "Inconnu";
    }
  }

  void _demarrerCommande(int commandeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrer la mission'),
        content: const Text('Voulez-vous démarrer cette mission ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fermer la dialog

              // Mettre à jour le statut de la commande
              final success =
                  await _updateCommandeStatut(commandeId, 'en_cours');

              if (success) {
                // Trouver les données de la commande pour les passer à MissionSuiviPage
                final commande = _commandes.firstWhere(
                  (cmd) => cmd['id'] == commandeId,
                );

                // Naviguer vers la page MissionSuiviPage avec les données
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MissionSuiviPage(
                      commandeId: commandeId,
                      clientAddress: commande['depart_adresse'],
                      clientLatitude: _extractLatitude(commande),
                      clientLongitude: _extractLongitude(commande),
                      washerId: widget.washerId,
                      nom: widget.nom,
                    ),
                  ),
                );
              }
            },
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  // Méthodes pour extraire les coordonnées GPS
  double? _extractLatitude(Map<String, dynamic> commande) {
    // Si votre API retourne les coordonnées directement
    if (commande['latitude'] != null) {
      return double.tryParse(commande['latitude'].toString());
    }

    // Si les coordonnées sont dans un sous-objet
    if (commande['location'] != null &&
        commande['location']['latitude'] != null) {
      return double.tryParse(commande['location']['latitude'].toString());
    }

    // Si les coordonnées sont dans client
    if (commande['client'] != null && commande['client']['latitude'] != null) {
      return double.tryParse(commande['client']['latitude'].toString());
    }

    return null;
  }

  double? _extractLongitude(Map<String, dynamic> commande) {
    // Si votre API retourne les coordonnées directement
    if (commande['longitude'] != null) {
      return double.tryParse(commande['longitude'].toString());
    }

    // Si les coordonnées sont dans un sous-objet
    if (commande['location'] != null &&
        commande['location']['longitude'] != null) {
      return double.tryParse(commande['location']['longitude'].toString());
    }

    // Si les coordonnées sont dans client
    if (commande['client'] != null && commande['client']['longitude'] != null) {
      return double.tryParse(commande['client']['longitude'].toString());
    }

    return null;
  }

  void _terminerCommande(int commandeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terminer la mission'),
        content: const Text('Voulez-vous terminer cette mission ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateCommandeStatut(commandeId, 'terminee');
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  Future<bool> _updateCommandeStatut(
      int commandeId, String nouveauStatut) async {
    try {
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId/statut'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statut': nouveauStatut}),
      );

      if (response.statusCode == 200) {
        _showSuccess('Statut mis à jour avec succès');
        _fetchCommandesAujourdhui(); // Rafraîchir la liste
        return true;
      } else {
        _showError('Erreur lors de la mise à jour');
        return false;
      }
    } catch (e) {
      _showError('Erreur de connexion');
      return false;
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF34C759); // Vert light plus agréable

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
                      "Commandes du Jour",
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
                      Icons.today,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_commandes.length} commande(s)',
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

  void _navigateToDashboard(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardWasherPage(
          nom: widget.nom,
          washerId: widget.washerId,
        ),
      ),
    );
  }

  void _navigateToEarnings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasherEarningsPage(
          washerId: widget.washerId,
        ),
      ),
    );
  }

  void _navigateToLocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasherSetGPSPage(
          washerId: widget.washerId,
          washerData: null,
        ),
      ),
    );
  }

  // Bottom Navigation Bar simplifiée sans labels
  Widget _buildBottomNavigationBar() {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF34C759); // Vert light plus agréable

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
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
    const accentColor = Color(0xFF34C759); // Vert light plus agréable

    return GestureDetector(
      onTap: () => _onBottomNavItemTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
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
      case 1: // Aujourd'hui (déjà sur cette page)
        // Ne rien faire, on est déjà sur cette page
        break;
      case 2: // Missions
        // Vous pouvez ajouter la navigation vers la page des missions ici
        // Navigator.pushReplacement(...);
        break;
      case 3: // Profil
        // Vous pouvez ajouter la navigation vers la page de profil ici
        // Navigator.pushReplacement(...);
        break;
    }
  }

  // Drawer
  Widget _buildModernDrawer(
      BuildContext context, Color primaryColor, Color accentColor) {
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
                            () => _navigateToDashboard(context),
                          ),
                          _buildDrawerItem(
                            Icons.today_rounded,
                            "Aujourd'hui",
                            true,
                            primaryColor,
                            () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            Icons.list_alt_rounded,
                            "Mes commandes",
                            false,
                            primaryColor,
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WasherCommandsPage(
                                    nom: widget.nom,
                                    washerId: widget.washerId,
                                  ),
                                ),
                              );
                            },
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
                            () => _navigateToEarnings(context),
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
                                        ))),
                          ),
                          _buildDrawerItem(
                            Icons.help_rounded,
                            "Aide & Support",
                            false,
                            primaryColor,
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MesTicketsWasher(
                                    washerId: widget.washerId,
                                    washerData: null,
                                  ),
                                ),
                              );
                            },
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
                              () async {
                                final shouldLogout = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                        "Déconnexion",
                                        style: TextStyle(
                                          color: Color(0xFF022519),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      content: const Text(
                                          "Êtes-vous sûr de vouloir vous déconnecter ?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(false),
                                          child: const Text("Annuler"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(true),
                                          child: const Text(
                                            "Déconnexion",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldLogout == true) {
                                  await AuthService.logout();
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const WelcomePage()),
                                    (route) => false,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Déconnexion réussie"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
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

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer:
          _buildModernDrawer(context, primaryColor, const Color(0xFF34C759)),
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
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: _fetchCommandesAujourdhui,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              _buildStatistiques(),
                              Expanded(
                                child: _commandes.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.event_available,
                                                size: 64, color: Colors.grey),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Aucune commande aujourd\'hui',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.grey),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Profitez de votre journée !',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey[500]),
                                            ),
                                          ],
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: _fetchCommandesAujourdhui,
                                        child: ListView.builder(
                                          itemCount: _commandes.length,
                                          itemBuilder: (context, index) {
                                            return _buildCommandeCard(
                                                _commandes[index]);
                                          },
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
