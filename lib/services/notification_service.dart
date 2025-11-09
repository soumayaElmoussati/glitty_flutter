// lib/services/notification_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glitty/config/env.dart';

class NotificationService {
  // Envoyer une notification aux washers proches
  static Future<Map<String, dynamic>> notifyNearbyWashers({
    required double latitude,
    required double longitude,
    required int commandeId,
    required String clientAddress,
    required String typeLavage,
    required double prix,
    required String date,
    required String creneau,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/notifications/notify-nearby-washers'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'commande_id': commandeId,
          'client_address': clientAddress,
          'type_lavage': typeLavage,
          'prix': prix,
          'date': date,
          'creneau': creneau,
          'radius': 10, // Rayon en km
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
          'message': 'Notifications envoyées aux washers proches',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de l\'envoi des notifications',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // Récupérer les notifications d'un washer
  static Future<Map<String, dynamic>> getWasherNotifications(
      int washerId) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/notifications/washer/$washerId'),
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
          'error': 'Erreur lors de la récupération des notifications',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  // Marquer une notification comme lue
  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/notifications/$notificationId/read'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Notification marquée comme lue',
        };
      } else {
        return {
          'success': false,
          'error': 'Erreur lors de la mise à jour',
        };
      }
    } catch (error) {
      return {
        'success': false,
        'error': 'Erreur réseau: $error',
      };
    }
  }

  static Future<Map<String, dynamic>> rejectCommande(int notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Env.baseUrl}/api/notifications/$notificationId/reject'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Commande refusée avec succès',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erreur lors du refus de la commande',
        };
      }
    } catch (error) {
      print('❌ Erreur service rejectCommande: $error');
      return {
        'success': false,
        'error': 'Erreur de connexion',
      };
    }
  }

  //

  static Future<Map<String, dynamic>> acceptCommande({
    required int notificationId,
    required int commandeId,
    required int washerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/notifications/accept-commande'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notification_id': notificationId,
          'commande_id': commandeId,
          'washer_id': washerId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Commande acceptée avec succès',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error':
              data['error'] ?? 'Erreur lors de l\'acceptation de la commande',
        };
      }
    } catch (error) {
      print('❌ Erreur service acceptCommande: $error');
      return {
        'success': false,
        'error': 'Erreur de connexion',
      };
    }
  }
}
