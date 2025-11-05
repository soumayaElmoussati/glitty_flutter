import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'LocalisationChoix.dart';
import 'AjouterVehicule.dart';
import 'ClientAccueil.dart';

class ReserverLavagePage extends StatefulWidget {
  final int clientId;
  final Map<String, dynamic>? clientData;
  final String? token;

  const ReserverLavagePage(
      {super.key, required this.clientId, this.clientData, this.token});

  @override
  State<ReserverLavagePage> createState() => _ReserverLavagePageState();
}

class _ReserverLavagePageState extends State<ReserverLavagePage> {
  int _currentIndex = 0;
  Map<String, dynamic>? tarifsData;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTarifs();
  }

  Future<void> _fetchTarifs() async {
    try {
      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/tarif/derniers'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            tarifsData = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                data['message'] ?? 'Erreur lors du chargement des tarifs';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erreur serveur: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Erreur de connexion: $error';
        isLoading = false;
      });
    }
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
                              token: widget.token,
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
                              token: widget.token,
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
                              token: widget.token,
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
              if (_currentIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientAccueil(
                      clientData: widget.clientData,
                      token: widget.token,
                    ),
                  ),
                );
              }
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
                    token: widget.token,
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

          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientAccueil(
                    clientData: widget.clientData,
                    token: widget.token,
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

          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientAccueil(
                    clientData: widget.clientData,
                    token: widget.token,
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
                      // Builder pour accéder au contexte du Scaffold
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

                  // Deuxième ligne : barre de recherche + icône salut
                  Row(
                    children: [
                      // AJOUT: Bouton de retour avec flèche complète
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClientAccueil(
                                clientData: widget.clientData,
                                token: widget.token,
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
                child: isLoading
                    ? _buildLoadingIndicator()
                    : errorMessage.isNotEmpty
                        ? _buildErrorWidget()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Titre avec bouton de retour
                                Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    // Titre
                                    const Expanded(
                                      child: Text(
                                        "Choisir votre lavage",
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
                                    ),
                                    // Espace vide pour équilibrer la disposition
                                    const SizedBox(width: 48),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Card avec dégradé radial - Lavage intérieur
                                GestureDetector(
                                  onTap: () {
                                    // Navigation vers AjouterVehicule sans prix
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AjouterVehicule(
                                          clientId: widget.clientId,
                                          typeLavage: "Lavage intérieur",
                                          typePrestation: "intérieur",
                                          clientData: widget.clientData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 345.563,
                                    height: 165.396,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.0,
                                        colors: [
                                          Color(0xFF4FBF67),
                                          Color(0xFF12A932),
                                        ],
                                        stops: [0.0, 1.0],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Titre en haut à gauche
                                        const Positioned(
                                          top: 16,
                                          left: 31,
                                          child: Text(
                                            "Lavage intérieur",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontSize: 25.053,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -1.069,
                                            ),
                                          ),
                                        ),

                                        // Liste des éléments sous le titre
                                        const Positioned(
                                          top: 60,
                                          left: 31,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "✅ Nettoyage intérieur",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "DM Sans",
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  height: 14 / 9,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "✅ Tableau de bord",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "DM Sans",
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  height: 14 / 9,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "✅ Aspirateur",
                                                style: TextStyle(
                                                  color: Colors.white,
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

                                        // Image en bas à droite
                                        Positioned(
                                          bottom: 16,
                                          right: 33,
                                          child: Image.asset(
                                            'assets/protection 1.png',
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Card Lavage extérieur
                                GestureDetector(
                                  onTap: () {
                                    // Navigation vers AjouterVehicule sans prix
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AjouterVehicule(
                                          clientId: widget.clientId,
                                          typeLavage: "Lavage extérieur",
                                          typePrestation: "extérieur",
                                          clientData: widget.clientData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 345.563,
                                    height: 165.396,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.0,
                                        colors: [
                                          Color(0xFFFF7800),
                                          Color(0xFFE84B00),
                                        ],
                                        stops: [0.0, 1.0],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        // Titre en haut à gauche
                                        const Positioned(
                                          top: 16,
                                          left: 31,
                                          child: Text(
                                            "Lavage extérieur",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontSize: 25.053,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -1.069,
                                            ),
                                          ),
                                        ),
                                        const Positioned(
                                          top: 60,
                                          left: 31,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "✅ Nettoyage extérieur",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "DM Sans",
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  height: 14 / 9,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "✅ Nettoyage des vitres",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "DM Sans",
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  height: 14 / 9,
                                                  letterSpacing: -0.3,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "✅ Nettoyage des roues",
                                                style: TextStyle(
                                                  color: Colors.white,
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

                                        Positioned(
                                          bottom: 16,
                                          right: 33,
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    'assets/protection 1.png'),
                                                fit: BoxFit.cover,
                                                alignment: Alignment.center,
                                              ),
                                              color: const Color(0xFFD3D3D3),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Card Lavage premium
                                GestureDetector(
                                  onTap: () {
                                    // Navigation vers AjouterVehicule sans prix
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AjouterVehicule(
                                          clientId: widget.clientId,
                                          typeLavage: "LAVAGE PREMIUM",
                                          typePrestation: "premium",
                                          clientData: widget.clientData,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 345.563,
                                    height: 165.396,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      gradient: const RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.0,
                                        colors: [
                                          Color(0xFF00A2FF),
                                          Color(0xFF009BCF),
                                        ],
                                        stops: [0.0, 1.0],
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        const Positioned(
                                          top: 16,
                                          left: 31,
                                          child: Text(
                                            "LAVAGE PREMIUM",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontFamily: "Poppins",
                                              fontSize: 25.053,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -1.069,
                                            ),
                                          ),
                                        ),

                                        const Positioned(
                                          top: 60,
                                          left: 31,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "✅ Nettoyage extérieur",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "✅ Nettoyage des vitres",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "✅ Nettoyage des roues",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              SizedBox(width: 20),

                                              // Deuxième colonne
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "✅ Nettoyage intérieur",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "✅ Tableau de bord",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                  SizedBox(height: 4),
                                                  Text(
                                                    "✅ Aspirateur",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: "DM Sans",
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      height: 14 / 9,
                                                      letterSpacing: -0.3,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Image en bas à droite
                                        Positioned(
                                          bottom: 16,
                                          right: 33,
                                          child: Image.asset(
                                            'assets/auto 2.png',
                                            width: 80,
                                            height: 80,
                                          ),
                                        ),
                                      ],
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

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des tarifs...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchTarifs,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
