import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/ConfirmCommande.dart';
import 'package:glitty/CLient/LocationPage.dart' show LocationPage;
import 'package:glitty/services/commande_service.dart';
import 'package:cross_file/cross_file.dart';

class RecapCommandePage extends StatefulWidget {
  final int clientId;
  final String selectedAddress;
  final double latitude;
  final double longitude;
  final String typeLavage;

  final Map<String, dynamic>? vehicleData;
  final List<dynamic>? photos;
  final String date;
  final String creneau;
  final Map<String, dynamic>? clientData;

  const RecapCommandePage({
    super.key,
    required this.clientId,
    required this.selectedAddress,
    required this.latitude,
    required this.longitude,
    required this.typeLavage,
    this.vehicleData,
    this.photos,
    required this.date,
    required this.creneau,
    this.clientData,
  });

  @override
  State<RecapCommandePage> createState() => _RecapCommandePageState();
}

class _RecapCommandePageState extends State<RecapCommandePage> {
  bool _useGlittyBalance = false;
  bool _showPaymentModal = false;
  String? _selectedPaymentMethod;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Debug: afficher le clientId reçu
    print('=== RECAP COMMANDE PAGE DEBUG ===');
    print('ClientId reçu: ${widget.clientId}');
    print('Type de clientId: ${widget.clientId.runtimeType}');
    print('ClientData: ${widget.clientData}');
    print('==============================');
  }

  // Fonction pour convertir les photos en XFile
  List<XFile>? _convertPhotosToXFiles() {
    if (widget.photos == null) return null;

    List<XFile> xFiles = [];

    for (var photo in widget.photos!) {
      if (photo is XFile) {
        xFiles.add(photo);
      } else if (photo is String) {
        // Si c'est un chemin de fichier
        xFiles.add(XFile(photo));
      } else {
        // Pour tout autre type, essayer de convertir en String path
        try {
          final path = photo.toString();
          if (path.isNotEmpty) {
            xFiles.add(XFile(path));
          }
        } catch (e) {
          print('Erreur conversion photo: $e');
        }
      }
    }

    return xFiles.isNotEmpty ? xFiles : null;
  }

  // Fonction pour créer la commande - SIMPLIFIÉE
  Future<void> _createCommande() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner un mode de paiement"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Debug avant l'appel API
    print('=== CRÉATION COMMANDE DEBUG ===');
    print('ClientId utilisé: ${widget.clientId}');
    print('Type de lavage: ${widget.typeLavage}');
    print('Date: ${widget.date}');
    print('Créneau: ${widget.creneau}');
    print('Adresse: ${widget.selectedAddress}');
    print('Méthode paiement: $_selectedPaymentMethod');
    print('============================');

    setState(() {
      _isLoading = true;
    });

    try {
      // Conversion des photos
      final xPhotos = _convertPhotosToXFiles();

      final result = await CommandeService.createCommande(
        clientId: widget
            .clientId, // Utilisation DIRECTE du clientId passé en paramètre
        vehicleId: null, // Nouveau véhicule
        vehicleData: widget.vehicleData,
        date: widget.date,
        creneau: widget.creneau,
        heure: null,
        departLat: widget.latitude,
        departLng: widget.longitude,
        departAdresse: widget.selectedAddress,
        arriveeLat: null,
        arriveeLng: null,
        arriveeAdresse: null,
        typeLavage: widget.typeLavage,

        notes: null,
        dureeEstimee: null,
        methodPaiement: _selectedPaymentMethod,
        photos: xPhotos,
      );

      setState(() {
        _isLoading = false;
      });

      // Debug après l'appel API
      print('=== RÉPONSE API DEBUG ===');
      print('Succès: ${result['success']}');
      print('Erreur: ${result['error']}');
      print('Données: ${result['data']}');
      print('========================');

      if (result['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmCommandePage(
              commandeData: result['data']['commande'],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erreur inconnue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      // Debug en cas d'erreur
      print('=== ERREUR CRÉATION COMMANDE ===');
      print('Erreur: $error');
      print('==============================');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour formater l'adresse
  Map<String, String> _parseAddress(String fullAddress) {
    try {
      if (fullAddress.contains(',')) {
        final parts = fullAddress.split(',');
        if (parts.length >= 2) {
          return {
            'street': parts[0].trim(),
            'city': parts.sublist(1).join(',').trim(),
          };
        }
      }
      return {
        'street': fullAddress,
        'city': '',
      };
    } catch (e) {
      print('Erreur parsing adresse: $e');
      return {
        'street': fullAddress,
        'city': '',
      };
    }
  }

  // Fonction pour formater la date
  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      final months = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
      ];
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  // Fonction pour formater le créneau
  String _formatCreneau(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin (8h-12h)';
      case 'apres_midi':
        return 'Après-midi (12h-17h)';
      case 'soir':
        return 'Soir (17h-20h)';
      default:
        return creneau;
    }
  }

  // Fonction pour obtenir le titre du lavage
  String _getLavageTitle(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return "Lavage Intérieur";
      case 'lavage_exterieur':
        return "Lavage Extérieur";
      case 'lavage_complet':
        return "Lavage Premium";
      default:
        return typeLavage;
    }
  }

  // Fonction pour obtenir la description du lavage
  List<String> _getLavageDescription(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return ["✅ Nettoyage intérieur", "✅ Tableau de bord", "✅ Aspirateur"];
      case 'lavage_exterieur':
        return [
          "✅ Nettoyage extérieur",
          "✅ Nettoyage des vitres",
          "✅ Nettoyage des roues"
        ];
      case 'lavage_complet':
        return [
          "✅ Nettoyage intérieur",
          "✅ Nettoyage extérieur",
          "✅ Nettoyage complet"
        ];
      default:
        return ["✅ Service de lavage"];
    }
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    // Parser l'adresse
    final addressParts = _parseAddress(widget.selectedAddress);

    return Scaffold(
      backgroundColor: dark,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Partie supérieure : fixe à 100
                Container(
                  height: 180,
                  width: double.infinity,
                  color: dark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // Première ligne : icônes menu, logo, notification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/menu-icone.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                          Image.asset(
                            'assets/logo-glitty.png',
                            width: 149,
                            height: 69,
                          ),
                          Image.asset(
                            'assets/notification-icone.png',
                            width: 24,
                            height: 24,
                            color: Colors.white,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {},
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
                                Icons.arrow_back_rounded, // Flèche complète
                                color: Color(0xFF022519),
                                size: 24, // Taille augmentée
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextField(
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText:
                                      'Prêt à faire briller sans polluer!',
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(0, 0, 0, 0.5),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 19 / 14,
                                    letterSpacing: -0.3,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical:
                                        12, // AJOUT: Padding vertical pour centrer
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

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
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Section Départ - Arrivée
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF949494).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Colonne des icônes
                                Column(
                                  children: [
                                    // Icône départ
                                    Image.asset(
                                      'assets/icon-depart.png',
                                      width: 20,
                                      height: 20,
                                    ),
                                  ],
                                ),

                                const SizedBox(width: 16),

                                // Colonne des adresses
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Adresse de départ (adresse choisie dynamiquement)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            addressParts['street']!,
                                            style: const TextStyle(
                                              color: Color(0xFF1B1D21),
                                              fontFamily: "DM Sans",
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              height: 18 / 14,
                                            ),
                                          ),
                                          if (addressParts['city']!.isNotEmpty)
                                            Text(
                                              addressParts['city']!,
                                              style: const TextStyle(
                                                color: Color(0xFF1B1D21),
                                                fontFamily: "DM Sans",
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: 18 / 14,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section Détails de la commande
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF949494).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Titre "Détails de la commande"
                                const Text(
                                  "Détails de la commande",
                                  style: TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "Poppins",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Ligne de séparation
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color:
                                      const Color(0xFF1B1D21).withOpacity(0.1),
                                ),

                                const SizedBox(height: 16),

                                // Service de lavage sélectionné
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Cadre avec dégradé radial et icône
                                    Container(
                                      width: 72,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        gradient: const RadialGradient(
                                          center: Alignment.center,
                                          radius: 0.8,
                                          colors: [
                                            Color(0xFF02AA26),
                                            Color(0xFF4FBF67),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Image.asset(
                                          'assets/protection-2 1.png',
                                          width: 32,
                                          height: 32,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Informations du produit
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Titre
                                          Text(
                                            _getLavageTitle(widget.typeLavage),
                                            style: const TextStyle(
                                              color: Color(0xFF1B1D21),
                                              fontFamily: "DM Sans",
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              height: 38 / 18,
                                              letterSpacing: -0.4,
                                            ),
                                          ),

                                          const SizedBox(height: 4),

                                          // Détails des services
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: _getLavageDescription(
                                                    widget.typeLavage)
                                                .map((service) => Text(
                                                      service,
                                                      style: TextStyle(
                                                        color: const Color(
                                                            0xFF797979),
                                                        fontFamily: "DM Sans",
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        height: 14 / 9,
                                                        letterSpacing: -0.3,
                                                      ),
                                                    ))
                                                .toList(),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 16),

                                    // Prix aligné au centre vertical
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color:
                                      const Color(0xFF1B1D21).withOpacity(0.1),
                                ),

                                const SizedBox(height: 16),

                                // Informations véhicule
                                if (widget.vehicleData != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Informations du véhicule",
                                        style: TextStyle(
                                          color: Color(0xFF1B1D21),
                                          fontFamily: "DM Sans",
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          height: 17 / 12,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Type: ${widget.vehicleData!['type']}",
                                        style: const TextStyle(
                                          color: Color(0xFF797979),
                                          fontFamily: "DM Sans",
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "Immatriculation: ${widget.vehicleData!['immatriculation']}",
                                        style: const TextStyle(
                                          color: Color(0xFF797979),
                                          fontFamily: "DM Sans",
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (widget.vehicleData!['description'] !=
                                          null)
                                        Text(
                                          "Description: ${widget.vehicleData!['description']}",
                                          style: const TextStyle(
                                            color: Color(0xFF797979),
                                            fontFamily: "DM Sans",
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      const SizedBox(height: 16),
                                      Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: const Color(0xFF1B1D21)
                                            .withOpacity(0.1),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Date du rendez-vous
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Date du rendez-vous",
                                      style: TextStyle(
                                        color: Color(0xFF1B1D21),
                                        fontFamily: "DM Sans",
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        height: 17 / 12,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    Text(
                                      "${_formatDate(widget.date)} - ${_formatCreneau(widget.creneau)}",
                                      style: TextStyle(
                                        color: const Color(0xFF1B1D21),
                                        fontFamily: "Poppins",
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Ligne de séparation sous la date
                                Container(
                                  width: double.infinity,
                                  height: 1,
                                  color:
                                      const Color(0xFF1B1D21).withOpacity(0.1),
                                ),

                                const SizedBox(height: 16),

                                // Total
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Total",
                                      style: TextStyle(
                                        color: Color(0xFF1B1D21),
                                        fontFamily: "DM Sans",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        height: 17 / 12,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Section Moyens de paiement
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF949494).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Titre "Moyens de paiement"
                                const Text(
                                  "Moyens de paiement",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: "DM Sans",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 38 / 18,
                                    letterSpacing: -0.4,
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Cartes de méthode de paiement
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // Carte Credit/Debit
                                    _buildPaymentCard(
                                      iconPath: 'assets/Bank-Card.svg',
                                      title: "Carte",
                                      isSelected:
                                          _selectedPaymentMethod == 'carte',
                                      onTap: () {
                                        setState(() {
                                          _selectedPaymentMethod = 'carte';
                                        });
                                      },
                                    ),

                                    // Espèces
                                    _buildPaymentCard(
                                      iconPath: 'assets/especes-Card.svg',
                                      title: "Espèces",
                                      isSelected:
                                          _selectedPaymentMethod == 'espece',
                                      onTap: () {
                                        setState(() {
                                          _selectedPaymentMethod = 'espece';
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Section Utiliser mon solde Glitty
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _useGlittyBalance = !_useGlittyBalance;
                                      if (_useGlittyBalance) {
                                        _showPaymentModal = true;
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE6E8EC),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Checkbox et texte
                                        Row(
                                          children: [
                                            Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color:
                                                      const Color(0xFFE6E8EC),
                                                  width: 1,
                                                ),
                                                color: _useGlittyBalance
                                                    ? const Color(0xFF4FBF67)
                                                    : Colors.transparent,
                                              ),
                                              child: _useGlittyBalance
                                                  ? const Center(
                                                      child: Icon(
                                                        Icons.check,
                                                        size: 14,
                                                        color: Colors.white,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              "Utiliser mon solde Glitty",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontFamily: "DM Sans",
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                height: 24 / 14,
                                                letterSpacing: -0.3,
                                              ),
                                            ),
                                          ],
                                        ),

                                        // Montant
                                        Text(
                                          "120€",
                                          style: TextStyle(
                                            color: const Color(0xFF4FBF67),
                                            fontFamily: "DM Sans",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            height: 24 / 14,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                // Bouton Valider
                                _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Color(0xFF4FBF67),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
                                        onTap: _createCommande,
                                        child: Container(
                                          width: 295,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4FBF67),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              "Valider la commande",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "DM Sans",
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Modal de paiement
          if (_showPaymentModal)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Header de la modal
                          Container(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Titre
                                const Text(
                                  "Paiement",
                                  style: TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "DM Sans",
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 26 / 16,
                                    letterSpacing: -0.356,
                                  ),
                                ),

                                // Bouton Ajouter
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(19),
                                    color: const Color(0xFF8F92A1)
                                        .withOpacity(0.1),
                                  ),
                                  child: const Text(
                                    "Ajouter",
                                    style: TextStyle(
                                      color: Color(0xFF1B1D21),
                                      fontFamily: "DM Sans",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Ligne de séparation
                          Container(
                            width: double.infinity,
                            height: 1,
                            color: const Color(0xFF1B1D21).withOpacity(0.1),
                          ),

                          // Contenu de la modal
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Image PNG (remplacez par votre image)
                                  SvgPicture.asset(
                                    'assets/payment-card.svg',
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.contain,
                                  ),

                                  const SizedBox(height: 32),

                                  // Titre "Ajouter une Carte"
                                  const Text(
                                    "Ajouter une Carte",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF1B1D21),
                                      fontFamily: "DM Sans",
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 38 / 18,
                                      letterSpacing: -0.4,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Paragraphe
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      "Il semble que vous n'ayez ajouté aucune carte de crédit ou de débit. Ajoutez une carte pour un accès plus rapide.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF797979),
                                        fontFamily: "DM Sans",
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 19 / 14,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Bouton Retour
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _showPaymentModal = false;
                                        _useGlittyBalance = false;
                                      });
                                    },
                                    child: Container(
                                      width: 295,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF797979),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "Retour",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "DM Sans",
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  // Widget pour construire une carte de paiement avec SVG
  Widget _buildPaymentCard({
    required String iconPath,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 157,
        height: 118,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF949494).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: isSelected
              ? Border.all(
                  color: const Color(0xFF4FBF67),
                  width: 2,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Contenu principal centré
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icône SVG
                  SvgPicture.asset(
                    iconPath,
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(height: 8),
                  // Texte
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF1B1D21),
                      fontFamily: "DM Sans",
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      height: 14 / 9,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            // Cercle de sélection en haut à droite
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? const Color(0xFF4FBF67) : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4FBF67)
                        : const Color(0xFFE6E8EC),
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
