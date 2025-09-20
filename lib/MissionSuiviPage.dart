import 'package:flutter/material.dart';
import 'dart:async';

class MissionSuiviPage extends StatefulWidget {
  const MissionSuiviPage({Key? key}) : super(key: key);

  @override
  _MissionSuiviPageState createState() => _MissionSuiviPageState();
}

class _MissionSuiviPageState extends State<MissionSuiviPage> {
  String _missionStatus = 'En route vers le client';
  bool _isMissionStarted = false;
  Timer? _timer;
  int _timeElapsed = 0;
  
  final List<String> _missionSteps = [
    'En route vers le client',
    'Arrivé sur place',
    'Mission commencée',
    'Lavage extérieur',
    'Nettoyage intérieur',
    'Finitions',
    'Mission terminée'
  ];
  
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _nextStep() {
    if (_currentStepIndex < _missionSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
        _missionStatus = _missionSteps[_currentStepIndex];
        if (_currentStepIndex == 2) {
          _isMissionStarted = true;
        }
      });
    }
  }

  void _completeMission() {
    Navigator.pushNamed(context, '/mission-complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Mission en cours',
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
            icon: const Icon(Icons.phone, color: Colors.white),
            onPressed: () {
              // Appeler le client
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statut et minuteur
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
                Icon(
                  _isMissionStarted ? Icons.cleaning_services : Icons.directions_car,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 10),
                Text(
                  _missionStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Temps écoulé: ${_formatTime(_timeElapsed)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Carte GPS (simulée)
          Expanded(
            flex: 2,
            child: Container(
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
                              size: 60,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Navigation GPS',
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
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '5 min',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Étapes de la mission
          Expanded(
            flex: 1,
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
                  Text(
                    'Progression de la mission',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _missionSteps.length,
                      itemBuilder: (context, index) {
                        bool isCompleted = index < _currentStepIndex;
                        bool isCurrent = index == _currentStepIndex;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCompleted 
                                      ? Colors.green 
                                      : isCurrent 
                                          ? Color(0xFF1E3A8A)
                                          : Colors.grey[300],
                                ),
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _missionSteps[index],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCompleted || isCurrent 
                                        ? Color(0xFF1E3A8A)
                                        : Colors.grey,
                                  ),
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
                if (_currentStepIndex < _missionSteps.length - 1)
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentStepIndex == 0 
                              ? 'Je suis arrivé'
                              : _currentStepIndex == 1
                                  ? 'Commencer le lavage'
                                  : 'Étape suivante',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_currentStepIndex == _missionSteps.length - 1)
                  Expanded(
                    child: Container(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _completeMission,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1E3A8A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Terminer et facturer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
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