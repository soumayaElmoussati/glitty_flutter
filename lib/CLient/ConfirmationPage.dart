// lib/CLient/ConfirmationPage.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ConfirmationPage extends StatelessWidget {
  final dynamic notificationData;
  final Map<String, dynamic>? clientData;

  const ConfirmationPage({
    super.key,
    required this.notificationData,
    this.clientData,
  });

  String _formatCreneau(String creneau) {
    switch (creneau) {
      case 'matin':
        return 'Matin';
      case 'apres_midi':
        return 'Après-midi';
      case 'soir':
        return 'Soir';
      default:
        return creneau;
    }
  }

  String _formatTypeLavage(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return 'Lavage Intérieur';
      case 'lavage_exterieur':
        return 'Lavage Extérieur';
      case 'lavage_complet':
        return 'Lavage Complet';
      default:
        return typeLavage;
    }
  }

  String _formatDisplayDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    // Extraction des données de la notification
    final metadata = notificationData['metadata'] ?? {};
    final washerName = metadata['washer_name'] ?? 'Notre washer';
    final typeLavage = metadata['type_lavage'] ?? 'lavage_complet';
    final prix = metadata['prix'] ?? '0';
    final date = metadata['date'] ?? '';
    final creneau = metadata['creneau'] ?? '';
    final washerPhone = metadata['washer_phone'] ?? '';

    return Scaffold(
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure
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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                          'assets/menu-icone.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
                      ),
                      Image.asset(
                        'assets/logo-glitty.png',
                        width: 149,
                        height: 69,
                      ),
                      GestureDetector(
                        onTap: () {
                          // Option: Naviguer vers les notifications
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          'assets/notification-icone.png',
                          width: 24,
                          height: 24,
                          color: Colors.white,
                        ),
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
                                height: 46 / 36,
                                letterSpacing: -1.6,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Paragraphe dynamique
                            Text(
                              "Votre commande a été acceptée par $washerName.\nSi vous rencontrez un problème, contactez-nous au (+1) 999 999 999",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF9A9A9A),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 24 / 14,
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // "VOTRE WASHER"
                            Text(
                              washerName.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF797979),
                                fontFamily: "DM Sans",
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                height: 24 / 10,
                                letterSpacing: 1.4,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Informations dynamiques de la commande
                            Column(
                              children: [
                                Text(
                                  "${_formatTypeLavage(typeLavage)} • ${prix}€",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "DM Sans",
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 24 / 14,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${_formatDisplayDate(date)} • ${_formatCreneau(creneau)}",
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF1B1D21),
                                    fontFamily: "DM Sans",
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 24 / 12,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                if (washerPhone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Contact: $washerPhone",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF1B1D21),
                                      fontFamily: "DM Sans",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      height: 24 / 12,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 32),

                            // Carte pour afficher plus de détails
                            Container(
                              width: 295,
                              height: 181,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8E8E8).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(44),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.local_car_wash_rounded,
                                    size: 40,
                                    color: dark.withOpacity(0.6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _formatTypeLavage(typeLavage),
                                    style: TextStyle(
                                      color: dark,
                                      fontFamily: "DM Sans",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Votre washer $washerName arrive bientôt !",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF797979),
                                      fontFamily: "DM Sans",
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
