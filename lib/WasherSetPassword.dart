import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:glitty/LoginWasherPage.dart';
 
class WasherSetPasswordPage extends StatefulWidget {
  @override
  _WasherSetPasswordPageState createState() => _WasherSetPasswordPageState();
}

class _WasherSetPasswordPageState extends State<WasherSetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String motDePasse = '';
  String message = '';
  bool isLoading = false;

  // URL dynamique selon la plateforme
  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  Future<void> _setPassword() async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/washer/setPassword'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'mot_de_passe': motDePasse,
        }),
      );

      final result = jsonDecode(response.body);

      setState(() {
        message = result['message'];
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mot de passe défini ! Vous pouvez maintenant vous connecter.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginWasherPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        message = 'Erreur de connexion.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  final dark = const Color(0xFF022519);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: dark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Color(0xFF022519)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Washer",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text("Définir mot de passe",
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text("Dashboard"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Mot de passe"),
              onTap: () => Navigator.pop(context),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Déconnexion",
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Définir le mot de passe'),
        backgroundColor: dark,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => email = val ?? '',
                validator: (val) =>
                    val != null && val.contains('@') ? null : 'Email invalide',
              ),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Nouveau mot de passe'),
                obscureText: true,
                onSaved: (val) => motDePasse = val ?? '',
                validator: (val) => val != null && val.length >= 4
                    ? null
                    : 'Mot de passe trop court',
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    _setPassword();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: dark,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Valider',
                        style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
              if (message.isNotEmpty)
                Text(
                  message,
                  style: TextStyle(
                      color: message.contains('succès')
                          ? Colors.green
                          : Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
