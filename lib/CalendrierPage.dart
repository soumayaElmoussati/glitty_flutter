import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CalendrierPage extends StatefulWidget {
  final int washerId;
  const CalendrierPage({Key? key, required this.washerId}) : super(key: key);

  @override
  _CalendrierPageState createState() => _CalendrierPageState();
}

class _CalendrierPageState extends State<CalendrierPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  List<dynamic> _missions = [];
  bool _isLoading = false;

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
    _fetchMissions();
  }

  Future<void> _fetchMissions() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/missions/calendar/${widget.washerId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _missions = data['missions'] ?? [];
        });
      }
    } catch (e) {
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
    return _missions.where((mission) {
      try {
        final missionDate = DateTime.parse(mission['date_mission']);
        return missionDate.year == date.year &&
               missionDate.month == date.month &&
               missionDate.day == date.day;
      } catch (e) {
        return false;
      }
    }).cast<Map<String, dynamic>>().toList();
  }

  bool _hasMissionsOnDate(DateTime date) {
    return _getMissionsForDate(date).isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    const darkColor = Color(0xFF022519);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Planning des missions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today, color: Colors.white),
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _currentMonth = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
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
                Text(
                  _getMonthYearText(_currentMonth),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  Text(
                    'Missions du ${_formatSelectedDate(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF022519),
                    ),
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
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
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

        final date = DateTime(_currentMonth.year, _currentMonth.month, dayNumber);
        final isSelected = _isSameDay(date, _selectedDate);
        final isToday = _isSameDay(date, DateTime.now());
        final hasMissions = _hasMissionsOnDate(date);

        return GestureDetector(
          onTap: () {
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
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasMissions 
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
                              : Colors.black,
                      fontWeight: isSelected || isToday 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ),
                if (hasMissions && !isSelected)
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
              'Aucune mission prévue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Profitez de cette journée libre !',
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
    final status = mission['statut'] ?? 'en cours';
    final time = mission['heure_mission'] ?? '00:00';
    
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
                Text(
                  mission['type_lavage'] ?? 'Lavage',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
                  time,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
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
                Text(
                  mission['client_nom'] ?? 'Client',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
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
      case 'en cours':
        color = Colors.orange;
        text = 'En cours';
        break;
      case 'accepté':
        color = Colors.blue;
        text = 'Accepté';
        break;
      case 'terminé':
        color = Colors.green;
        text = 'Terminé';
        break;
      case 'annulé':
        color = Colors.red;
        text = 'Annulé';
        break;
      default:
        color = Colors.grey;
        text = status;
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _getMonthYearText(DateTime date) {
    const months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatSelectedDate(DateTime date) {
    const days = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    const months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }
} 