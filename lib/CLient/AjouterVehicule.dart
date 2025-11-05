import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/ReserverLavagePage.dart';
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

class AjouterVehicule extends StatefulWidget {
  final int clientId;
  final String typeLavage;
  final String typePrestation;
  final Map<String, dynamic>? clientData;
  final String? token;

  const AjouterVehicule(
      {super.key,
      required this.clientId,
      required this.typeLavage,
      required this.typePrestation,
      this.clientData,
      this.token});

  @override
  State<AjouterVehicule> createState() => _AjouterVehiculeState();
}

class _AjouterVehiculeState extends State<AjouterVehicule> {
  final TextEditingController _immatriculationController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedVehicleType;
  List<File> _selectedPhotos = [];
  int _currentIndex = 0;

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
              // Titre
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
              // Option Galerie
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
              // Option Caméra
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

  // AJOUT: Méthode pour construire le Drawer
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
            // En-tête du Drawer
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
            // Contenu du Drawer
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
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('token');
                          await prefs.remove('userData');

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WelcomePage()),
                            (route) => false,
                          );
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

  // AJOUT: Méthode pour construire un item du Drawer
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

  // AJOUT: Méthode pour construire la bottom navigation bar
  Widget _buildBottomNavigationBar() {
    final double iconSize = 24;
    final double containerSize = 40;

    return Container(
      height: 80,
      color: Colors.black,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Icône Home
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
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: _currentIndex == 0 ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone-home.svg',
                  width: iconSize,
                  height: iconSize,
                  color: _currentIndex == 0 ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),

          // Icône Commandes
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
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: _currentIndex == 1 ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone2.svg',
                  width: iconSize,
                  height: iconSize,
                  color: _currentIndex == 1 ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),

          // Icône Portefeuille
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
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: _currentIndex == 2 ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone3.svg',
                  width: iconSize,
                  height: iconSize,
                  color: _currentIndex == 2 ? Colors.white : Colors.grey[400],
                ),
              ),
            ),
          ),

          // Icône Profil
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
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: _currentIndex == 3 ? Colors.green : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone4.svg',
                  width: iconSize,
                  height: iconSize,
                  color: _currentIndex == 3 ? Colors.white : Colors.grey[400],
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
      // AJOUT: Drawer ici
      drawer: _buildClientDrawer(context),
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure : fixe à 100
            Container(
              height: 180,
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Première ligne : icônes menu, logo, notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // AJOUT: Builder pour accéder au contexte du Scaffold
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

                      // Nouvelle ligne : Gestion du véhicule
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Partie gauche : icône + titre
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

                            // Bouton Ajouter des photos à droite
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

                      // Paragraphe sous "Gestion du véhicule"
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

                      // Section des photos sélectionnées
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
                            // Label Immatriculation
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
                            // Input field
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

                      // Input Type de véhicule avec Bottom Sheet
                      Container(
                        width: 319,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label Type de véhicule
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
                            // Input field qui ouvre le bottom sheet
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

                      // Input Description
                      Container(
                        width: 319,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Label Description
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
                            // Input field
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

                      // Bouton Suivant
                      GestureDetector(
                        onTap: () {
                          // Vérifier que les champs obligatoires sont remplis
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

                          // Préparer les données du véhicule
                          Map<String, dynamic> vehicleData = {
                            'type': _selectedVehicleType!,
                            'immatriculation': _immatriculationController.text,
                            'description': _descriptionController.text.isEmpty
                                ? null
                                : _descriptionController.text,
                          };

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
                              ),
                            ),
                          );
                        },
                        child: Container(
                          width: 160,
                          height: 39,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color(0xFF4FBF67),
                          ),
                          child: const Center(
                            child: Text(
                              "Suivant",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "DM Sans",
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 32 / 22,
                                letterSpacing: -0.4,
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
      // AJOUT: Bottom Navigation Bar ici
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
              // Titre
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

              // Paragraphe
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

              // Option 1 - Citadine
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "Citadine";
                  });
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

              // Option 2 - SUV
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "SUV";
                  });
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

              // Option 3 - Moto
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = "Moto";
                  });
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
