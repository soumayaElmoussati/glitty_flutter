import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WasherSetGPSPage extends StatefulWidget {
  const WasherSetGPSPage({super.key});

  @override
  State<WasherSetGPSPage> createState() => _WasherSetGPSPageState();
}

class _WasherSetGPSPageState extends State<WasherSetGPSPage> {
  LatLng _position = LatLng(31.63, -8.01);
  final TextEditingController _emailController = TextEditingController();
  final Color dark = const Color(0xFF022519);

  Future<void> _validerPosition() async {
    final url = Uri.parse('https://glitty.fr/api/washer/setLocation');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text.trim(),
        'latitude': _position.latitude,
        'longitude': _position.longitude,
      }),
    );

    final data = jsonDecode(response.body);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(data['message'])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Définir la position GPS"),
        backgroundColor: dark,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _position,
                zoom: 13,
                onTap: (tap, point) {
                  setState(() {
                    _position = point;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.glitty',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: _position,
                      builder: (context) => const Icon(Icons.location_on, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Votre email"),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _validerPosition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Enregistrer la position"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
