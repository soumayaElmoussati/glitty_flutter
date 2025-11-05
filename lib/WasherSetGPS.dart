import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glitty/config/env.dart';
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

  // Gardez toutes les fonctions de géocodage existantes...
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
                //   washerData: widget.washerData,
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
                            //     washerData: widget.washerData,
                          ),
                        ),
                      ),
                    ),
                    _buildDrawerItem(
                      Icons.notifications_rounded,
                      "Notifications",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/notifications'),
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
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: _buildDrawerItem(
                        Icons.logout_rounded,
                        "Déconnexion",
                        false,
                        Colors.red,
                        () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginWasherPage()),
                          (route) => false,
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
    return Scaffold(
      backgroundColor: dark,
      drawer: _buildModernDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header identique au Dashboard
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
                      // Icône notification désactivée
                      Container(
                        width: 24,
                        height: 24,
                        color: Colors.transparent,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16), // Espace entre les deux lignes

                  // Deuxième ligne : titre
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          child: const Center(
                            child: Text(
                              "Définir la position GPS",
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

            // Carte OpenStreetMap
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
                child: Stack(
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
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.red),
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
                    Positioned(
                      top: 20,
                      right: 20,
                      child: FloatingActionButton(
                        onPressed: _getCurrentLocation,
                        backgroundColor: Colors.white,
                        mini: true,
                        child: Icon(
                          Icons.my_location,
                          color: _isLoading ? Colors.grey : dark,
                        ),
                      ),
                    ),
                    if (_isLoading)
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
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
                  ],
                ),
              ),
            ),

            // Section d'adresse et bouton d'enregistrement
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
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
                                  'Cliquez sur la carte pour sélectionner une position...',
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_street.isNotEmpty || _city.isNotEmpty)
                                      Text(
                                        '${_street.isNotEmpty ? _street : ''}${_street.isNotEmpty && _city.isNotEmpty ? ', ' : ''}${_city.isNotEmpty ? _city : ''}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_position.latitude.toStringAsFixed(6)}, Lng: ${_position.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
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

                  const SizedBox(height: 16),

                  // Bouton d'enregistrement
                  ElevatedButton(
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
                          : dark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                            "Enregistrer la position",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }
}
