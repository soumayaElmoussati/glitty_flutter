import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ReserverLavagePage.dart';
import 'MesCommandesPage.dart';
import 'PortefeuillePage.dart';
import 'ParrainagePage.dart';
import '../WelcomePage.dart';

class ClientAccueil extends StatelessWidget {
  final Map<String, dynamic>? clientData;
  final String? token;
  
  const ClientAccueil({super.key, this.clientData, this.token});

  Future<void> _logout(BuildContext context) async {
    // Effacer les données stockées
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // Afficher un message de confirmation
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Déconnexion réussie'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Rediriger vers la page d'accueil
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: dark,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec bouton de déconnexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Bienvenue 👋",
                          style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => _logout(context),
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Se déconnecter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: "Que souhaitez-vous faire ?",
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Actions rapides",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    _menuCard(context, "Réserver un lavage", Icons.local_car_wash,
                        const ReserverLavagePage(), Colors.blue),
                    _menuCard(context, "Mes commandes", Icons.history,
                        MesCommandesPage(clientId: clientData?['id'] ?? 1), Colors.orange),
                    _menuCard(context, "Mon portefeuille",
                        Icons.account_balance_wallet, PortefeuillePage(clientId: clientData?['id'] ?? 1), Colors.green),
                    _menuCard(context, "Parrainer un ami", Icons.person_add_alt,
                        ParrainagePage(clientId: clientData?['id'] ?? 1), Colors.purple),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _menuCard(BuildContext context, String title, IconData icon,
      Widget page, Color iconColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
