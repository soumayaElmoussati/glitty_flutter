import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherNotificationsPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';

// Importez votre page MesTicketsWasher
import 'package:glitty/MesTicketsWasher.dart';
// AJOUT: Import du service de notifications
import 'package:glitty/services/notification_service.dart';

class DashboardWasherPage extends StatefulWidget {
  final String nom;
  final int washerId;
  final Map<String, dynamic>? washerData;

  const DashboardWasherPage(
      {Key? key, required this.nom, this.washerData, required this.washerId})
      : super(key: key);

  @override
  _DashboardWasherPageState createState() => _DashboardWasherPageState();
}

class _DashboardWasherPageState extends State<DashboardWasherPage> {
  Map<String, dynamic> _stats = {'total_commandes': 0, 'total_revenus': 0};
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;

  bool _isOnline = false;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _fetchWasherStats();
    _checkUnreadNotifications();
    _fetchWasherStatus();
  }

  Future<void> _fetchWasherStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/washer/${widget.washerId}/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isOnline = data['data']['is_online'] ?? false;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur récupération statut: $e');
    }
  }

// NOUVEAU: Basculer le statut en ligne/hors ligne
  Future<void> _toggleOnlineStatus() async {
    if (_isUpdatingStatus) return;

    setState(() {
      _isUpdatingStatus = true;
    });

    try {
      final newStatus = !_isOnline;
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/washer/${widget.washerId}/online-status'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'is_online': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _isOnline = newStatus;
          });

          // Afficher un message de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus
                    ? '✅ Vous êtes maintenant en ligne'
                    : '🔴 Vous êtes maintenant hors ligne',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          _showError(data['message'] ?? "Erreur lors du changement de statut");
        }
      } else {
        _showError("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Erreur changement statut: $e');
      _showError("Erreur de connexion");
    } finally {
      setState(() {
        _isUpdatingStatus = false;
      });
    }
  }

  Future<void> _fetchWasherStats() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/commande/total-commande-washer/${widget.washerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stats = data['data'];
            _isLoading = false;
          });
        }
      } else {
        _showError("Erreur lors du chargement des statistiques");
      }
    } catch (e) {
      print('❌ Erreur API stats: $e');
      _showError("Erreur de connexion");
    } finally {
      if (_isLoading) {
        setState(() => _isLoading = false);
      }
    }
  }

// AJOUT: Méthode pour vérifier les notifications non lues
  Future<void> _checkUnreadNotifications() async {
    try {
      final result =
          await NotificationService.getWasherNotifications(widget.washerId);

      if (result['success'] == true) {
        final notifications = result['data']['notifications'] ?? [];
        // CORRECTION: Vérifier is_read comme number (0) ET comme boolean
        final hasUnread = notifications.any((notif) {
          final isRead = notif['is_read'];
          return isRead == 0 || isRead == false;
        });

        setState(() {
          _hasUnreadNotifications = hasUnread;
        });
      }
    } catch (e) {
      print('❌ Erreur vérification notifications: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A2C42);
    const accentColor = Color(0xFF4CAF50);
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: dark,
      drawer: _buildModernDrawer(context, dark, accentColor),
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure identique
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
                      // CORRECTION: Icône de notification avec badge
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WasherNotificationsPage(
                                washerId: widget.washerId,
                                washerData: widget.washerData,
                              ),
                            ),
                          ).then((_) {
                            // Recharger les notifications quand on revient de la page notifications
                            _checkUnreadNotifications();
                          });
                        },
                        child: Stack(
                          children: [
                            Image.asset(
                              'assets/notification-icone.png',
                              width: 24,
                              height: 24,
                              color: Colors.white,
                            ),
                            // Badge pour notifications non lues
                            if (_hasUnreadNotifications)
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
                              "Tableau de Bord prestataire de service",
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

            // Contenu principal du dashboard
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeSection(widget.nom, dark),
                      const SizedBox(height: 30),
                      _buildStatsGrid(context, dark, accentColor),
                      const SizedBox(height: 30),
                      _buildQuickActionsSection(context, dark),
                      const SizedBox(height: 30),
                      _buildRecentActivitySection(dark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODIFIEZ LA MÉTHODE _buildStatsGrid
  Widget _buildStatsGrid(BuildContext context, Color dark, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistiques",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                  "Missions",
                  _isLoading ? "..." : "${_stats['total_commandes']}",
                  Icons.cleaning_services_rounded,
                  const Color(0xFF2196F3)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard(
                  "Revenus",
                  _isLoading ? "..." : "${_stats['total_revenus']}€",
                  Icons.euro_rounded,
                  const Color(0xFF4CAF50)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildStatCard("Taux réussite", _isLoading ? "..." : "98%",
                  Icons.trending_up_rounded, const Color(0xFFFF9800)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildStatCard("Satisfaction", "4.9★", Icons.star_rounded,
                  const Color(0xFFFFD700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernDrawer(
      BuildContext context, Color dark, Color accentColor) {
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
                        widget.nom.isNotEmpty
                            ? widget.nom[0].toUpperCase()
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
                    widget.nom,
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
                      true,
                      dark,
                      () => Navigator.pop(context),
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
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WasherSetPasswordPage())),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
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

  Widget _buildWelcomeSection(String nom, Color dark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour, $nom ! 👋",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Prêt pour une nouvelle journée de travail ?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 15),

                // NOUVEAU: Toggle statut en ligne avec indicateur de chargement
                GestureDetector(
                  onTap: _isUpdatingStatus ? null : _toggleOnlineStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? Color(0xFF4CAF50).withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _isOnline ? Color(0xFF4CAF50) : Colors.orange,
                          width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isUpdatingStatus)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isOnline ? Color(0xFF4CAF50) : Colors.orange,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color:
                                  _isOnline ? Color(0xFF4CAF50) : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 8),
                        Text(
                          _isUpdatingStatus
                              ? "Chargement..."
                              : _isOnline
                                  ? "🟢 En ligne"
                                  : "🔴 Hors ligne",
                          style: TextStyle(
                            color:
                                _isOnline ? Color(0xFF4CAF50) : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isOnline ? Icons.toggle_on : Icons.toggle_off,
                          color: _isOnline ? Color(0xFF4CAF50) : Colors.orange,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dark.withOpacity(0.1),
                  const Color(0xFF4CAF50).withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: dark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Actions rapides",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                "Nouvelle mission",
                "Commencer maintenant",
                Icons.play_circle_fill_rounded,
                const Color(0xFF1A2C42),
                () => Navigator.pushNamed(context, '/checklist-preparation'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                context,
                "Mission en cours",
                "Continuer le suivi",
                Icons.location_on_rounded,
                const Color(0xFFFF9800),
                () => Navigator.pushNamed(context, '/mission-suivi'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                "Planning",
                "Voir le calendrier",
                Icons.calendar_month_rounded,
                const Color(0xFF9C27B0),
                () => Navigator.pushNamed(context, '/calendrier'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                context,
                "Mes gains",
                "Historique détaillé",
                Icons.trending_up_rounded,
                const Color(0xFF4CAF50),
                () => Navigator.pushNamed(context, '/washer-earnings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Activité récente",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: dark,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                  "Mission terminée",
                  "Lavage complet - 35€",
                  Icons.check_circle_rounded,
                  const Color(0xFF4CAF50),
                  "Il y a 2h"),
              const Divider(height: 30),
              _buildActivityItem(
                  "Nouveau planning",
                  "3 missions programmées",
                  Icons.calendar_today_rounded,
                  const Color(0xFF2196F3),
                  "Il y a 4h"),
              const Divider(height: 30),
              _buildActivityItem("Paiement reçu", "Virement de 180€",
                  Icons.payment_rounded, const Color(0xFF4CAF50), "Hier"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
      String title, String subtitle, IconData icon, Color color, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
