// services/google_auth_service.dart - AVEC Client ID
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:glitty/config/env.dart';

class GoogleAuthService {
  // REMPLACEZ PAR VOTRE VRAI CLIENT ID
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '677117119587-7ushv1me3405f6v7esvb6q4d96ikrdf7.apps.googleusercontent.com',
  );

  static Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('🚀 Début de la connexion Google...');
      print('🔑 Client ID: ${_googleSignIn.clientId}');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print('❌ Connexion Google annulée par l\'utilisateur');
        return null;
      }

      print('✅ Utilisateur Google récupéré: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print('🔐 Access Token obtenu');

      // Préparer les données pour l'API
      final userData = {
        'googleId': googleUser.id,
        'email': googleUser.email,
        'firstName': _extractFirstName(googleUser.displayName),
        'lastName': _extractLastName(googleUser.displayName),
        'avatarUrl': googleUser.photoUrl,
        'accessToken': googleAuth.accessToken,
        'idToken': googleAuth.idToken,
      };

      print('📤 Envoi des données au serveur...');

      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/client/google-auth'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(userData),
      );

      print('📡 Réponse serveur: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('🎉 Connexion Google réussie!');
          return data;
        } else {
          throw Exception(data['message'] ?? 'Erreur API Google');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      rethrow;
    }
  }

  static String _extractFirstName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return 'Utilisateur';
    return displayName.split(' ').first;
  }

  static String _extractLastName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return '';
    final parts = displayName.split(' ');
    return parts.length > 1 ? parts.last : '';
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      print('✅ Déconnexion Google réussie');
    } catch (e) {
      print('❌ Erreur déconnexion: $e');
    }
  }
}
