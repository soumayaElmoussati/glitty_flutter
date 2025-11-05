import 'package:flutter/material.dart';
import 'package:glitty/DashboardWasher.dart';
import 'package:glitty/config/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'AddWasherPage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class LoginWasherPage extends StatefulWidget {
  const LoginWasherPage({Key? key}) : super(key: key);

  @override
  _LoginWasherPageState createState() => _LoginWasherPageState();
}

class _LoginWasherPageState extends State<LoginWasherPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String _message = '';
  bool _isLoading = false;

  final dark = const Color(0xFF022519);
  final fieldBg = const Color(0xFFF4F6F9);

  Future<void> _login() async {
    if (_isLoading) return; // Prevent multiple calls

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      print(
          ' Tentative de connexion à: ${Env.baseUrl}/api/washer/login-washer');
      print(' Email: $email');

      final response = await http
          .post(
            Uri.parse('${Env.baseUrl}/api/washer/login-washer'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print(' Response status: ${response.statusCode}');
      print(' Response body: ${response.body}');

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final washer = result['washer'];
        final token = result['token'];
        final washerId = washer['id']; // Récupérer l'ID du washer

        print(' Connexion réussie pour: ${washer['first_name']}');
        print(' ID du washer: $washerId');
        print(' Token reçu: $token');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('washer_token', token);
        await prefs.setInt('washer_id', washerId); // Sauvegarder l'ID aussi

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DashboardWasherPage(
                nom: washer['first_name'],
                washerId: washerId,
                washerData: washer,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _message = result['message'] ?? 'Erreur d\'authentification';
        });
        print(' Erreur d\'authentification: ${result['message']}');
      }
    } catch (e) {
      print(' Erreur de connexion: $e');
      setState(() {
        if (e.toString().contains('TimeoutException')) {
          _message = 'Timeout: Vérifiez que le serveur est démarré';
        } else if (e.toString().contains('SocketException')) {
          _message = 'Erreur réseau: Impossible de joindre le serveur';
        } else {
          _message = 'Erreur de connexion: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _input({
    required String hint,
    required IconData icon,
    bool obscure = false,
    required Function(String?) onSaved,
    required String? Function(String?) validator,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        obscureText: obscure,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.grey),
        ),
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Connexion Washer'),
        backgroundColor: dark,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Handle missing logo gracefully
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: dark.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_car_wash,
                  size: 80,
                  color: Color(0xFF022519),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Bienvenue',
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: dark),
              ),
              const SizedBox(height: 8),
              Text(
                'Connectez‑vous pour continuer',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              // Platform info for debugging
              if (kIsWeb) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🌐 Version Web - API: ${Env.baseUrl}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],

              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _input(
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      onSaved: (v) => email = v ?? '',
                      validator: (v) => v != null && v.contains('@')
                          ? null
                          : 'Email invalide',
                      bg: fieldBg,
                    ),
                    const SizedBox(height: 16),
                    _input(
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline,
                      obscure: true,
                      onSaved: (v) => password = v ?? '',
                      validator: (v) => v != null && v.length >= 4
                          ? null
                          : 'Mot de passe requis',
                      bg: fieldBg,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                if (_formKey.currentState!.validate()) {
                                  _formKey.currentState!.save();
                                  _login();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dark,
                          disabledBackgroundColor: dark.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Connexion en cours...',
                                      style: TextStyle(color: Colors.white)),
                                ],
                              )
                            : const Text('Se connecter',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _message.contains('réussie')
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _message.contains('réussie')
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _message.contains('réussie')
                                ? Colors.green[700]
                                : Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore de compte ? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => AddWasherPage()),
                            );
                          },
                          child: Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: dark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
