import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/ClientAccueil.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/CLient/RecapCommande.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'LocalisationChoix.dart';
import 'ConfirmationPage.dart';

class ConfirmCommandePage extends StatefulWidget {
  final Map<String, dynamic> commandeData;
  final Map<String, dynamic>? clientData;

  const ConfirmCommandePage({
    super.key,
    required this.commandeData,
    this.clientData,
  });

  @override
  State<ConfirmCommandePage> createState() => _ConfirmCommandePageState();
}

class _ConfirmCommandePageState extends State<ConfirmCommandePage> {
  int _currentIndex = 0;

  // NOUVELLE FONCTION : Configuration des statuts avec couleurs et badges
  Map<String, Map<String, dynamic>> get _statusConfig => {
        'en_attente': {
          'label': 'En attente',
          'color': Color(0xFFFFA726), // Orange
          'backgroundColor': Color(0xFFFFF3E0),
          'icon': Icons.access_time_rounded,
        },
        'confirme': {
          'label': 'Confirmé',
          'color': Color(0xFF4CAF50), // Vert
          'backgroundColor': Color(0xFFE8F5E8),
          'icon': Icons.check_circle_rounded,
        },
        'en_cours': {
          'label': 'En cours',
          'color': Color(0xFF2196F3), // Bleu
          'backgroundColor': Color(0xFFE3F2FD),
          'icon': Icons.play_circle_fill_rounded,
        },
        'termine': {
          'label': 'Terminé',
          'color': Color(0xFF4CAF50), // Vert
          'backgroundColor': Color(0xFFE8F5E8),
          'icon': Icons.done_all_rounded,
        },
        'annule': {
          'label': 'Annulé',
          'color': Color(0xFFF44336), // Rouge
          'backgroundColor': Color(0xFFFFEBEE),
          'icon': Icons.cancel_rounded,
        },
        'refuse': {
          'label': 'Refusé',
          'color': Color(0xFFF44336), // Rouge
          'backgroundColor': Color(0xFFFFEBEE),
          'icon': Icons.block_rounded,
        },
      };

  // NOUVELLE FONCTION : Obtenir la configuration du statut
  Map<String, dynamic> _getStatusConfig() {
    final status =
        widget.commandeData['statut']?.toString().toLowerCase() ?? 'en_attente';
    return _statusConfig[status] ?? _statusConfig['en_attente']!;
  }

  // NOUVELLE FONCTION : Widget pour afficher le badge de statut
  Widget _buildStatusBadge() {
    final statusConfig = _getStatusConfig();
    final status =
        widget.commandeData['statut']?.toString().toLowerCase() ?? 'en_attente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: statusConfig['backgroundColor'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusConfig['color'].withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusConfig['icon'],
            color: statusConfig['color'],
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            statusConfig['label'],
            style: TextStyle(
              color: statusConfig['color'],
              fontFamily: "DM Sans",
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
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
                          child: Icon(
                            Icons.menu_rounded,
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
                      Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
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
                      Container(
                        margin: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/Shield.svg',
                              width: 120,
                              height: 120,
                            ),
                            const SizedBox(height: 32),

                            // NOUVEAU : Badge de statut ajouté ici
                            _buildStatusBadge(),
                            const SizedBox(height: 16),

                            const Text(
                              "Commande passée",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF040415),
                                fontFamily: "DM Sans",
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 46 / 36,
                                letterSpacing: -1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Votre commande a été passée avec succès.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF797979),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 24 / 14,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (widget.commandeData.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF4FBF67),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Détails de la commande:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4FBF67),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Numéro: ${widget.commandeData['reference'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    // SUPPRIMÉ : Ligne du statut (déjà affiché dans le badge)
                                    Text(
                                      "Prix: ${widget.commandeData['prix'] ?? 'N/A'}€",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 24),
                            Text(
                              _getScheduleText(widget.commandeData),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1B1D21),
                                fontFamily: "DM Sans",
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 17 / 12,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 22, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1F4E5),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                "Ajouter au calendrier",
                                style: TextStyle(
                                  color: const Color(0xFF4FBF67),
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                width: 295,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF797979),
                                    width: 1,
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Profil",
                                    style: TextStyle(
                                      color: Color(0xFF1B1D21),
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

  // Fonction pour obtenir le texte d'horaire dynamique
  String _getScheduleText(Map<String, dynamic> commandeData) {
    final date = commandeData['date'] ?? '';
    final creneau = commandeData['creneau'] ?? '';

    if (date.isNotEmpty && creneau.isNotEmpty) {
      return "Le ${_formatDate(date)} - ${_formatCreneau(creneau)}";
    }

    return "Demain à 10h00 précises";
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
}
