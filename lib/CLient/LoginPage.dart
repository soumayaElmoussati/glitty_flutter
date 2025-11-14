import 'package:flutter/material.dart';
import 'package:glitty/CLient/ResetPasswordPage.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:glitty/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'ClientAccueil.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _passwordVisible = false;

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
    super.dispose();
  }

  Future<void> _checkIfLoggedIn() async {
    final loginStatus = await AuthService.checkLoginStatus();

    if (loginStatus['isLoggedIn'] == true && mounted) {
      final userType = loginStatus['userType'];
      final userData = loginStatus['userData'];
      final token = loginStatus['token'];

      if (userType == 'client') {
        print('🔄 Client already logged in, redirecting...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientAccueil(
              clientData: userData,
              token: token,
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
    });

    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/client/login-client'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          await AuthService.saveClientLogin(data['client'], data['token']);

          print('✅ Client login successful - ID: ${data['client']['id']}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Connexion réussie'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ClientAccueil(
                clientData: data['client'],
                token: data['token'],
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Erreur de connexion'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur réseau: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    });

    try {
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/client/register-client'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'first_name': _prenomController.text.trim(),
          'last_name': _nomController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _telephoneController.text.trim(),
          'password': _passwordController.text,
          'address': _addressController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Inscription réussie'),
              backgroundColor: Colors.green,
            ),
          );

          await _performAutoLoginAfterRegister();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Erreur d\'inscription'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        Uri.parse('${Env.baseUrl}/api/client/login-client'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success']) {
        await AuthService.saveClientLogin(data['client'], data['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ClientAccueil(
              clientData: data['client'],
              token: data['token'],
            ),
          ),
        );
      }
    } catch (e) {
      print('Auto-login error: $e');
      setState(() {
        _isLogin = true;
      });
    }
  }

  void _navigateToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ResetPasswordPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);
    const accentColor = Color(0xFF4FBF67);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              const Color(0xFF022519).withOpacity(0.03),
              const Color(0xFF022519).withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec bouton retour
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: Color(0xFF022519),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WelcomePage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    Image.asset(
                      'assets/logo-glitty.png',
                      height: 40,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Titre principal
                Text(
                  _isLogin ? 'Content de vous revoir !' : 'Créez votre compte',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                    fontFamily: 'DM Sans',
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  _isLogin
                      ? 'Connectez-vous pour continuer votre expérience'
                      : 'Rejoignez notre communauté dès maintenant',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'DM Sans',
                  ),
                ),

                const SizedBox(height: 40),

                // Formulaire SANS fond blanc
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Champs inscription seulement
                      if (!_isLogin) ...[
                        _buildAnimatedFormSection(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _prenomController,
                                    label: 'Prénom',
                                    icon: Icons.person_outline_rounded,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Prénom requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _nomController,
                                    label: 'Nom',
                                    icon: Icons.person_rounded,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Nom requis';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _telephoneController,
                              label: 'Téléphone',
                              icon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Téléphone requis';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Adresse',
                              icon: Icons.home_rounded,
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Adresse requise';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],

                      // Champs communs
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email requis';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: _passwordController,
                        label: 'Mot de passe',
                        icon: Icons.lock_rounded,
                        obscureText: !_passwordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            color: Colors.grey[500],
                          ),
                          onPressed: () {
                            setState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
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

                      // Mot de passe oublié (seulement en mode login)
                      if (_isLogin) ...[
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _navigateToResetPassword,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Mot de passe oublié ?',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Bouton principal
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : (_isLogin ? _login : _register),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: accentColor.withOpacity(0.3),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _isLogin
                                          ? 'Se connecter'
                                          : 'Créer mon compte',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'DM Sans',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Séparateur
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: Colors.grey[300],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Basculer entre connexion/inscription
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? 'Nouveau chez Glitty ? '
                            : 'Déjà un compte ? ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _formKey.currentState?.reset();
                                  _emailController.clear();
                                  _passwordController.clear();
                                  if (!_isLogin) {
                                    _nomController.clear();
                                    _prenomController.clear();
                                    _telephoneController.clear();
                                    _addressController.clear();
                                  }
                                });
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isLogin ? 'S\'inscrire' : 'Se connecter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'DM Sans',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Footer informatif
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.05),
                        primaryColor.withOpacity(0.02),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        color: Color(0xFF4FBF67),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Sécurité Premium',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF022519),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vos données sont cryptées et protégées\nselon les normes les plus strictes',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'DM Sans',
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          color: Color(0xFF022519),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF4FBF67).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF4FBF67),
            ),
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(
              color: Color(0xFF4FBF67),
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
      ),
    );
  }

  Widget _buildAnimatedFormSection({required List<Widget> children}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Column(children: children),
    );
  }
}
