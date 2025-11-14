import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glitty/config/env.dart';

class ClientNotificationService {
  static Future<Map<String, dynamic>> getClientNotifications(
      int clientId) async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/notifications/client/$clientId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erreur de chargement',
        };
      }
    } catch (error) {
      print('❌ Erreur service getClientNotifications: $error');
      return {
        'success': false,
        'error': 'Erreur de connexion',
      };
    }
  }

  static Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse(
            '${Env.baseUrl}/api/notifications/client/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Notification marquée comme lue',
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Erreur lors du marquage',
        };
      }
    } catch (error) {
      print('❌ Erreur service markAsRead: $error');
      return {
        'success': false,
        'error': 'Erreur de connexion',
      };
    }
  }
}
