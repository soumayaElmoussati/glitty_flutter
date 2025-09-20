import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:glitty/CLient/ClientAccueil.dart';
import 'package:glitty/CLient/ClientSuiviMissionPage.dart';
import 'package:glitty/CLient/LoginPage.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/ChecklistPreparationPage.dart';
import 'package:glitty/MissionSuiviPage.dart';
import 'package:glitty/WelcomePage.dart';

import 'package:glitty/WasherEarningsPage.dart';
import 'package:glitty/AdminValidationPage.dart';
import 'package:glitty/AdminDashboardPage.dart';
import 'package:glitty/NotificationsPage.dart';
import 'package:glitty/CalendrierPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: LoginWasherPage(),
      home: ClientAccueil(),
    );
  }
}
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Stripe only for mobile platforms
  if (!kIsWeb) {
    Stripe.publishableKey = 'pk_test_51RW28ZPNEpqAWzT7eCsUilQuStwuC1prDFJrpnsHLtOGCnZff84op1KxaukE48ILVMl4RlYjL2tvHFTuKxr7YyN800kTuYHpZe';
    Stripe.merchantIdentifier = 'merchant.flutter.stripe';
    Stripe.urlScheme = 'flutterstripe';
    await Stripe.instance.applySettings();
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glitty - Car Wash Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      
      //home: LoginWasherPage(),
      //home: const LoginPage(),
      home: const WelcomePage(),
      
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/client-login': (context) => const LoginPage(),
        '/washer-login': (context) => const LoginWasherPage(),
        '/client-accueil': (context) => ClientAccueil(),
        '/client-suivi-mission': (context) => ClientSuiviMissionPage(),
        '/washer-dashboard': (context) => DashboardWasherPage(nom: 'Washer'),
        '/checklist-preparation': (context) => ChecklistPreparationPage(),
        '/mission-gps': (context) => MissionSuiviPage(),
        '/mission-suivi': (context) => MissionSuiviPage(),

        '/washer-earnings': (context) => WasherEarningsPage(),
        '/admin-validation': (context) => const AdminDashboardPage(),
        '/admin-old': (context) => AdminValidationPage(),
        '/notifications': (context) => NotificationsPage(washerId: 1), // TODO: dynamic washerId
        '/calendrier': (context) => CalendrierPage(washerId: 1), // TODO: dynamic washerId
      },
    );
  }
}

