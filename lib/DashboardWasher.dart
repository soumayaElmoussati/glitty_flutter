import 'package:flutter/material.dart';
import 'package:glitty/CommandesAujourdhuiPage.dart';
import 'package:glitty/CommandesListPage.dart';
import 'package:glitty/WasherCommandsPage.dart';
import 'package:glitty/WasherNotificationsPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/services/notification_service.dart';
import 'package:glitty/services/firebase_notification_service.dart';

class DashboardWasherPage extends StatefulWidget {
  final String nom;
  final int washerId;
  final Map<String, dynamic>? washerData;

  const DashboardWasherPage({
    Key? key,
    required this.nom,
    this.washerData,
    required this.washerId,
  }) : super(key: key);

  @override
  _DashboardWasherPageState createState() => _DashboardWasherPageState();
}

class _DashboardWasherPageState extends State<DashboardWasherPage> {
  Map<String, dynamic> _stats = {
    'total_commandes': 0,
    'total_revenus': 0,
    'note_moyenne': 0.0,
    'missions_mois': 0
  };
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;
  bool _isOnline = false;
  bool _isUpdatingStatus = false;
  int _currentIndex = 0;
  List<dynamic> _recentActivity = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _checkUnreadNotifications();
    _fetchWasherStatus();
    _initializeFirebaseNotifications();
  }

  @override
  void dispose() {
    FirebaseNotificationService.dispose();
    super.dispose();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchWasherStats(),
        _fetchWasherRating(),
        _fetchRecentActivity(),
        _fetchMonthlyStats(),
      ]);
    } catch (e) {
      print('❌ Erreur chargement dashboard: $e');
      _showError("Erreur lors du chargement des données");
    } finally {
      setState(() => _isLoading = false);
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
            _stats['total_commandes'] = data['data']['total_commandes'] ?? 0;
            _stats['total_revenus'] = data['data']['total_revenus'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur API stats: $e');
    }
  }

  Future<void> _fetchWasherRating() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/${widget.washerId}/evaluations'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stats['note_moyenne'] = data['data']['note_moyenne'] ?? 0.0;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur API évaluations: $e');
      // Valeur par défaut pour les démos
      setState(() {
        _stats['note_moyenne'] = 4.5;
      });
    }
  }

  Future<void> _fetchRecentActivity() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/recent-activity/${widget.washerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _recentActivity = data['data'] ?? [];
          });
        }
      }
    } catch (e) {
      print('❌ Erreur API activité récente: $e');
      // Données par défaut pour les démos
      _recentActivity = [
        {
          'type': 'mission_terminee',
          'titre': 'Mission terminée',
          'description': 'Lavage complet - Peugeot 308',
          'date': DateTime.now().subtract(Duration(hours: 2)),
        },
        {
          'type': 'nouveau_planning',
          'titre': 'Mission confirmée',
          'description': 'Lavage intérieur - Renault Clio',
          'date': DateTime.now().subtract(Duration(hours: 4)),
        },
        {
          'type': 'paiement_recu',
          'titre': 'Paiement reçu',
          'description': 'Virement de 85€',
          'date': DateTime.now().subtract(Duration(days: 1)),
        },
      ];
    }
  }

  Future<void> _fetchMonthlyStats() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/stats-mois/${widget.washerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _stats['missions_mois'] = data['data']['missions_mois'] ?? 0;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur API stats mois: $e');
      // Valeur par défaut
      setState(() {
        _stats['missions_mois'] = 12;
      });
    }
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

  Future<void> _initializeFirebaseNotifications() async {
    try {
      print('🚀 Initialisation des notifications Firebase...');
      await FirebaseNotificationService.initialize();

      String? fcmToken = await FirebaseNotificationService.getFCMToken();
      if (fcmToken != null) {
        await _sendFCMTokenToServer(fcmToken);
      }

      FirebaseNotificationService.notifications.listen((notification) {
        _handlePushNotification(notification);
      });

      print('✅ Notifications Firebase initialisées avec succès');
    } catch (e) {
      print('❌ Erreur initialisation notifications Firebase: $e');
    }
  }

  Future<void> _sendFCMTokenToServer(String token) async {
    try {
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/washer/${widget.washerId}/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fcm_token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Token FCM envoyé au serveur avec succès!');
      } else {
        print('❌ Erreur envoi token FCM: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur envoi token FCM: $e');
    }
  }

  void _handlePushNotification(Map<String, dynamic> notification) {
    print('🎯 Notification push reçue: ${notification['title']}');
    _checkUnreadNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(notification['title'] ?? 'Nouvelle commande disponible'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WasherNotificationsPage(
                    washerId: widget.washerId,
                    washerData: widget.washerData,
                  ),
                ),
              );
            },
          ),
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final result =
          await NotificationService.getWasherNotifications(widget.washerId);

      if (result['success'] == true) {
        final notifications = result['data']['notifications'] ?? [];
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return _buildPlaceholderPage("Planning");
      case 2:
        return _buildPlaceholderPage("Missions");
      case 3:
        return _buildPlaceholderPage("Profil");
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildPlaceholderPage(String title) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded,
              size: 64,
              color: Color(0xFF4CAF50),
            ),
            SizedBox(height: 16),
            Text(
              "$title",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF022519),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Page en développement",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildModernDrawer(context, primaryColor, accentColor),
      body: _getCurrentPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    const primaryColor = Color(0xFF022519);

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
              _buildBottomNavItem(1, Icons.calendar_month_rounded),
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

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Color(0xFF4CAF50) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
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

  Widget _buildDashboardContent() {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

    return SafeArea(
      child: Column(
        children: [
          // Header amélioré
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
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
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
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
                      width: 120,
                      height: 50,
                    ),
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
                          _checkUnreadNotifications();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.notifications_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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
                            "Tableau de Bord",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: "DM Sans",
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Bonjour, ${widget.nom} 👋",
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: "DM Sans",
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Voici votre activité aujourd'hui",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.2),
                            accentColor.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pro',
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
          ),

          // Contenu principal
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: _isLoading
                  ? _buildLoadingState()
                  : SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatusSection(primaryColor, accentColor),
                          const SizedBox(height: 20),
                          _buildStatsGrid(primaryColor, accentColor),
                          const SizedBox(height: 20),
                          _buildQuickActionsSection(primaryColor),
                          const SizedBox(height: 20),
                          _buildRecentActivitySection(primaryColor),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            strokeWidth: 3,
          ),
          SizedBox(height: 20),
          Text(
            'Chargement de votre tableau de bord...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(Color primaryColor, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
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
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? accentColor.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                        size: 16,
                        color: _isOnline ? accentColor : Colors.orange,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Statut de disponibilité",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _isOnline
                      ? "Vous êtes visible et pouvez recevoir de nouvelles missions"
                      : "Vous êtes invisible et ne recevrez pas de missions",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isUpdatingStatus ? null : _toggleOnlineStatus,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: _isOnline
                          ? LinearGradient(
                              colors: [
                                accentColor.withOpacity(0.1),
                                accentColor.withOpacity(0.05)
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.orange.withOpacity(0.1),
                                Colors.orange.withOpacity(0.05)
                              ],
                            ),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: _isOnline ? accentColor : Colors.orange,
                          width: 1.5),
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
                                _isOnline ? accentColor : Colors.orange,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _isOnline ? accentColor : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: 10),
                        Text(
                          _isUpdatingStatus
                              ? "Chargement..."
                              : _isOnline
                                  ? "🟢 En ligne - Actif"
                                  : "🔴 Hors ligne - Inactif",
                          style: TextStyle(
                            color: _isOnline ? accentColor : Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 15),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.1),
                  accentColor.withOpacity(0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _isOnline
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 32,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "Mes Statistiques",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildStatCard(
              "Missions",
              "${_stats['total_commandes']}",
              Icons.cleaning_services_rounded,
              Color(0xFF2196F3),
              "Total réalisées",
            ),
            _buildStatCard(
              "Revenus",
              "${_stats['total_revenus']}€",
              Icons.account_balance_wallet_rounded,
              Color(0xFF4CAF50),
              "Total gagné",
            ),
            _buildStatCard(
              "Note moyenne",
              _stats['note_moyenne'] > 0
                  ? "${_stats['note_moyenne']}/5"
                  : "N/A",
              Icons.star_rounded,
              Color(0xFFFFC107),
              "Satisfaction clients",
            ),
            _buildStatCard(
              "Ce mois",
              "${_stats['missions_mois']}",
              Icons.trending_up_rounded,
              Color(0xFFFF9800),
              "Missions",
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(
            "Actions Rapides",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.0,
          children: [
            _buildActionCard(
              "Nouvelles missions",
              "Commandes disponibles",
              Icons.add_circle_rounded,
              Color(0xFF2196F3),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommandesListPage(
                      nom: widget.nom,
                      washerId: widget.washerId,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              "Aujourd'hui",
              "Planning du jour",
              Icons.today_rounded,
              Color(0xFFFF9800),
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommandesAujourdhuiPage(
                      washerId: widget.washerId,
                      nom: widget.nom,
                    ),
                  ),
                );
              },
            ),
            _buildActionCard(
              "Planning",
              "Voir calendrier",
              Icons.calendar_month_rounded,
              Color(0xFF9C27B0),
              () => Navigator.pushNamed(context, '/calendrier'),
            ),
            _buildActionCard(
              "Mes gains",
              "Historique détaillé",
              Icons.bar_chart_rounded,
              Color(0xFF4CAF50),
              () => Navigator.pushNamed(context, '/washer-earnings'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Text(
                "Activité Récente",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
            ),
            if (_recentActivity.isNotEmpty)
              TextButton(
                onPressed: _fetchDashboardData,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Actualiser",
                      style: TextStyle(
                        color: Color(0xFF4CAF50),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _recentActivity.isEmpty
            ? _buildEmptyActivityState()
            : Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: _recentActivity
                      .asMap()
                      .entries
                      .map(
                          (entry) => _buildActivityItem(entry.value, entry.key))
                      .toList(),
                ),
              ),
      ],
    );
  }

  Widget _buildEmptyActivityState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune activité récente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos dernières activités apparaitront ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity, int index) {
    final config = _getActivityConfig(activity);
    final date = activity['date'] is String
        ? DateTime.parse(activity['date'])
        : (activity['date'] as DateTime? ?? DateTime.now());

    return Container(
      decoration: BoxDecoration(
        border: index < _recentActivity.length - 1
            ? Border(
                bottom: BorderSide(
                  color: Colors.grey[100]!,
                  width: 1,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(config.icon, color: config.color, size: 20),
        ),
        title: Text(
          activity['titre'] ?? config.defaultTitle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF022519),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2),
            Text(
              activity['description'] ?? config.defaultDescription,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              _formatTimeAgo(date),
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ActivityConfig _getActivityConfig(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'mission_terminee':
        return ActivityConfig(
          color: Color(0xFF4CAF50),
          icon: Icons.check_circle_rounded,
          defaultTitle: 'Mission terminée',
          defaultDescription: 'Lavage complet effectué',
        );
      case 'nouveau_planning':
        return ActivityConfig(
          color: Color(0xFF2196F3),
          icon: Icons.calendar_today_rounded,
          defaultTitle: 'Mission confirmée',
          defaultDescription: 'Nouvelle mission programmée',
        );
      case 'paiement_recu':
        return ActivityConfig(
          color: Color(0xFF4CAF50),
          icon: Icons.payment_rounded,
          defaultTitle: 'Paiement reçu',
          defaultDescription: 'Virement effectué',
        );
      default:
        return ActivityConfig(
          color: Color(0xFF666666),
          icon: Icons.notifications_rounded,
          defaultTitle: 'Nouvelle activité',
          defaultDescription: 'Activité récente',
        );
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'À l\'instant';
    if (difference.inMinutes < 60) return 'Il y a ${difference.inMinutes} min';
    if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
    return 'Le ${date.day}/${date.month}/${date.year}';
  }

  Widget _buildModernDrawer(
      BuildContext context, Color primaryColor, Color accentColor) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Section header réduite et corrigée
              Container(
                height: 130, // Hauteur réduite
                padding: const EdgeInsets.all(12), // Padding réduit
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2), // Padding réduit
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: 1.5), // Bordure plus fine
                      ),
                      child: CircleAvatar(
                        radius: 26, // Rayon réduit
                        backgroundColor: accentColor,
                        child: Text(
                          widget.nom.isNotEmpty
                              ? widget.nom[0].toUpperCase()
                              : 'W',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16, // Taille réduite
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6), // Espace réduit
                    Text(
                      widget.nom.length > 12
                          ? '${widget.nom.substring(0, 12)}...'
                          : widget.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Taille réduite
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3), // Espace réduit
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1), // Padding réduit
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withOpacity(0.4)),
                      ),
                      child: const Text(
                        "Washer", // Texte raccourci
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9, // Taille réduite
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
                            true,
                            primaryColor,
                            () => Navigator.pop(context),
                          ),
                          _buildDrawerItem(
                            Icons.today_rounded,
                            "Aujourd'hui",
                            false,
                            primaryColor,
                            () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CommandesAujourdhuiPage(
                                    washerId: widget.washerId,
                                    nom: widget.nom,
                                  ),
                                ),
                              );
                            },
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
                            () => Navigator.pushNamed(context, '/calendrier'),
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
                                    washerData: widget.washerData,
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
}

class ActivityConfig {
  final Color color;
  final IconData icon;
  final String defaultTitle;
  final String defaultDescription;

  ActivityConfig({
    required this.color,
    required this.icon,
    required this.defaultTitle,
    required this.defaultDescription,
  });
}
