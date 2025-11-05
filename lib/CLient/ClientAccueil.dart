import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ReserverLavagePage.dart';
import 'MesCommandesPage.dart';
import 'PortefeuillePage.dart';
import 'ParrainagePage.dart';
import '../WelcomePage.dart';

class ClientAccueil extends StatefulWidget {
  final Map<String, dynamic>? clientData;
  final String? token;

  const ClientAccueil({super.key, this.clientData, this.token});

  @override
  State<ClientAccueil> createState() => _ClientAccueilState();
}

class _ClientAccueilState extends State<ClientAccueil> {
  int _currentIndex = 0;
  late final int clientId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    clientId = widget.clientData?['id'] ?? 1;
  }

  // Méthode pour obtenir la page actuelle
  Widget _getCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return MesCommandesPage(
          clientId: clientId,
          clientData: widget.clientData,
          token: widget.token,
          // Passer la clé
        );
      case 2:
        return PortefeuillePage(
          clientId: clientId,
          clientData: widget.clientData,
          token: widget.token,
        );
      case 3:
        return MonProfile(
          clientData: widget.clientData,
          token: widget.token,
        );
      default:
        return _buildHomeContent();
    }
  }

  // Méthode pour construire le Drawer (sidebar)
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
                      Icons.people_rounded,
                      "Accueil",
                      true,
                      dark,
                      () {
                        Navigator.pop(context);
                        // Reste sur la même page
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
                      Icons.people_rounded,
                      "Portefeuille",
                      false,
                      dark,
                      () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PortefeuillePage(
                                    clientId: clientId,
                                    clientData: widget.clientData,
                                    token: widget.token,
                                  )),
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
                                    clientId: clientId,
                                    clientData: widget.clientData,
                                    token: widget.token,
                                  )),
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
                              clientId: clientId,
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

  Widget _buildHomeContent() {
    const dark = Color(0xFF022519);

    return Container(
      color: dark,
      child: SafeArea(
        child: Column(
          children: [
            // Partie supérieure - Header
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
                      // Menu icon qui ouvre le drawer
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => _scaffoldKey.currentState?.openDrawer(),
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

            // Partie inférieure blanche avec borderRadius top
            Expanded(
              child: Stack(
                children: [
                  // Fond blanc avec borderRadius
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),

                  // Contenu scrollable avec vos cartes
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          "Planifier votre lavage",
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
                        _menuCard(
                          "Réservez votre lavage",
                          pngPath: 'assets/lavage-icone.png',
                          page: ReserverLavagePage(
                            clientId: clientId,
                            clientData: widget.clientData,
                            token: widget.token,
                          ),
                        ),
                        _menuCard(
                          "Mes commandes",
                          pngPath: 'assets/orders-icone.png',
                          page: MesCommandesPage(
                            clientId: clientId,
                            clientData: widget.clientData,
                            token: widget.token,
                          ),
                        ),
                        _menuCard(
                          "Mon portefeuille",
                          pngPath: 'assets/wallet-icone.png',
                          page: PortefeuillePage(
                            clientId: clientId,
                            clientData: widget.clientData,
                            token: widget.token,
                          ),
                        ),
                        _menuCard(
                          "Parrainez des amis",
                          svgPath: 'assets/icone_parrainage.svg',
                          page: ParrainagePage(
                            clientId: clientId,
                            clientData: widget.clientData,
                            token: widget.token,
                          ),
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(
    String title, {
    IconData? icon,
    String? svgPath,
    String? pngPath,
    required Widget page,
  }) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: icon != null
                  ? Icon(icon, size: 22)
                  : pngPath != null
                      ? Image.asset(
                          pngPath,
                          width: 22,
                          height: 22,
                        )
                      : SvgPicture.asset(
                          svgPath!,
                          width: 22,
                          height: 22,
                        ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double iconSize = 24;
    final double containerSize = 40;

    return Scaffold(
      key: _scaffoldKey, // Clé pour contrôler le drawer
      backgroundColor: Colors.white,
      drawer: _buildClientDrawer(context), // Drawer dans le Scaffold principal
      body: _getCurrentPage(),
      bottomNavigationBar: Container(
        height: 80,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Icône Home
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 0),
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
            // Icône Commandes
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MesCommandesPage(
                      clientId: widget.clientData?['id'] ?? 1,
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
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
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

            // Icône Portefeuille
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PortefeuillePage(
                      clientId: clientId,
                      clientData: widget.clientData,
                      token: widget.token,
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

            // Icône Profil
            GestureDetector(
              onTap: () {
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
              child: Container(
                width: containerSize,
                height: containerSize,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                ),
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
      ),
    );
  }
}
