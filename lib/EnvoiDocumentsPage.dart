import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:glitty/LoginWasherPage.dart';
import 'package:glitty/WasherSetPassword.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class EnvoiDocumentsPage extends StatefulWidget {
  final int washerId;
  const EnvoiDocumentsPage({required this.washerId});

  @override
  _EnvoiDocumentsPageState createState() => _EnvoiDocumentsPageState();
}

class _EnvoiDocumentsPageState extends State<EnvoiDocumentsPage> {
  PlatformFile? pieceIdentite;
  PlatformFile? justificatifDomicile;
  PlatformFile? permisConduire;
  PlatformFile? certificatsFormation;

  late final String idWasher;

  // URL dynamique selon la plateforme
  String get baseUrl {
    if (kIsWeb) {
      return 'https://glitty.fr';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }

  @override
  void initState() {
    super.initState();
    idWasher = widget.washerId.toString();
  }

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

  Future<void> _send() async {
    if (pieceIdentite == null ||
        justificatifDomicile == null ||
        certificatsFormation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Veuillez sélectionner tous les fichiers requis')),
      );
      return;
    }

    final req = http.MultipartRequest(
        'POST', Uri.parse('$baseUrl/api/washer/documents/'));
    req.fields['id_washer'] = idWasher;

    await _addFile(req, 'piece_identite', pieceIdentite!);
    await _addFile(req, 'justificatif_domicile', justificatifDomicile!);
    await _addFile(req, 'certificats_formation', certificatsFormation!);
    if (permisConduire != null) {
      await _addFile(req, 'permis_conduire', permisConduire!);
    }

    try {
      final res = await req.send();
      final body = await res.stream.bytesToString();
      
      if (res.statusCode == 201) {
        // Documents uploadés avec succès, rediriger vers définition mot de passe
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Documents envoyés ! Définissez maintenant votre mot de passe.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => WasherSetPasswordPage()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur upload: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Widget _fileTile(
      {required String label,
      required PlatformFile? file,
      required VoidCallback onTap}) {
    const bg = Color(0xFFF4F6F9);
    const dark = Color(0xFF0F172A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                file == null ? label : file.name,
                style: TextStyle(
                    color: file == null ? Colors.grey : dark, fontSize: 15),
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
    const dark = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: dark,
        elevation: 2,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _fileTile(
                label: 'Pièce d\'identité',
                file: pieceIdentite,
                onTap: () async {
                  final f = await _selectFile('Pièce d\'identité');
                  if (f != null) setState(() => pieceIdentite = f);
                },
              ),
              _fileTile(
                label: 'Justificatif de domicile',
                file: justificatifDomicile,
                onTap: () async {
                  final f = await _selectFile('Justificatif de domicile');
                  if (f != null) setState(() => justificatifDomicile = f);
                },
              ),
              _fileTile(
                label: 'Permis de conduire (optionnel)',
                file: permisConduire,
                onTap: () async {
                  final f = await _selectFile('Permis de conduire');
                  if (f != null) setState(() => permisConduire = f);
                },
              ),
              _fileTile(
                label: 'Certificats de formation',
                file: certificatsFormation,
                onTap: () async {
                  final f = await _selectFile('Certificats de formation');
                  if (f != null) setState(() => certificatsFormation = f);
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _send,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Envoyer',
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
