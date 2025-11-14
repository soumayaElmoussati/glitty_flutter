import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
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
  Map<String, dynamic>? tarifsData;
  bool isLoading = true;
  String errorMessage = '';

  // NOUVELLE PALETTE DE COULEURS DANS LES VERTS
  final Color _primaryColor = const Color(0xFF022519);
  final Color _accentColor = const Color(0xFF27AE60); // Vert émeraude
  final Color _cardColor1 = const Color(0xFF2ECC71); // Vert clair
  final Color _cardColor2 = const Color(0xFF16A085); // Vert océan
  final Color _cardColor3 = const Color(0xFF229954); // Vert forêt
  final Color _backgroundColor = const Color(0xFFF8F9FA); // Gris très clair

  // NOUVEAU : Configuration des services disponibles
  final List<Map<String, dynamic>> _services = [
    {
      'title': 'Lavage Intérieur',
      'description': 'Nettoyage complet et détaillé de l\'habitacle',
      'apiKey': 'lavage_interieur',
      'color': const Color(0xFF2ECC71),
      'icon': Icons.airline_seat_recline_normal_rounded,
      'features': [
        'Nettoyage intérieur complet',
        'Tableau de bord et plastiques',
        'Aspirateur professionnel',
        'Désinfection des surfaces'
      ],
    },
    {
      'title': 'Lavage Extérieur',
      'description': 'Brillance et propreté extérieure optimale',
      'apiKey': 'lavage_exterieur',
      'color': const Color(0xFF16A085),
      'icon': Icons.car_repair_rounded,
      'features': [
        'Nettoyage extérieur complet',
        'Vitres cristallines',
        'Nettoyage des roues et jantes',
        'Séchage sans trace'
      ],
    },
    {
      'title': 'Lavage Complet',
      'description': 'L\'excellence d\'un nettoyage intégral',
      'apiKey': 'lavage_complet',
      'color': const Color(0xFF229954),
      'icon': Icons.diamond_rounded,
      'features': [
        'Intérieur et extérieur complet',
        'Traitement anti-poussière',
        'Produits écologiques premium',
        'Garantie satisfaction 48h'
      ],
    },
  ];

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

  // MÉTHODE POUR EXTRAIRE ET FORMATER LES PRIX
  String _getFormattedPrice(
      Map<String, dynamic>? tarifsData, String serviceType) {
    if (tarifsData == null) {
      // Retourne "Recommandé" pour les lavages intérieur et extérieur, "Complet" pour premium
      if (serviceType == 'lavage_complet') {
        return "Complet";
      } else {
        return "Recommandé";
      }
    }

    // Si tarifsData contient des objets avec des champs 'price'
    if (tarifsData[serviceType] is Map) {
      final serviceData = tarifsData[serviceType] as Map;
      final price = serviceData['price'] ??
          serviceData['montant'] ??
          serviceData['tarif'];
      if (price != null) {
        if (price is num) return "${price.toStringAsFixed(2)} €";
        if (price is String) {
          final numericPrice = double.tryParse(price);
          if (numericPrice != null)
            return "${numericPrice.toStringAsFixed(2)} €";
          return price;
        }
      }
    }

    // Si c'est directement un nombre
    final price = tarifsData[serviceType];
    if (price is num) return "${price.toStringAsFixed(2)} €";
    if (price is String) {
      final numericPrice = double.tryParse(price);
      if (numericPrice != null) return "${numericPrice.toStringAsFixed(2)} €";
      return price;
    }

    // Par défaut, retourne "Recommandé" ou "Complet" selon le type de service
    if (serviceType == 'lavage_complet') {
      return "Complet";
    } else {
      return "Recommandé";
    }
  }

  // Méthode pour construire le Drawer
  Widget _buildClientDrawer(BuildContext context) {
    final clientName = widget.clientData?['first_name'] ?? 'Client';

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor, _primaryColor.withOpacity(0.8)],
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
                      backgroundColor: _accentColor,
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
                      color: _accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _accentColor.withOpacity(0.3)),
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
                      _primaryColor,
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
                      _primaryColor,
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
                      _primaryColor,
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
                      _primaryColor,
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
                      _primaryColor,
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
                      _primaryColor,
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

  // MÉTHODE : Construction des cartes de service minimalistes
  Widget _buildServiceCard({
    required String title,
    required String description,
    required String price,
    required Color color,
    required IconData icon,
    required List<String> features,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: _primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: features
                    .map((feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: color,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    "SÉLECTIONNER",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Méthode de navigation
  void _navigateToVehicle(String typeLavage, String typePrestation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AjouterVehicule(
          clientId: widget.clientId,
          typeLavage: typeLavage,
          typePrestation: typePrestation,
          clientData: widget.clientData,
        ),
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
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icone-home.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.white,
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
                    token: widget.token,
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
                    token: widget.token,
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
                    token: widget.token,
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
    // DEBUG : Afficher la structure des données tarifsData
    if (tarifsData != null) {
      print("Structure tarifsData: $tarifsData");
    }

    return Scaffold(
      drawer: _buildClientDrawer(context),
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure inchangée
            Container(
              height: 180,
              width: double.infinity,
              color: _primaryColor,
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
                          child: Icon(
                            Icons.arrow_back_rounded,
                            color: _primaryColor,
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

            // SECTION : Design épuré des services
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: const BorderRadius.only(
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
                                // En-tête simplifié
                                Container(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        "Nos Prestations",
                                        style: TextStyle(
                                          color: _primaryColor,
                                          fontFamily: "Poppins",
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Choisissez le service qui correspond à vos besoins",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontFamily: "DM Sans",
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // NOUVEAU : Cartes de services générées dynamiquement
                                ..._services.map((service) => Column(
                                      children: [
                                        _buildServiceCard(
                                          title: service['title'],
                                          description: service['description'],
                                          price: _getFormattedPrice(
                                              tarifsData, service['apiKey']),
                                          color: service['color'],
                                          icon: service['icon'],
                                          features: service['features'],
                                          onTap: () => _navigateToVehicle(
                                              service['title'],
                                              service['apiKey']),
                                        ),
                                        if (_services.indexOf(service) <
                                            _services.length - 1)
                                          const SizedBox(height: 16),
                                      ],
                                    )),
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

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: _cardColor2,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchTarifs,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
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
}
