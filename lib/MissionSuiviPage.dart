import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MissionSuiviPage extends StatefulWidget {
  final String? clientAddress;
  final double? clientLatitude;
  final double? clientLongitude;
  final int commandeId;
  final int washerId;
  final String nom;
  final Map<String, dynamic>? washerData;

  const MissionSuiviPage({
    Key? key,
    this.clientAddress,
    this.clientLatitude,
    this.clientLongitude,
    required this.commandeId,
    required this.washerId,
    required this.nom,
    this.washerData,
  }) : super(key: key);

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

  // Variables pour la carte et tracking
  LatLng _currentPosition = LatLng(46.603354, 1.888334);
  LatLng? _clientPosition;
  MapController _mapController = MapController();
  bool _isLoadingLocation = true;
  Timer? _locationTimer;
  Timer? _positionUpdateTimer;
  double _distanceToClient = 0.0;
  String _estimatedTime = 'Calcul en cours...';

  // Historique des positions pour une animation fluide
  List<LatLng> _positionHistory = [];
  bool _isArrived = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _initializeMap();
    _startRealTimeTracking();
    _geocodeClientAddressIfNeeded();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    _positionUpdateTimer?.cancel();
    super.dispose();
  }

  void _initializeMap() {
    // Définir la position du client si les coordonnées sont disponibles
    if (widget.clientLatitude != null && widget.clientLongitude != null) {
      _clientPosition = LatLng(widget.clientLatitude!, widget.clientLongitude!);
    }
    _getCurrentLocation();
  }

  void _startRealTimeTracking() {
    // Mise à jour de la position toutes les 5 secondes
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });

    // Envoi de la position au serveur toutes les 10 secondes
    _positionUpdateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _sendPositionToServer();
    });
  }

  Future<void> _geocodeClientAddressIfNeeded() async {
    // Si on a l'adresse mais pas les coordonnées, on géocode
    if (widget.clientAddress != null &&
        widget.clientLatitude == null &&
        widget.clientLongitude == null) {
      await _geocodeAddress(widget.clientAddress!);
    }
  }

  Future<void> _geocodeAddress(String address) async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(address)}&limit=1',
        ),
        headers: {
          'User-Agent': 'GlittyApp/1.0 (contact@glitty.com)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _clientPosition = LatLng(
              double.parse(data[0]['lat']),
              double.parse(data[0]['lon']),
            );
          });
          print('📍 Adresse géocodée: ${data[0]['display_name']}');
        }
      }
    } catch (e) {
      print('Erreur de géocodage: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showLocationError('Service de localisation désactivé');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          _showLocationError('Permission de localisation refusée');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError('Permission de localisation définitivement refusée');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;

        // Ajouter à l'historique pour animation
        _positionHistory.add(_currentPosition);
        if (_positionHistory.length > 10) {
          _positionHistory.removeAt(0);
        }
      });

      _calculateDistanceAndTime();
      _checkIfArrived();

      // Centrer automatiquement la carte sur la position actuelle
      if (!_isArrived) {
        _mapController.move(_currentPosition, 15.0);
      }
    } catch (e) {
      print('Erreur de localisation: $e');
      _showLocationError('Erreur de localisation: $e');
    }
  }

  void _checkIfArrived() {
    if (_clientPosition != null && _distanceToClient < 0.05) {
      // 50 mètres
      setState(() {
        _isArrived = true;
        _missionStatus = 'Arrivé chez le client';
        if (_currentStepIndex == 0) {
          _currentStepIndex = 1;
        }
      });

      // Arrêter le tracking intensif si arrivé
      _locationTimer?.cancel();
      _positionUpdateTimer?.cancel();
    }
  }

  void _calculateDistanceAndTime() {
    if (_clientPosition != null) {
      final distance = Geolocator.distanceBetween(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _clientPosition!.latitude,
        _clientPosition!.longitude,
      );

      // Calcul plus réaliste du temps estimé
      final estimatedTimeMinutes = _calculateRealisticTime(distance);

      setState(() {
        _distanceToClient = distance / 1000;
        _estimatedTime = estimatedTimeMinutes <= 1
            ? 'Moins d\'1 min'
            : '${estimatedTimeMinutes} min';
      });
    }
  }

  int _calculateRealisticTime(double distanceMeters) {
    // Logique plus réaliste pour le temps estimé
    if (distanceMeters < 1000) {
      return (distanceMeters / 100).round(); // 100 mètres/minute en ville
    } else {
      return (distanceMeters / 500).round(); // 500 mètres/minute = 30 km/h
    }
  }

  Future<void> _sendPositionToServer() async {
    // TODO: Implémenter l'envoi de la position au serveur
    try {
      /* Exemple d'implémentation :
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/commande/${widget.commandeId}/position'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': _currentPosition.latitude,
          'longitude': _currentPosition.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      */
      print(
          '📍 Position envoyée: ${_currentPosition.latitude}, ${_currentPosition.longitude}');
    } catch (e) {
      print('Erreur envoi position: $e');
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
    // Arrêter tous les timers
    _locationTimer?.cancel();
    _positionUpdateTimer?.cancel();

    // Naviguer vers la page de confirmation
    Navigator.pushNamed(context, '/mission-complete');
  }

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: _currentPosition,
                zoom: 15.0,
                interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.glitty.app',
                ),

                // Ligne de trajectoire (historique des positions)
                if (_positionHistory.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _positionHistory,
                        color: Colors.blue.withOpacity(0.4),
                        strokeWidth: 3.0,
                      ),
                    ],
                  ),

                // Ligne de direction vers le client
                if (_clientPosition != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_currentPosition, _clientPosition!],
                        color: Colors.blue.withOpacity(0.8),
                        strokeWidth: 4.0,
                        borderStrokeWidth: 2.0,
                        borderColor: Colors.white,
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    // Marqueur position actuelle (avec animation)
                    Marker(
                      width: 50.0,
                      height: 50.0,
                      point: _currentPosition,
                      builder: (ctx) => Stack(
                        children: [
                          // Cercle d'animation pulsante
                          if (!_isArrived)
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.withOpacity(0.3),
                              ),
                              child: const SizedBox(),
                            ),

                          // Marqueur principal
                          const Icon(
                            Icons.navigation,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ],
                      ),
                    ),

                    // Marqueur position client
                    if (_clientPosition != null)
                      Marker(
                        width: 40.0,
                        height: 40.0,
                        point: _clientPosition!,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Overlay d'informations en temps réel
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          color: Colors.blue[700],
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _estimatedTime,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (_distanceToClient > 0)
                      Text(
                        '${_distanceToClient.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Indicateur de statut
            if (_isArrived)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '🟢 Arrivé',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            // Bouton de recentrage
            Positioned(
              bottom: 10,
              right: 10,
              child: FloatingActionButton(
                onPressed: () {
                  _mapController.move(_currentPosition, 15.0);
                },
                backgroundColor: Colors.white,
                mini: true,
                child: Icon(
                  Icons.my_location,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

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
                      Icons.calendar_month_rounded,
                      "Planning",
                      false,
                      primaryColor,
                      () => _navigateToCalendar(context),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      primaryColor,
                      () => _navigateToEarnings(context),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      primaryColor,
                      () => _navigateToSecurity(context),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      primaryColor,
                      () => _navigateToLocation(context),
                    ),
                    _buildDrawerItem(
                      Icons.help_rounded,
                      "Aide & Support",
                      false,
                      primaryColor,
                      () => _navigateToHelp(context),
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
                        () => _logout(context),
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
    // Implémentez la navigation vers le dashboard
  }

  void _navigateToCalendar(BuildContext context) {
    // Implémentez la navigation vers le calendrier
  }

  void _navigateToEarnings(BuildContext context) {
    // Implémentez la navigation vers les gains
  }

  void _navigateToSecurity(BuildContext context) {
    // Implémentez la navigation vers la sécurité
  }

  void _navigateToLocation(BuildContext context) {
    // Implémentez la navigation vers la localisation
  }

  void _navigateToHelp(BuildContext context) {
    // Implémentez la navigation vers l'aide
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Déconnexion"),
          content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Annuler"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
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
      // Implémentez la déconnexion
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    const backgroundColor = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: _buildModernDrawer(context),
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
                        onTap: () {
                          // Navigation vers les notifications
                        },
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
                              "Mission en cours",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _missionStatus,
                              style: const TextStyle(
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
                              Icons.timer,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTime(_timeElapsed),
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
                    // Carte GPS interactive
                    Expanded(
                      flex: 2,
                      child: _buildMap(),
                    ),

                    const SizedBox(height: 20),

                    // Informations de distance et temps
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildInfoCard(
                            Icons.place,
                            'Distance',
                            '${_distanceToClient.toStringAsFixed(1)} km',
                            primaryColor,
                          ),
                          _buildInfoCard(
                            Icons.access_time,
                            'Temps estimé',
                            _estimatedTime,
                            accentColor,
                          ),
                          _buildInfoCard(
                            Icons.speed,
                            'Statut',
                            _isArrived ? 'Arrivé' : 'En route',
                            _isArrived ? Colors.green : Colors.orange,
                          ),
                        ],
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
                              'Progression de la mission',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF022519),
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
                                                ? accentColor
                                                : isCurrent
                                                    ? primaryColor
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
                                              fontWeight: isCurrent
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isCompleted || isCurrent
                                                  ? primaryColor
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
                                    backgroundColor: accentColor,
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
                                    backgroundColor: primaryColor,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
