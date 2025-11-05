import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glitty/CLient/AjouterVehicule.dart';
import 'package:glitty/CLient/LocalisationChoix.dart';
import 'package:glitty/CLient/LocationPage.dart';
import 'package:glitty/CLient/MesCommandesPage.dart';
import 'package:glitty/CLient/MesTickets.dart';
import 'package:glitty/CLient/MonProfile.dart';
import 'package:glitty/CLient/ParrainagePage.dart';
import 'package:glitty/CLient/PortefeuillePage.dart';
import 'package:glitty/CLient/ReserverLavagePage.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'RecapCommande.dart';
import 'ClientAccueil.dart';

class ChoisirCreneau extends StatefulWidget {
  final int clientId;
  final String typeLavage;
  final Map<String, dynamic>? vehicleData;
  final Map<String, dynamic>? clientData;
  final List<File>? photos;
  final String? token;

  const ChoisirCreneau({
    super.key,
    required this.clientId,
    required this.typeLavage,
    this.vehicleData,
    this.clientData,
    this.photos,
    this.token,
  });

  @override
  State<ChoisirCreneau> createState() => _ChoisirCreneauState();
}

class _ChoisirCreneauState extends State<ChoisirCreneau> {
  String selectedDate = "8"; // Date sélectionnée par défaut
  String selectedTime = "matin"; // Option sélectionnée par défaut
  String selectedHour = "08"; // Heure par défaut
  String selectedMinute = "00"; // Minute par défaut
  int _currentIndex = 0;

  // Contrôleurs pour les champs de saisie
  final TextEditingController _hourController = TextEditingController();
  final TextEditingController _minuteController = TextEditingController();

  // Fonction pour formater la date au format YYYY-MM-DD
  String _getFormattedDate() {
    final now = DateTime.now();
    final selectedDay = int.parse(selectedDate);

    // Calculer le mois et l'année corrects en fonction du jour sélectionné
    DateTime selectedDateTime;

    // Si le jour est inférieur au jour actuel, on suppose que c'est le mois suivant
    if (selectedDay < now.day) {
      selectedDateTime = DateTime(now.year, now.month + 1, selectedDay);
    } else {
      selectedDateTime = DateTime(now.year, now.month, selectedDay);
    }

    return "${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}";
  }

  // Fonction pour convertir le créneau en format API
  String _getCreneauForAPI() {
    switch (selectedTime) {
      case "matin":
        return "matin";
      case "apres-midi":
        return "apres_midi";
      default:
        return "matin";
    }
  }

  // Fonction pour obtenir le nom du mois actuel
  String _getCurrentMonth() {
    final now = DateTime.now();
    final selectedDay = int.parse(selectedDate);

    DateTime selectedDateTime;
    if (selectedDay < now.day) {
      selectedDateTime = DateTime(now.year, now.month + 1, selectedDay);
    } else {
      selectedDateTime = DateTime(now.year, now.month, selectedDay);
    }

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

    return months[selectedDateTime.month - 1];
  }

  // Fonction pour valider et formater l'heure
  void _validateAndSetTime() {
    String hour = _hourController.text;
    String minute = _minuteController.text;

    // Validation de l'heure
    if (hour.isEmpty) hour = "08";
    int hourInt = int.tryParse(hour) ?? 8;
    if (hourInt < 8) hourInt = 8;
    if (hourInt > 23) hourInt = 23;
    if (selectedTime == "matin" && hourInt > 11) hourInt = 11;
    if (selectedTime == "apres-midi" && hourInt < 12) hourInt = 12;

    // Validation des minutes
    if (minute.isEmpty) minute = "00";
    int minuteInt = int.tryParse(minute) ?? 0;
    if (minuteInt < 0) minuteInt = 0;
    if (minuteInt > 59) minuteInt = 59;

    setState(() {
      selectedHour = hourInt.toString().padLeft(2, '0');
      selectedMinute = minuteInt.toString().padLeft(2, '0');
      _hourController.text = selectedHour;
      _minuteController.text = selectedMinute;
    });
  }

  // Fonction pour obtenir l'heure formatée
  String _getFormattedTime() {
    return "$selectedHour:$selectedMinute";
  }

  void _navigateToLocation() {
    final formattedDate = _getFormattedDate();
    final creneauForAPI = _getCreneauForAPI();
    final formattedTime = _getFormattedTime();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPage(
          clientId: widget.clientId,
          typeLavage: widget.typeLavage,
          vehicleData: widget.vehicleData,
          clientData: widget.clientData,
          date: formattedDate,
          creneau: creneauForAPI,
          //  heurePrecise: formattedTime,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Initialiser les contrôleurs avec les valeurs par défaut
    _hourController.text = selectedHour;
    _minuteController.text = selectedMinute;
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  // AJOUT: Méthode pour construire le Drawer
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
      // AJOUT: Drawer ici
      drawer: _buildClientDrawer(context),
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
                      // AJOUT: Builder pour accéder au contexte du Scaffold
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
                      // AJOUT: Bouton de retour avec flèche complète
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AjouterVehicule(
                                clientId: widget.clientId,
                                typeLavage: widget.typeLavage,
                                typePrestation: widget.typeLavage,
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
                          child: const Icon(
                            Icons.arrow_back_rounded, // Flèche complète
                            color: Color(0xFF022519),
                            size: 24, // Taille augmentée
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
                      const Text(
                        "Choisir un créneau",
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
                      const SizedBox(height: 20),

                      // Calendrier
                      Container(
                        width: 295,
                        height: 300,
                        child: Column(
                          children: [
                            // MOIS AU-DESSUS DU CALENDRIER
                            Container(
                              height: 50,
                              child: Center(
                                child: Text(
                                  _getCurrentMonth().toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF022519),
                                    fontFamily: "DM Sans",
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ),

                            // Header avec les jours de la semaine
                            Container(
                              height: 40,
                              child: const Row(
                                children: [
                                  _DayHeader(day: "Lun"),
                                  _DayHeader(day: "Mar"),
                                  _DayHeader(day: "Mer"),
                                  _DayHeader(day: "Jeu"),
                                  _DayHeader(day: "Ven"),
                                  _DayHeader(day: "Sam"),
                                  _DayHeader(day: "Dim"),
                                ],
                              ),
                            ),

                            // Corps du calendrier
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    // Première ligne
                                    Row(
                                      children: [
                                        _CalendarDay(
                                          number: "26",
                                          isSelected: selectedDate == "26",
                                          onTap: () => _selectDate("26"),
                                        ),
                                        _CalendarDay(
                                          number: "27",
                                          isSelected: selectedDate == "27",
                                          onTap: () => _selectDate("27"),
                                        ),
                                        _CalendarDay(
                                          number: "28",
                                          isSelected: selectedDate == "28",
                                          onTap: () => _selectDate("28"),
                                        ),
                                        _CalendarDay(
                                          number: "29",
                                          isSelected: selectedDate == "29",
                                          onTap: () => _selectDate("29"),
                                        ),
                                        _CalendarDay(
                                          number: "30",
                                          isSelected: selectedDate == "30",
                                          onTap: () => _selectDate("30"),
                                        ),
                                        _CalendarDay(
                                          number: "31",
                                          isSelected: selectedDate == "31",
                                          onTap: () => _selectDate("31"),
                                        ),
                                        _CalendarDay(
                                          number: "1",
                                          isSelected: selectedDate == "1",
                                          onTap: () => _selectDate("1"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Deuxième ligne
                                    Row(
                                      children: [
                                        _CalendarDay(
                                          number: "2",
                                          isSelected: selectedDate == "2",
                                          onTap: () => _selectDate("2"),
                                        ),
                                        _CalendarDay(
                                          number: "3",
                                          isSelected: selectedDate == "3",
                                          onTap: () => _selectDate("3"),
                                        ),
                                        _CalendarDay(
                                          number: "4",
                                          isSelected: selectedDate == "4",
                                          onTap: () => _selectDate("4"),
                                        ),
                                        _CalendarDay(
                                          number: "5",
                                          isSelected: selectedDate == "5",
                                          onTap: () => _selectDate("5"),
                                        ),
                                        _CalendarDay(
                                          number: "6",
                                          isSelected: selectedDate == "6",
                                          onTap: () => _selectDate("6"),
                                        ),
                                        _CalendarDay(
                                          number: "7",
                                          isSelected: selectedDate == "7",
                                          onTap: () => _selectDate("7"),
                                        ),
                                        _CalendarDay(
                                          number: "8",
                                          isSelected: selectedDate == "8",
                                          onTap: () => _selectDate("8"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Troisième ligne
                                    Row(
                                      children: [
                                        _CalendarDay(
                                          number: "9",
                                          isSelected: selectedDate == "9",
                                          onTap: () => _selectDate("9"),
                                        ),
                                        _CalendarDay(
                                          number: "10",
                                          isSelected: selectedDate == "10",
                                          onTap: () => _selectDate("10"),
                                        ),
                                        _CalendarDay(
                                          number: "11",
                                          isSelected: selectedDate == "11",
                                          onTap: () => _selectDate("11"),
                                        ),
                                        _CalendarDay(
                                          number: "12",
                                          isSelected: selectedDate == "12",
                                          onTap: () => _selectDate("12"),
                                        ),
                                        _CalendarDay(
                                          number: "13",
                                          isSelected: selectedDate == "13",
                                          onTap: () => _selectDate("13"),
                                        ),
                                        _CalendarDay(
                                          number: "14",
                                          isSelected: selectedDate == "14",
                                          onTap: () => _selectDate("14"),
                                        ),
                                        _CalendarDay(
                                          number: "15",
                                          isSelected: selectedDate == "15",
                                          onTap: () => _selectDate("15"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Quatrième ligne
                                    Row(
                                      children: [
                                        _CalendarDay(
                                          number: "16",
                                          isSelected: selectedDate == "16",
                                          onTap: () => _selectDate("16"),
                                        ),
                                        _CalendarDay(
                                          number: "17",
                                          isSelected: selectedDate == "17",
                                          onTap: () => _selectDate("17"),
                                        ),
                                        _CalendarDay(
                                          number: "18",
                                          isSelected: selectedDate == "18",
                                          onTap: () => _selectDate("18"),
                                        ),
                                        _CalendarDay(
                                          number: "19",
                                          isSelected: selectedDate == "19",
                                          onTap: () => _selectDate("19"),
                                        ),
                                        _CalendarDay(
                                          number: "20",
                                          isSelected: selectedDate == "20",
                                          onTap: () => _selectDate("20"),
                                        ),
                                        _CalendarDay(
                                          number: "21",
                                          isSelected: selectedDate == "21",
                                          onTap: () => _selectDate("21"),
                                        ),
                                        _CalendarDay(
                                          number: "22",
                                          isSelected: selectedDate == "22",
                                          onTap: () => _selectDate("22"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Cinquième ligne
                                    Row(
                                      children: [
                                        _CalendarDay(
                                          number: "23",
                                          isSelected: selectedDate == "23",
                                          onTap: () => _selectDate("23"),
                                        ),
                                        _CalendarDay(
                                          number: "24",
                                          isSelected: selectedDate == "24",
                                          onTap: () => _selectDate("24"),
                                        ),
                                        _CalendarDay(
                                          number: "25",
                                          isSelected: selectedDate == "25",
                                          onTap: () => _selectDate("25"),
                                        ),
                                        _CalendarDay(
                                          number: "26",
                                          isSelected: selectedDate == "26",
                                          onTap: () => _selectDate("26"),
                                        ),
                                        _CalendarDay(
                                          number: "27",
                                          isSelected: selectedDate == "27",
                                          onTap: () => _selectDate("27"),
                                        ),
                                        _CalendarDay(
                                          number: "28",
                                          isSelected: selectedDate == "28",
                                          onTap: () => _selectDate("28"),
                                        ),
                                        _CalendarDay(
                                          number: "29",
                                          isSelected: selectedDate == "29",
                                          onTap: () => _selectDate("29"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Titre "Pick time"
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Choisir l'horaire",
                          style: TextStyle(
                            color: Color(0xFF040415),
                            fontFamily: "DM Sans",
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Options Matin et Après-midi - CENTRÉES
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Option Matin
                            _TimeOption(
                              text: "Matin",
                              isSelected: selectedTime == "matin",
                              onTap: () {
                                _selectTime("matin");
                                // Ajuster l'heure pour le matin
                                if (int.parse(selectedHour) > 11) {
                                  selectedHour = "08";
                                  _hourController.text = selectedHour;
                                }
                                _validateAndSetTime();
                              },
                              width: 120,
                            ),
                            const SizedBox(width: 12),
                            // Option Après-midi
                            _TimeOption(
                              text: "Après-midi",
                              isSelected: selectedTime == "apres-midi",
                              onTap: () {
                                _selectTime("apres-midi");
                                // Ajuster l'heure pour l'après-midi
                                if (int.parse(selectedHour) < 12) {
                                  selectedHour = "12";
                                  _hourController.text = selectedHour;
                                }
                                _validateAndSetTime();
                              },
                              width: 140,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Sélection de l'heure précise avec inputs
                      Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: const Text(
                          "Choisir l'heure précise",
                          style: TextStyle(
                            color: Color(0xFF040415),
                            fontFamily: "DM Sans",
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 26 / 16,
                            letterSpacing: -0.356,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Inputs pour l'heure et les minutes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Input Heure
                          Container(
                            width: 80,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color.fromRGBO(143, 146, 161, 0.05),
                            ),
                            child: TextField(
                              controller: _hourController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 2,
                              decoration: InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                hintText: "HH",
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(143, 146, 161, 0.6),
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF1B1D21),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              onChanged: (value) {
                                _validateAndSetTime();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            ":",
                            style: TextStyle(
                              color: Color(0xFF1B1D21),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Input Minutes
                          Container(
                            width: 80,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color.fromRGBO(143, 146, 161, 0.05),
                            ),
                            child: TextField(
                              controller: _minuteController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 2,
                              decoration: InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                                hintText: "MM",
                                hintStyle: const TextStyle(
                                  color: Color.fromRGBO(143, 146, 161, 0.6),
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                              ),
                              style: const TextStyle(
                                color: Color(0xFF1B1D21),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                              ),
                              onChanged: (value) {
                                _validateAndSetTime();
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),
                      Text(
                        selectedTime == "matin"
                            ? "Heures disponibles: 08h - 11h"
                            : "Heures disponibles: 12h - 17h",
                        style: const TextStyle(
                          color: Color(0xFF8F92A1),
                          fontFamily: "DM Sans",
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Affichage de la sélection actuelle
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(top: 20, bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Créneau sélectionné:",
                              style: TextStyle(
                                color: Color(0xFF022519),
                                fontFamily: "DM Sans",
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Le ${selectedDate} ${_getCurrentMonth()} - ${_getTimeDisplay(selectedTime)} - ${_getFormattedTime()}",
                              style: const TextStyle(
                                color: Color(0xFF4FBF67),
                                fontFamily: "DM Sans",
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bouton Suivant centré
                      GestureDetector(
                        onTap: _navigateToLocation,
                        child: Center(
                          child: Container(
                            width: 295,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFF4FBF67),
                            ),
                            child: const Center(
                              child: Text(
                                "Suivant",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: "DM Sans",
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 24 / 14,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                          ),
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
      // AJOUT: Bottom Navigation Bar ici
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  void _selectDate(String date) {
    setState(() {
      selectedDate = date;
    });
  }

  void _selectTime(String time) {
    setState(() {
      selectedTime = time;
    });
  }

  String _getLavageTitle(String typeLavage) {
    switch (typeLavage) {
      case 'lavage_interieur':
        return "Lavage Intérieur";
      case 'lavage_exterieur':
        return "Lavage Extérieur";
      case 'lavage_complet':
        return "Lavage Premium";
      default:
        return typeLavage;
    }
  }

  String _getTimeDisplay(String time) {
    switch (time) {
      case "matin":
        return "Matin (8h-12h)";
      case "apres-midi":
        return "Après-midi (12h-17h)";
      default:
        return time;
    }
  }
}

// Widget pour les en-têtes des jours
class _DayHeader extends StatelessWidget {
  final String day;

  const _DayHeader({required this.day});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        child: Text(
          day,
          style: const TextStyle(
            color: Color(0xFF4FBF67),
            fontFamily: "DM Sans",
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 17 / 12,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}

// Widget pour les jours du calendrier
class _CalendarDay extends StatelessWidget {
  final String number;
  final bool isSelected;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.number,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          child: isSelected
              ? Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF4FBF67),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      number,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: "DM Sans",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Text(
                  number,
                  style: const TextStyle(
                    color: Color(0xFF1B1D21),
                    fontFamily: "DM Sans",
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// Widget pour les options de temps
class _TimeOption extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const _TimeOption({
    required this.text,
    required this.isSelected,
    required this.onTap,
    this.width = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(90),
          color: isSelected ? const Color(0xFF4FBF67) : Colors.transparent,
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4FBF67) : const Color(0xFFE6E8EC),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1B1D21),
              fontFamily: "DM Sans",
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
