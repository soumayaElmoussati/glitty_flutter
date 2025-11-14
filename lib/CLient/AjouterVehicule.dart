import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/ReserverLavagePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'ChoisirCreneau.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ClientAccueil.dart';
import 'package:glitty/services/commande_service.dart';

class AjouterVehicule extends StatefulWidget {
  final int clientId;
  final String typeLavage;
  final String typePrestation;
  final Map<String, dynamic>? clientData;
  final String? token;

  final Map<String, dynamic>? existingVehicleData;
  final List<File>? existingPhotos;
  final double? existingPrix;

  const AjouterVehicule({
    super.key,
    required this.clientId,
    required this.typeLavage,
    required this.typePrestation,
    this.clientData,
    this.token,
    this.existingVehicleData,
    this.existingPhotos,
    this.existingPrix,
  });

  @override
  State<AjouterVehicule> createState() => _AjouterVehiculeState();
}

class _AjouterVehiculeState extends State<AjouterVehicule> {
  final TextEditingController _immatriculationController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedVehicleType;
  List<File> _selectedPhotos = [];

  // Variables pour le prix
  double? _prix;
  bool _isLoadingPrix = false;

  @override
  void initState() {
    super.initState();
    _initializeExistingData();
  }

  // NOUVELLE MÉTHODE: Initialiser avec les données existantes
  void _initializeExistingData() {
    print('🔄 Initialisation des données existantes...');

    // Si des données existantes sont fournies, les initialiser
    if (widget.existingVehicleData != null) {
      _immatriculationController.text =
          widget.existingVehicleData!['immatriculation'] ?? '';
      _descriptionController.text =
          widget.existingVehicleData!['description'] ?? '';
      _selectedVehicleType = widget.existingVehicleData!['type'];

      print('✅ Données véhicule chargées:');
      print('   - Immatriculation: ${_immatriculationController.text}');
      print('   - Type: $_selectedVehicleType');
      print('   - Description: ${_descriptionController.text}');
    }

    // Initialiser les photos existantes
    if (widget.existingPhotos != null && widget.existingPhotos!.isNotEmpty) {
      _selectedPhotos.addAll(widget.existingPhotos!);
      print('✅ ${_selectedPhotos.length} photo(s) chargée(s)');
    }

    // Gérer le prix
    if (widget.existingPrix != null) {
      _prix = widget.existingPrix;
      print('✅ Prix existant chargé: $_prix');
    } else if (_selectedVehicleType != null) {
      // Si pas de prix mais type de véhicule, recalculer
      print('🔄 Recalcul du prix...');
      _fetchPrix();
    }
  }

  // Fonction pour récupérer le prix selon le véhicule et la prestation
  Future<void> _fetchPrix() async {
    if (_selectedVehicleType == null) return;

    setState(() {
      _isLoadingPrix = true;
    });

    try {
      String typeVehiculeApi = _convertVehicleTypeToApi(_selectedVehicleType!);
      String typePrestationApi =
          _convertPrestationTypeToApi(widget.typePrestation);

      print('🔄 Récupération prix pour: $typeVehiculeApi - $typePrestationApi');

      final result = await CommandeService.getPrix(
        typeVehicule: typeVehiculeApi,
        typePrestation: typePrestationApi,
      );

      print('📦 Résultat API complet: $result');

      if (result['success'] == true && result['data'] != null) {
        double? prixTrouve;

        // Essayer différentes structures de données possibles
        if (result['data']['data'] != null &&
            result['data']['data']['prix'] != null) {
          prixTrouve = _parsePrix(result['data']['data']['prix']);
          print('✅ Prix trouvé dans data.data.prix: $prixTrouve');
        } else if (result['data']['prix'] != null) {
          prixTrouve = _parsePrix(result['data']['prix']);
          print('✅ Prix trouvé dans data.prix: $prixTrouve');
        } else if (result['prix'] != null) {
          prixTrouve = _parsePrix(result['prix']);
          print('✅ Prix trouvé dans result.prix: $prixTrouve');
        }

        if (prixTrouve != null) {
          setState(() {
            _prix = prixTrouve;
          });
          print('🎯 Prix final: $_prix');
        } else {
          print('❌ Aucun prix trouvé dans la réponse');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Prix non disponible pour cette combinaison"),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        print('❌ Erreur récupération prix: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${result['error'] ?? 'Erreur inconnue'}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      print('❌ Erreur fetchPrix: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur de connexion: $error"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoadingPrix = false;
      });
    }
  }

  // Méthode utilitaire pour parser le prix depuis différents types
  double? _parsePrix(dynamic prixValue) {
    if (prixValue == null) return null;

    try {
      if (prixValue is num) {
        return prixValue.toDouble();
      } else if (prixValue is String) {
        return double.tryParse(prixValue);
      } else {
        return double.tryParse(prixValue.toString());
      }
    } catch (e) {
      print('❌ Erreur parsing prix: $e');
      return null;
    }
  }

  // Fonctions de conversion
  String _convertVehicleTypeToApi(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'citadine':
        return 'citadine';
      case 'suv':
        return 'suv';
      case 'moto':
        return 'moto';
      default:
        return 'citadine';
    }
  }

  String _convertPrestationTypeToApi(String prestationType) {
    switch (prestationType.toLowerCase()) {
      case 'lavage_interieur':
        return 'lavage_interieur';
      case 'lavage_exterieur':
        return 'lavage_exterieur';
      case 'lavage_complet':
        return 'lavage_complet';
      default:
        return 'lavage_interieur';
    }
  }

  // Widget pour afficher le prix
  Widget _buildPrixDisplay() {
    if (_isLoadingPrix) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4FBF67)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Calcul du prix...',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4FBF67),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_prix != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF4FBF67).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4FBF67).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.euro_symbol,
              color: Color(0xFF4FBF67),
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Prix: ${_prix!.toStringAsFixed(2)}€',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF022519),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox();
  }

  // Fonction pour sélectionner des photos depuis la galerie
  Future<void> _selectPhotosFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedPhotos
              .addAll(images.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      print('Erreur lors de la sélection des photos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la sélection des photos"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour prendre une photo avec la caméra
  Future<void> _takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _selectedPhotos.add(File(photo.path));
        });
      }
    } catch (e) {
      print('Erreur lors de la prise de photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur lors de la prise de photo"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fonction pour supprimer une photo
  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  // Fonction pour afficher le modal de choix de source photo
  void _showPhotoSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  "Ajouter des photos du véhicule",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF4FBF67)),
                title: const Text("Galerie photos"),
                subtitle: const Text("Sélectionner depuis votre galerie"),
                onTap: () {
                  Navigator.pop(context);
                  _selectPhotosFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4FBF67)),
                title: const Text("Appareil photo"),
                subtitle: const Text("Prendre une nouvelle photo"),
                onTap: () {
                  Navigator.pop(context);
                  _takePhotoWithCamera();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // Méthode pour construire le Drawer
  Widget _buildClientDrawer(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);
    final clientName = widget.clientData?['first_name'] ?? 'Client';

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
                        clientName.isNotEmpty
                            ? clientName[0].toUpperCase()
                            : 'C',
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
                    clientName,
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
                      "● Client",
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
                      Icons.home_rounded,
                      "Accueil",
                      false,
                      dark,
                      () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientAccueil(
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.shopping_bag_rounded,
                      "Mes commandes",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesCommandesPage(
                              clientId: widget.clientData?['id'] ?? 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Portefeuille",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PortefeuillePage(
                              clientId: widget.clientData?['id'] ?? 1,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.person_rounded,
                      "Mon profil",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MonProfile(
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.people_rounded,
                      "Parrainage",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ParrainagePage(
                                  clientId: widget.clientData?['id'] ?? 1)),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.help_rounded,
                      "Aide & Support",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MesTicketsClient(
                              clientId: widget.clientData?['id'],
                              clientData: widget.clientData,
                            ),
                          ),
                        );
                      },
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
                        () async {
                          // Afficher une boîte de dialogue de confirmation
                          final shouldLogout = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Déconnexion"),
                                content: const Text(
                                    "Êtes-vous sûr de vouloir vous déconnecter ?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("Annuler"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text(
                                      "Déconnexion",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (shouldLogout == true) {
                            // Utiliser AuthService pour la déconnexion
                            await AuthService.logout();

                            // Navigation vers la page d'accueil
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const WelcomePage()),
                              (route) => false,
                            );

                            // Optionnel : Afficher un message de confirmation
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Déconnexion réussie"),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
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

  // Méthode pour construire un item du Drawer
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

  // Méthode pour construire la bottom navigation bar
  Widget _buildBottomNavigationBar() {
    final double iconSize = 24;
    final double containerSize = 40;

    return Container(
      height: 80,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientAccueil(
                    clientData: widget.clientData,
                  ),
                ),
              );
            },
            child: Container(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone-home.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MesCommandesPage(
                    clientData: widget.clientData,
                    clientId: widget.clientData?['id'],
                  ),
                ),
              );
            },
            child: Container(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone2.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PortefeuillePage(
                    clientData: widget.clientData,
                    clientId: widget.clientData?['id'],
                  ),
                ),
              );
            },
            child: Container(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone3.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MonProfile(
                    clientData: widget.clientData,
                  ),
                ),
              );
            },
            child: Container(
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone4.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      drawer: _buildClientDrawer(context),
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReserverLavagePage(
                                clientData: widget.clientData,
                                token: widget.token,
                                clientId: widget.clientId,
                              ),
                            ),
                          );
                        },
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
                              hintText: 'Prêt à faire briller sans polluer!',
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
                                vertical: 12,
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
                      const Text(
                        "Ajouter un véhicule",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF000000),
                          fontFamily: "DM Sans",
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 26 / 16,
                          letterSpacing: -0.356,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset(
                                  'assets/meduim-logo.png',
                                  width: 24,
                                  height: 24,
                                  color: const Color(0xFF1B1D21),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  "Gestion du véhicule",
                                  style: TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "DM Sans",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 38 / 18,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(19.5),
                                color: const Color(0xFFEEF7FF),
                              ),
                              child: TextButton.icon(
                                onPressed: _showPhotoSourceModal,
                                icon: Image.asset(
                                  'assets/add-icon.png',
                                  width: 16,
                                  height: 16,
                                  color: const Color(0xFF4FBF67),
                                ),
                                label: const Text(
                                  "Ajouter",
                                  style: TextStyle(
                                    color: Color(0xFF4FBF67),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 24 / 14,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(19.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const Text(
                          "Ajoutez les informations de votre véhicule afin de faciliter son identification!",
                          style: TextStyle(
                            color: Color.fromRGBO(0, 0, 0, 0.5),
                            fontFamily: "DM Sans",
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                          ),
                        ),
                      ),
                      if (_selectedPhotos.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "PHOTOS DU VÉHICULE",
                                style: TextStyle(
                                  color: Color(0xFF8F92A1),
                                  fontFamily: "DM Sans",
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  height: 20 / 10,
                                  letterSpacing: 0.833,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _selectedPhotos.length,
                                  itemBuilder: (context, index) {
                                    return Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          margin:
                                              const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            image: DecorationImage(
                                              image: FileImage(
                                                  _selectedPhotos[index]),
                                              fit: BoxFit.cover,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removePhoto(index),
                                            child: Container(
                                              width: 24,
                                              height: 24,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4,
                                          left: 4,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${_selectedPhotos.length} photo(s) sélectionnée(s)",
                                style: const TextStyle(
                                  color: Color(0xFF4FBF67),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        width: 319,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "IMMATRICULATION",
                              style: TextStyle(
                                color: Color(0xFF8F92A1),
                                fontFamily: "DM Sans",
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 20 / 10,
                                letterSpacing: 0.833,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 319,
                              height: 46,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color:
                                    const Color.fromRGBO(143, 146, 161, 0.05),
                              ),
                              child: TextField(
                                controller: _immatriculationController,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: "Entrez l'immatriculation",
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(143, 146, 161, 0.6),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF1B1D21),
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 319,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "TYPE DE VÉHICULE",
                              style: TextStyle(
                                color: Color(0xFF8F92A1),
                                fontFamily: "DM Sans",
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 20 / 10,
                                letterSpacing: 0.833,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                _showVehicleTypeBottomSheet(context);
                              },
                              child: Container(
                                width: 319,
                                height: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color:
                                      const Color.fromRGBO(143, 146, 161, 0.05),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text(
                                          _selectedVehicleType ??
                                              "Sélectionnez le type de véhicule",
                                          style: TextStyle(
                                            color: _selectedVehicleType != null
                                                ? const Color(0xFF1B1D21)
                                                : const Color(0xFF8F92A1)
                                                    .withOpacity(0.6),
                                            fontFamily: "DM Sans",
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(right: 16),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Color(0xFF8F92A1),
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 319,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "DESCRIPTION",
                              style: TextStyle(
                                color: Color(0xFF8F92A1),
                                fontFamily: "DM Sans",
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 20 / 10,
                                letterSpacing: 0.833,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 319,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color:
                                    const Color.fromRGBO(143, 146, 161, 0.05),
                              ),
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText:
                                      "Description du véhicule (optionnel)",
                                  hintStyle: const TextStyle(
                                    color: Color.fromRGBO(143, 146, 161, 0.6),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF1B1D21),
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildPrixDisplay(),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          if (_immatriculationController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Veuillez saisir l'immatriculation"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_selectedVehicleType == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Veuillez sélectionner le type de véhicule"),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (_prix == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Calcul du prix en cours..."),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          Map<String, dynamic> vehicleData = {
                            'type': _selectedVehicleType!,
                            'immatriculation': _immatriculationController.text,
                            'description': _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                          };

                          print('💰 Prix transmis à ChoisirCreneau: $_prix');

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChoisirCreneau(
                                clientId:
                                    widget.clientData?['id'] ?? widget.clientId,
                                typeLavage: widget.typePrestation,
                                vehicleData: vehicleData,
                                clientData: widget.clientData,
                                photos: _selectedPhotos,
                                prix: _prix!,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 295,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF4FBF67),
                          ),
                          child: const Center(
                            child: Text(
                              "Suivant",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 24 / 14,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
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
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _showVehicleTypeBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sélectionner votre type de véhicule",
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: "DM Sans",
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 26 / 22,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Différents types de véhicules peuvent être lavés à des tarifs différents",
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontFamily: "DM Sans",
                  fontSize: 14,
                  fontWeight: FontWeight.w200,
                  height: 21 / 14,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "Citadine";
                  });
                  _fetchPrix();
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/citadine-icon.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Citadine",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: "DM Sans",
                            fontSize: 19,
                            fontWeight: FontWeight.w300,
                            height: 21 / 19,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 305,
                      height: 1,
                      color: const Color(0xFF4FBF67),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "SUV";
                  });
                  _fetchPrix();
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/suv-icon.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "SUV",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: "DM Sans",
                            fontSize: 19,
                            fontWeight: FontWeight.w300,
                            height: 21 / 19,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 305,
                      height: 1,
                      color: const Color(0xFF4FBF67),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "Moto";
                  });
                  _fetchPrix();
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/moto-icon.png',
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Moto",
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: "DM Sans",
                            fontSize: 19,
                            fontWeight: FontWeight.w300,
                            height: 21 / 19,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 305,
                      height: 1,
                      color: const Color(0xFF4FBF67),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
