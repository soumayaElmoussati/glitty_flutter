import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:glitty/CLient/PaiementPage.dart';
import 'package:latlong2/latlong.dart';

class LocalisationChoix extends StatefulWidget {
  final String optionChoisie;
  // final int prix;

  const LocalisationChoix({
    super.key,
    required this.optionChoisie,
    //  required this.prix,
  });

  @override
  _LocalisationChoixState createState() => _LocalisationChoixState();
}

class _LocalisationChoixState extends State<LocalisationChoix> {
  LatLng _selectedPosition = LatLng(31.63, -8.01);

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choisir une localisation"),
        backgroundColor: dark,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: _selectedPosition,
                zoom: 13.0,
                onTap: (tapPos, point) {
                  setState(() {
                    _selectedPosition = point;
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
                      point: _selectedPosition,
                      builder: (context) => const Icon(Icons.location_on,
                          color: Colors.red, size: 40),
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
                Text(
                  "Option sélectionnée : ${widget.optionChoisie}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 4),
                // Text("Prix : ${widget.prix} €",
                //   style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  "Coordonnées : ${_selectedPosition.latitude.toStringAsFixed(5)}, ${_selectedPosition.longitude.toStringAsFixed(5)}",
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    // Rediriger vers la page de paiement avec les informations
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaiementPage(
                          optionChoisie: widget.optionChoisie,
                          // prix: widget.prix,
                          latitude: _selectedPosition.latitude,
                          longitude: _selectedPosition.longitude,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Continuer vers le paiement",
                    style: TextStyle(color: Colors.white),
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
