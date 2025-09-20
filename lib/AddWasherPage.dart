import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'EnvoiDocumentsPage.dart';

class AddWasherPage extends StatefulWidget {
  @override
  _AddWasherPageState createState() => _AddWasherPageState();
}

class _AddWasherPageState extends State<AddWasherPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {
    'nom': '',
    'prenom': '',
    'email': '',
    'telephone': '',
    'adresse': '',
  };

  String _responseMessage = '';

  // URL dynamique selon la plateforme
  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/washer/add'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(_formData),
        );

        final result = json.decode(response.body);
        if (response.statusCode == 200) {

          final washerId = result['id'];
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EnvoiDocumentsPage(washerId: washerId),
            ),
          );
        } else {
          setState(() {
            _responseMessage = result['message'] ?? 'Erreur inconnue';
          });
        }
      } catch (e) {
        setState(() {
          _responseMessage = 'Erreur lors de l’envoi';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF022519);
    const fieldBg   = Color(0xFFF4F6F9);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: Image.asset('assets/logo.png'),
                ),
                const SizedBox(height: 30),
                Text(
                  'Devenir Washer',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complétez vos informations personnelles',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _inputField(
                        hint: 'Nom',
                        icon: Icons.person_outline,
                        validatorMsg: 'Nom requis',
                        onSaved: (v) => _formData['nom'] = v!,
                        bg: fieldBg,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        hint: 'Prénom',
                        icon: Icons.person_outline,
                        validatorMsg: 'Prénom requis',
                        onSaved: (v) => _formData['prenom'] = v!,
                        bg: fieldBg,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        hint: 'Email',
                        icon: Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) =>
                            v != null && v.contains('@') ? null : 'Email invalide',
                        onSaved: (v) => _formData['email'] = v!,
                        bg: fieldBg, validatorMsg: '',
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        hint: 'Téléphone',
                        icon: Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validatorMsg: 'Téléphone requis',
                        onSaved: (v) => _formData['telephone'] = v!,
                        bg: fieldBg,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        hint: 'Adresse',
                        icon: Icons.home_outlined,
                        validatorMsg: 'Adresse requise',
                        onSaved: (v) => _formData['adresse'] = v!,
                        bg: fieldBg,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Enregistrer',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                      if (_responseMessage.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          _responseMessage,
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

  Widget _inputField({
    required String hint,
    required IconData icon,
    required String validatorMsg,
    required Function(String?) onSaved,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    required Color bg,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          icon: Icon(icon, color: Colors.grey),
        ),
        validator: validator ?? (v) => (v == null || v.isEmpty) ? validatorMsg : null,
        onSaved: onSaved,
      ),
    );
  }
}
