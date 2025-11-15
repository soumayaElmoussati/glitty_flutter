import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';

class DetailCommandePage extends StatefulWidget {
  final int commandeId;
  final Map<String, dynamic>? clientData;
  final String? token;

  const DetailCommandePage({
    Key? key,
    required this.commandeId,
    this.clientData,
    this.token,
  }) : super(key: key);

  @override
  State<DetailCommandePage> createState() => _DetailCommandePageState();
}

class _DetailCommandePageState extends State<DetailCommandePage> {
  Map<String, dynamic>? commandeDetails;
  bool isLoading = true;
  String? error;
  bool isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadCommandeDetails();
  }

  Future<void> _loadCommandeDetails() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await http.get(
        Uri.parse(
            '${Env.baseUrl}/api/commande/details-commande/${widget.commandeId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            commandeDetails = data['data'];
          });
        } else {
          throw Exception(
              data['message'] ?? 'Erreur lors du chargement des détails');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = 'Erreur de chargement: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Méthode pour terminer la commande avec évaluation
  Future<void> _terminerCommandeAvecEvaluation(
      int note, String? commentaire) async {
    try {
      setState(() {
        isUpdatingStatus = true;
      });

      final response = await http.put(
        Uri.parse(
            '${Env.baseUrl}/api/commande/terminate-commande/${widget.commandeId}'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'statut': 'terminee',
          'evaluation': {
            'note': note,
            'commentaire': commentaire,
            'washer_id': commandeDetails!['laveur']?['id'],
            'date_evaluation': DateTime.now().toIso8601String(),
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Recharger les détails pour avoir les données à jour
          await _loadCommandeDetails();

          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Commande terminée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );

          // Retourner true pour indiquer qu'un rafraîchissement est nécessaire
          Navigator.pop(context, true);
        } else {
          throw Exception(data['message'] ?? 'Erreur lors de la mise à jour');
        }
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isUpdatingStatus = false;
      });
    }
  }

  // Méthodes de formatage
  String _formatTypeLavage(String type) {
    switch (type) {
      case 'lavage_exterieur':
        return 'Lavage Extérieur';
      case 'lavage_interieur':
        return 'Lavage Intérieur';
      case 'lavage_complet':
        return 'Lavage Complet';
      case 'lavage_premium':
        return 'Lavage Premium';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  String _formatStatut(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'en_cours':
        return 'En cours';
      case 'terminee':
        return 'Terminée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return Colors.blue;
      case 'en_cours':
        return Colors.lightBlue;
      case 'terminee':
        return Colors.green;
      case 'annulee':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'en_attente':
        return Icons.access_time;
      case 'confirmee':
        return Icons.check_circle_outline;
      case 'en_cours':
        return Icons.play_circle_outline;
      case 'terminee':
        return Icons.verified;
      case 'annulee':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatMethodPaiement(String? method) {
    switch (method) {
      case 'espece':
        return 'Espèces';
      case 'carte':
        return 'Carte bancaire';
      case 'virement':
        return 'Virement';
      case 'mobile_money':
        return 'Mobile Money';
      case 'solde_glitty':
        return 'Solde Glitty';
      case 'mixte':
        return 'Paiement mixte';
      case 'mixte_espece':
        return 'Mixte avec espèces';
      default:
        return method ?? 'Non spécifié';
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final commandeDate = DateTime(date.year, date.month, date.day);

      if (commandeDate == today) {
        return "Aujourd'hui";
      } else if (commandeDate == today.subtract(const Duration(days: 1))) {
        return 'Hier';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFF022519),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Première ligne : icônes menu, logo, notification
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Bouton retour - Retourne false car pas de modification
              GestureDetector(
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF022519),
                    size: 24,
                  ),
                ),
              ),
              Image.asset(
                'assets/logo-glitty.png',
                width: 149,
                height: 69,
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Détails de la commande",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: "DM Sans",
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF022519), Color(0xFF4CAF50)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commandeDetails!['reference'] ?? 'N/A',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créée le ${_formatDate(commandeDetails!['created_at'])}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatutCard() {
    final statut = commandeDetails!['statut'];
    final color = _getStatutColor(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            _getStatutIcon(statut),
            color: color,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatut(statut),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getStatutDescription(statut),
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getStatutDescription(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'Votre commande est en attente de confirmation';
      case 'confirmee':
        return 'Votre commande a été confirmée';
      case 'en_cours':
        return 'Votre véhicule est en cours de lavage';
      case 'terminee':
        return 'Votre commande a été terminée avec succès';
      case 'annulee':
        return 'Votre commande a été annulée';
      default:
        return 'Statut inconnu';
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF022519),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: const Color(0xFF022519),
              size: 20,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF022519),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaveurInfo() {
    if (commandeDetails!['laveur'] == null) {
      return _buildInfoSection(
        'Prestataire',
        [
          _buildInfoRow(
            'Assignation',
            'En attente d\'assignation',
            icon: Icons.person_outline,
          ),
        ],
      );
    }

    final laveur = commandeDetails!['laveur'];
    return _buildInfoSection(
      'Votre Laveur',
      [
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF022519).withOpacity(0.1),
                image: laveur['photo'] != null
                    ? DecorationImage(
                        image: NetworkImage(laveur['photo']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: laveur['photo'] == null
                  ? const Icon(
                      Icons.person,
                      color: Color(0xFF022519),
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    laveur['nom_complet'] ?? 'Laveur',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF022519),
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (laveur['telephone'] != null)
                    Text(
                      laveur['telephone']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
            if (laveur['telephone'] != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF4CAF50)),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.phone,
                    color: Color(0xFF4CAF50),
                    size: 20,
                  ),
                  onPressed: () {
                    // Action d'appel
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    final statut = commandeDetails!['statut'];

    // Afficher uniquement le bouton "Terminer" pour les statuts "confirmee" ou "en_cours"
    if (statut != 'confirmee' && statut != 'en_cours') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isUpdatingStatus
            ? null
            : () {
                _showEvaluationDialog();
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          minimumSize: const Size(double.infinity, 50),
        ),
        child: isUpdatingStatus
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Terminer la commande',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showEvaluationDialog() {
    int note = 5;
    TextEditingController commentaireController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              "Évaluer le service",
              style: TextStyle(
                color: Color(0xFF022519),
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Comment évaluez-vous le service de notre laveur ?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Évaluation par étoiles
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              note = index + 1;
                            });
                          },
                          child: Icon(
                            index < note ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 40,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      _getNoteDescription(note),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Commentaire
                  const Text(
                    "Commentaire (optionnel):",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF022519),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentaireController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Partagez votre expérience...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF022519)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Annuler",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _terminerCommandeAvecEvaluation(
                      note,
                      commentaireController.text.isEmpty
                          ? null
                          : commentaireController.text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
                child: const Text("Terminer et évaluer"),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getNoteDescription(int note) {
    switch (note) {
      case 1:
        return 'Médiocre';
      case 2:
        return 'Passable';
      case 3:
        return 'Bien';
      case 4:
        return 'Très bien';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(dark),
                      ),
                    )
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 64,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadCommandeDetails,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: dark,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : commandeDetails == null
                          ? const Center(
                              child: Text(
                                'Aucune donnée disponible',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : Stack(
                              children: [
                                SingleChildScrollView(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      _buildReferenceCard(),
                                      _buildStatutCard(),

                                      // Informations de lavage
                                      _buildInfoSection(
                                        'Détails du lavage',
                                        [
                                          _buildInfoRow(
                                            'Type de lavage',
                                            _formatTypeLavage(commandeDetails![
                                                'type_lavage']),
                                            icon: Icons.local_car_wash,
                                          ),
                                          _buildInfoRow(
                                            'Prix',
                                            '${commandeDetails!['prix']}€',
                                            icon: Icons.euro,
                                          ),
                                          _buildInfoRow(
                                            'Date',
                                            _formatDate(
                                                commandeDetails!['date']),
                                            icon: Icons.calendar_today,
                                          ),
                                          _buildInfoRow(
                                            'Créneau',
                                            commandeDetails![
                                                    'creneau_complet'] ??
                                                'Non défini',
                                            icon: Icons.access_time,
                                          ),
                                          if (commandeDetails![
                                                  'method_paiement'] !=
                                              null)
                                            _buildInfoRow(
                                              'Méthode de paiement',
                                              _formatMethodPaiement(
                                                  commandeDetails![
                                                      'method_paiement']),
                                              icon: Icons.payment,
                                            ),
                                        ],
                                      ),

                                      // Informations véhicule
                                      _buildInfoSection(
                                        'Véhicule',
                                        [
                                          _buildInfoRow(
                                            'Type',
                                            commandeDetails!['vehicule']
                                                    ['type'] ??
                                                'Non spécifié',
                                            icon: Icons.directions_car,
                                          ),
                                          _buildInfoRow(
                                            'Immatriculation',
                                            commandeDetails!['vehicule']
                                                    ['immatriculation'] ??
                                                'Non spécifié',
                                            icon: Icons.confirmation_number,
                                          ),
                                          if (commandeDetails!['vehicule']
                                                  ['description'] !=
                                              null)
                                            _buildInfoRow(
                                              'Description',
                                              commandeDetails!['vehicule']
                                                  ['description']!,
                                              icon: Icons.description,
                                            ),
                                        ],
                                      ),

                                      // Adresse
                                      _buildInfoSection(
                                        'Adresse de prise en charge',
                                        [
                                          _buildInfoRow(
                                            'Lieu',
                                            commandeDetails!['adresses']
                                                    ['depart']['adresse'] ??
                                                'Non spécifié',
                                            icon: Icons.location_on,
                                          ),
                                        ],
                                      ),

                                      // Informations laveur
                                      _buildLaveurInfo(),

                                      // Notes
                                      if (commandeDetails!['notes'] != null)
                                        _buildInfoSection(
                                          'Notes supplémentaires',
                                          [
                                            Text(
                                              commandeDetails!['notes']!,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFF022519),
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: _buildBottomActions(),
                                ),
                              ],
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
