import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/NotificationsPage.dart';
import 'package:glitty/WasherCommandsPage.dart' hide NotificationsPage;
import 'package:glitty/CommandesAujourdhuiPage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';

class WasherEarningsPage extends StatefulWidget {
  final String nom;
  final int washerId;

  const WasherEarningsPage({
    Key? key,
    this.nom = '',
    required this.washerId,
  }) : super(key: key);

  @override
  _WasherEarningsPageState createState() => _WasherEarningsPageState();
}

class _WasherEarningsPageState extends State<WasherEarningsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 3; // Index pour la BottomNavigationBar (3 pour "Profil")

  List<dynamic> _earnings = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchEarningsData() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/washer/${widget.washerId}/earnings'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _earnings = data['data']['earnings'] ?? [];
          _statistics = data['data']['statistics'] ?? {};
        });
      } else {
        setState(() {
          _error = true;
        });
        _showError('Erreur lors du chargement des gains');
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

  // Calcul des statistiques basées sur les données de l'API
  double get _totalEarnings => _statistics['total_earnings']?.toDouble() ?? 0.0;
  double get _pendingEarnings =>
      _statistics['pending_earnings']?.toDouble() ?? 0.0;
  double get _thisMonthEarnings =>
      _statistics['this_month_earnings']?.toDouble() ?? 0.0;
  double get _lastMonthEarnings =>
      _statistics['last_month_earnings']?.toDouble() ?? 0.0;

  String get _growthPercentage {
    if (_lastMonthEarnings == 0) return '+0%';
    final growth =
        ((_thisMonthEarnings - _lastMonthEarnings) / _lastMonthEarnings * 100);
    return '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(0)}%';
  }

  bool get _isGrowthPositive => _thisMonthEarnings >= _lastMonthEarnings;

  // Bottom Navigation Bar - Même style que les autres pages
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
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CommandesAujourdhuiPage(
              washerId: widget.washerId,
              nom: widget.nom,
            ),
          ),
        );
        break;
      case 2: // Missions
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WasherCommandsPage(
              nom: widget.nom,
              washerId: widget.washerId,
            ),
          ),
        );
        break;
      case 3: // Profil (déjà sur cette page)
        // Ne rien faire, on est déjà sur cette page
        break;
    }
  }

  // Header amélioré - Même style que CalendrierPage
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
                      "Mes Gains",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: "DM Sans",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Suivi financier",
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
                      Icons.account_balance_wallet,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${_thisMonthEarnings.toStringAsFixed(0)} €',
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

  // Drawer - Même style que CalendrierPage
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
                      false,
                      primaryColor,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DashboardWasherPage(
                              washerId: widget.washerId,
                              nom: widget.nom,
                            ),
                          ),
                        );
                      },
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
                      true,
                      primaryColor,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      primaryColor,
                      () => Navigator.pop(context),
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
          ],
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

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(washerId: widget.washerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildModernDrawer(context, primaryColor, accentColor),
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
                    ? _buildLoadingState()
                    : _error
                        ? _buildErrorState()
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Résumé financier amélioré
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF022519)
                                        .withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFF022519)
                                          .withOpacity(0.1),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildEnhancedStatCard(
                                              'Gains disponibles',
                                              '${_totalEarnings.toStringAsFixed(2)} €',
                                              Icons.account_balance_wallet,
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: _buildEnhancedStatCard(
                                              'En attente',
                                              '${_pendingEarnings.toStringAsFixed(2)} €',
                                              Icons.schedule,
                                              Colors.orange,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF022519),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Total ce mois',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Text(
                                                  '${_thisMonthEarnings.toStringAsFixed(2)} €',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _isGrowthPositive
                                                    ? Colors.green
                                                    : Colors.orange,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                _growthPercentage,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Historique des gains
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.history_rounded,
                                              color: const Color(0xFF022519),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Historique des gains',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF022519),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF34C759)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                '${_earnings.length}',
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFF34C759),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Expanded(
                                          child: _earnings.isEmpty
                                              ? _buildEmptyState()
                                              : ListView.builder(
                                                  itemCount: _earnings.length,
                                                  itemBuilder:
                                                      (context, index) {
                                                    final earning =
                                                        _earnings[index];
                                                    return _buildEarningCard(
                                                        earning);
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
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF022519),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des gains...',
            style: TextStyle(
              color: Color(0xFF022519),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _fetchEarningsData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF022519),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun gain pour le moment',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos gains apparaîtront ici après vos premières missions',
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

  Widget _buildEarningCard(Map<String, dynamic> earning) {
    final commande = earning['commande'] ?? {};
    final status = earning['statut'] ?? 'pending';
    final partWasher = (earning['part_washer'] as num?)?.toDouble() ?? 0.0;
    final partAdmin = (earning['part_admin'] as num?)?.toDouble() ?? 0.0;
    final prixTotal = (earning['prix_total'] as num?)?.toDouble() ?? 0.0;
    final createdAt = earning['created_at'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Commande #${commande['reference'] ?? ''}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getLavageTitle(commande['type_lavage'] ?? ''),
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            _formatDate(createdAt),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Votre gain',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${partWasher.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Commission Glitty',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '-${partAdmin.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total commande',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${prixTotal.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
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

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildEnhancedStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
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
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF022519),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
