import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glitty/MesTicketsWasher.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/DashboardWasher.dart';

class WasherSetGPSPage extends StatefulWidget {
  final int washerId;
  final Map<String, dynamic>? washerData;

  const WasherSetGPSPage({
    super.key,
    required this.washerId,
    this.washerData,
    Map<String, dynamic>? commandeData,
  });

  @override
  State<WasherSetGPSPage> createState() => _WasherSetGPSPageState();
}

class _WasherSetGPSPageState extends State<WasherSetGPSPage> {
  LatLng _position = LatLng(46.603354, 1.888334);
  final Color dark = const Color(0xFF022519);
  final Color accentColor = const Color(0xFF4CAF50);
  MapController _mapController = MapController();
  bool _isLoading = false;
  bool _locationLoaded = false;
  bool _isLoadingAddress = false;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showLocationModal = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _street = '';
  String _city = '';
  String _postalCode = '';
  String _country = '';

  @override
  void initState() {
    super.initState();
    print('🚗 WasherSetGPSPage initialisé avec washerId: ${widget.washerId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  // Fonctions de géocodage existantes
  Future<Map<String, dynamic>> _getAddressDetailsFromLatLng(
      LatLng latLng) async {
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
        final addressDetails = data['address'] ?? {};

        final street = _extractStreet(addressDetails);
        final city = _extractCity(addressDetails);
        final postalCode = addressDetails['postcode']?.toString() ?? '';
        final country = addressDetails['country']?.toString() ?? '';

        setState(() {
          _addressController.text = address;
          _street = street;
          _city = city;
          _postalCode = postalCode;
          _country = country;
          _isLoadingAddress = false;
        });

        return {
          'formatted_address': address,
          'street': street,
          'city': city,
          'postal_code': postalCode,
          'country': country,
        };
      } else {
        return _getFallbackAddress();
      }
    } catch (e) {
      return _getFallbackAddress();
    }
  }

  String _extractStreet(Map<String, dynamic> addressDetails) {
    if (addressDetails['road'] != null)
      return addressDetails['road'].toString();
    if (addressDetails['street'] != null)
      return addressDetails['street'].toString();
    if (addressDetails['pedestrian'] != null)
      return addressDetails['pedestrian'].toString();
    return '';
  }

  String _extractCity(Map<String, dynamic> addressDetails) {
    if (addressDetails['city'] != null)
      return addressDetails['city'].toString();
    if (addressDetails['town'] != null)
      return addressDetails['town'].toString();
    if (addressDetails['village'] != null)
      return addressDetails['village'].toString();
    if (addressDetails['municipality'] != null)
      return addressDetails['municipality'].toString();
    return '';
  }

  Map<String, dynamic> _getFallbackAddress() {
    final fallbackAddress = 'Position sélectionnée sur la carte';
    setState(() {
      _addressController.text = fallbackAddress;
      _street = '';
      _city = '';
      _postalCode = '';
      _country = '';
      _isLoadingAddress = false;
    });

    return {
      'formatted_address': fallbackAddress,
      'street': '',
      'city': '',
      'postal_code': '',
      'country': '',
    };
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le service de localisation est désactivé.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Les permissions de localisation sont refusées.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Les permissions de localisation sont définitivement refusées.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _position = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });

      _mapController.move(_position, 15.0);
      await _getAddressDetailsFromLatLng(_position);
    } catch (error) {
      print('Erreur de localisation: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la récupération de la position'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onMapTap(LatLng point) async {
    setState(() {
      _position = point;
      _addressController.text = 'Chargement de l\'adresse...';
    });

    await _getAddressDetailsFromLatLng(point);
    _mapController.move(point, 15.0);
  }

  // NOUVELLES FONCTIONS POUR LA RECHERCHE
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
      _position = newLocation;
      _addressController.text = address;
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
      _position = LatLng(46.603354, 1.888334);
      _addressController.text = 'France';
    });
    _mapController.move(_position, 6.0);
  }

  Future<void> _validerPosition() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Préparer les données avec tous les détails d'adresse
      final Map<String, dynamic> requestData = {
        'latitude': _position.latitude,
        'longitude': _position.longitude,
        'formatted_address': _addressController.text.isEmpty
            ? 'Position sélectionnée sur la carte'
            : _addressController.text,
        'street': _street,
        'city': _city,
        'postal_code': _postalCode,
        'country': _country,
      };

      print('📤 Données envoyées: $requestData');
      print('👤 Washer ID: ${widget.washerId}');
      print(
          '🌐 URL: ${Env.baseUrl}/api/washer/add-location-washer/${widget.washerId}');

      // Utiliser la nouvelle API avec l'ID dans l'URL
      final url = Uri.parse(
          '${Env.baseUrl}/api/washer/add-location-washer/${widget.washerId}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                data['message'] ?? '✅ Localisation enregistrée avec succès'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        print('✅ Localisation enregistrée: ${data['data']}');

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardWasherPage(
                nom: widget.washerData?['first_name'] ?? 'Washer',
                washerId: widget.washerId,
                washerData: widget.washerData,
              ),
            ),
          );
        });
      } else {
        final data = jsonDecode(response.body);
        String errorMessage =
            data['message'] ?? '❌ Erreur lors de l\'enregistrement';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      print('❌ Erreur API: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Erreur de connexion au serveur'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Drawer identique
  Widget _buildModernDrawer(BuildContext context) {
    final washerName = widget.washerData?['first_name'] ?? 'Washer';

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
                        washerName.isNotEmpty
                            ? washerName[0].toUpperCase()
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
                    washerName,
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
                      () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DashboardWasherPage(
                            nom: washerName,
                            washerId: widget.washerId,
                            washerData: widget.washerData,
                          ),
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.calendar_month_rounded,
                      "Planning",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/security'),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      true,
                      dark,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.help_rounded,
                      "Aide & Support",
                      false,
                      dark,
                      () {
                        Navigator.pop(context); // Fermer le drawer
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

  // NOUVELLE MÉTHODE POUR LA MODALE DE RECHERCHE
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
              color: dark,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildModernDrawer(context),
      backgroundColor: dark,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _position,
              zoom: _locationLoaded ? 15.0 : 10.0,
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
                    point: _position,
                    builder: (ctx) => Stack(
                      children: [
                        const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                        if (_isLoadingAddress)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.red),
                                ),
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
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Localisation en cours...',
                    style: TextStyle(
                      color: Colors.black,
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
                          Container(
                            width: 24,
                            height: 24,
                            color: Colors.transparent,
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
                                  builder: (_) => DashboardWasherPage(
                                    nom: widget.washerData?['first_name'] ??
                                        'Washer',
                                    washerId: widget.washerId,
                                    washerData: widget.washerData,
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
                    color: _isLoading ? Colors.grey : dark,
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
              decoration: BoxDecoration(
                color: dark,
                borderRadius: const BorderRadius.only(
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
                            builder: (_) => DashboardWasherPage(
                              nom: widget.washerData?['first_name'] ?? 'Washer',
                              washerId: widget.washerId,
                              washerData: widget.washerData,
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
                              else if (_addressController.text.isEmpty)
                                const Text(
                                  'Cliquez sur la carte ou recherchez une adresse...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _addressController.text,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_street.isNotEmpty || _city.isNotEmpty)
                                      Text(
                                        '${_street.isNotEmpty ? _street : ''}${_street.isNotEmpty && _city.isNotEmpty ? ', ' : ''}${_city.isNotEmpty ? _city : ''}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              if (!_isLoadingAddress &&
                                  _addressController.text.isNotEmpty)
                                Text(
                                  '${_position.latitude.toStringAsFixed(6)}, ${_position.longitude.toStringAsFixed(6)}',
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
                      onPressed: (_isLoading ||
                              _isLoadingAddress ||
                              _addressController.text.isEmpty)
                          ? null
                          : _validerPosition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_isLoading ||
                                _isLoadingAddress ||
                                _addressController.text.isEmpty)
                            ? Colors.grey
                            : const Color(0xFF4FBF67),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Enregistrer la position',
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

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
