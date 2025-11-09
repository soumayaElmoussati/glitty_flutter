import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:glitty/CLient/MonCagnotte.dart';
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

class EditProfile extends StatefulWidget {
  final Map<String, dynamic>? clientData;
  final String? token;
  const EditProfile({super.key, this.clientData, this.token});

  @override
  State<EditProfile> createState() => _EditProfileContentState();
}

class _EditProfileContentState extends State<EditProfile> {
  // Contrôleurs pour les champs du formulaire
  TextEditingController _prenomController = TextEditingController();
  TextEditingController _nomController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _telephoneController = TextEditingController();
  TextEditingController _adresseController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-remplir les champs avec les données existantes
    _prenomController.text = widget.clientData?['first_name'] ?? '';
    _nomController.text = widget.clientData?['last_name'] ?? '';
    _emailController.text = widget.clientData?['email'] ?? '';
    _telephoneController.text = widget.clientData?['phone'] ?? '';
    _adresseController.text = widget.clientData?['address'] ?? '';
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  // Méthode pour construire un champ de formulaire
  Widget _buildFormField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B1D21),
              fontFamily: "DM Sans",
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                hintText: "Entrez votre $label",
                hintStyle: const TextStyle(
                  color: Color(0xFF8F92A1),
                  fontFamily: "DM Sans",
                  fontSize: 14,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF1B1D21),
                fontFamily: "DM Sans",
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Méthode pour sauvegarder le profil via API
  Future<void> _sauvegarderProfil() async {
    // Récupérer les valeurs des champs
    final String prenom = _prenomController.text;
    final String nom = _nomController.text;
    final String email = _emailController.text;
    final String telephone = _telephoneController.text;
    final String adresse = _adresseController.text;

    // Validation basique
    if (prenom.isEmpty || nom.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final clientId = widget.clientData?['id'];
      if (clientId == null) {
        throw Exception('ID client non trouvé');
      }

      final response = await http.put(
        Uri.parse('${Env.baseUrl}/api/client/client/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode({
          'first_name': prenom,
          'last_name': nom,
          'email': email,
          'phone': telephone,
          'address': adresse,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                responseData['message'] ?? "Profil mis à jour avec succès!"),
            backgroundColor: Colors.green,
          ),
        );

        // Mettre à jour les données locales
        final updatedClient = responseData['data'];

        // Sauvegarder les nouvelles données dans SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData', json.encode(updatedClient));

        // CORRECTION : Retourner les données mises à jour à la page précédente
        if (mounted) {
          Navigator.of(context).pop(updatedClient);
        }
      } else {
        throw Exception(
            responseData['message'] ?? 'Erreur lors de la mise à jour');
      }
    } catch (error) {
      print('Erreur mise à jour profil: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ClientAccueil(
                              clientData: widget.clientData,
                              token: widget.token,
                            ),
                          ),
                          (route) => false,
                        );
                      },
                    ),
                    _buildDrawerItem(
                      Icons.shopping_bag_rounded,
                      "Mes commandes",
                      false,
                      dark,
                      () {
                        Navigator.push(
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
                      false,
                      dark,
                      () {
                        Navigator.push(
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
                    ),
                    _buildDrawerItem(
                      Icons.person_rounded,
                      "Mon profil",
                      true,
                      dark,
                      () {
                        Navigator.pop(context);
                      },
                    ),
                    _buildDrawerItem(
                      Icons.people_rounded,
                      "Parrainage",
                      false,
                      dark,
                      () {
                        Navigator.push(
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
          // Icône Home
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => ClientAccueil(
                    clientData: widget.clientData,
                    token: widget.token,
                  ),
                ),
                (route) => false,
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
                  'assets/icone-home.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PortefeuillePage(
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
                  'assets/icone3.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.grey[400],
                ),
              ),
            ),
          ),

          // Icône Profil - ACTIVE
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
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
                  'assets/icone4.svg',
                  width: iconSize,
                  height: iconSize,
                  color: Colors.white,
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
                        // Titre de la page
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 30),
                          child: const Text(
                            "Modifier le profil",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF1B1D21),
                              fontFamily: "DM Sans",
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),

                        // Formulaire avec prénom et nom séparés
                        _buildFormField("Prénom", _prenomController),
                        _buildFormField("Nom", _nomController),
                        _buildFormField("Email", _emailController,
                            keyboardType: TextInputType.emailAddress),
                        _buildFormField(
                            "Numéro de téléphone", _telephoneController,
                            keyboardType: TextInputType.phone),
                        _buildFormField("Adresse", _adresseController),

                        const SizedBox(height: 30),

                        // Bouton Sauvegarder avec indicateur de chargement
                        SizedBox(
                          width: 295,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _sauvegarderProfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FBF67),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Sauvegarder",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "DM Sans",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
}
