import 'package:flutter/material.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';

class MesTicketsWasher extends StatefulWidget {
  final Map<String, dynamic>? washerData;
  final int washerId;

  const MesTicketsWasher({super.key, required this.washerId, this.washerData});

  @override
  State<MesTicketsWasher> createState() => _MesTicketsWasherState();
}

class _MesTicketsWasherState extends State<MesTicketsWasher> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final washerEmail = widget.washerData!['email'];

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/ticket/ticket-email/$washerEmail'),
      );

      print('🔍 Statut de la réponse: ${response.statusCode}');
      print('🔍 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tickets = data['data'] ?? [];
          _isLoading = false;
        });
        print('✅ ${_tickets.length} tickets chargés avec succès');
      } else {
        throw Exception('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des tickets: $e');
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ouvert':
        return 'Ouvert';
      case 'en_cours':
        return 'En cours';
      case 'en_attente':
        return 'En attente';
      case 'résolu':
        return 'Résolu';
      case 'fermé':
        return 'Fermé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ouvert':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'en_attente':
        return Colors.yellow[700]!;
      case 'résolu':
        return Colors.green;
      case 'fermé':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'technique':
        return 'Technique';
      case 'facturation':
        return 'Facturation';
      case 'service':
        return 'Service';
      case 'paiement':
        return 'Paiement';
      case 'mission':
        return 'Mission';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      drawer: _buildWasherDrawer(context),
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure - Header
            Container(
              height: 180,
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Première ligne : icônes menu, logo, notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Menu icon qui ouvre le drawer
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Image.asset(
                            'assets/menu-icone.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/logo-glitty.png',
                        width: 149,
                        height: 69,
                      ),
                      Image.asset(
                        'assets/notification-icone.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Titre de la page
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          child: const Center(
                            child: Text(
                              "Aide & Support",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "DM Sans",
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Partie inférieure blanche avec borderRadius top
            Expanded(
              child: Stack(
                children: [
                  // Fond blanc avec borderRadius
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Contenu scrollable
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Centre d'Aide Washer",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: "DM Sans",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Historique des tickets
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HistoriqueTicketsWasherPage(
                                  washerData: widget.washerData,
                                  washerId: widget.washerId,
                                ),
                              ),
                            );
                          },
                          child: _buildSupportItem(
                            "Historique mes tickets",
                            "Consultez l'historique de vos demandes",
                            Icons.history,
                            Colors.purple,
                          ),
                        ),

                        _buildSupportItem(
                          "Centre d'aide Washer",
                          "Guide et ressources pour les washers",
                          Icons.help_outline,
                          Colors.blue,
                        ),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContactSupportWasherPage(
                                  washerId: widget.washerId,
                                  washerData: widget.washerData,
                                ),
                              ),
                            );
                          },
                          child: _buildSupportItem(
                            "Contactez le support",
                            "Notre équipe est là pour vous aider",
                            Icons.contact_support,
                            Colors.green,
                          ),
                        ),

                        _buildSupportItem(
                          "FAQ Washer",
                          "Questions fréquentes des washers",
                          Icons.question_answer,
                          Colors.orange,
                        ),
                        _buildSupportItem(
                          "Signaler un problème",
                          "Un problème avec une mission?",
                          Icons.report_problem,
                          Colors.red,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire un item de support
  Widget _buildSupportItem(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        ],
      ),
    );
  }

  // Méthode pour construire le Drawer (sidebar) pour washer
  Widget _buildWasherDrawer(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    final washerName = widget.washerData?['nom'] ??
        widget.washerData?['first_name'] ??
        'Washer';

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [dark, dark.withOpacity(0.8)],
          ),
        ),
        child: Column(
          children: [
            // En-tête du Drawer
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: accentColor,
                      child: Text(
                        washerName.isNotEmpty
                            ? washerName[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    washerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "● Washer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Contenu du Drawer
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildDrawerItem(
                      Icons.dashboard_rounded,
                      "Dashboard",
                      false,
                      dark,
                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardWasherPage(
                              nom: washerName,
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
                      dark,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WasherSetPasswordPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WasherSetGPSPage(
                              washerId: widget.washerId,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.help_rounded,
                      "Aide & Support",
                      true, // Actif car nous sommes sur cette page
                      dark,
                      () {
                        Navigator.pop(context);
                      },
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: _buildDrawerItem(
                        Icons.logout_rounded,
                        "Déconnexion",
                        false,
                        Colors.red,
                        () async {
                          // Afficher une boîte de dialogue de confirmation
                          final shouldLogout = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Déconnexion"),
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
                            // Utiliser AuthService pour la déconnexion
                            await AuthService.logout();

                            // Navigation vers la page d'accueil
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WelcomePage()),
                              (route) => false,
                            );

                            // Optionnel : Afficher un message de confirmation
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
          ],
        ),
      ),
    );
  }

  // Méthode pour construire un item du Drawer
  Widget _buildDrawerItem(IconData icon, String title, bool isActive,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? color : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? color : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class HistoriqueTicketsWasherPage extends StatefulWidget {
  final Map<String, dynamic>? washerData;
  final int washerId;

  const HistoriqueTicketsWasherPage(
      {super.key, required this.washerId, this.washerData});

  @override
  State<HistoriqueTicketsWasherPage> createState() =>
      _HistoriqueTicketsWasherPageState();
}

class _HistoriqueTicketsWasherPageState
    extends State<HistoriqueTicketsWasherPage> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      // Récupérer l'email depuis SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final washerEmail = prefs.getString('washer_email');

      if (washerEmail == null) {
        setState(() {
          _isLoading = false;
          _error = 'Email non disponible. Veuillez vous reconnecter.';
        });
        return;
      }

      print('📧 Chargement des tickets pour: $washerEmail');

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/ticket/ticket-email/$washerEmail'),
      );

      print('🔍 Statut de la réponse: ${response.statusCode}');
      print('🔍 Corps de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tickets = data['data'] ?? [];
          _isLoading = false;
        });
        print('✅ ${_tickets.length} tickets chargés avec succès');
      } else {
        throw Exception('Erreur de chargement: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement des tickets: $e');
      setState(() {
        _error = 'Erreur de chargement: $e';
        _isLoading = false;
      });
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'ouvert':
        return 'Ouvert';
      case 'en_cours':
        return 'En cours';
      case 'en_attente':
        return 'En attente';
      case 'résolu':
        return 'Résolu';
      case 'fermé':
        return 'Fermé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ouvert':
        return Colors.orange;
      case 'en_cours':
        return Colors.blue;
      case 'en_attente':
        return Colors.yellow[700]!;
      case 'résolu':
        return Colors.green;
      case 'fermé':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'technique':
        return 'Technique';
      case 'facturation':
        return 'Facturation';
      case 'service':
        return 'Service';
      case 'paiement':
        return 'Paiement';
      case 'mission':
        return 'Mission';
      case 'autre':
        return 'Autre';
      default:
        return type;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildTicketItem(Map<String, dynamic> ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
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
              Expanded(
                child: Text(
                  ticket['title'] ?? 'Sans titre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(ticket['status'] ?? '').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _getStatusColor(ticket['status'] ?? '')),
                ),
                child: Text(
                  _getStatusLabel(ticket['status'] ?? 'inconnu'),
                  style: TextStyle(
                    color: _getStatusColor(ticket['status'] ?? ''),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ticket['description'] ?? 'Aucune description',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getTypeLabel(ticket['type'] ?? 'autre'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Priorité: ${ticket['priority'] ?? 'normale'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Réf: #${ticket['reference'] ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                _formatDate(ticket['created_at'] ?? DateTime.now().toString()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      drawer: _buildWasherDrawer(context),
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            // Header identique
            Container(
              height: 180,
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Image.asset(
                            'assets/menu-icone.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/logo-glitty.png',
                        width: 149,
                        height: 69,
                      ),
                      Image.asset(
                        'assets/notification-icone.png',
                        width: 24,
                        height: 24,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          child: const Center(
                            child: Text(
                              "Historique des Tickets",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "DM Sans",
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Contenu de l'historique
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadTickets,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: dark,
                                    ),
                                    child: const Text(
                                      'Réessayer',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : _tickets.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.history,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'Aucun ticket trouvé',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Vous n\'avez pas encore créé de ticket',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Historique de vos tickets",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF000000),
                                          fontFamily: "DM Sans",
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 26 / 16,
                                          letterSpacing: -0.356,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${_tickets.length} ticket(s) trouvé(s)',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                      ..._tickets
                                          .map((ticket) =>
                                              _buildTicketItem(ticket))
                                          .toList(),
                                    ],
                                  ),
                                ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes du drawer (identique à MesTicketsWasher)
  Widget _buildWasherDrawer(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    final washerName = widget.washerData?['nom'] ??
        widget.washerData?['first_name'] ??
        'Washer';

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [dark, dark.withOpacity(0.8)],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: accentColor,
                      child: Text(
                        washerName.isNotEmpty
                            ? washerName[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    washerName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "● Washer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildDrawerItem(
                      Icons.dashboard_rounded,
                      "Dashboard",
                      false,
                      dark,
                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardWasherPage(
                              nom: washerName,
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
                      dark,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WasherSetPasswordPage(),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WasherSetGPSPage(
                              washerId: widget.washerId,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.help_rounded,
                      "Aide & Support",
                      true,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesTicketsWasher(
                              washerId: widget.washerId,
                              washerData: widget.washerData,
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: _buildDrawerItem(
                        Icons.logout_rounded,
                        "Déconnexion",
                        false,
                        Colors.red,
                        () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('washer_token');
                          await prefs.remove('washer_id');
                          await prefs.remove('washer_email');

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginWasherPage()),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, bool isActive,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? color : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? color : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Page de contact support pour washer
class ContactSupportWasherPage extends StatelessWidget {
  final int washerId;
  final Map<String, dynamic>? washerData;

  const ContactSupportWasherPage({
    super.key,
    required this.washerId,
    this.washerData,
  });

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        title: const Text(
          'Contact Support',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text(
          'Page de contact support pour washer - À implémenter',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
