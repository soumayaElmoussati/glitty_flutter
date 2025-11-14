// services/password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glitty/config/env.dart';

class PasswordService {
  static final String _baseUrl = Env.baseUrl;

  // Changer le mot de passe
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/client/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Mot de passe changé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Erreur lors du changement de mot de passe',
          'error': responseData['error'],
        };
      }
    } catch (error) {
      print('❌ Erreur changement mot de passe: $error');
      return {
        'success': false,
        'message': 'Erreur de connexion. Veuillez réessayer.',
        'error': error.toString(),
      };
    }
  }

  // Vérifier la force du mot de passe
  static Map<String, dynamic> validatePasswordStrength(String password) {
    if (password.length < 6) {
      return {
        'isValid': false,
        'message': 'Le mot de passe doit contenir au moins 6 caractères'
      };
    }

    if (password.length < 8) {
      return {
        'isValid': true,
        'message': 'Mot de passe acceptable',
        'strength': 'medium'
      };
    }

    // Vérifier la complexité
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChars =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    int strength = 1;
    if (hasUpperCase) strength++;
    if (hasLowerCase) strength++;
    if (hasNumbers) strength++;
    if (hasSpecialChars) strength++;

    String message = 'Mot de passe faible';
    if (strength >= 3) message = 'Mot de passe moyen';
    if (strength >= 5) message = 'Mot de passe fort';

    return {
      'isValid': true,
      'message': message,
      'strength': strength >= 5
          ? 'strong'
          : strength >= 3
              ? 'medium'
              : 'weak'
    };
  }
}
