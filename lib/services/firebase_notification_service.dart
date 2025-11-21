import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController<Map<String, dynamic>>.broadcast();

  static Stream<Map<String, dynamic>> get notifications =>
      _notificationStream.stream;

  static Future<void> initialize() async {
    try {
      print('🚀 Vérification initialisation Firebase...');

      // Vérifier si Firebase est déjà initialisé
      try {
        Firebase.app(); // Cette ligne va lancer une exception si non initialisé
        print('✅ Firebase déjà initialisé');
      } catch (e) {
        print('⚠️ Firebase pas encore initialisé, initialisation...');
        await Firebase.initializeApp();
        print('✅ Firebase initialisé par le service');
      }

      // Configuration des notifications
      await _configureNotifications();

      // Écouter les messages
      _setupMessageHandlers();

      // Récupérer le token
      await _getFCMToken();
    } catch (e) {
      print('❌ Erreur initialisation notifications: $e');
    }
  }

  static Future<void> _configureNotifications() async {
    // Demander les permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    print('📋 Statut permissions: ${settings.authorizationStatus}');

    // Configurer l'affichage des notifications en foreground
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true, // Afficher la notification
      badge: true, // Mettre à jour le badge
      sound: true, // Jouer le son
    );
  }

  static void _setupMessageHandlers() {
    // Message reçu quand l'app est en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 Notification reçue en foreground');
      _handleNotification(message);
    });

    // Notification cliquée quand l'app est en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🎯 Notification cliquée (background)');
      _handleNotification(message, isBackground: true);
    });

    // Notification cliquée quand l'app est fermée
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('🎯 Notification cliquée (app fermée)');
        _handleNotification(message, isBackground: true);
      }
    });
  }

  static void _handleNotification(RemoteMessage message,
      {bool isBackground = false}) {
    final notification = message.notification;
    final data = message.data;

    print('📨 Données notification:');
    print('- Titre: ${notification?.title}');
    print('- Corps: ${notification?.body}');
    print('- Data: $data');

    // Préparer les données pour le stream
    final notificationData = {
      'title': notification?.title,
      'body': notification?.body,
      'data': data,
      'isBackground': isBackground,
      'timestamp': DateTime.now().toString(),
    };

    // Émettre dans le stream
    _notificationStream.add(notificationData);

    // Afficher un snackbar si en foreground
    if (!isBackground) {
      _showInAppNotification(notificationData);
    }
  }

  static void _showInAppNotification(Map<String, dynamic> notificationData) {
    // Cette méthode sera implémentée dans le widget
    print('📢 Notification in-app: ${notificationData['title']}');
  }

  static Future<String?> _getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print('🔥 Token FCM: $token');
      return token;
    } catch (e) {
      print('❌ Erreur récupération token FCM: $e');
      return null;
    }
  }

  static Future<String?> getFCMToken() async {
    return await _getFCMToken();
  }

  // Envoyer le token au serveur
  static Future<void> sendTokenToServer(int washerId, String token) async {
    try {
      // Implémentez l'envoi du token à votre backend
      print('📤 Envoi du token FCM au serveur pour washer $washerId');
      // await http.post(...);
    } catch (e) {
      print('❌ Erreur envoi token au serveur: $e');
    }
  }

  // AJOUTEZ CETTE MÉTHODE POUR FERMER LE STREAM
  static void dispose() {
    if (!_notificationStream.isClosed) {
      _notificationStream.close();
    }
  }
}
