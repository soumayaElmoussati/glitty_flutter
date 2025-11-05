import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glitty/CLient/LoginPage.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WelcomePage.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < 2) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WelcomePage()),
        );
      }
    });
  }

  // Fonction pour passer à la page suivante
  void _goToNextPage() {
    if (_currentPage < 2) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // Fonction pour aller à la page Welcome en tant que client
  void _goToWelcomeAsClient() {
    _timer.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // Fonction pour aller à la page Welcome en tant que washer
  void _goToWelcomeAsWasher() {
    _timer.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginWasherPage()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double halfHeight = screenHeight * 0.5; // 50% de la hauteur écran

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Column(
            children: [
              // Partie haute (50% de l'écran)
              SizedBox(
                height: halfHeight,
                child: Container(
                  decoration: _buildTopDecoration(index),
                  child: Center(
                    child: _buildTopImage(index),
                  ),
                ),
              ),

              // Partie basse
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Texte selon la page
                      if (index == 0) ...[
                        const SizedBox(height: 40),
                        const Text(
                          "Choisir un lavage",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 30,
                            letterSpacing: -0.8,
                            height: 1.6,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Choisissez le service qui correspond à vos besoins : lavage intérieur, extérieur ou formule premium pour un nettoyage complet.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ] else if (index == 1) ...[
                        const SizedBox(height: 40),
                        const Text(
                          "Choisir un créneau",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 30,
                            letterSpacing: -0.8,
                            height: 1.6,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Réservez facilement la date et heure qui vous conviennent, directement depuis l'application.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ] else if (index == 2) ...[
                        const SizedBox(height: 40),
                        const Text(
                          "Washer sur la route",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 30,
                            letterSpacing: -0.8,
                            height: 1.6,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Une fois votre demande confirmée, un washer se rendra à l'adresse indiquée pour effectuer le lavage choisi, en toute simplicité.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontStyle: FontStyle.normal,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // ---- Indicateurs ----
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (dotIndex) {
                            bool isActive = dotIndex == index;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: isActive ? 28 : 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFF4FBF67)
                                    : const Color(0xFFE2E2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ---- Boutons ----
                      if (index == 0 || index == 1)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FBF67),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _goToNextPage,
                            child: const Text(
                              "Suivant",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else if (index == 2) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FBF67),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _goToWelcomeAsClient,
                            child: const Text(
                              "Êtes-vous client ?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6628),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            onPressed: _goToWelcomeAsWasher,
                            child: const Text(
                              "Êtes-vous un Washer ?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopImage(int index) {
    switch (index) {
      case 0:
        return Image.asset(
          'assets/onboarding-1.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        );
      case 1:
        return Image.asset(
          'assets/onboarding-2.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        );
      case 2:
        return Image.asset(
          'assets/onboarding-3.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  BoxDecoration _buildTopDecoration(int index) {
    switch (index) {
      case 0:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFFB180),
              Color(0xFF5DA0D3),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        );
      case 1:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF7AC2EB),
              Color(0xFF2299DD),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        );
      case 2:
        return const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF77FFA2),
              Color(0xFF299CC2),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        );
      default:
        return const BoxDecoration(color: Colors.white);
    }
  }
}
