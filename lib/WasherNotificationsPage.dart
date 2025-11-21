// lib/WasherNotificationsPage.dart
import 'package:flutter/material.dart';
import 'package:glitty/services/notification_service.dart';
import 'package:glitty/WasherCommandeDetailPage.dart';

class WasherNotificationsPage extends StatefulWidget {
  final int washerId;
  final Map<String, dynamic>? washerData;
  final String? washerName;

  const WasherNotificationsPage({
    Key? key,
    required this.washerId,
    this.washerData,
    this.washerName,
  }) : super(key: key);

  @override
  _WasherNotificationsPageState createState() =>
      _WasherNotificationsPageState();
}

class _WasherNotificationsPageState extends State<WasherNotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _hasUnreadNotifications = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    final result =
        await NotificationService.getWasherNotifications(widget.washerId);

    if (result['success'] == true) {
      final data = result['data'];
      List<dynamic> notifications = [];

      if (data is Map<String, dynamic>) {
        if (data.containsKey('notifications')) {
          notifications = data['notifications'] ?? [];
        } else if (data.containsKey('data') &&
            data['data'] is Map &&
            data['data']?['notifications'] != null) {
          notifications = data['data']['notifications'] ?? [];
        }
      }

      final hasUnread = notifications.any((notif) {
        final isRead = notif['is_read'];
        if (isRead is num) return isRead == 0;
        if (isRead is bool) return !isRead;
        if (isRead is String)
          return isRead == '0' || isRead.toLowerCase() == 'false';
        return false;
      });

      setState(() {
        _notifications = notifications;
        _hasUnreadNotifications = hasUnread;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur de chargement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isNotificationRead(dynamic notification) {
    final isRead = notification['is_read'];
    if (isRead is num) return isRead == 1;
    if (isRead is bool) return isRead;
    if (isRead is String)
      return isRead == '1' || isRead.toLowerCase() == 'true';
    return true;
  }

  void _markAsRead(int notificationId) async {
    final result = await NotificationService.markAsRead(notificationId);
    if (result['success'] == true) {
      _loadNotifications();
    }
  }

  Widget _buildNotificationHeader() {
    const dark = Color(0xFF022519);
    final unreadCount =
        _notifications.where((n) => !_isNotificationRead(n)).length;
    final totalCount = _notifications.length;

    return Container(
      height: 180, // Hauteur fixe pour éviter les débordements
      width: double.infinity,
      color: dark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // IMPORTANT: Évite l'expansion excessive
        children: [
          // Première ligne : bouton retour et logo
          SizedBox(
            height: 40, // Hauteur fixe pour la première ligne
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/logo-glitty.png',
                  width: 149,
                  height: 69,
                  fit: BoxFit.contain,
                ),
                // Espaceur pour équilibrer la disposition
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Titre et statistiques - SOLUTION ROBUSTE AVEC ESPACE CONTRÔLÉ
          Expanded(
            // Utilise l'espace restant de manière contrôlée
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Mes Notifications",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "DM Sans",
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Container pour les statistiques avec hauteur fixe
                SizedBox(
                  height: 40, // Hauteur fixe pour éviter le débordement
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Première partie des statistiques
                      _buildStatItem(
                        '$totalCount',
                        'notification${totalCount > 1 ? 's' : ''}',
                      ),

                      // Séparateur
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Deuxième partie des statistiques
                      _buildStatItem(
                        '$unreadCount',
                        'non lue${unreadCount > 1 ? 's' : ''}',
                      ),

                      // Badge notifications non lues
                      if (_hasUnreadNotifications) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget réutilisable pour les items de statistique
  Widget _buildStatItem(String count, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.0,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(dynamic notification, int index) {
    const accentColor = Color(0xFF4CAF50);
    final isRead = _isNotificationRead(notification);
    final isCommande = notification['type'] == 'new_commande';

    return GestureDetector(
      onTap: () {
        if (isCommande) {
          _viewCommandeDetails(notification);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: isRead ? Colors.white : const Color(0xFFF0F9F0),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isRead ? Colors.grey[200]! : accentColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête de la notification
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isCommande
                                  ? accentColor.withOpacity(0.1)
                                  : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isCommande
                                  ? Icons.cleaning_services_rounded
                                  : Icons.notifications_rounded,
                              color: isCommande ? accentColor : Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  notification['title'] ??
                                      'Nouvelle notification',
                                  style: TextStyle(
                                    fontWeight: isRead
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification['message'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Détails de la commande
                      if (isCommande) _buildCommandeDetails(notification),

                      // Actions
                      if (isCommande) _buildActionButtons(notification),

                      // Date et heure
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey[400],
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTime(notification['created_at']),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (!isRead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nouveau',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Indicateur de lecture
                if (!isRead)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommandeDetails(dynamic notification) {
    final metadata = notification['metadata'];
    final hasMetadata = metadata != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Ligne 1: Type de lavage et prix
          Row(
            children: [
              Icon(
                Icons.local_car_wash_rounded,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasMetadata
                      ? '${_formatTypeLavage(metadata['type_lavage'])}'
                      : '${_formatTypeLavage(notification['type_lavage'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${hasMetadata ? metadata['prix'] : notification['prix']}€',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ligne 2: Date et créneau
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${hasMetadata ? _formatDisplayDate(metadata['date']) : _formatDisplayDate(notification['date'])} • ${_formatCreneau(hasMetadata ? metadata['creneau'] : notification['creneau'])}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ligne 3: Adresse
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_rounded,
                color: Colors.grey[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasMetadata
                      ? '${metadata['client_address']}'
                      : '${notification['depart_adresse']}',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(dynamic notification) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => _acceptCommande(
                notification['id'],
                notification['commande_id'],
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Accepter',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _rejectCommande(notification['id']),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Refuser',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _viewCommandeDetails(dynamic notification) async {
    final notificationId = notification['id'];
    final commandeId = notification['commande_id'];

    print('=== NAVIGATION VERS DÉTAILS ===');
    print('Notification ID: $notificationId');
    print('Commande ID: $commandeId');
    print('Washer ID: ${widget.washerId}');

    // Marquer comme lu
    await NotificationService.markAsRead(notificationId);

    // Naviguer vers la page de détails
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WasherCommandeDetailPage(
            commandeId: commandeId,
            notificationId: notificationId,
            washerId: widget.washerId,
          ),
        ),
      ).then((_) {
        // Recharger les notifications quand on revient de la page détails
        _loadNotifications();
      });
    }
  }

  void _rejectCommande(int notificationId) async {
    final result = await NotificationService.rejectCommande(notificationId);

    if (result['success'] == true) {
      // Supprimer la notification localement sans recharger toute la liste
      setState(() {
        _notifications.removeWhere((notif) => notif['id'] == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Commande refusée'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors du refus'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _acceptCommande(int notificationId, int commandeId) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
              SizedBox(width: 20),
              Text("Acceptation de la commande..."),
            ],
          ),
        );
      },
    );

    final result = await NotificationService.acceptCommande(
      notificationId: notificationId,
      commandeId: commandeId,
      washerId: widget.washerId,
    );

    // Fermer le dialogue de chargement
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      // Supprimer la notification localement sans recharger toute la liste
      setState(() {
        _notifications.removeWhere((notif) => notif['id'] == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Commande acceptée avec succès!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Optionnel : Naviguer vers la page de détails de la commande
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WasherCommandeDetailPage(
              commandeId: commandeId,
              notificationId: notificationId,
              washerId: widget.washerId,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de l\'acceptation'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header personnalisé
            _buildNotificationHeader(),

            // Contenu principal
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                        ),
                      )
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.notifications_off_rounded,
                                  size: 100,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune notification',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Text(
                                    'Vous serez notifié dès qu\'une nouvelle commande sera disponible',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 30),
                                ElevatedButton(
                                  onPressed: _loadNotifications,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF022519),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Actualiser',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadNotifications,
                            color: const Color(0xFF4CAF50),
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 30, 20, 20),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                return _buildNotificationCard(
                                    _notifications[index], index);
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) return 'À l\'instant';
      if (difference.inMinutes < 60)
        return 'Il y a ${difference.inMinutes} min';
      if (difference.inHours < 24) return 'Il y a ${difference.inHours} h';
      if (difference.inDays < 7) return 'Il y a ${difference.inDays} j';
      return 'Le ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatDisplayDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatCreneau(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin';
      case 'apres_midi':
        return 'Après-midi';
      case 'soir':
        return 'Soir';
      default:
        return creneau;
    }
  }

  String _formatTypeLavage(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return 'Lavage Intérieur';
      case 'lavage_exterieur':
        return 'Lavage Extérieur';
      case 'lavage_complet':
        return 'Lavage Complet';
      default:
        return typeLavage;
    }
  }
}
