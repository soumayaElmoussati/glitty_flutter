import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glitty/CLient/RecapCommande.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  final int clientId;
  final String typeLavage;

  final Map<String, dynamic>? vehicleData;
  final Map<String, dynamic>? clientData;
  final List<dynamic>? photos;
  final String date;
  final String creneau;

  const LocationPage({
    super.key,
    required this.clientId,
    required this.typeLavage,
    this.vehicleData,
    this.clientData,
    this.photos,
    required this.date,
    required this.creneau,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool _useGlittyBalance = false;
  bool _showLocationModal = false;
  final TextEditingController _locationController = TextEditingController();
  LatLng _currentLocation = LatLng(46.603354, 1.888334);
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showLocationError('Permission de localisation refusée');
          setState(() {
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
            'Permission de localisation définitivement refusée. Activez-la dans les paramètres.');
        setState(() {
          _isLoadingLocation = false;
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoadingLocation = false;
      });

      _mapController.move(_currentLocation, 13.0);
      _getAddressFromLatLng(_currentLocation);
    } catch (e) {
      print('Erreur de géolocalisation: $e');
      _showLocationError('Impossible d\'obtenir la position actuelle');
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _showLocationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<String> _getAddressFromLatLng(LatLng latLng) async {
    setState(() {
      _isLoadingAddress = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1',
        ),
        headers: {
          'User-Agent': 'GlittyApp/1.0 (contact@glitty.com)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['display_name'] ?? 'Adresse non trouvée';
        setState(() {
          _locationController.text = address;
          _isLoadingAddress = false;
        });
        return address;
      } else {
        print('Erreur HTTP: ${response.statusCode}');
        final fallbackAddress =
            '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
        setState(() {
          _locationController.text = fallbackAddress;
          _isLoadingAddress = false;
        });
        return fallbackAddress;
      }
    } catch (e) {
      print('Erreur reverse geocoding: $e');
      final fallbackAddress =
          '${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}';
      setState(() {
        _locationController.text = fallbackAddress;
        _isLoadingAddress = false;
      });
      return fallbackAddress;
    }
  }

  void _onMapTap(LatLng point) async {
    setState(() {
      _currentLocation = point;
      _locationController.text = 'Chargement de l\'adresse...';
    });

    await _getAddressFromLatLng(point);
    _mapController.move(point, 15.0);
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(query)}&limit=5&addressdetails=1&countrycodes=fr',
        ),
        headers: {
          'User-Agent': 'GlittyApp/1.0 (contact@glitty.com)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            return {
              'display_name': item['display_name'],
              'lat': double.parse(item['lat']),
              'lon': double.parse(item['lon']),
            };
          }).toList();
        });
      } else {
        print('Erreur HTTP recherche: ${response.statusCode}');
        setState(() {
          _searchResults = [];
        });
      }
    } catch (e) {
      print('Erreur de recherche: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _updateMapLocation(LatLng newLocation, String address) {
    setState(() {
      _currentLocation = newLocation;
      _locationController.text = address;
    });
    _mapController.move(newLocation, 15.0);
    Navigator.pop(context);
  }

  void _showLocationBottomSheet() {
    setState(() {
      _showLocationModal = true;
      _searchResults = [];
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationModal(),
    ).then((value) {
      setState(() {
        _showLocationModal = false;
        _searchResults = [];
      });
    });
  }

  void _centerOnFrance() {
    setState(() {
      _currentLocation = LatLng(46.603354, 1.888334);
      _locationController.text = 'France';
    });
    _mapController.move(_currentLocation, 6.0);
  }

  // MODIFIÉ : Navigation vers RecapCommandePage avec tous les paramètres
  void _navigateToRecapCommande() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecapCommandePage(
          clientId: widget.clientData?['id'],
          selectedAddress: _locationController.text.isEmpty
              ? 'Position: ${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}'
              : _locationController.text,
          latitude: _currentLocation.latitude,
          longitude: _currentLocation.longitude,
          typeLavage: widget.typeLavage,
          vehicleData: widget.vehicleData,
          photos: widget.photos,
          date: widget.date,
          creneau: widget.creneau,
          clientData: widget.clientData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _currentLocation,
              zoom: _isLoadingLocation ? 6.0 : 13.0,
              onTap: (tapPosition, point) {
                _onMapTap(point);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.glitty.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 40.0,
                    height: 40.0,
                    point: _currentLocation,
                    builder: (ctx) => Stack(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                        if (_isLoadingAddress)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Indicateur de chargement principal
          if (_isLoadingLocation)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Localisation en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          SafeArea(
            child: Column(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  color: dark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/menu-icone.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
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
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText:
                                      'Prêt à faire briller sans polluer!',
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 19 / 14,
                                    letterSpacing: -0.3,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Image.asset(
                                      'assets/search-icone.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/salut-icone.png',
                            width: 40,
                            height: 40,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Afficher les informations de la commande
          Positioned(
            top: 200,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Text(
                    _getLavageTitle(widget.typeLavage),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF022519),
                    ),
                  ),
                  if (widget.vehicleData != null)
                    Text(
                      "Véhicule: ${widget.vehicleData!['type']}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    "Date: ${_formatDate(widget.date)}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    "Créneau: ${_formatCreneau(widget.creneau)}",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: 200,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  backgroundColor: Colors.white,
                  mini: true,
                  child: Icon(
                    Icons.my_location,
                    color: _isLoadingLocation
                        ? Colors.grey
                        : const Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _centerOnFrance,
                  backgroundColor: Colors.white,
                  mini: true,
                  child: const Icon(
                    Icons.map,
                    color: Color(0xFF022519),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavIcon(Icons.home, 'Home'),
                      _buildNavIcon(Icons.search, 'Rechercher'),
                      _buildNavIcon(Icons.add, 'Ajouter'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isLoadingAddress)
                                const Text(
                                  'Chargement de l\'adresse...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                )
                              else if (_locationController.text.isEmpty)
                                const Text(
                                  'Cliquez sur la carte pour sélectionner une adresse...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Text(
                                  _locationController.text,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (!_isLoadingAddress &&
                                  _locationController.text.isNotEmpty)
                                Text(
                                  '${_currentLocation.latitude.toStringAsFixed(6)}, ${_currentLocation.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (_isLoadingAddress)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _locationController.text.isEmpty
                          ? null
                          : _navigateToRecapCommande,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _locationController.text.isEmpty
                            ? Colors.grey
                            : const Color(0xFF4FBF67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Choisir cette localisation',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 30,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Choisir la localisation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Rechercher une adresse en France...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.length > 2) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    _searchLocation(value);
                  });
                } else {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildDefaultSuggestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return ListTile(
          leading: const Icon(Icons.location_on, color: Color(0xFF022519)),
          title: Text(
            result['display_name'],
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          onTap: () {
            _updateMapLocation(
              LatLng(result['lat'], result['lon']),
              result['display_name'],
            );
          },
        );
      },
    );
  }

  Widget _buildDefaultSuggestions() {
    final frenchCities = [
      {'name': '📍 Paris, France', 'lat': 48.8566, 'lon': 2.3522},
      {'name': '📍 Lyon, France', 'lat': 45.7640, 'lon': 4.8357},
      {'name': '📍 Marseille, France', 'lat': 43.2965, 'lon': 5.3698},
      {'name': '📍 Toulouse, France', 'lat': 43.6047, 'lon': 1.4442},
      {'name': '📍 Nice, France', 'lat': 43.7102, 'lon': 7.2620},
      {'name': '📍 Bordeaux, France', 'lat': 44.8378, 'lon': -0.5792},
    ];

    return ListView(
      children: frenchCities.map((city) {
        return _buildLocationSuggestion(
          city['name'] as String,
          Icons.location_city,
          onTap: () {
            _updateMapLocation(
              LatLng(city['lat'] as double, city['lon'] as double),
              city['name'] as String,
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildLocationSuggestion(String text, IconData icon,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF022519)),
      title: Text(text),
      onTap: onTap,
    );
  }

  // Fonctions utilitaires
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
      final parsedDate = DateTime.parse(date);
      final months = [
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
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatCreneau(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin (8h-12h)';
      case 'apres_midi':
        return 'Après-midi (12h-17h)';
      case 'soir':
        return 'Soir (17h-20h)';
      default:
        return creneau;
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }
}
