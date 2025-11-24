import 'package:flutter/material.dart';
import 'package:glitty/CommandesAujourdhuiPage.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/NotificationsPage.dart' hide NotificationsPage;
import 'package:glitty/WasherCommandsPage.dart';
import 'package:glitty/WasherEarningsPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CalendrierPage extends StatefulWidget {
  final int washerId;
  final Map<String, dynamic>? washerData;
  final String nom;
  const CalendrierPage({
    Key? key,
    required this.washerId,
    required this.nom,
    this.washerData,
  }) : super(key: key);

  @override
  _CalendrierPageState createState() => _CalendrierPageState();
}

class _CalendrierPageState extends State<CalendrierPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<dynamic> _missions = [];
  bool _isLoading = false;
  int _currentIndex =
      1; // Index pour la BottomNavigationBar (1 pour "Planning")

  @override
  void initState() {
    super.initState();
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/commande/mission-washer/${widget.washerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _missions = data['missions']['future'] ?? [];
        });
        print('✅ ${_missions.length} missions futures chargées');
      } else {
        _showError("Erreur serveur: ${response.statusCode}");
      }
    } catch (e) {
      print('❌ Erreur: $e');
      _showError("Erreur lors du chargement du calendrier");
    } finally {
      setState(() => _isLoading = false);
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

  List<Map<String, dynamic>> _getMissionsForDate(DateTime date) {
    return _missions
        .where((mission) {
          try {
            final missionDate = DateTime.parse(mission['date_mission']);
            return missionDate.year == date.year &&
                missionDate.month == date.month &&
                missionDate.day == date.day;
          } catch (e) {
            return false;
          }
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  bool _hasMissionsOnDate(DateTime date) {
    return _getMissionsForDate(date).isNotEmpty;
  }

  int _getMissionCountForDate(DateTime date) {
    return _getMissionsForDate(date).length;
  }

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
      case 1: // Planning (déjà sur cette page)
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
            Container(
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
                              "Mon Calendrier",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "Planning des missions",
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: accentColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_missions.length} mission(s)',
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
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // En-tête du calendrier amélioré
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month - 1,
                                );
                              });
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.chevron_left,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                _getMonthYearText(_currentMonth),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF022519),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_getMissionsForMonth(_currentMonth).length} mission(s) ce mois',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _currentMonth = DateTime(
                                  _currentMonth.year,
                                  _currentMonth.month + 1,
                                );
                              });
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.chevron_right,
                                color: primaryColor,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Jours de la semaine améliorés
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children:
                            ['LUN', 'MAR', 'MER', 'JEU', 'VEN', 'SAM', 'DIM']
                                .map((day) => Expanded(
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                      ),
                    ),

                    // Grille du calendrier améliorée avec bordures vertes
                    Expanded(
                      flex: 2,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildEnhancedCalendarGrid(),
                      ),
                    ),

                    // Séparateur
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 16),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Liste des missions du jour
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.event_note_rounded,
                                  color: primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Missions du ${_formatSelectedDate(_selectedDate)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF022519),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_getMissionsForDate(_selectedDate).length}',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildModernMissionsList(),
                            ),
                          ],
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

  Widget _buildEnhancedCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      // CORRECTION : Suppression de NeverScrollableScrollPhysics pour permettre le scroll
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.3,
      ),
      itemCount: 42,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekdayOfMonth + 2;

        if (dayNumber <= 0 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final date =
            DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasMissions = _hasMissionsOnDate(date);
        final isPast =
            date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return GestureDetector(
          onTap: isPast ? null : () => setState(() => _selectedDate = date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF022519)
                  : isToday
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              // BORDURE VERTE POUR LES DATES AVEC MISSIONS - comme ancien code
              border: hasMissions && !isPast && !isSelected
                  ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                  : isToday && !isSelected
                      ? Border.all(color: const Color(0xFF4CAF50), width: 2)
                      : null,
            ),
            child: Stack(
              children: [
                // Contenu principal de la cellule
                Center(
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? const Color(0xFF4CAF50)
                              : isPast
                                  ? Colors.grey[400]
                                  : Colors.grey[800],
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),

                // Indicateur de jour passé
                if (isPast)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.lock_clock,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ),

                // Petit point vert pour les missions (optionnel)
                if (hasMissions && !isSelected && !isPast)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernMissionsList() {
    final missionsForDay = _getMissionsForDate(_selectedDate);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des missions...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (missionsForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedDate.isBefore(DateTime.now())
                  ? Icons.history_rounded
                  : Icons.event_available_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDate.isBefore(DateTime.now())
                  ? 'Journée passée'
                  : 'Aucune mission prévue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedDate.isBefore(DateTime.now())
                  ? 'Cette date est dans le passé'
                  : 'Profitez de cette journée libre !',
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

    return ListView.builder(
      itemCount: missionsForDay.length,
      itemBuilder: (context, index) {
        return _buildEnhancedMissionCard(missionsForDay[index]);
      },
    );
  }

  Widget _buildEnhancedMissionCard(Map<String, dynamic> mission) {
    final status = mission['statut'] ?? 'en_attente';
    final time = mission['heure_mission'] ?? '00:00';
    final creneau = mission['creneau'] ?? '';
    final vehicle = mission['vehicle_info'] ?? {};
    final missionDate = DateTime.parse(mission['date_mission']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec statut et prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEnhancedStatusChip(status),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${mission['prix'] ?? 0}€',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      _formatTime(time),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type de lavage
            Text(
              _getLavageTitle(mission['type_lavage'] ?? ''),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF022519),
              ),
            ),
            const SizedBox(height: 12),

            // Informations détaillées
            _buildEnhancedInfoRow(
              Icons.access_time_rounded,
              '${_formatCreneau(creneau)} • ${_formatTime(time)}',
            ),
            const SizedBox(height: 8),

            _buildEnhancedInfoRow(
              Icons.location_on_rounded,
              mission['adresse'] ?? 'Adresse non spécifiée',
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            _buildEnhancedInfoRow(
              Icons.person_rounded,
              mission['client_nom'] ?? 'Client',
            ),

            if (vehicle['type'] != null) ...[
              const SizedBox(height: 8),
              _buildEnhancedInfoRow(
                Icons.directions_car_rounded,
                '${vehicle['type']} • ${vehicle['marque'] ?? ''} ${vehicle['modele'] ?? ''}',
              ),
            ],

            // Séparateur et actions
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: Colors.grey[200],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (missionDate.isAfter(DateTime.now()))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF022519).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'À venir',
                      style: TextStyle(
                        color: const Color(0xFF022519),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildEnhancedInfoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedStatusChip(String status) {
    final statusConfig = _getStatusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusConfig.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusConfig.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusConfig.text,
            style: TextStyle(
              color: statusConfig.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = parts[1];
        return '${hour.toString().padLeft(2, '0')}:$minute';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  StatusConfig _getStatusConfig(String status) {
    switch (status) {
      case 'en_cours':
        return StatusConfig(
          color: Colors.orange,
          text: 'En cours',
          icon: Icons.play_arrow_rounded,
        );
      case 'confirmee':
        return StatusConfig(
          color: Colors.blue,
          text: 'Confirmée',
          icon: Icons.check_circle_rounded,
        );
      case 'terminee':
        return StatusConfig(
          color: Colors.green,
          text: 'Terminée',
          icon: Icons.done_all_rounded,
        );
      case 'annulee':
        return StatusConfig(
          color: Colors.red,
          text: 'Annulée',
          icon: Icons.cancel_rounded,
        );
      case 'en_attente':
      default:
        return StatusConfig(
          color: Colors.grey,
          text: 'En attente',
          icon: Icons.schedule_rounded,
        );
    }
  }

  List<Map<String, dynamic>> _getMissionsForMonth(DateTime month) {
    return _missions
        .where((mission) {
          try {
            final missionDate = DateTime.parse(mission['date_mission']);
            return missionDate.year == month.year &&
                missionDate.month == month.month;
          } catch (e) {
            return false;
          }
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

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
                      () => _navigateToDashboard(context),
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

  void _navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsPage(washerId: widget.washerId),
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

  void _navigateToSecurity(BuildContext context) {
    // Navigation vers la page de sécurité
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

  String _formatCreneau(String creneau) {
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    const days = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    const months = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre'
    ];

    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
}

class StatusConfig {
  final Color color;
  final String text;
  final IconData icon;

  StatusConfig({
    required this.color,
    required this.text,
    required this.icon,
  });
}
