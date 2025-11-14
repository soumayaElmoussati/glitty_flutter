// lib/CLient/ClientNotificationsPage.dart
import 'package:flutter/material.dart';
import 'package:glitty/CLient/ConfirmationPage.dart';
import 'package:glitty/services/client_notification_service.dart';

class ClientNotificationsPage extends StatefulWidget {
  final int clientId;
  final Map<String, dynamic>? clientData;

  const ClientNotificationsPage({
    Key? key,
    required this.clientId,
    this.clientData,
  }) : super(key: key);

  @override
  _ClientNotificationsPageState createState() =>
      _ClientNotificationsPageState();
}

class _ClientNotificationsPageState extends State<ClientNotificationsPage> {
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
        await ClientNotificationService.getClientNotifications(widget.clientId);

    if (result['success'] == true) {
      final data = result['data'];
      final notifications = data['notifications'] ?? [];

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
    final result = await ClientNotificationService.markAsRead(notificationId);
    if (result['success'] == true) {
      _loadNotifications();
    }
  }

  // MODIFICATION: Navigation vers ConfirmationPage
  void _onNotificationTap(dynamic notification) {
    // Marquer comme lu si ce n'est pas déjà fait
    if (!_isNotificationRead(notification)) {
      _markAsRead(notification['id']);
    }

    // Naviguer vers la page de confirmation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmationPage(
          notificationData: notification,
          clientData: widget.clientData,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

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
                                    'Vous serez notifié dès qu\'il y aura du nouveau',
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

  Widget _buildNotificationHeader() {
    const dark = Color(0xFF022519);

    return Container(
      height: 180,
      width: double.infinity,
      color: dark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Première ligne : menu, logo, espace pour équilibrer
          Row(
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
              ),
              // Espaceur pour équilibrer la disposition
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          // Titre et statistiques
          Row(
            children: [
              Expanded(
                child: Column(
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
                    const SizedBox(height: 8),
                    Text(
                      "${_notifications.length} notification${_notifications.length > 1 ? 's' : ''} • ${_notifications.where((n) => !_isNotificationRead(n)).length} non lue${_notifications.where((n) => !_isNotificationRead(n)).length > 1 ? 's' : ''}",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Badge notifications non lues
              if (_hasUnreadNotifications)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_notifications.where((n) => !_isNotificationRead(n)).length}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notification, int index) {
    const accentColor = Color(0xFF4CAF50);
    final isRead = _isNotificationRead(notification);
    final isCommande = notification['type'] == 'commande_acceptee';

    return GestureDetector(
      // MODIFICATION: Ajout du onTap ici
      onTap: () => _onNotificationTap(notification),
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

          // Ligne 3: Washer
          if (hasMetadata && metadata['washer_name'] != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.person_rounded,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Washer: ${metadata['washer_name']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
        ],
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
