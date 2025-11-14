import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _clientTokenKey = 'client_token';
  static const String _washerTokenKey = 'washer_token';
  static const String _clientDataKey = 'client_data';
  static const String _washerDataKey = 'washer_data';
  static const String _userTypeKey = 'user_type';

  // Sauvegarder les données de connexion client
  static Future<void> saveClientLogin(
      Map<String, dynamic> clientData, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clientTokenKey, token);
    await prefs.setString(_clientDataKey, json.encode(clientData));
    await prefs.setString(_userTypeKey, 'client');
    print('✅ Client session saved - ID: ${clientData['id']}');
  }

  // Sauvegarder les données de connexion washer
  static Future<void> saveWasherLogin(
      Map<String, dynamic> washerData, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_washerTokenKey, token);
    await prefs.setString(_washerDataKey, json.encode(washerData));
    await prefs.setString(_userTypeKey, 'washer');
    print('✅ Washer session saved - ID: ${washerData['id']}');
  }

  // Vérifier si l'utilisateur est connecté
  static Future<Map<String, dynamic>> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_userTypeKey);

    if (userType == 'client') {
      final token = prefs.getString(_clientTokenKey);
      final clientData = prefs.getString(_clientDataKey);

      if (token != null && clientData != null) {
        return {
          'userType': 'client',
          'token': token,
          'userData': json.decode(clientData),
          'isLoggedIn': true,
        };
      }
    } else if (userType == 'washer') {
      final token = prefs.getString(_washerTokenKey);
      final washerData = prefs.getString(_washerDataKey);

      if (token != null && washerData != null) {
        return {
          'userType': 'washer',
          'token': token,
          'userData': json.decode(washerData),
          'isLoggedIn': true,
        };
      }
    }

    return {'isLoggedIn': false};
  }

  // Déconnexion
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_userTypeKey);

    if (userType == 'client') {
      await prefs.remove(_clientTokenKey);
      await prefs.remove(_clientDataKey);
      print('✅ Client logged out');
    } else if (userType == 'washer') {
      await prefs.remove(_washerTokenKey);
      await prefs.remove(_washerDataKey);
      print('✅ Washer logged out');
    }

    await prefs.remove(_userTypeKey);
  }

  // Récupérer le token actuel
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_userTypeKey);

    if (userType == 'client') {
      return prefs.getString(_clientTokenKey);
    } else if (userType == 'washer') {
      return prefs.getString(_washerTokenKey);
    }

    return null;
  }

  // Récupérer le type d'utilisateur
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTypeKey);
  }
}
