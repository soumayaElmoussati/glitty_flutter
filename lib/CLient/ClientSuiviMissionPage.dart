import 'package:flutter/material.dart';
import 'dart:async';

class ClientSuiviMissionPage extends StatefulWidget {
  const ClientSuiviMissionPage({Key? key}) : super(key: key);

  @override
  _ClientSuiviMissionPageState createState() => _ClientSuiviMissionPageState();
}

class _ClientSuiviMissionPageState extends State<ClientSuiviMissionPage> {
  String _missionStatus = 'Washer en route';
  Timer? _timer;
  int _timeElapsed = 0;
  bool _washerArrived = false;
  
  final List<Map<String, dynamic>> _missionSteps = [
    {
      'title': 'Washer en route',
      'subtitle': 'Votre washer se dirige vers vous',
      'icon': Icons.directions_car,
      'completed': false,
      'estimatedTime': '10 min',
    },
    {
      'title': 'Arrivé sur place',
      'subtitle': 'Le washer est arrivé à votre adresse',
      'icon': Icons.location_on,
      'completed': false,
      'estimatedTime': '',
    },
    {
      'title': 'Lavage en cours',
      'subtitle': 'Nettoyage de votre véhicule',
      'icon': Icons.cleaning_services,
      'completed': false,
      'estimatedTime': '45 min',
    },
    {
      'title': 'Mission terminée',
      'subtitle': 'Votre véhicule est prêt !',
      'icon': Icons.check_circle,
      'completed': false,
      'estimatedTime': '',
    },
  ];
  
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _simulateProgress();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeElapsed++;
      });
    });
  }

  void _simulateProgress() {
    // Simulation de progression automatique
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _missionSteps[0]['completed'] = true;
          _currentStepIndex = 1;
          _missionStatus = 'Arrivé sur place';
        });
      }
    });
    
    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _missionSteps[1]['completed'] = true;
          _currentStepIndex = 2;
          _missionStatus = 'Lavage en cours';
          _washerArrived = true;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Suivi de mission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed: () {
              // Contacter le washer
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête avec statut
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Alexandre Martin',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text(
                      ' 4.8 (156 avis)',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: _washerArrived ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _missionStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Carte de localisation
          Container(
            height: 200,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Localisation en temps réel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_washerArrived)
                    Positioned(
                      top: 15,
                      left: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              '7 min',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
          
          const SizedBox(height: 20),
          
          // Progression de la mission
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progression',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        'Temps écoulé: ${_formatTime(_timeElapsed)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ListView.builder(
                      itemCount: _missionSteps.length,
                      itemBuilder: (context, index) {
                        final step = _missionSteps[index];
                        bool isCompleted = step['completed'];
                        bool isCurrent = index == _currentStepIndex && !isCompleted;
                        bool isFuture = index > _currentStepIndex;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCompleted 
                                          ? Colors.green 
                                          : isCurrent 
                                              ? Color(0xFF1E3A8A)
                                              : Colors.grey[300],
                                    ),
                                    child: Icon(
                                      isCompleted ? Icons.check : step['icon'],
                                      color: isCompleted || isCurrent 
                                          ? Colors.white 
                                          : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                  if (index < _missionSteps.length - 1)
                                    Container(
                                      width: 2,
                                      height: 30,
                                      color: isCompleted 
                                          ? Colors.green 
                                          : Colors.grey[300],
                                    ),
                                ],
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          step['title'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted || isCurrent 
                                                ? Color(0xFF1E3A8A)
                                                : Colors.grey,
                                          ),
                                        ),
                                        if (step['estimatedTime'].isNotEmpty && isFuture)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[50],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              step['estimatedTime'],
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue[800],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      step['subtitle'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    if (isCurrent)
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.grey[200],
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xFF1E3A8A),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Boutons d'action
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Appeler le washer
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Color(0xFF1E3A8A)),
                        foregroundColor: Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Container(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Envoyer un message
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 