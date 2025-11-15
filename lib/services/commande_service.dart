// lib/services/commande_service.dart
import 'dart:convert';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/notification_service.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CommandeService {
  static Future<Map<String, dynamic>> getPrix({
    required String typeVehicule,
    required String typePrestation,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/tarif/vehicule-prestation?type_vehicule=${Uri.encodeQueryComponent(typeVehicule)}&type_prestation=${Uri.encodeQueryComponent(typePrestation)}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Réponse API brute: $data');

        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la récupération du prix',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

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
    required double prix,
    required String? notes,
    required String? dureeEstimee,
    required String? methodPaiement,
    List<XFile>? photos,
    double? soldeUtilise,
  }) async {
    try {
      var uri =
          Uri.parse('${Env.baseUrl}/api/commande/create-commande/$clientId');
      var request = http.MultipartRequest('POST', uri);

      // DEBUG: Afficher les données envoyées
      print('📤 === ENVOI CRÉATION COMMANDE ===');
      print('👤 Client ID: $clientId');
      print('📍 Adresse: $departAdresse');
      print('📅 Date: $date');
      print('⏰ Créneau: $creneau');
      print('💰 Prix: $prix €');
      print('🚗 Type lavage: $typeLavage');
      print('📍 Coordonnées: $departLat, $departLng');
      print('📸 Photos: ${photos?.length ?? 0}');
      print('💳 Méthode paiement: $methodPaiement');
      print('💎 Solde utilisé: $soldeUtilise €');

      // Ajouter les champs textuels
      if (vehicleId != null) {
        request.fields['vehicle_id'] = vehicleId.toString();
        print('🚙 Vehicle ID: $vehicleId');
      }

      if (vehicleData != null) {
        request.fields['vehicle_data'] = json.encode(vehicleData);
        print('🚙 Vehicle Data: $vehicleData');
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
      request.fields['prix'] = prix.toString();

      if (notes != null) request.fields['notes'] = notes;
      if (dureeEstimee != null) request.fields['duree_estimee'] = dureeEstimee;
      if (methodPaiement != null)
        request.fields['method_paiement'] = methodPaiement;

      // NOUVEAU: Ajouter le solde utilisé si présent
      if (soldeUtilise != null && soldeUtilise > 0) {
        request.fields['solde_utilise'] = soldeUtilise.toString();
        print('✅ Solde utilisé ajouté: $soldeUtilise €');
      }

      // Ajouter les photos
      if (photos != null && photos.isNotEmpty) {
        for (var i = 0; i < photos.length; i++) {
          var photo = photos[i];
          try {
            var file = await http.MultipartFile.fromPath(
              'photos',
              photo.path,
            );
            request.files.add(file);
            print('📸 Photo $i ajoutée: ${photo.path}');
          } catch (e) {
            print('⚠️ Erreur ajout photo $i: $e');
          }
        }
      }

      print('🔄 Envoi de la requête...');
      var response = await request.send();
      var responseString = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseString);

      print('📡 === RÉPONSE API ===');
      print('Status: ${response.statusCode}');
      print('Body: $jsonResponse');

      if (response.statusCode == 201) {
        print('✅ Commande créée avec succès!');

        // CORRECTION: Gestion flexible de la structure de réponse
        dynamic commandeData;

        if (jsonResponse['commande'] != null) {
          commandeData = jsonResponse['commande'];
          print('📋 Données commande trouvées dans [commande]');
        } else if (jsonResponse['data'] != null) {
          if (jsonResponse['data'] is Map &&
              jsonResponse['data']['commande'] != null) {
            commandeData = jsonResponse['data']['commande'];
            print('📋 Données commande trouvées dans [data][commande]');
          } else {
            commandeData = jsonResponse['data'];
            print('📋 Données commande trouvées dans [data]');
          }
        } else {
          commandeData = jsonResponse;
          print('📋 Données commande dans la racine');
        }

        // Récupérer l'ID de la commande
        final commandeId = _extractCommandeId(commandeData);

        if (commandeId != null) {
          print('🆔 ID Commande: $commandeId');

          // Envoyer les notifications en arrière-plan
          _sendNotificationsInBackground(
            departLat: departLat,
            departLng: departLng,
            commandeId: commandeId,
            departAdresse: departAdresse,
            typeLavage: typeLavage,
            prix: prix,
            date: date,
            creneau: creneau,
          );
        } else {
          print('⚠️ ID de commande non trouvé dans la réponse');
        }

        return {
          'success': true,
          'data': jsonResponse,
          'commande': commandeData,
        };
      } else {
        final errorMessage = jsonResponse['message'] ??
            jsonResponse['error'] ??
            'Erreur lors de la création de la commande (${response.statusCode})';

        print('❌ Erreur création commande: $errorMessage');

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (error) {
      print('❌ Erreur création commande: $error');
      print('Stack trace: ${error.toString()}');

      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // Extraire l'ID de la commande depuis différentes structures
  static int? _extractCommandeId(dynamic commandeData) {
    if (commandeData == null) return null;

    if (commandeData is Map) {
      // Essayer différents noms de clés possibles
      if (commandeData['id'] != null) {
        return int.tryParse(commandeData['id'].toString());
      }
      if (commandeData['commande_id'] != null) {
        return int.tryParse(commandeData['commande_id'].toString());
      }
      if (commandeData['Id'] != null) {
        return int.tryParse(commandeData['Id'].toString());
      }
    }

    return null;
  }

  // Envoyer les notifications en arrière-plan
  static void _sendNotificationsInBackground({
    required double departLat,
    required double departLng,
    required int commandeId,
    required String departAdresse,
    required String typeLavage,
    required double prix,
    required String date,
    required String creneau,
  }) async {
    try {
      print('🔔 === ENVOI NOTIFICATIONS ===');
      print('🆔 Commande ID: $commandeId');
      print('📍 Localisation: $departLat, $departLng');

      final notificationResult = await NotificationService.notifyNearbyWashers(
        latitude: departLat,
        longitude: departLng,
        commandeId: commandeId,
        clientAddress: departAdresse,
        typeLavage: typeLavage,
        prix: prix,
        date: date,
        creneau: creneau,
      );

      if (notificationResult['success'] == true) {
        print('✅ Notifications envoyées avec succès');
        print('📨 Message: ${notificationResult['message']}');
      } else {
        print('⚠️ Erreur envoi notifications: ${notificationResult['error']}');
      }
    } catch (e) {
      print('⚠️ Erreur envoi notifications: $e');
      // Ne pas bloquer la création de commande en cas d'erreur de notification
    }
  }

  // Méthode pour récupérer les commandes d'un client
  static Future<Map<String, dynamic>> getClientCommandes(int clientId) async {
    try {
      print('📋 Récupération des commandes pour client: $clientId');

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/commande/client/$clientId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la récupération des commandes',
        };
      }
    } catch (error) {
      print('❌ Erreur récupération commandes: $error');
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // Méthode pour récupérer une commande spécifique
  static Future<Map<String, dynamic>> getCommandeById(int commandeId) async {
    try {
      print('🔍 Récupération commande: $commandeId');

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Commande non trouvée',
        };
      }
    } catch (error) {
      print('❌ Erreur récupération commande: $error');
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // Méthode pour annuler une commande
  static Future<Map<String, dynamic>> cancelCommande(int commandeId) async {
    try {
      print('❌ Annulation commande: $commandeId');

      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId/cancel'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de l\'annulation de la commande',
        };
      }
    } catch (error) {
      print('❌ Erreur annulation commande: $error');
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // NOUVELLE MÉTHODE: Récupérer le solde du client
  static Future<Map<String, dynamic>> getSoldeClient(int clientId) async {
    try {
      print('💰 Récupération solde pour client: $clientId');

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/solde/$clientId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'solde': data['solde'] is int
              ? (data['solde'] as int).toDouble()
              : double.tryParse(data['solde'].toString()) ?? 0.0,
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la récupération du solde',
          'solde': 0.0,
        };
      }
    } catch (error) {
      print('❌ Erreur récupération solde: $error');
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
        'solde': 0.0,
      };
    }
  }

  //

  static Future<Map<String, dynamic>> getCommandeDetail({
    required int commandeId,
    required int washerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/commande/$commandeId/details-commande?washerId=$washerId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        return {
          'success': false,
          'error': 'Erreur de chargement: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }
}
