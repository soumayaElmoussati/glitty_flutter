import 'dart:async';
import 'package:flutter/material.dart';
import 'package:glitty/WelcomePage.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  // Données pour chaque page d'onboarding
  final List<OnboardingPageData> _onboardingData = [
    OnboardingPageData(
      image: 'assets/onboarding1.jpeg',
      pageNumber: 'On touring 2',
      title: 'Choice your house needs in one place',
      description:
          'We provide every service to make your home experience smooth.',
      buttonText: 'Submit',
    ),
    OnboardingPageData(
      image: 'assets/onboarding1.jpeg',
      pageNumber: 'On touring 3',
      title: 'Choisir la date',
      description:
          'We provide the best transportation service and organize your furniture properly to prevent any damage.',
      buttonText: 'Submit',
    ),
    OnboardingPageData(
      image: 'assets/onboarding1.jpeg',
      pageNumber: 'On touring 7',
      title: 'Washer sur la route',
      description:
          'We provide the best transportation service and organize your furniture properly to prevent any damage. Stop your door shut.',
      buttonText: 'Submit',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_currentPage < _onboardingData.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _goToWelcomePage();
        timer.cancel();
      }
    });
  }

  void _goToWelcomePage() {
    _timer?.cancel();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const WelcomePage()),
    );
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    } else {
      _goToWelcomePage();
    }
  }

  void _skipToEnd() {
    _goToWelcomePage();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _timer?.cancel();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // PageView principal
          PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _onboardingData.asMap().entries.map((entry) {
              return _OnboardingPage(
                data: entry.value,
                pageIndex: entry.key,
                currentPage: _currentPage,
                totalPages: _onboardingData.length,
              );
            }).toList(),
          ),

          // Bouton Skip en haut à droite
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: _skipToEnd,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}

// Modèle de données pour chaque page
class OnboardingPageData {
  final String image;
  final String pageNumber;
  final String title;
  final String description;
  final String buttonText;

  OnboardingPageData({
    required this.image,
    required this.pageNumber,
    required this.title,
    required this.description,
    required this.buttonText,
  });
}

// Widget pour chaque page d'onboarding
class _OnboardingPage extends StatelessWidget {
  final OnboardingPageData data;
  final int pageIndex;
  final int currentPage;
  final int totalPages;

  const _OnboardingPage({
    required this.data,
    required this.pageIndex,
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Partie supérieure avec fond radial
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  const Color(0xFFFFB180), // FF B1 80
                  const Color(0xFF5DA0D3), // 5D A0 D3
                ],
                stops: const [0.0, 1.0],
              ),
            ),
            child: Stack(
              children: [
                // Contenu de la partie supérieure
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),

                      // Numéro de page en haut à gauche (ex: "On touring 2")
                      Text(
                        data.pageNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Titre principal
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Description
                      Text(
                        data.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Bouton Submit - SEULEMENT pour les pages 2 et 3
                      if (pageIndex >
                          0) // Afficher le bouton seulement pour les pages 2 et 3
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final state = context.findAncestorStateOfType<
                                  _OnboardingScreenState>();
                              if (pageIndex < totalPages - 1) {
                                state?._pageController.nextPage(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeInOut,
                                );
                              } else {
                                state?._goToWelcomePage();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                            ),
                            child: Text(
                              data.buttonText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // SVG centré - SEULEMENT pour la première page
                if (pageIndex == 0)
                  Center(
                    child: Container(
                      width: 294,
                      height: 294,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: _SvgPainter(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Partie inférieure blanche
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Image - SEULEMENT pour les pages 2 et 3
                if (pageIndex > 0)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(
                        data.image,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Indicateurs de page (points) centrés en bas
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentPage == index
                            ? Colors.blue
                            : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// CustomPainter pour dessiner le SVG
class _SvgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB180)
      ..style = PaintingStyle.fill;

    // Dessiner un rectangle simple comme placeholder
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );

    // Vous pouvez ajouter ici le code pour dessiner le SVG réel
    // en utilisant les données base64 fournies
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
