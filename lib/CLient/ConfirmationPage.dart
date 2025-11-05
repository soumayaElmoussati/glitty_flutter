import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'LocalisationChoix.dart';

class ConfirmationPage extends StatelessWidget {
  const ConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
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

                  const SizedBox(height: 16), // Espace entre les deux lignes

                  // Deuxième ligne : barre de recherche + icône salut
                  Row(
                    children: [
                      // Barre de recherche à gauche
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical
                                .center, // Centrage vertical du texte
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
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Image.asset(
                                  'assets/search-icone.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Image.asset(
                        'assets/salut-icone.png',
                        width: 40,
                        height: 40,
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
                      // Contenu principal
                      Container(
                        margin: const EdgeInsets.only(top: 40),
                        child: Column(
                          children: [
                            // Image PNG au centre
                            SvgPicture.asset(
                              'assets/Success.svg',
                              width: 120,
                              height: 120,
                              fit: BoxFit.contain,
                            ),

                            const SizedBox(height: 32),

                            // Titre "Washer sur la route"
                            const Text(
                              "Washer sur la route",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF040415),
                                fontFamily: "DM Sans",
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                height: 46 / 36, // 127.778%
                                letterSpacing: -1.6,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Paragraphe
                            const Text(
                              "Si vous rencontrez un problème,\nn'hésitez pas à nous contacter au (+1) 999 999 999",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF9A9A9A),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 24 / 14, // 171.429%
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // "VOTRE WASHER"
                            const Text(
                              "VOTRE WASHER",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF797979),
                                fontFamily: "DM Sans",
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 24 / 10, // 240%
                                letterSpacing: 1.4,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // "Heure d'intervention : 8PM - 9PM"
                            const Text(
                              "Heure d'intervention : 8PM - 9PM",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF1B1D21),
                                fontFamily: "DM Sans",
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 24 / 12,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 32),

                            Container(
                              width: 295,
                              height: 181,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(44),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Container(
                              width: 295,
                              height: 56,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FBF67),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Text(
                                  "Page d'accueil",
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
