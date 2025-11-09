import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:glitty/config/env.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glitty/CLient/ClientAccueil.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import '../WelcomePage.dart';

class MonCagnotte extends StatefulWidget {
  final Map<String, dynamic>? clientData;
  final String? token;
  const MonCagnotte({super.key, this.clientData, this.token});

  @override
  State<MonCagnotte> createState() => _MonCagnotteContentState();
}

class _MonCagnotteContentState extends State<MonCagnotte> {
  List<dynamic> offers = [];
  double solde = 0.0;
  bool isLoading = true;
  bool isLoadingSolde = true;
  String? error;
  String? errorSolde;

  // Variables pour la gestion de la quantité
  TextEditingController quantityController = TextEditingController();
  int quantity = 0;
  double? bonusAmount;
  int _currentIndex = 2; // Index pour Portefeuille

  @override
  void initState() {
    super.initState();
    _loadData();
    quantityController.text = quantity.toString();
    quantityController.addListener(_calculateNewSolde);
  }

  @override
  void dispose() {
    quantityController.dispose();
    super.dispose();
  }

  // MÉTHODE AMÉLIORÉE : Vérification Stripe pour Android
  Future<bool> _isStripeConfigured() async {
    try {
      print(
          '🔍 Vérification Stripe - Plateforme: ${kIsWeb ? 'Web' : 'Android'}');

      // Vérification de base
      if (Stripe.publishableKey.isEmpty) {
        print('❌ Clé Stripe non définie');
        return false;
      }

      if (!Stripe.publishableKey.startsWith('pk_')) {
        print('❌ Format de clé invalide');
        return false;
      }

      // Pour Android, vérification plus poussée
      if (!kIsWeb) {
        if (Stripe.merchantIdentifier!.isEmpty) {
          print('⚠️ Merchant Identifier non défini pour Android');
        }
        if (Stripe.urlScheme!.isEmpty) {
          print('⚠️ URL Scheme non défini pour Android');
        }
      }

      // Test d'application des paramètres
      await Stripe.instance.applySettings();

      print('✅ Stripe configuré pour ${kIsWeb ? 'web' : 'Android'}');
      return true;
    } catch (e) {
      print('❌ Erreur configuration Stripe: $e');

      // Sur Android, on peut tenter une reconfiguration
      if (!kIsWeb) {
        return await _reconfigureStripe();
      }

      return false;
    }
  }

  // Reconfiguration pour Android
  Future<bool> _reconfigureStripe() async {
    try {
      print('🔄 Tentative de reconfiguration Stripe pour Android...');

      Stripe.publishableKey =
          'pk_test_51Oc5eADpYkFJXArEDbkqigIGvAtDGcBHk1QRrWNMflzNugw7Ef6xhk3feNN9EG8PTx3cavbIAR28rRQBnzbAb5jK00x6vblvxj';
      Stripe.merchantIdentifier = 'merchant.flutter.stripe';
      Stripe.urlScheme = 'flutterstripe';

      await Stripe.instance.applySettings();

      print('✅ Stripe reconfiguré avec succès');
      return true;
    } catch (e) {
      print('❌ Échec reconfiguration: $e');
      return false;
    }
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadOffers(),
      _loadSolde(),
    ]);
  }

  Future<void> _loadOffers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/offert/all-offerts'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            offers = data['data']['offers'];
          });
        } else {
          throw Exception('Erreur API: ${data['message']}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadSolde() async {
    try {
      setState(() {
        isLoadingSolde = true;
        errorSolde = null;
      });

      final clientId = widget.clientData?['id'];
      if (clientId == null) {
        throw Exception('ID client non trouvé');
      }

      final response = await http.get(
        Uri.parse('${Env.baseUrl}/api/solde/$clientId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            // CORRECTION: Conversion sécurisée du solde
            if (data['solde'] is int) {
              solde = (data['solde'] as int).toDouble();
            } else if (data['solde'] is double) {
              solde = data['solde'];
            } else if (data['solde'] is String) {
              solde = double.tryParse(data['solde']) ?? 0.0;
            } else {
              solde = 0.0;
            }
          });
        } else {
          throw Exception('Erreur API solde: ${data['message']}');
        }
      } else {
        throw Exception('Erreur HTTP solde: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorSolde = e.toString();
      });
    } finally {
      setState(() {
        isLoadingSolde = false;
      });
    }
  }

  void _calculateNewSolde() {
    final inputValue = int.tryParse(quantityController.text) ?? 0;
    setState(() {
      quantity = inputValue;
      bonusAmount = _calculateBonus(quantity);
    });
  }

  double? _calculateBonus(int amount) {
    if (amount <= 0) return null;

    for (var offer in offers) {
      final prix = offer['prix']?.toDouble() ?? 0.0;
      if (amount == prix.toInt()) {
        return offer['offer']?.toDouble() ?? 0.0;
      }
    }
    return null;
  }

  void _incrementQuantity() {
    setState(() {
      quantity++;
      quantityController.text = quantity.toString();
    });
    _calculateNewSolde();
  }

  void _decrementQuantity() {
    if (quantity > 0) {
      setState(() {
        quantity--;
        quantityController.text = quantity.toString();
      });
      _calculateNewSolde();
    }
  }

  double get _newSolde {
    final bonus = bonusAmount ?? 0.0;
    return solde + quantity + bonus;
  }

  // AJOUT: Méthode pour construire le Drawer (sidebar)
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MesCommandesPage(
                              clientId: widget.clientData?['id'] ?? 1,
                              clientData: widget.clientData,
                              token: widget.token,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Portefeuille",
                      true,
                      dark,
                      () {
                        Navigator.pop(context);
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
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ParrainagePage(
                              clientId: widget.clientData?['id'] ?? 1,
                              clientData: widget.clientData,
                              token: widget.token,
                            ),
                          ),
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
                        // Ajouter la navigation vers la page d'aide
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
                    token: widget.token,
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

          // Icône Portefeuille
          GestureDetector(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PortefeuillePage(
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
            // Partie supérieure - Header identique aux autres pages
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
                              builder: (context) => PortefeuillePage(
                                clientData: widget.clientData,
                                token: widget.token,
                                clientId: widget.clientData?['id'],
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

            // Partie inférieure blanche avec borderRadius top
            Expanded(
              child: Stack(
                children: [
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            "Recharger votre Cagnotte",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1B1D21),
                              fontFamily: "DM Sans",
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 26 / 16,
                              letterSpacing: -0.356,
                            ),
                          ),
                        ),
                        if (isLoading)
                          const Center(child: CircularProgressIndicator())
                        else if (error != null)
                          Column(
                            children: [
                              Text(
                                'Erreur offres: $error',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadOffers,
                                child: Text('Réessayer'),
                              ),
                            ],
                          )
                        else if (offers.isEmpty)
                          Text(
                            'Aucune offre disponible',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          )
                        else
                          _buildOffersGrid(),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 30),
                          height: 1,
                          width: double.infinity,
                          color: Color(0xFF8F92A1).withOpacity(0.1),
                        ),
                        _buildWalletSection(),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: 295,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: quantity > 0
                                ? () {
                                    _processRecharge();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: quantity > 0
                                  ? Color(0xFF4FBF67)
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Recharger",
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: "DM Sans",
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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
          ],
        ),
      ),
      // AJOUT: Bottom Navigation Bar ici
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // TEST DE CONFIGURATION STRIPE
  Future<void> _testStripeConfiguration() async {
    final isConfigured = await _isStripeConfigured();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isConfigured
            ? '✅ Stripe configuré pour Android'
            : '❌ Stripe non configuré'),
        backgroundColor: isConfigured ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildOffersGrid() {
    List<Widget> offerRows = [];
    for (int i = 0; i < offers.length; i += 2) {
      List<Widget> rowChildren = [];

      if (i < offers.length) {
        rowChildren.add(_buildOfferCard(offers[i]));
      }

      if (i + 1 < offers.length) {
        rowChildren.add(const SizedBox(width: 16));
        rowChildren.add(_buildOfferCard(offers[i + 1]));
      }

      offerRows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: rowChildren,
        ),
      );

      if (i + 2 < offers.length) {
        offerRows.add(const SizedBox(height: 16));
      }
    }

    return Column(
      children: offerRows,
    );
  }

  Widget _buildOfferCard(Map<String, dynamic> offer) {
    // CORRECTION: Conversion sécurisée des prix
    final prix = _safeConvertToDouble(offer['prix']) ?? 0.0;
    final offerAmount = _safeConvertToDouble(offer['offer']) ?? 0.0;
    final total = prix + offerAmount;
    final isSelected = quantity == prix.toInt();

    return GestureDetector(
      onTap: () {
        setState(() {
          quantity = prix.toInt();
          quantityController.text = quantity.toString();
        });
        _calculateNewSolde();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 84,
            height: 73,
            decoration: BoxDecoration(
              color: isSelected
                  ? Color(0xFF4FBF67).withOpacity(0.2)
                  : Color(0xFFEEF7F4),
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: Color(0xFF4FBF67), width: 2)
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${prix.toInt()}€',
                  style: TextStyle(
                    color: isSelected ? Color(0xFF022519) : Color(0xFF4FBF67),
                    fontFamily: "DM Sans",
                    fontSize: 30,
                    fontWeight: FontWeight.w400,
                    height: 34 / 30,
                    letterSpacing: -0.8,
                  ),
                ),
                Text(
                  '${total.toInt()}€ recharges',
                  style: TextStyle(
                    color: isSelected ? Color(0xFF022519) : Color(0xFF171717),
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
          if (offerAmount > 0)
            Positioned(
              right: -8,
              top: -4,
              child: Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Color(0xFF4FBF67),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "+${offerAmount.toInt()}€ Offert",
                  style: TextStyle(
                    color: Color(0xFFFCFCFE),
                    fontFamily: "DM Sans",
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    height: 14 / 9,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

// NOUVELLE MÉTHODE: Conversion sécurisée en double
  double? _safeConvertToDouble(dynamic value) {
    if (value == null) return null;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value);
    return null;
  }

  Widget _buildWalletSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/wallet-icone.png',
            width: 40,
            height: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Votre Cagnotte",
                  style: TextStyle(
                    color: Color(0xFF1B1D21),
                    fontFamily: "DM Sans",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 26 / 16,
                    letterSpacing: -0.356,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLoadingSolde)
                  const CircularProgressIndicator()
                else if (errorSolde != null)
                  Text(
                    'Erreur solde',
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: "DM Sans",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 38 / 18,
                      letterSpacing: -0.4,
                    ),
                  )
                else
                  Text(
                    '${solde.toStringAsFixed(0)}€',
                    style: TextStyle(
                      color: Color.fromRGBO(0, 0, 0, 0.5),
                      fontFamily: "DM Sans",
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 38 / 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  "Nouveau Solde: ${_newSolde.toStringAsFixed(0)}€",
                  style: TextStyle(
                    color: Color.fromRGBO(0, 0, 0, 0.5),
                    fontFamily: "DM Sans",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 24 / 14,
                    letterSpacing: -0.3,
                  ),
                ),
                if (bonusAmount != null && bonusAmount! > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Dont ${bonusAmount!.toInt()}€ de bonus",
                      style: TextStyle(
                        color: Color(0xFF4FBF67),
                        fontFamily: "DM Sans",
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildQuantityControl(),
        ],
      ),
    );
  }

  Widget _buildQuantityControl() {
    return Container(
      width: 100,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(0xFFEEF7F4),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.remove, size: 16),
              onPressed: _decrementQuantity,
            ),
          ),
          Expanded(
            child: Container(
              height: 30,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: TextField(
                controller: quantityController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                  hintText: '0',
                ),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (value) {
                  _calculateNewSolde();
                },
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(0xFF4FBF67),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.add, size: 16, color: Colors.white),
              onPressed: _incrementQuantity,
            ),
          ),
        ],
      ),
    );
  }

  void _processRecharge() async {
    final totalAmount = quantity + (bonusAmount ?? 0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmer la recharge"),
        content: Text(
            "Voulez-vous recharger $quantity€ + ${bonusAmount?.toInt() ?? 0}€ de bonus = $totalAmount€ ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _initiateStripePayment();
            },
            child: Text("Payer avec Stripe"),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateStripePayment() async {
    try {
      setState(() {
        isLoading = true;
      });

      print('💰 Début paiement - Plateforme: ${kIsWeb ? 'Web' : 'Android'}');

      // VÉRIFICATION AVEC RECONFIGURATION AUTOMATIQUE
      bool isConfigured = await _isStripeConfigured();

      if (!isConfigured) {
        print('🔄 Tentative de reconfiguration automatique...');
        isConfigured = await _reconfigureStripe();
      }

      if (!isConfigured) {
        throw Exception('Stripe n\'est pas disponible sur cet appareil');
      }

      final clientId = widget.clientData?['id'];

      // 1. Créer le PaymentIntent
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientId': clientId,
          'montant': quantity,
          'bonus': bonusAmount ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          // 2. Initialiser le Payment Sheet
          await _setupPaymentSheet(data['clientSecret']);
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur initialisation paiement: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur paiement: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _setupPaymentSheet(String clientSecret) async {
    try {
      print('🔄 Configuration Payment Sheet pour Android...');

      final paymentSheetParameters = SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'Glitty',
        style: ThemeMode.light,
        primaryButtonLabel: 'Payer $quantity€',

        // Configuration d'apparence
        appearance: const PaymentSheetAppearance(
          colors: PaymentSheetAppearanceColors(
            primary: Color(0xFF022519),
            background: Colors.white,
            componentBackground: Colors.white,
            componentBorder: Color(0xFFE5E5E5),
            componentDivider: Color(0xFFE5E5E5),
            primaryText: Colors.black,
            secondaryText: Color(0xFF6B7280),
            componentText: Colors.black,
            placeholderText: Color(0xFF9CA3AF),
          ),
        ),

        // Google Pay pour Android
        googlePay: const PaymentSheetGooglePay(
          merchantCountryCode: 'FR',
          currencyCode: 'EUR',
          testEnv: true,
        ),

        customFlow: false,
        allowsDelayedPaymentMethods: false,
      );

      print('🎯 Initialisation Payment Sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: paymentSheetParameters,
      );

      print('🚀 Affichage Payment Sheet...');
      await Stripe.instance.presentPaymentSheet();

      print('✅ Paiement réussi !');
      await _confirmRecharge();
    } on StripeException catch (e) {
      print('❌ Erreur Stripe: ${e.error}');
      _handleStripeError(e);
    } catch (e) {
      print('❌ Erreur générale Payment Sheet: $e');
      _handleGenericError(e);
    }
  }

  Future<void> _confirmRecharge() async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/confirm-recharge'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientId': widget.clientData?['id'],
          'montant': quantity,
          'bonus': bonusAmount ?? 0,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Recharge effectuée avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          await _loadSolde();

          setState(() {
            quantity = 0;
            quantityController.text = '0';
            bonusAmount = null;
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Erreur confirmation: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur confirmation recharge: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la confirmation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleStripeError(StripeException e) {
    String errorMessage = 'Erreur de paiement';
    Color backgroundColor = Colors.red;

    switch (e.error?.code) {
      case FailureCode.Canceled:
        errorMessage = 'Paiement annulé';
        backgroundColor = Colors.orange;
        break;
      case FailureCode.Failed:
        errorMessage = 'Paiement échoué';
        break;
      case FailureCode.Timeout:
        errorMessage = 'Délai dépassé';
        backgroundColor = Colors.orange;
        break;
      default:
        errorMessage = 'Erreur: ${e.error?.message ?? "Veuillez réessayer"}';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: backgroundColor,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleGenericError(dynamic e) {
    print('❌ Erreur générale: $e');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
