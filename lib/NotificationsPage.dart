import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class NotificationsPage extends StatefulWidget {
  final int washerId;
  const NotificationsPage({Key? key, required this.washerId}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final url = '$baseUrl/api/notifications/${widget.washerId}';
      print('🔍 Récupération notifications depuis: $url'); // DEBUG
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Status code: ${response.statusCode}'); // DEBUG
      print('📡 Response body: ${response.body}'); // DEBUG

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _notifications = data['notifications'] ?? [];
          _isLoading = false;
        });
        print('✅ ${_notifications.length} notifications chargées'); // DEBUG
      } else {
        _showError("Erreur ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print('❌ Erreur: $e'); // DEBUG
      _showError("Erreur réseau: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await http.patch(
        Uri.parse('$baseUrl/api/notifications/$notificationId/read'),
      );
      await _fetchNotifications(); // Rafraîchir
    } catch (e) {
      _showError("Erreur lors de la mise à jour");
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkColor = Color(0xFF022519);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchNotifications,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune notification',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous serez notifié ici des mises à jour importantes',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['is_read'] == true;
    final type = notification['type'] ?? 'info';
    final createdAt = notification['created_at']?.toString().substring(0, 19) ?? '';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isRead ? null : () => _markAsRead(notification['id']),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isRead ? Colors.white : Colors.blue[50],
            border: Border.all(
              color: isRead ? Colors.grey[200]! : Colors.blue[200]!,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification['title'] ?? 'Notification',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      notification['message'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(String type) {
    switch (type) {
      case 'validation_approved':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: Colors.green[700],
            size: 24,
          ),
        );
      case 'validation_rejected':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cancel,
            color: Colors.red[700],
            size: 24,
          ),
        );
      case 'new_mission':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cleaning_services,
            color: Colors.blue[700],
            size: 24,
          ),
        );
      case 'payment':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.payment,
            color: Colors.orange[700],
            size: 24,
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.info,
            color: Colors.grey[700],
            size: 24,
          ),
        );
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) {
        return 'Il y a ${diff.inDays} jour${diff.inDays > 1 ? 's' : ''}';
      } else if (diff.inHours > 0) {
        return 'Il y a ${diff.inHours} heure${diff.inHours > 1 ? 's' : ''}';
      } else if (diff.inMinutes > 0) {
        return 'Il y a ${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''}';
      } else {
        return 'À l\'instant';
      }
    } catch (e) {
      return dateStr;
    }
  }
} 