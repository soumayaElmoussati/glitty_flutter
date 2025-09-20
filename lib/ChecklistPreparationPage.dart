import 'package:flutter/material.dart';

class ChecklistPreparationPage extends StatefulWidget {
  const ChecklistPreparationPage({Key? key}) : super(key: key);

  @override
  _ChecklistPreparationPageState createState() => _ChecklistPreparationPageState();
}

class _ChecklistPreparationPageState extends State<ChecklistPreparationPage> {
  final Map<String, bool> _checklistItems = {
    'Produits de lavage': false,
    'Éponges et chiffons': false,
    'Aspirateur portable': false,
    'Seau d\'eau': false,
    'Produits d\'entretien intérieur': false,
    'Gants de protection': false,
    'Tapis de sol': false,
    'Téléphone chargé': false,
    'GPS fonctionnel': false,
    'Moyens de paiement mobile': false,
  };

  bool get _allItemsChecked => _checklistItems.values.every((checked) => checked);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Préparation Mission',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.checklist_outlined,
                    size: 50,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vérifiez votre équipement',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Assurez-vous d\'avoir tout le matériel nécessaire',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liste de vérification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _checklistItems.length,
                        itemBuilder: (context, index) {
                          final item = _checklistItems.keys.elementAt(index);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _checklistItems[item]! 
                                    ? Colors.green 
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  decoration: _checklistItems[item]!
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              value: _checklistItems[item],
                              onChanged: (bool? value) {
                                setState(() {
                                  _checklistItems[item] = value ?? false;
                                });
                              },
                              activeColor: Colors.green,
                              checkColor: Colors.white,
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _allItemsChecked ? () {
                          Navigator.pushNamed(context, '/mission-gps');
                        } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _allItemsChecked 
                              ? Color(0xFF1E3A8A) 
                              : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _allItemsChecked 
                              ? 'Commencer la mission' 
                              : 'Terminez la checklist',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 