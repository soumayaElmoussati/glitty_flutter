import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';

class ChecklistPreparationPage extends StatefulWidget {
  final String nom;
  final int washerId;

  const ChecklistPreparationPage(
      {Key? key, required this.nom, required this.washerId})
      : super(key: key);

  @override
  _ChecklistPreparationPageState createState() =>
      _ChecklistPreparationPageState();
}

class _ChecklistPreparationPageState extends State<ChecklistPreparationPage> {
  final Map<String, bool> _checklistItems = {
    'Produits de lavage': false,
    'Éponges et chiffons': false,
    'Aspirateur portable': false,
    'Seau d\'eau': false,
    'Produits d\'entretien intérieur': false,
    'Gants de protection': false,
    'Tapis de sol': false,
    'Téléphone chargé': false,
    'GPS fonctionnel': false,
    'Moyens de paiement mobile': false,
  };

  bool get _allItemsChecked =>
      _checklistItems.values.every((checked) => checked);

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);
    const accentColor = Color(0xFF4CAF50);

    return Scaffold(
      backgroundColor: dark,
      drawer: _buildModernDrawer(context, dark, accentColor),
      body: SafeArea(
        child: Column(
          children: [
            // Partie supérieure avec menu, logo, notification - HAUTEUR RÉDUITE
            Container(
              height: 100, // ← HAUTEUR RÉDUITE pour éviter l'overflow
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12), // ← PADDING RÉDUIT
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center, // ← CENTRER LE CONTENU
                children: [
                  // Première ligne : icônes menu, logo, notification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Menu icon qui ouvre le drawer
                      Builder(
                        builder: (context) => GestureDetector(
                          onTap: () => Scaffold.of(context).openDrawer(),
                          child: Image.asset(
                            'assets/menu-icone.png',
                            width: 22, // ← TAILLE RÉDUITE
                            height: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // Logo avec taille réduite
                      Image.asset(
                        'assets/logo-glitty.png',
                        width: 100, // ← TAILLE RÉDUITE
                        height: 46,
                        fit: BoxFit.contain,
                      ),
                      // Notification avec taille réduite
                      Image.asset(
                        'assets/notification-icone.png',
                        width: 22, // ← TAILLE RÉDUITE
                        height: 22,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8), // ← ESPACE RÉDUIT
                  // Titre de la page - TEXTE PLUS PETIT
                  Text(
                    'Préparation Mission',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "DM Sans",
                      fontSize: 14, // ← TAILLE RÉDUITE
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1, // ← UNE SEULE LIGNE
                    overflow: TextOverflow.ellipsis, // ← ELLIPSIS SI TROP LONG
                  ),
                ],
              ),
            ),

            // Contenu principal
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
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: dark.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.checklist_outlined,
                              size: 50,
                              color: dark,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Vérifiez votre équipement',
                              style: TextStyle(
                                color: dark,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Assurez-vous d\'avoir tout le matériel nécessaire',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liste de vérification',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: dark,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _checklistItems.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _checklistItems.keys.elementAt(index);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _checklistItems[item]!
                                              ? Colors.green
                                              : Colors.grey[300]!,
                                          width: 2,
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          item,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            decoration: _checklistItems[item]!
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                        value: _checklistItems[item],
                                        onChanged: (bool? value) {
                                          setState(() {
                                            _checklistItems[item] =
                                                value ?? false;
                                          });
                                        },
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                        controlAffinity:
                                            ListTileControlAffinity.trailing,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _allItemsChecked
                                      ? () {
                                          Navigator.pushNamed(
                                              context, '/mission-gps');
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _allItemsChecked
                                        ? dark
                                        : Colors.grey[400],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    _allItemsChecked
                                        ? 'Commencer la mission'
                                        : 'Terminez la checklist',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  // Méthode pour construire le drawer (identique à DashboardWasherPage)
  Widget _buildModernDrawer(
      BuildContext context, Color dark, Color accentColor) {
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
                        widget.nom.isNotEmpty
                            ? widget.nom[0].toUpperCase()
                            : 'W',
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
                    widget.nom,
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
                      "● Washer",
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
                      Icons.dashboard_rounded,
                      "Dashboard",
                      false,
                      dark,
                      () => Navigator.pushNamedAndRemoveUntil(
                          context, '/dashboard', (route) => false),
                    ),
                    _buildDrawerItem(
                      Icons.notifications_rounded,
                      "Notifications",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildDrawerItem(
                      Icons.calendar_month_rounded,
                      "Planning",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.checklist_rounded,
                      "Préparation",
                      true, // Actif pour cette page
                      dark,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      dark,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      dark,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WasherSetPasswordPage())),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      dark,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => WasherSetGPSPage(
                                    washerId: widget.washerId,
                                  ))),
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
                        () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LoginWasherPage())),
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
}
