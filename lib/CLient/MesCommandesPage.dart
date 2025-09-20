import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

import 'Paiement.dart';

class MesCommandesPage extends StatefulWidget {
  final int clientId;
  const MesCommandesPage({super.key, required this.clientId});

  @override
  State<MesCommandesPage> createState() => _MesCommandesPageState();
}

class _MesCommandesPageState extends State<MesCommandesPage> with TickerProviderStateMixin {
  List<dynamic> _reservations = [];
  List<dynamic> _washers = [];
  bool _isLoading = true;
  bool _isAnimating = false;
  final Distance _distance = const Distance();
  Timer? _refreshTimer;
  DateTime? _lastRefresh;

  // URL dynamique selon la plateforme
  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  static const Color _darkColor = Color(0xFF022519);
  static const Color _cardColor = Color(0xFFF4F6F9);
  static const Color _backgroundColor = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchDataSilently();
      }
    });
  }

  Future<void> _fetchDataSilently() async {
    // Fetch data without showing loading indicator
    try {
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/reservations/client/${widget.clientId}')),
        http.get(Uri.parse('$baseUrl/api/admin/washers')),
      ]);

      if (responses.every((r) => r.statusCode == 200)) {
        final reservationsData = jsonDecode(responses[0].body);
        final washersData = jsonDecode(responses[1].body);
        
        final newReservations = reservationsData['data'] ?? [];
        final newWashers = washersData['washers'] ?? [];
        
        // Check if data actually changed
        final oldReservationsCount = _reservations.length;
        
        if (newReservations.length != oldReservationsCount || 
            newWashers.length != _washers.length) {
          setState(() {
            _reservations = newReservations;
            _washers = newWashers;
            _lastRefresh = DateTime.now();
          });
          
          // Show notification if new reservations arrived
          if (newReservations.length > oldReservationsCount) {
            _showSuccess("🔔 Nouvelle commande reçue !");
          }
        } else {
          // Update last refresh time even if no data changed
          setState(() {
            _lastRefresh = DateTime.now();
          });
        }
      }
    } catch (e) {
      // Silent fail for background refresh
      print('Background refresh failed: $e');
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      print('📱 Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('🌐 Base URL: $baseUrl');
      print('👤 Client ID: ${widget.clientId}');
      
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/api/reservations/client/${widget.clientId}')),
        http.get(Uri.parse('$baseUrl/api/admin/washers')),
      ]);

      print('📊 Reservations response: ${responses[0].statusCode}');
      print('🔧 Washers response: ${responses[1].statusCode}');

      if (responses.every((r) => r.statusCode == 200)) {
        final reservationsData = jsonDecode(responses[0].body);
        final washersData = jsonDecode(responses[1].body);
        
        print('📋 Reservations data: $reservationsData');
        print('👥 Washers data: $washersData');
        
        setState(() {
          _reservations = reservationsData['data'] ?? [];
          _washers = washersData['washers'] ?? [];
          _isLoading = false;
          _lastRefresh = DateTime.now();
        });
        
        print('✅ Data loaded: ${_reservations.length} reservations, ${_washers.length} washers');
      } else {
        print('❌ API Error - Reservations: ${responses[0].statusCode}, Washers: ${responses[1].statusCode}');
        _showError("Erreur lors du chargement des données");
      }
    } catch (e) {
      print('💥 Fetch error: $e');
      _showError("Erreur réseau: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double? _tryParseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  List<Map<String, dynamic>> _getSortedWashersForReservation(Map<String, dynamic> reservation) {
    final resLat = _tryParseDouble(reservation['latitude']);
    final resLng = _tryParseDouble(reservation['longitude']);

    return _washers.map((washer) {
      final washerLat = _tryParseDouble(washer['latitude']);
      final washerLng = _tryParseDouble(washer['longitude']);
      
      final dist = (resLat == null || resLng == null || washerLat == null || washerLng == null)
          ? double.infinity
          : _distance.as(
              LengthUnit.Kilometer,
              LatLng(resLat, resLng),
              LatLng(washerLat, washerLng),
            );

      return {
        'washer': washer,
        'distance': dist,
        'isCurrentWasher': false, // Pas applicable pour un client
      };
    }).toList()
      ..sort((a, b) => a['distance'].compareTo(b['distance']));
  }

  Future<bool> _updateReservationStatus(int reservationId, String status) async {
    try {
      print('🔄 Updating reservation $reservationId to status: $status');
      final response = await http.patch(
        Uri.parse('$baseUrl/api/reservations/updateStatut/$reservationId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'statut': status}),
      );

      print('📡 Update response: ${response.statusCode}');
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to update status: ${response.body}');
      }
    } catch (e) {
      print('❌ Update error: $e');
      throw Exception('Error updating status: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleAcceptReservation(Map<String, dynamic> reservation) async {
    try {
      // Vérifier si la réservation n'est pas déjà acceptée
      if (reservation['statut'] != 'accepté') {
        await _updateReservationStatus(reservation['id'], 'accepté');
        _showSuccess("Commande acceptée. Redirection vers paiement...");
      } else {
        _showSuccess("Commande déjà acceptée. Redirection vers paiement...");
      }
      
      if (!mounted) return;
      
      // Convertir le prix en double, puis multiplier par 100 et convertir en int
      final prix = double.tryParse(reservation['prix'].toString()) ?? 0.0;
      
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaiementPage(
            reservationId: reservation['id'],
            amount: (prix * 100).toInt(),
          ),
        ),
      );
      
      await _fetchData(); // Refresh data after returning from payment
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
    }
  }

  Future<void> _handleRejectReservation(Map<String, dynamic> reservation) async {
    try {
      setState(() => _isAnimating = true);
      await _updateReservationStatus(reservation['id'], 'refusé');
      _showSuccess("Commande refusée");
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      setState(() {
        _reservations.remove(reservation);
        _isAnimating = false;
      });
    } catch (e) {
      _showError("Erreur: ${e.toString()}");
      setState(() => _isAnimating = false);
    }
  }

  Widget _buildWasherDistanceItem(Map<String, dynamic> washerData) {
    final washer = washerData['washer'];
    final dist = washerData['distance'];
    final isCurrent = washerData['isCurrentWasher'] ?? false;

    return ListTile(
      leading: Icon(
        isCurrent ? Icons.person : Icons.person_outline,
        color: isCurrent ? Colors.teal : Colors.grey,
      ),
      title: Text(
        "${washer['nom']} ${washer['prenom']}",
        style: TextStyle(
          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: Text(
        dist.isFinite ? "${dist.toStringAsFixed(2)} km" : "N/A",
        style: const TextStyle(color: Colors.grey),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation, int index) {
    final sortedWashers = _getSortedWashersForReservation(reservation);

    return AnimatedSize(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: _isAnimating && index == 0
          ? const SizedBox.shrink()
          : Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation['type_lavage'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Prix : ${reservation['prix']} €",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "Date : ${reservation['date_creation'].toString().substring(0, 10)}",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    const Text(
                      "Washers disponibles:",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...sortedWashers.map(_buildWasherDistanceItem),
                    if (index == 0) _buildActionButtons(reservation),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> reservation) {
    // Ne montrer les boutons que pour les réservations "en cours"
    if (reservation['statut'] != 'en cours') {
      // Si la réservation est acceptée ou validée (payée), montrer le bouton de suivi
      if (reservation['statut'] == 'accepté' || reservation['statut'] == 'validé') {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Text(
                  'Statut: ${reservation['statut'] == 'validé' ? 'Payée ✓' : reservation['statut'] + ' ✓'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1E3A8A),
                  minimumSize: const Size(200, 40),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/client-suivi-mission');
                },
                icon: const Icon(Icons.location_on, color: Colors.white),
                label: const Text("Suivre ma mission", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
      
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Statut: ${reservation['statut']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(120, 40),
            ),
            onPressed: () => _showAcceptDialog(reservation),
            child: const Text("Accepter & Payer"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(120, 40),
            ),
            onPressed: () => _showRejectDialog(reservation),
            child: const Text("Refuser"),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcceptDialog(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer l'acceptation"),
        content: const Text("Voulez-vous accepter et procéder au paiement ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleAcceptReservation(reservation);
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> reservation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmer le refus"),
        content: const Text("Voulez-vous vraiment refuser cette commande ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Confirmer"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleRejectReservation(reservation);
    }
  }

  String _getLastRefreshText() {
    if (_lastRefresh == null) return "Jamais synchronisé";
    final now = DateTime.now();
    final diff = now.difference(_lastRefresh!);
    
    if (diff.inSeconds < 60) {
      return "Synchronisé il y a ${diff.inSeconds}s";
    } else if (diff.inMinutes < 60) {
      return "Synchronisé il y a ${diff.inMinutes}m";
    } else {
      return "Synchronisé il y a ${diff.inHours}h";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Commandes", style: TextStyle(color: Colors.white)),
        backgroundColor: _darkColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  "Auto",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          // Indicateur de synchronisation
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.wifi, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      "🔄 Synchronisation automatique toutes les 10s",
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getLastRefreshText(),
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reservations.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            "Aucune commande disponible",
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Les nouvelles commandes apparaîtront automatiquement",
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          itemCount: _reservations.length,
                          itemBuilder: (context, index) {
                            return _buildReservationCard(_reservations[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}