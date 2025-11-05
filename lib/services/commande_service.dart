// lib/services/commande_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CommandeService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> createCommande({
    required int clientId,
    required int? vehicleId,
    required Map<String, dynamic>? vehicleData,
    required String date,
    required String creneau,
    required String? heure,
    required double departLat,
    required double departLng,
    required String departAdresse,
    required double? arriveeLat,
    required double? arriveeLng,
    required String? arriveeAdresse,
    required String typeLavage,
    required String? notes,
    required String? dureeEstimee,
    required String? methodPaiement,
    List<XFile>? photos,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl/commande/create-commande/$clientId');
      var request = http.MultipartRequest('POST', uri);

      // Ajouter les champs textuels
      if (vehicleId != null) {
        request.fields['vehicle_id'] = vehicleId.toString();
      }

      if (vehicleData != null) {
        request.fields['vehicle_data'] = json.encode(vehicleData);
      }

      request.fields['date'] = date;
      request.fields['creneau'] = creneau;
      if (heure != null) request.fields['heure'] = heure;
      request.fields['depart_lat'] = departLat.toString();
      request.fields['depart_lng'] = departLng.toString();
      request.fields['depart_adresse'] = departAdresse;

      if (arriveeLat != null)
        request.fields['arrivee_lat'] = arriveeLat.toString();
      if (arriveeLng != null)
        request.fields['arrivee_lng'] = arriveeLng.toString();
      if (arriveeAdresse != null)
        request.fields['arrivee_adresse'] = arriveeAdresse;

      request.fields['type_lavage'] = typeLavage;

      if (notes != null) request.fields['notes'] = notes;
      if (dureeEstimee != null) request.fields['duree_estimee'] = dureeEstimee;
      if (methodPaiement != null)
        request.fields['method_paiement'] = methodPaiement;

      // Ajouter les photos
      if (photos != null && photos.isNotEmpty) {
        for (var photo in photos) {
          var file = await http.MultipartFile.fromPath(
            'photos',
            photo.path,
          );
          request.files.add(file);
        }
      }

      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseString);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonResponse,
        };
      } else {
        return {
          'success': false,
          'error': jsonResponse['message'] ?? 'Erreur inconnue',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }
}
