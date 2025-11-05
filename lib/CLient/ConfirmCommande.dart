import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'LocalisationChoix.dart';
import 'ConfirmationPage.dart'; // Importez la page ConfirmationPage

class ConfirmCommandePage extends StatelessWidget {
  final Map<String, dynamic> commandeData; // AJOUT DU PARAMÈTRE

  const ConfirmCommandePage({
    super.key,
    required this.commandeData, // AJOUT DU PARAMÈTRE REQUIS
  });

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
                      // Contenu principal avec margin top
                      Container(
                        margin: const EdgeInsets.only(top: 40), // Margin top
                        child: Column(
                          children: [
                            // Image SVG au centre
                            SvgPicture.asset(
                              'assets/Shield.svg',
                              width: 120,
                              height: 120,
                            ),

                            const SizedBox(height: 32),

                            // Titre "Commande passée"
                            const Text(
                              "Commande passée",
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
                              "Votre commande a été passée avec succès.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF797979),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 24 / 14, // 171.429%
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 40), // Grand margin top

                            // Affichage des données de la commande (OPTIONNEL)
                            if (commandeData.isNotEmpty)
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
                                      "ID: ${commandeData['id'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      "Statut: ${commandeData['statut'] ?? 'N/A'}",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      "Prix: ${commandeData['prix'] ?? 'N/A'}€",
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    // Ajoutez d'autres champs selon votre structure de données
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // "Demain à 10h00 précises" (vous pouvez dynamiser cette partie)
                            Text(
                              _getScheduleText(
                                  commandeData), // Fonction pour obtenir le texte dynamique
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF1B1D21),
                                fontFamily: "DM Sans",
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 17 / 12, // 141.667%
                                letterSpacing: -0.3,
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Bouton "Ajouter au calendrier"
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

                            // Bouton "Profil" en bas
                            GestureDetector(
                              onTap: () {
                                // Navigation vers ConfirmationPage
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ConfirmationPage(),
                                  ),
                                );
                              },
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
    );
  }

  // Fonction pour obtenir le texte d'horaire dynamique
  String _getScheduleText(Map<String, dynamic> commandeData) {
    // Vous pouvez adapter cette fonction selon la structure de vos données
    final date = commandeData['date'] ?? '';
    final creneau = commandeData['creneau'] ?? '';

    if (date.isNotEmpty && creneau.isNotEmpty) {
      return "Le ${_formatDate(date)} - ${_formatCreneau(creneau)}";
    }

    return "Demain à 10h00 précises"; // Valeur par défaut
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
