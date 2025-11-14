import 'package:flutter/material.dart';
import 'package:glitty/WelcomePage.dart';
import 'package:glitty/config/env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetInstructions() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Implémenter l'appel API pour la réinitialisation
      // Simuler un délai d'envoi
      await Future.delayed(const Duration(seconds: 2));

      // Exemple d'appel API (à adapter selon votre backend)
      /*
      final response = await http.post(
        Uri.parse('${Env.baseUrl}/api/client/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _emailSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      */

      // Pour l'instant, on simule le succès
      setState(() {
        _emailSent = true;
      });

      print('📧 Instructions envoyées à: ${_emailController.text}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur réseau: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _returnToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const WelcomePage(),
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
                        onPressed: () => Navigator.pop(context),
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

                // Icône principale
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withOpacity(0.2),
                          accentColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _emailSent
                          ? Icons.mark_email_read_rounded
                          : Icons.lock_reset_rounded,
                      size: 40,
                      color: accentColor,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Titre principal
                Text(
                  _emailSent ? 'Email envoyé !' : 'Mot de passe oublié',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF022519),
                    fontFamily: 'DM Sans',
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 12),

                // Sous-titre
                Text(
                  _emailSent
                      ? 'Nous avons envoyé les instructions de réinitialisation à votre adresse email'
                      : 'Entrez votre email pour recevoir les instructions de réinitialisation',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'DM Sans',
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                if (!_emailSent) ...[
                  // Formulaire de réinitialisation
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildEmailField(),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ],

                if (_emailSent) ...[
                  // Confirmation de succès
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4FBF67),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Vérifiez votre boîte email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF022519),
                            fontFamily: 'DM Sans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nous avons envoyé un lien de réinitialisation à :',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _emailController.text,
                          style: const TextStyle(
                            color: Color(0xFF022519),
                            fontWeight: FontWeight.w600,
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        _buildReturnButton(),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Informations supplémentaires
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
                        Icons.info_outline_rounded,
                        color: Color(0xFF4FBF67),
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Conseil de sécurité',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF022519),
                          fontFamily: 'DM Sans',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Le lien de réinitialisation est valable 24 heures. Pensez à vérifier vos spams si vous ne recevez pas l\'email.',
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

  Widget _buildEmailField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: TextFormField(
        controller: _emailController,
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
        style: const TextStyle(
          fontFamily: 'DM Sans',
          fontSize: 16,
          color: Color(0xFF022519),
        ),
        decoration: InputDecoration(
          labelText: 'Adresse email',
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
            child: const Icon(
              Icons.email_rounded,
              color: Color(0xFF4FBF67),
            ),
          ),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _sendResetInstructions,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4FBF67),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          shadowColor: const Color(0xFF4FBF67).withOpacity(0.3),
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
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Envoyer les instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'DM Sans',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.send_rounded,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildReturnButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _returnToLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF022519),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Retour à la connexion',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'DM Sans',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
