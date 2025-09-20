import 'package:flutter/material.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetGPS.dart';
import 'package:glitty/WasherSetPassword.dart';

class DashboardWasherPage extends StatelessWidget {
  final String nom;

  const DashboardWasherPage({Key? key, required this.nom}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A2C42);
    const accentColor = Color(0xFF4CAF50);
    const lightBackground = Color(0xFFF8FAFC);
    
    return Scaffold(
      backgroundColor: lightBackground,
      drawer: _buildModernDrawer(context, primaryColor, accentColor),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, primaryColor, accentColor),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(nom, primaryColor),
                  const SizedBox(height: 30),
                  _buildStatsGrid(context, primaryColor, accentColor),
                  const SizedBox(height: 30),
                  _buildQuickActionsSection(context, primaryColor),
                  const SizedBox(height: 30),
                  _buildRecentActivitySection(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDrawer(BuildContext context, Color primaryColor, Color accentColor) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
                        nom.isNotEmpty ? nom[0].toUpperCase() : 'W',
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
                    nom,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "● Washers",
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
                      true,
                      primaryColor,
                      () => Navigator.pop(context),
                    ),
                    _buildDrawerItem(
                      Icons.notifications_rounded,
                      "Notifications",
                      false,
                      primaryColor,
                      () => Navigator.pushNamed(context, '/notifications'),
                    ),
                    _buildDrawerItem(
                      Icons.calendar_month_rounded,
                      "Planning",
                      false,
                      primaryColor,
                      () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    _buildDrawerItem(
                      Icons.account_balance_wallet_rounded,
                      "Mes gains",
                      false,
                      primaryColor,
                      () => Navigator.pushNamed(context, '/washer-earnings'),
                    ),
                    _buildDrawerItem(
                      Icons.lock_rounded,
                      "Sécurité",
                      false,
                      primaryColor,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => WasherSetPasswordPage())),
                    ),
                    _buildDrawerItem(
                      Icons.location_on_rounded,
                      "Localisation",
                      false,
                      primaryColor,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => WasherSetGPSPage())),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _buildDrawerItem(
                        Icons.logout_rounded,
                        "Déconnexion",
                        false,
                        Colors.red,
                        () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginWasherPage())),
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

  Widget _buildDrawerItem(IconData icon, String title, bool isActive, Color color, VoidCallback onTap) {
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

  Widget _buildSliverAppBar(BuildContext context, Color primaryColor, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
            ),
          ),
        ),
        title: const Text(
          "Washer Dashboard",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      backgroundColor: primaryColor,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 15),
          child: IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, color: Colors.white, size: 26),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(String nom, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bonjour, $nom ! 👋",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Prêt pour une nouvelle journée de travail ?",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "🟢 En ligne",
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor.withOpacity(0.1), const Color(0xFF4CAF50).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Color primaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Statistiques du jour",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildStatCard("Missions", "12", Icons.cleaning_services_rounded, const Color(0xFF2196F3))),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard("Revenus", "245€", Icons.euro_rounded, const Color(0xFF4CAF50))),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildStatCard("Temps", "6h 30m", Icons.access_time_rounded, const Color(0xFFFF9800))),
            const SizedBox(width: 15),
            Expanded(child: _buildStatCard("Note", "4.9★", Icons.star_rounded, const Color(0xFFFFD700))),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context, Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Actions rapides",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                "Nouvelle mission",
                "Commencer maintenant",
                Icons.play_circle_fill_rounded,
                const Color(0xFF1A2C42),
                () => Navigator.pushNamed(context, '/checklist-preparation'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                context,
                "Mission en cours",
                "Continuer le suivi",
                Icons.location_on_rounded,
                const Color(0xFFFF9800),
                () => Navigator.pushNamed(context, '/mission-suivi'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                "Planning",
                "Voir le calendrier",
                Icons.calendar_month_rounded,
                const Color(0xFF9C27B0),
                () => Navigator.pushNamed(context, '/calendrier'),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: _buildActionCard(
                context,
                "Mes gains",
                "Historique détaillé",
                Icons.trending_up_rounded,
                const Color(0xFF4CAF50),
                () => Navigator.pushNamed(context, '/washer-earnings'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Activité récente",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 0,
                blurRadius: 15,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem("Mission terminée", "Lavage complet - 35€", Icons.check_circle_rounded, const Color(0xFF4CAF50), "Il y a 2h"),
              const Divider(height: 30),
              _buildActivityItem("Nouveau planning", "3 missions programmées", Icons.calendar_today_rounded, const Color(0xFF2196F3), "Il y a 4h"),
              const Divider(height: 30),
              _buildActivityItem("Paiement reçu", "Virement de 180€", Icons.payment_rounded, const Color(0xFF4CAF50), "Hier"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String time) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}
