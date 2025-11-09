import 'package:flutter/material.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/NotificationsPage.dart';
import 'package:glitty/WasherEarningsPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CalendrierPage extends StatefulWidget {
  final int washerId;
  final Map<String, dynamic>? washerData;
  final String nom;
  const CalendrierPage(
      {Key? key, required this.washerId, required this.nom, this.washerData})
      : super(key: key);

  @override
  _CalendrierPageState createState() => _CalendrierPageState();
}

class _CalendrierPageState extends State<CalendrierPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<dynamic> _missions = [];
  bool _isLoading = false;

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
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      drawer: _buildModernDrawer(context, dark, const Color(0xFF4CAF50)),
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure identique à DashboardWasherPage
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

                  const SizedBox(height: 16), // Espace entre les deux lignes

                  // Deuxième ligne : barre de recherche + icône salut
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          child: const Center(
                            child: Text(
                              "Planning des missions",
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

            // Contenu principal du calendrier
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
                    // En-tête du calendrier
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
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
                            icon: const Icon(Icons.chevron_left, size: 30),
                          ),
                          Column(
                            children: [
                              Text(
                                _getMonthYearText(_currentMonth),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_missions.length} mission(s) future(s)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
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
                            icon: const Icon(Icons.chevron_right, size: 30),
                          ),
                        ],
                      ),
                    ),

                    // Jours de la semaine
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                            .map((day) => Expanded(
                                  child: Center(
                                    child: Text(
                                      day,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),

                    // Grille du calendrier
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: _buildCalendarGrid(),
                      ),
                    ),

                    // Liste des missions du jour sélectionné
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Missions du ${_formatSelectedDate(_selectedDate)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF022519),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_getMissionsForDate(_selectedDate).length}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _buildMissionsList(),
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
    );
  }

  // Méthode pour construire le drawer avec navigation ajustée
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
                      false,
                      dark,
                      () => _navigateToDashboard(context),
                    ),
                    _buildDrawerItem(
                      Icons.calendar_month_rounded,
                      "Planning",
                      true,
                      dark,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => _navigateToEarnings(context),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () => _navigateToSecurity(context),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
                      () => _navigateToLocation(context),
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

  // Méthodes de navigation
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
        builder: (context) => WasherEarningsPage(),
      ),
    );
  }

  void _navigateToSecurity(BuildContext context) {
    // Navigator.push(context
    //  MaterialPageRoute(
    //     builder: (context) => SecurityPage(washerId: widget.washerId),
    // ),
    //   );
  }

  void _navigateToLocation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WasherSetGPSPage(
          washerId: widget.washerId,
          washerData: null, // Vous pouvez passer des données si disponibles
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    // Ajoutez ici votre logique de déconnexion
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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

  // Le reste de votre code reste inchangé...
  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekdayOfMonth = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
      ),
      itemCount: 42, // 6 semaines max
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekdayOfMonth + 2;

        if (dayNumber <= 0 || dayNumber > daysInMonth) {
          return Container(); // Cellule vide
        }

        final date =
            DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasMissions = _hasMissionsOnDate(date);
        final isPast =
            date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

        return GestureDetector(
          onTap: isPast
              ? null
              : () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(0xFF022519)
                  : isToday
                      ? Colors.blue[100]
                      : isPast
                          ? Colors.grey[100]
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasMissions && !isPast
                  ? Border.all(color: Colors.green, width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? Colors.blue[800]
                              : isPast
                                  ? Colors.grey[400]
                                  : Colors.black,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasMissions && !isSelected && !isPast)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (isPast)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Icon(
                      Icons.lock_clock,
                      size: 12,
                      color: Colors.grey[400],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissionsList() {
    final missionsForDay = _getMissionsForDate(_selectedDate);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (missionsForDay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 64,
              color: Colors.grey[400],
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
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: missionsForDay.length,
      itemBuilder: (context, index) {
        return _buildMissionCard(missionsForDay[index]);
      },
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final status = mission['statut'] ?? 'en_attente';
    final time = mission['heure_mission'] ?? '00:00';
    final creneau = mission['creneau'] ?? '';
    final vehicle = mission['vehicle_info'] ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getLavageTitle(mission['type_lavage'] ?? ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$time (${_formatCreneau(creneau)})',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mission['adresse'] ?? 'Adresse non spécifiée',
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mission['client_nom'] ?? 'Client',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                if (vehicle['type'] != null) ...[
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${vehicle['type']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  '${mission['prix'] ?? 0}€',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'en_cours':
        color = Colors.orange;
        text = 'En cours';
        break;
      case 'confirmee':
        color = Colors.blue;
        text = 'Confirmée';
        break;
      case 'terminee':
        color = Colors.green;
        text = 'Terminée';
        break;
      case 'annulee':
        color = Colors.red;
        text = 'Annulée';
        break;
      case 'en_attente':
      default:
        color = Colors.grey;
        text = 'En attente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
