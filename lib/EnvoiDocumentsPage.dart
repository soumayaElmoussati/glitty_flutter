import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:glitty/config/env.dart';

class EnvoiDocumentsPage extends StatefulWidget {
  final Map<String, String> formData;

  const EnvoiDocumentsPage({
    required this.formData,
  });

  @override
  _EnvoiDocumentsPageState createState() => _EnvoiDocumentsPageState();
}

class _EnvoiDocumentsPageState extends State<EnvoiDocumentsPage> {
  PlatformFile? pieceIdentite;
  PlatformFile? justificatifDomicile;
  PlatformFile? permisConduire;
  PlatformFile? certificatsFormation;

  bool _isLoading = false;

  Future<PlatformFile?> _selectFile(String label) async {
    final res = await FilePicker.platform.pickFiles();
    if (res != null && res.files.isNotEmpty) {
      final file = res.files.single;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label : ${file.name} sélectionné')),
      );
      return file;
    }
    return null;
  }

  Future<void> _addFile(
      http.MultipartRequest req, String field, PlatformFile f) async {
    final mime = lookupMimeType(f.name) ?? 'application/octet-stream';
    if (kIsWeb) {
      final bytes = f.bytes;
      if (bytes != null) {
        req.files.add(http.MultipartFile.fromBytes(field, bytes,
            filename: f.name, contentType: MediaType.parse(mime)));
      }
    } else {
      final path = f.path;
      if (path != null) {
        final file = File(path);
        final length = await file.length();
        req.files.add(http.MultipartFile(field, file.openRead(), length,
            filename: f.name, contentType: MediaType.parse(mime)));
      }
    }
  }

  Future<void> _sendAllData() async {
    if (pieceIdentite == null ||
        justificatifDomicile == null ||
        certificatsFormation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner tous les fichiers requis')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${Env.baseUrl}/api/washer/add-washer'),
      );

      // Ajouter tous les champs du formulaire
      request.fields.addAll(widget.formData);

      // Ajouter les fichiers
      await _addFile(request, 'piece_identite', pieceIdentite!);
      await _addFile(request, 'justificatif_domicile', justificatifDomicile!);
      await _addFile(request, 'certificats_formation', certificatsFormation!);
      if (permisConduire != null) {
        await _addFile(request, 'permis_conduire', permisConduire!);
      }

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final result = json.decode(body);

      if (response.statusCode == 201 && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']}'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers la page de connexion
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginWasherPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de l\'envoi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _fileTile({
    required String label,
    required PlatformFile? file,
    required VoidCallback onTap,
    bool required = true,
  }) {
    const bg = Color(0xFFF4F6F9);
    const dark = Color(0xFF022519);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: required && file == null
              ? Border.all(color: Colors.red, width: 1)
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file == null
                    ? '$label ${required ? '*' : '(optionnel)'}'
                    : file.name,
                style: TextStyle(
                  color: file == null ? Colors.grey : dark,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.upload_file,
                color: file == null ? Colors.grey[600] : dark),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF022519);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Documents requis'),
        backgroundColor: dark,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Téléchargez vos documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Les documents marqués d\'un * sont obligatoires',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _fileTile(
                label: 'Pièce d\'identité',
                file: pieceIdentite,
                onTap: () async {
                  final f = await _selectFile('Pièce d\'identité');
                  if (f != null) setState(() => pieceIdentite = f);
                },
                required: true,
              ),
              _fileTile(
                label: 'Justificatif de domicile',
                file: justificatifDomicile,
                onTap: () async {
                  final f = await _selectFile('Justificatif de domicile');
                  if (f != null) setState(() => justificatifDomicile = f);
                },
                required: true,
              ),
              _fileTile(
                label: 'Permis de conduire',
                file: permisConduire,
                onTap: () async {
                  final f = await _selectFile('Permis de conduire');
                  if (f != null) setState(() => permisConduire = f);
                },
                required: false,
              ),
              _fileTile(
                label: 'Certificats de formation',
                file: certificatsFormation,
                onTap: () async {
                  final f = await _selectFile('Certificats de formation');
                  if (f != null) setState(() => certificatsFormation = f);
                },
                required: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendAllData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Finaliser mon inscription',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
