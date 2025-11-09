import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glitty/CLient/ChoisirCreneau.dart';
import 'package:glitty/CLient/ClientAccueil.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/CLient/RecapCommande.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

class LocationPage extends StatefulWidget {
  final int clientId;
  final String typeLavage;
  final Map<String, dynamic>? vehicleData;
  final Map<String, dynamic>? clientData;
  final List<File>? photos;
  final String date;
  final String creneau;
  final String? heure;
  final double prix;

  const LocationPage({
    super.key,
    required this.clientId,
    required this.typeLavage,
    this.vehicleData,
    this.clientData,
    this.photos,
    required this.date,
    required this.creneau,
    this.heure,
    required this.prix,
  });

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  bool _useGlittyBalance = false;
  bool _showLocationModal = false;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  LatLng _currentLocation = LatLng(46.603354, 1.888334);
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  MapController _mapController = MapController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
          'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeQueryComponent(query)}&limit=10&addressdetails=1&countrycodes=fr&viewbox=-5.0,41.0,9.0,51.0&bounded=1',
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
              'type': item['type'],
              'importance': item['importance'] ?? 0.0,
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
      _searchController.clear();
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
          heure: widget.heure,
          prix: widget.prix,
          clientData: widget.clientData,
        ),
      ),
    );
  }

  // Méthode pour construire le Drawer
  Widget _buildClientDrawer(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    final clientName = widget.clientData?['first_name'] ?? 'Client';

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
                        clientName.isNotEmpty
                            ? clientName[0].toUpperCase()
                            : 'C',
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
                    clientName,
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
                      "● Client",
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
                      Icons.home_rounded,
                      "Accueil",
                      false,
                      dark,
                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientAccueil(
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.shopping_bag_rounded,
                      "Mes commandes",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesCommandesPage(
                              clientId: widget.clientData?['id'] ?? 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Portefeuille",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortefeuillePage(
                              clientId: widget.clientData?['id'] ?? 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.person_rounded,
                      "Mon profil",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MonProfile(
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.people_rounded,
                      "Parrainage",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ParrainagePage(
                                  clientId: widget.clientData?['id'] ?? 1)),
                        );
                      },
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
                            builder: (_) => MesTicketsClient(
                              clientId: widget.clientData?['id'],
                              clientData: widget.clientData,
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

  // Méthode pour construire un item du Drawer
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

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      key: _scaffoldKey, // CLÉ AJOUTÉE POUR CONTRÔLER LE DRAWER
      drawer: _buildClientDrawer(context), // DRAWER AJOUTÉ ICI
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
                          // BOUTON MENU CORRIGÉ POUR OUVRIR LE DRAWER
                          Builder(
                            builder: (context) => GestureDetector(
                              onTap: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChoisirCreneau(
                                    clientId: widget.clientId,
                                    typeLavage: widget.typeLavage,
                                    vehicleData: widget.vehicleData,
                                    clientData: widget.clientData,
                                    photos: widget.photos,
                                    prix: widget.prix,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF022519),
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: GestureDetector(
                              onTap: _showLocationBottomSheet,
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.search,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Rechercher une adresse...',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                  if (widget.heure != null)
                    Text(
                      "Heure: ${widget.heure}",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    "Prix: ${widget.prix.toStringAsFixed(2)}€",
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
                      _buildNavIcon(Icons.home_filled, 'Accueil', () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientAccueil(
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      }),
                      _buildNavIcon(
                          Icons.search, 'Rechercher', _showLocationBottomSheet),
                      _buildNavIcon(Icons.location_on, 'Ma position',
                          _getCurrentLocation),
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
                                  'Cliquez sur la carte ou recherchez une adresse...',
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

  Widget _buildNavIcon(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
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
      ),
    );
  }

  Widget _buildLocationModal() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
                'Rechercher une adresse',
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Entrez une adresse, une ville, un lieu...',
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults = [];
                          });
                        },
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
          const SizedBox(height: 10),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Text('Recherche en cours...'),
                ],
              ),
            ),
          const SizedBox(height: 10),
          Expanded(
            child: _searchResults.isNotEmpty
                ? _buildSearchResults()
                : _buildEmptyState(),
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
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          elevation: 1,
          child: ListTile(
            leading: Icon(
              _getLocationIcon(result['type']),
              color: const Color(0xFF022519),
            ),
            title: Text(
              result['display_name'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              '${result['lat'].toStringAsFixed(6)}, ${result['lon'].toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
            onTap: () {
              _updateMapLocation(
                LatLng(result['lat'], result['lon']),
                result['display_name'],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Entrez une adresse pour commencer la recherche'
                : 'Aucun résultat trouvé pour "${_searchController.text}"',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (_searchController.text.isEmpty)
            Text(
              'Exemples: "Paris", "12 rue de la Paix Lyon", "Eiffel Tower"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getLocationIcon(String type) {
    switch (type) {
      case 'city':
      case 'town':
      case 'village':
        return Icons.location_city;
      case 'street':
      case 'road':
        return Icons.signpost;
      case 'house':
      case 'building':
        return Icons.home;
      case 'amenity':
        return Icons.local_activity;
      case 'natural':
        return Icons.landscape;
      default:
        return Icons.place;
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
    _searchController.dispose();
    super.dispose();
  }
}
