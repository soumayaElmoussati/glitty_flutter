import 'dart:convert';
import 'dart:math';

class MockApiService {
  static const bool USE_MOCK_DATA = true; // Changez à false quand les vraies APIs sont prêtes

  // Données simulées pour les washers en attente
  static final List<Map<String, dynamic>> _pendingWashers = [
    {
      'id': 1,
      'nom': 'Martin',
      'prenom': 'Alexandre',
      'email': 'alexandre.martin@email.com',
      'telephone': '06 12 34 56 78',
      'adresse': '123 Rue de la Paix, 75001 Paris',
      'date_creation': '2024-12-15T10:30:00Z',
      'piece_identite': 'carte_identite_alexandre.pdf',
      'justificatif_domicile': 'facture_edf_alexandre.pdf',
      'permis_conduire': 'permis_alexandre.pdf',
      'certificats_formation': 'certificat_formation_alexandre.pdf',
      'statut': 'en_attente'
    },
    {
      'id': 2,
      'nom': 'Dubois',
      'prenom': 'Sophie',
      'email': 'sophie.dubois@email.com',
      'telephone': '07 98 76 54 32',
      'adresse': '456 Avenue des Champs, 69000 Lyon',
      'date_creation': '2024-12-14T14:20:00Z',
      'piece_identite': 'passeport_sophie.pdf',
      'justificatif_domicile': 'quittance_loyer_sophie.pdf',
      'permis_conduire': null,
      'certificats_formation': 'formation_auto_sophie.pdf',
      'statut': 'en_attente'
    },
    {
      'id': 3,
      'nom': 'Garcia',
      'prenom': 'Carlos',
      'email': 'carlos.garcia@email.com',
      'telephone': '06 45 67 89 01',
      'adresse': '789 Boulevard du Soleil, 13000 Marseille',
      'date_creation': '2024-12-13T09:15:00Z',
      'piece_identite': 'carte_identite_carlos.pdf',
      'justificatif_domicile': 'facture_gaz_carlos.pdf',
      'permis_conduire': 'permis_carlos.pdf',
      'certificats_formation': 'certification_pro_carlos.pdf',
      'statut': 'en_attente'
    }
  ];

  // Données simulées pour les notifications
  static final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'washer_id': 1,
      'type': 'validation_approved',
      'title': 'Félicitations ! Votre compte a été approuvé',
      'message': 'Votre demande d\'inscription comme washer a été approuvée. Vous pouvez maintenant commencer à recevoir des missions de lavage.',
      'is_read': false,
      'created_at': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
    },
    {
      'id': 2,
      'washer_id': 1,
      'type': 'new_mission',
      'title': 'Nouvelle mission disponible',
      'message': 'Une nouvelle mission de lavage extérieur est disponible dans votre zone. Prix: 25€ - Distance: 2.5km',
      'is_read': false,
      'created_at': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
    },
    {
      'id': 3,
      'washer_id': 1,
      'type': 'payment',
      'title': 'Paiement reçu',
      'message': 'Votre paiement de 29.75€ pour la mission du 14 décembre a été transféré vers votre portefeuille.',
      'is_read': true,
      'created_at': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
    },
    {
      'id': 4,
      'washer_id': 1,
      'type': 'info',
      'title': 'Mise à jour de l\'application',
      'message': 'Une nouvelle version de l\'application Glitty est disponible avec de nouvelles fonctionnalités.',
      'is_read': true,
      'created_at': DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
    }
  ];

  // Données simulées pour le calendrier des missions
  static final List<Map<String, dynamic>> _missions = [
    {
      'id': 1,
      'washer_id': 1,
      'client_nom': 'Jean Dupont',
      'type_lavage': 'Lavage complet',
      'prix': 35.00,
      'date_mission': DateTime.now().toIso8601String().split('T')[0],
      'heure_mission': '10:30',
      'adresse': '123 Rue de la République, Paris',
      'statut': 'accepté'
    },
    {
      'id': 2,
      'washer_id': 1,
      'client_nom': 'Marie Martin',
      'type_lavage': 'Lavage extérieur',
      'prix': 20.00,
      'date_mission': DateTime.now().toIso8601String().split('T')[0],
      'heure_mission': '14:00',
      'adresse': '456 Avenue des Lilas, Paris',
      'statut': 'en cours'
    },
    {
      'id': 3,
      'washer_id': 1,
      'client_nom': 'Pierre Durand',
      'type_lavage': 'Nettoyage intérieur',
      'prix': 25.00,
      'date_mission': DateTime.now().add(Duration(days: 1)).toIso8601String().split('T')[0],
      'heure_mission': '09:00',
      'adresse': '789 Boulevard Saint-Germain, Paris',
      'statut': 'accepté'
    },
    {
      'id': 4,
      'washer_id': 1,
      'client_nom': 'Sophie Laurent',
      'type_lavage': 'Lavage complet',
      'prix': 35.00,
      'date_mission': DateTime.now().add(Duration(days: 2)).toIso8601String().split('T')[0],
      'heure_mission': '11:30',
      'adresse': '321 Rue de Rivoli, Paris',
      'statut': 'terminé'
    },
    {
      'id': 5,
      'washer_id': 1,
      'client_nom': 'Antoine Moreau',
      'type_lavage': 'Lavage extérieur',
      'prix': 20.00,
      'date_mission': DateTime.now().add(Duration(days: 5)).toIso8601String().split('T')[0],
      'heure_mission': '16:00',
      'adresse': '654 Place de la Bastille, Paris',
      'statut': 'en cours'
    }
  ];

  /// Simule l'API GET /api/admin/washers/pending
  static Map<String, dynamic> getPendingWashers() {
    return {
      'success': true,
      'washers': _pendingWashers.where((w) => w['statut'] == 'en_attente').toList(),
    };
  }

  /// Simule l'API PATCH /api/admin/washers/validate/:id
  static Map<String, dynamic> validateWasher(int washerId, bool approved) {
    final washerIndex = _pendingWashers.indexWhere((w) => w['id'] == washerId);
    if (washerIndex != -1) {
      _pendingWashers[washerIndex]['statut'] = approved ? 'approuvé' : 'rejeté';
      
      // Ajouter une notification pour ce washer
      if (approved) {
        _notifications.insert(0, {
          'id': _notifications.length + 1,
          'washer_id': washerId,
          'type': 'validation_approved',
          'title': 'Félicitations ! Votre compte a été approuvé',
          'message': 'Votre demande d\'inscription comme washer a été approuvée. Vous pouvez maintenant commencer à recevoir des missions.',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        _notifications.insert(0, {
          'id': _notifications.length + 1,
          'washer_id': washerId,
          'type': 'validation_rejected',
          'title': 'Candidature rejetée',
          'message': 'Malheureusement, votre candidature n\'a pas été retenue. Vous pouvez soumettre une nouvelle demande après avoir vérifié vos documents.',
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
    
    return {
      'success': true,
      'message': approved ? 'Washer approuvé avec succès' : 'Washer rejeté',
    };
  }

  /// Simule l'API GET /api/notifications/:washerId
  static Map<String, dynamic> getNotifications(int washerId) {
    final washerNotifications = _notifications
        .where((n) => n['washer_id'] == washerId)
        .toList()
      ..sort((a, b) => DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])));

    return {
      'success': true,
      'notifications': washerNotifications,
    };
  }

  /// Simule l'API PATCH /api/notifications/:id/read
  static Map<String, dynamic> markNotificationAsRead(int notificationId) {
    final notificationIndex = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (notificationIndex != -1) {
      _notifications[notificationIndex]['is_read'] = true;
    }
    
    return {
      'success': true,
      'message': 'Notification marquée comme lue',
    };
  }

  /// Simule l'API GET /api/missions/calendar/:washerId
  static Map<String, dynamic> getMissionsCalendar(int washerId) {
    final washerMissions = _missions
        .where((m) => m['washer_id'] == washerId)
        .toList();

    return {
      'success': true,
      'missions': washerMissions,
    };
  }

  /// Méthode utilitaire pour simuler un délai réseau
  static Future<void> simulateNetworkDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
  }
} 