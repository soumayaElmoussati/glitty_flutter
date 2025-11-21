// lib/WasherCommandeDetailPage.dart
import 'package:flutter/material.dart';
import 'package:glitty/services/commande_service.dart';
import 'package:glitty/services/notification_service.dart';

class WasherCommandeDetailPage extends StatefulWidget {
  final int commandeId;
  final int notificationId;
  final int washerId;

  const WasherCommandeDetailPage({
    Key? key,
    required this.commandeId,
    required this.notificationId,
    required this.washerId,
  }) : super(key: key);

  @override
  _WasherCommandeDetailPageState createState() =>
      _WasherCommandeDetailPageState();
}

class _WasherCommandeDetailPageState extends State<WasherCommandeDetailPage> {
  Map<String, dynamic>? _commandeData;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print('=== INIT WASHER COMMANDE DETAIL PAGE ===');
    print('Commande ID: ${widget.commandeId}');
    print('Notification ID: ${widget.notificationId}');
    print('Washer ID: ${widget.washerId}');

    _loadCommandeDetail();
    _markNotificationAsRead();
  }

  Future<void> _loadCommandeDetail() async {
    setState(() {
      _isLoading = true;
    });

    final result = await CommandeService.getCommandeDetail(
      commandeId: widget.commandeId,
      washerId: widget.washerId,
    );

    print('=== RÉSULTAT API ===');
    print('Success: ${result['success']}');
    print('Data: ${result['data']}');

    if (result['success'] == true) {
      setState(() {
        _commandeData = result['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'] ?? 'Erreur de chargement';
        _isLoading = false;
      });
    }
  }

  Future<void> _markNotificationAsRead() async {
    await NotificationService.markAsRead(widget.notificationId);
  }

  Future<void> _acceptCommande() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

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
      notificationId: widget.notificationId,
      commandeId: widget.commandeId,
      washerId: widget.washerId,
    );

    // Fermer le dialogue de chargement
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Commande acceptée avec succès!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Recharger les données de la commande
      await _loadCommandeDetail();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors de l\'acceptation'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Future<void> _rejectCommande() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final result =
        await NotificationService.rejectCommande(widget.notificationId);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Commande refusée'),
          backgroundColor: Colors.orange,
        ),
      );

      // Retourner à la page précédente
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erreur lors du refus'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isProcessing = false;
    });
  }

  Widget _buildHeader() {
    const dark = Color(0xFF022519);

    return Container(
      height: 180,
      width: double.infinity,
      color: dark,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Première ligne : bouton retour et logo
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
              const SizedBox(width: 40), // Espaceur pour équilibrer
            ],
          ),
          const SizedBox(height: 16),
          // Titre et référence
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Détails de la Commande",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "DM Sans",
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_commandeData != null)
                      Text(
                        "Réf: ${_commandeData!['reference']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGainsCard() {
    if (_commandeData == null) return Container();

    final commande = _commandeData!;
    const accentColor = Color(0xFF4CAF50);

    // Calcul des gains basé sur les pourcentages par défaut
    final double prix = (commande['prix'] as num).toDouble();
    final double pourcentageWasher = 80.0; // Pourcentage par défaut
    final double partWasher = (prix * pourcentageWasher) / 100;
    final double partAdmin = prix - partWasher;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.1),
                accentColor.withOpacity(0.05)
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_money_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Vos Gains",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF022519),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGainRow("Prix de la commande",
                    "${prix.toStringAsFixed(2)}€", Colors.grey[700]!),
                const SizedBox(height: 8),
                _buildGainRow("Votre pourcentage",
                    "${pourcentageWasher.toStringAsFixed(0)}%", accentColor),
                const SizedBox(height: 8),
                const Divider(height: 20),
                _buildGainRow("VOTRE GAIN", "${partWasher.toStringAsFixed(2)}€",
                    accentColor,
                    isBold: true, fontSize: 20),
                const SizedBox(height: 8),
                _buildGainRow("Part Glitty", "${partAdmin.toStringAsFixed(2)}€",
                    Colors.grey[600]!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGainRow(String label, String value, Color color,
      {bool isBold = false, double fontSize = 16}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: fontSize - 2,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_commandeData == null) return Container();

    final commande = _commandeData!;
    final statut = commande['statut'];

    // Si la commande est déjà confirmée, ne pas afficher les boutons
    if (statut != 'en_attente') {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          // Bouton Accepter avec icône
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _acceptCommande,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 24,
                    ),
              label: _isProcessing
                  ? const Text('Traitement...')
                  : const Text(
                      'Accepter',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Bouton Refuser avec icône
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : _rejectCommande,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Icon(
                      Icons.cancel_outlined,
                      size: 24,
                    ),
              label: _isProcessing
                  ? const Text('Traitement...')
                  : const Text(
                      'Refuser',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 2),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.red.withOpacity(0.05),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    if (_commandeData == null) return Container();

    final commande = _commandeData!;
    final client = commande['client'] ?? {};
    final vehicle = commande['vehicule'] ?? {};
    final adresses = commande['adresses'] ?? {};
    final depart = adresses['depart'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informations de la Commande",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow("Type de lavage",
                    _formatTypeLavage(commande['type_lavage'])),
                _buildInfoRow("Prix", "${commande['prix']}€"),
                _buildInfoRow("Date", _formatDisplayDate(commande['date'])),
                _buildInfoRow("Créneau", _formatCreneau(commande['creneau'])),
                if (commande['heure'] != null)
                  _buildInfoRow("Heure", _formatHeure(commande['heure'])),
                _buildInfoRow("Statut", _formatStatut(commande['statut'])),
                if (commande['method_paiement'] != null)
                  _buildInfoRow("Méthode de paiement",
                      _formatMethodPaiement(commande['method_paiement'])),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  "Informations Client",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                    "Client", client['nom_complet'] ?? 'Non spécifié'),
                _buildInfoRow(
                    "Téléphone", client['telephone'] ?? 'Non spécifié'),
                _buildInfoRow("Email", client['email'] ?? 'Non spécifié'),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  "Informations Véhicule",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow("Type", vehicle['type'] ?? 'Non spécifié'),
                _buildInfoRow("Immatriculation",
                    vehicle['immatriculation'] ?? 'Non spécifiée'),
                if (vehicle['description'] != null)
                  _buildInfoRow("Description", vehicle['description']!),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  "Adresse de Lavage",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow("Adresse", depart['adresse'] ?? 'Non spécifiée'),
                if (depart['lat'] != null && depart['lng'] != null)
                  _buildInfoRow(
                      "Coordonnées", "${depart['lat']}, ${depart['lng']}"),
                if (commande['notes'] != null && commande['notes'].isNotEmpty)
                  _buildInfoRow("Notes", commande['notes']),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

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
                    : _errorMessage.isNotEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _loadCommandeDetail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4CAF50),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadCommandeDetail,
                            color: const Color(0xFF4CAF50),
                            child: ListView(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 30, 20, 20),
                              children: [
                                // Carte des gains
                                _buildGainsCard(),

                                // Boutons d'action (Accepter/Refuser)
                                _buildActionButtons(),

                                // Carte des informations
                                _buildInfoCard(),
                              ],
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes de formatage
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

  String _formatMethodPaiement(String method) {
    switch (method) {
      case 'espece':
        return 'Espèces';
      case 'carte':
        return 'Carte bancaire';
      case 'virement':
        return 'Virement';
      case 'solde_glitty':
        return 'Solde Glitty';
      case 'mobile_money':
        return 'Mobile Money';
      default:
        return method;
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

  String _formatHeure(String heureString) {
    try {
      // Format "08:00:00" -> "08:00"
      if (heureString.contains(':')) {
        final parts = heureString.split(':');
        if (parts.length >= 2) {
          return '${parts[0]}:${parts[1]}';
        }
      }
      return heureString;
    } catch (e) {
      return heureString;
    }
  }
}
