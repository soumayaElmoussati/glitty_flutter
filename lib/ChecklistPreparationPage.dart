import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';
import 'package:intl/intl.dart';

class ChecklistPreparationPage extends StatefulWidget {
  final String nom;
  final int washerId;
  final Map<String, dynamic> commande;

  const ChecklistPreparationPage({
    Key? key,
    required this.nom,
    required this.washerId,
    required this.commande,
  }) : super(key: key);

  @override
  _ChecklistPreparationPageState createState() =>
      _ChecklistPreparationPageState();
}

class _ChecklistPreparationPageState extends State<ChecklistPreparationPage> {
  List<Map<String, dynamic>> _allEquipments = [];
  List<Map<String, dynamic>> _commandeChecklist = [];
  bool _allChecked = false;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // Stocker les modifications locales
  Map<int, bool> _localChanges = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _loadAllEquipments();
      await _loadCommandeChecklist();
      _mergeChecklistData();

      setState(() {
        _isLoading = false;
      });

      _updateCompletionStatus();
    } catch (e) {
      print('Erreur chargement des données: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadAllEquipments() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/commande/equipments/all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _allEquipments = List<Map<String, dynamic>>.from(data['data'])
              .map((equipment) => {
                    ...equipment,
                    'is_checked': false,
                    'checked_at': null,
                    'commande_equipment_id': null,
                  })
              .toList();

          print('✅ Équipements chargés: ${_allEquipments.length}');
        } else {
          throw Exception('Données invalides reçues de l\'API équipements');
        }
      } else {
        throw Exception('Erreur HTTP équipements: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur chargement équipements: $e');
      rethrow;
    }
  }

  Future<void> _loadCommandeChecklist() async {
    try {
      final commandeId = widget.commande['id'];
      if (commandeId == null) {
        print('⚠️ ID de commande non trouvé');
        return;
      }

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId/checklist'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          _commandeChecklist = List<Map<String, dynamic>>.from(data['data']);
          print(
              '✅ Checklist commande chargée: ${_commandeChecklist.length} équipements');
        } else {
          print('ℹ️ Aucune checklist existante pour cette commande');
        }
      } else if (response.statusCode == 404) {
        print('ℹ️ Checklist non trouvée pour cette commande');
      } else {
        print('⚠️ Erreur HTTP checklist: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur chargement checklist commande: $e');
    }
  }

  void _mergeChecklistData() {
    final checklistMap = {
      for (var item in _commandeChecklist)
        item['equipment_id']: {
          'is_checked': item['is_checked'] == true || item['is_checked'] == 1,
          'checked_at': item['checked_at'],
          'commande_equipment_id': item['id'],
        }
    };

    _allEquipments = _allEquipments.map((equipment) {
      final checklistItem = checklistMap[equipment['id']];
      return {
        ...equipment,
        'is_checked': checklistItem?['is_checked'] ?? false,
        'checked_at': checklistItem?['checked_at'],
        'commande_equipment_id': checklistItem?['commande_equipment_id'],
      };
    }).toList();

    print('🔄 Données fusionnées: ${_allEquipments.length} équipements');
  }

  // Mise à jour locale seulement
  void _updateChecklistItem(int equipmentId, bool isChecked) {
    setState(() {
      final index =
          _allEquipments.indexWhere((item) => item['id'] == equipmentId);
      if (index != -1) {
        _allEquipments[index]['is_checked'] = isChecked;
        _allEquipments[index]['checked_at'] =
            isChecked ? DateTime.now().toIso8601String() : null;

        _localChanges[equipmentId] = isChecked;
      }
      _updateCompletionStatus();
    });
  }

  // MODIFIÉ: Le bouton est activé si au moins 1 équipement est sélectionné
  void _updateCompletionStatus() {
    final hasAtLeastOneChecked =
        _allEquipments.any((item) => item['is_checked'] == true);
    setState(() => _allChecked = hasAtLeastOneChecked);
  }

  // NOUVELLE MÉTHODE: Sauvegarder tous les changements en une seule requête
  Future<void> _submitAllChanges() async {
    if (_isSubmitting || _localChanges.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final commandeId = widget.commande['id'];

      // Préparer la liste des équipements à mettre à jour
      final checklistToUpdate = _localChanges.entries.map((entry) {
        return {
          'equipment_id': entry.key,
          'is_checked': entry.value,
        };
      }).toList();

      print(
          '📤 Envoi de ${checklistToUpdate.length} équipements à mettre à jour');

      // Appel API unique avec la liste complète
      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/commande/$commandeId/checklist'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'checklist': checklistToUpdate,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // Vider les changements locaux après succès
          _localChanges.clear();

          // Afficher message de succès avec notification de confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${checklistToUpdate.length} équipement(s) ajouté(s) avec succès à la checklist',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // MODIFIÉ: Retour à la page précédente au lieu de WasherSetGPSPage
          Future.delayed(Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        } else {
          throw Exception(data['message'] ?? 'Erreur inconnue');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde checklist: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _toggleAllItems(bool value) {
    setState(() {
      final requiredItems =
          _allEquipments.where((item) => item['is_required'] == 1).toList();

      for (var item in requiredItems) {
        final index = _allEquipments.indexWhere((e) => e['id'] == item['id']);
        if (index != -1) {
          _allEquipments[index]['is_checked'] = value;
          _allEquipments[index]['checked_at'] =
              value ? DateTime.now().toIso8601String() : null;

          _localChanges[item['id']] = value;
        }
      }
      _updateCompletionStatus();
    });
  }

  // Getters pour les données de la commande
  String _getReference() => widget.commande['reference'] ?? '';
  String _getClientFullName() =>
      '${widget.commande['client_first_name'] ?? ''} ${widget.commande['client_last_name'] ?? ''}';
  String _getVehicleInfo() =>
      '${widget.commande['vehicle_type'] ?? ''} • ${widget.commande['vehicle_immatriculation'] ?? ''}';
  String _getTypeLavage() => widget.commande['type_lavage'] ?? '';
  double _getPrix() => (widget.commande['prix'] as num?)?.toDouble() ?? 0.0;
  String _getDate() => widget.commande['date'] ?? '';
  String _getCreneau() => widget.commande['creneau'] ?? '';

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(parsed);
    } catch (e) {
      return date;
    }
  }

  String _getCreneauDisplay(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin (8h-12h)';
      case 'apres_midi':
        return 'Après-midi (12h-18h)';
      case 'soir':
        return 'Soir (18h-22h)';
      default:
        return creneau;
    }
  }

  String _getCategoryDisplay(String category) {
    switch (category) {
      case 'base':
        return 'Équipements de Base';
      case 'exterieur':
        return 'Équipements Extérieur';
      case 'interieur':
        return 'Équipements Intérieur';
      case 'complet':
        return 'Équipements Complets';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'base':
        return const Color(0xFF2196F3);
      case 'exterieur':
        return const Color(0xFFFF9800);
      case 'interieur':
        return const Color(0xFF9C27B0);
      case 'complet':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF022519);
    }
  }

  // Header avec icône menu au lieu de bouton retour
  Widget _buildHeader() {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFF022519),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône menu pour ouvrir le drawer
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: Image.asset(
                    'assets/menu-icone.png',
                    width: 24,
                    height: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              // Logo
              Image.asset(
                'assets/logo-glitty.png',
                width: 100,
                height: 46,
              ),
              // Indicateur de modifications en attente
              if (_localChanges.isNotEmpty)
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${_localChanges.length}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Préparation de Mission',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'DM Sans',
            ),
          ),
        ],
      ),
    );
  }

  // Drawer identique à celui du dashboard
  Widget _buildModernDrawer(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [dark, dark.withOpacity(0.8)],
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 35,
                      backgroundColor: accentColor,
                      child: Text(
                        widget.nom.isNotEmpty
                            ? widget.nom[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "● Washer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildDrawerItem(
                      Icons.dashboard_rounded,
                      "Dashboard",
                      false,
                      dark,
                      () => Navigator.pushNamedAndRemoveUntil(
                          context, '/dashboard', (route) => false),
                    ),
                    _buildDrawerItem(
                      Icons.notifications_rounded,
                      "Notifications",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildDrawerItem(
                      Icons.calendar_month_rounded,
                      "Planning",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.checklist_rounded,
                      "Préparation",
                      true, // Actif car on est sur cette page
                      dark,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WasherSetPasswordPage())),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WasherSetGPSPage(
                                    washerId: widget.washerId,
                                  ))),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: _buildDrawerItem(
                        Icons.logout_rounded,
                        "Déconnexion",
                        false,
                        Colors.red,
                        () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginWasherPage())),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire les items du drawer
  Widget _buildDrawerItem(IconData icon, String title, bool isActive,
      Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? color : Colors.grey[600],
          size: 24,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isActive ? color : Colors.grey[700],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCommandeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF022519),
            Color(0xFF1A3A5F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Commande #${_getReference()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_getPrix().toStringAsFixed(2)}€',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person_outline, _getClientFullName()),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.directions_car_outlined, _getVehicleInfo()),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.cleaning_services_outlined, _getTypeLavage()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today,
                    size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${_formatDate(_getDate())} • ${_getCreneauDisplay(_getCreneau())}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: Colors.white70),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistHeader() {
    final checkedCount =
        _allEquipments.where((item) => item['is_checked'] == true).length;
    final totalCount = _allEquipments.length;
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Checklist d\'Équipement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF022519),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF022519).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$checkedCount/$totalCount',
                style: const TextStyle(
                  color: Color(0xFF022519),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez les équipements que vous allez utiliser pour ${_getTypeLavage().toLowerCase()}',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Barre de progression
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(3),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 6,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bouton Tout cocher/décocher
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _toggleAllItems(!_allChecked),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF022519),
                  side: const BorderSide(color: Color(0xFF022519)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _allChecked ? 'Tout décocher' : 'Tout cocher',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildChecklistItem(Map<String, dynamic> item, int index) {
    final isChecked = item['is_checked'] == true;
    final category = item['category'] ?? 'base';
    final isRequired = item['is_required'] == 1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isChecked ? const Color(0xFFE8F5E8) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isChecked ? const Color(0xFF4CAF50) : Colors.grey[300]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            _updateChecklistItem(item['id'], !isChecked);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isChecked
                        ? const Color(0xFF4CAF50)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isChecked
                          ? const Color(0xFF4CAF50)
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête avec catégorie
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.category,
                              size: 12,
                              color: _getCategoryColor(category),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getCategoryDisplay(category),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getCategoryColor(category),
                              ),
                            ),
                            if (isRequired) ...[
                              const SizedBox(width: 4),
                              Text(
                                '• Requis',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getCategoryColor(category),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Nom de l'équipement
                      Text(
                        item['name'] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isChecked
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF022519),
                          decoration:
                              isChecked ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      // Description
                      if (item['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          item['description'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      // Statut
                      if (isChecked) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Sélectionné ✓',
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF4CAF50).withOpacity(0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  isChecked ? Icons.verified_rounded : Icons.pending_rounded,
                  color: isChecked ? const Color(0xFF4CAF50) : Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MODIFIÉ: Bouton activé si au moins 1 équipement est sélectionné
  Widget _buildActionButton() {
    final hasChanges = _localChanges.isNotEmpty;
    final hasAtLeastOneChecked =
        _allChecked; // Maintenant _allChecked signifie "au moins un équipement sélectionné"

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: hasAtLeastOneChecked
            ? const LinearGradient(
                colors: [Color(0xFF022519), Color(0xFF1A3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasAtLeastOneChecked ? null : Colors.grey[400],
        borderRadius: BorderRadius.circular(15),
        boxShadow: hasAtLeastOneChecked
            ? [
                BoxShadow(
                  color: const Color(0xFF022519).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap:
              hasAtLeastOneChecked && !_isSubmitting ? _submitAllChanges : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _isLoading ? 0 : 1,
                child: Text(
                  _isSubmitting
                      ? 'Sauvegarde...'
                      : hasAtLeastOneChecked
                          ? hasChanges
                              ? 'Confirmer ${_localChanges.length} équipement(s)'
                              : 'Confirmer équipements'
                          : 'Sélectionnez au moins 1 équipement',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isSubmitting)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xFF022519),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement des équipements...',
            style: TextStyle(
              color: Color(0xFF022519),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Erreur de chargement',
            style: TextStyle(
              color: Color(0xFF022519),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Impossible de charger la liste des équipements',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF022519),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Réessayer',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun équipement disponible',
            style: TextStyle(
              color: Color(0xFF022519),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucun équipement n\'est configuré dans le système',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF022519),
      drawer: _buildModernDrawer(context),
      body: Column(
        children: [
          _buildHeader(),
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCommandeHeader(),
                    const SizedBox(height: 24),
                    Expanded(
                      child: _isLoading
                          ? _buildLoadingState()
                          : _allEquipments.isEmpty
                              ? _buildEmptyState()
                              : SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildChecklistHeader(),
                                      ..._allEquipments
                                          .where((item) =>
                                              item['is_required'] == 1)
                                          .toList()
                                          .asMap()
                                          .entries
                                          .map((entry) => _buildChecklistItem(
                                              entry.value, entry.key))
                                          .toList(),
                                      if (_allEquipments.any((item) =>
                                          item['is_required'] == 0)) ...[
                                        const SizedBox(height: 24),
                                        const Text(
                                          'Équipements Optionnels',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF022519),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ..._allEquipments
                                            .where((item) =>
                                                item['is_required'] == 0)
                                            .toList()
                                            .asMap()
                                            .entries
                                            .map((entry) => _buildChecklistItem(
                                                entry.value, entry.key))
                                            .toList(),
                                      ],
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                    ),
                    if (!_isLoading && _allEquipments.isNotEmpty)
                      _buildActionButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
