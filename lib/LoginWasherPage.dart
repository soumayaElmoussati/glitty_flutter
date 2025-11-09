import 'package:flutter/material.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'DashboardWasher.dart'; // Votre page dashboard existante
import 'AddWasherPage.dart'; // Pour l'inscription

class LoginWasherPage extends StatefulWidget {
  const LoginWasherPage({super.key});

  @override
  State<LoginWasherPage> createState() => _LoginWasherPageState();
}

class _LoginWasherPageState extends State<LoginWasherPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _passwordVisible = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _addressController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLoggedIn() async {
    final loginStatus = await AuthService.checkLoginStatus();

    if (loginStatus['isLoggedIn'] == true && mounted) {
      final userType = loginStatus['userType'];
      final userData = loginStatus['userData'];
      final token = loginStatus['token'];

      if (userType == 'washer') {
        print('🔄 Washer already logged in, redirecting to dashboard...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardWasherPage(
              nom: userData['first_name'] ?? 'Prestataire',
              washerId: userData['id'],
              washerData: userData,
            ),
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      print('🔐 Tentative de connexion washer: ${_emailController.text}');

      final response = await http
          .post(
            Uri.parse('${Env.baseUrl}/api/washer/login-washer'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }),
          )
          .timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📡 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final washer = data['washer'];
        final token = data['token'];
        final washerId = washer['id'];

        print(
            '✅ Washer login successful - ID: $washerId, Name: ${washer['first_name']}');

        // Sauvegarder avec le service d'authentification
        await AuthService.saveWasherLogin(washer, token);

        // Sauvegarder également dans SharedPreferences pour compatibilité
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('washer_token', token);
        await prefs.setInt('washer_id', washerId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Connexion réussie'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardWasherPage(
                nom: washer['first_name'] ?? 'Prestataire',
                washerId: washerId,
                washerData: washer,
              ),
            ),
          );
        }
      } else {
        setState(() {
          _message = data['message'] ?? 'Erreur de connexion';
        });
        print('❌ Login error: ${data['message']}');
      }
    } catch (e) {
      print('❌ Network error: $e');
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
    });

    try {
      print('📝 Tentative d\'inscription washer...');

      final response = await http
          .post(
            Uri.parse('${Env.baseUrl}/api/washer/register-washer'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'first_name': _prenomController.text.trim(),
              'last_name': _nomController.text.trim(),
              'email': _emailController.text.trim(),
              'phone': _telephoneController.text.trim(),
              'password': _passwordController.text,
              'address': _addressController.text.trim(),
              'experience': _experienceController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      print('📡 Inscription response status: ${response.statusCode}');
      print('📡 Inscription response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Inscription réussie'),
              backgroundColor: Colors.green,
            ),
          );

          // Auto-login après inscription
          await _performAutoLoginAfterRegister();
        }
      } else {
        setState(() {
          _message = data['message'] ?? 'Erreur d\'inscription';
        });
        print('❌ Registration error: ${data['message']}');
      }
    } catch (e) {
      print('❌ Registration network error: $e');
      setState(() {
        if (e.toString().contains('TimeoutException')) {
          _message = 'Timeout lors de l\'inscription';
        } else if (e.toString().contains('SocketException')) {
          _message = 'Erreur réseau lors de l\'inscription';
        } else {
          _message = 'Erreur d\'inscription: ${e.toString()}';
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

  Future<void> _performAutoLoginAfterRegister() async {
    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/washer/login-washer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        final washer = data['washer'];
        final token = data['token'];
        final washerId = washer['id'];

        await AuthService.saveWasherLogin(washer, token);

        // Sauvegarder également dans SharedPreferences pour compatibilité
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('washer_token', token);
        await prefs.setInt('washer_id', washerId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardWasherPage(
              nom: washer['first_name'] ?? 'Prestataire',
              washerId: washerId,
              washerData: washer,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Auto-login error: $e');
      // En cas d'erreur, basculer vers le mode login
      setState(() {
        _isLogin = true;
        _message = 'Inscription réussie! Veuillez vous connecter';
      });
    }
  }

  // Méthode pour utiliser votre page d'inscription existante
  void _navigateToAddWasherPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddWasherPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const fieldBg = Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF022519),
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomePage()),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Logo
              Container(
                height: 180,
                width: 180,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_car_wash,
                  size: 80,
                  color: Color(0xFF022519),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Espace Prestataire',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isLogin
                    ? 'Connectez-vous à votre compte prestataire'
                    : 'Devenez prestataire sur Glitty',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
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

              // Formulaire
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Champs inscription seulement
                      if (!_isLogin) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: fieldBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  controller: _prenomController,
                                  decoration: const InputDecoration(
                                    labelText: 'Prénom',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Prénom requis';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: fieldBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextFormField(
                                  controller: _nomController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nom',
                                    prefixIcon: Icon(Icons.person),
                                    border: InputBorder.none,
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Nom requis';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _telephoneController,
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: Icon(Icons.phone),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Téléphone requis';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Adresse',
                              prefixIcon: Icon(Icons.home_outlined),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Adresse requise';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: fieldBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextFormField(
                            controller: _experienceController,
                            decoration: const InputDecoration(
                              labelText: 'Expérience (années)',
                              prefixIcon: Icon(Icons.work_outline),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Expérience requise';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email
                      Container(
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: InputBorder.none,
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email requis';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Email invalide';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Mot de passe
                      Container(
                        decoration: BoxDecoration(
                          color: fieldBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          obscureText: !_passwordVisible,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Mot de passe requis';
                            }
                            if (!_isLogin && value.length < 6) {
                              return 'Au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Message d'erreur/succès
                      if (_message.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _message.contains('réussie') ||
                                    _message.contains('succès')
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _message.contains('réussie') ||
                                      _message.contains('succès')
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          child: Text(
                            _message,
                            style: TextStyle(
                              color: _message.contains('réussie') ||
                                      _message.contains('succès')
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_message.isNotEmpty) const SizedBox(height: 16),

                      // Bouton principal
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isLogin ? _login : _register),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            disabledBackgroundColor:
                                primaryColor.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Traitement en cours...',
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                )
                              : Text(
                                  _isLogin ? 'Se connecter' : 'S\'inscrire',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Basculer entre connexion/inscription OU lien vers AddWasherPage
              if (_isLogin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Pas encore de compte ? "),
                    GestureDetector(
                      onTap: _isLoading ? null : _navigateToAddWasherPage,
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Déjà un compte ? '),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _isLogin = true;
                                _message = '';
                                _formKey.currentState?.reset();
                              });
                            },
                      child: Text(
                        'Se connecter',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
