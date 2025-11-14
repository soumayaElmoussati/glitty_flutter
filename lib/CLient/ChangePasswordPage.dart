// CLient/ChangePasswordPage.dart
import 'package:flutter/material.dart';
import 'package:glitty/services/password_service.dart';
import 'package:glitty/CLient/ClientAccueil.dart';

class ChangePasswordPage extends StatefulWidget {
  final Map<String, dynamic>? clientData;
  final String? token;

  const ChangePasswordPage({super.key, this.clientData, this.token});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  String? _passwordStrength;
  Color _passwordStrengthColor = Colors.grey;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final result = await PasswordService.changePassword(
          token: widget.token!,
          currentPassword: _currentPasswordController.text,
          newPassword: _newPasswordController.text,
        );

        if (result['success'] == true) {
          _showSuccessDialog();
        } else {
          setState(() {
            _errorMessage = result['message'] ??
                'Erreur lors du changement de mot de passe';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Erreur de connexion: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Succès",
            style: TextStyle(
              color: Color(0xFF4FBF67),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text("Votre mot de passe a été changé avec succès."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Retour à la page précédente ou à l'accueil
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ClientAccueil(
                      clientData: widget.clientData,
                      token: widget.token,
                    ),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "OK",
                style: TextStyle(color: Color(0xFF4FBF67)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updatePasswordStrength(String password) {
    final validation = PasswordService.validatePasswordStrength(password);
    setState(() {
      _passwordStrength = validation['message'];
      switch (validation['strength']) {
        case 'weak':
          _passwordStrengthColor = Colors.red;
          break;
        case 'medium':
          _passwordStrengthColor = Colors.orange;
          break;
        case 'strong':
          _passwordStrengthColor = Colors.green;
          break;
        default:
          _passwordStrengthColor = Colors.grey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: dark,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Container(
              height: 170,
              width: double.infinity,
              color: dark,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Première ligne : Bouton retour, Logo, Notification
                  SizedBox(
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Bouton de retour
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
                              Icons.arrow_back_rounded,
                              color: Color(0xFF022519),
                              size: 20,
                            ),
                          ),
                        ),

                        // Logo
                        Image.asset(
                          'assets/logo-glitty.png',
                          width: 110,
                          height: 50,
                        ),

                        // Icône de notification
                        Image.asset(
                          'assets/notification-icone.png',
                          width: 22,
                          height: 22,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Section titre
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icône de sécurité
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FBF67).withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF4FBF67).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF4FBF67),
                            size: 20,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Titre principal
                        const Text(
                          "Changer le mot de passe",
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: "DM Sans",
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Sous-titre
                        const SizedBox(height: 2),
                        const Text(
                          "Sécurisez votre compte",
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: "DM Sans",
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // CORPS DE LA PAGE
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Message d'erreur
                        if (_errorMessage != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontFamily: "DM Sans",
                              ),
                            ),
                          ),

                        // Mot de passe actuel
                        _buildPasswordField(
                          controller: _currentPasswordController,
                          label: "Mot de passe actuel",
                          hintText: "Entrez votre mot de passe actuel",
                          obscureText: _obscureCurrentPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureCurrentPassword =
                                  !_obscureCurrentPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe actuel';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Nouveau mot de passe
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPasswordField(
                              controller: _newPasswordController,
                              label: "Nouveau mot de passe",
                              hintText: "Entrez votre nouveau mot de passe",
                              obscureText: _obscureNewPassword,
                              onToggleObscure: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                              onChanged: (value) {
                                _updatePasswordStrength(value);
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un nouveau mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                if (value == _currentPasswordController.text) {
                                  return 'Le nouveau mot de passe doit être différent de l\'ancien';
                                }
                                return null;
                              },
                            ),
                            if (_passwordStrength != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _passwordStrength!,
                                  style: TextStyle(
                                    color: _passwordStrengthColor,
                                    fontSize: 12,
                                    fontFamily: "DM Sans",
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Confirmer le nouveau mot de passe
                        _buildPasswordField(
                          controller: _confirmPasswordController,
                          label: "Confirmer le mot de passe",
                          hintText: "Confirmez votre nouveau mot de passe",
                          obscureText: _obscureConfirmPassword,
                          onToggleObscure: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez confirmer votre mot de passe';
                            }
                            if (value != _newPasswordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 30),

                        // Bouton de soumission
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4FBF67),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    "Changer le mot de passe",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: "DM Sans",
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    required String? Function(String?) validator,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1B1D21),
            fontFamily: "DM Sans",
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF8F92A1),
              fontFamily: "DM Sans",
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4FBF67)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF8F92A1),
              ),
              onPressed: onToggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
