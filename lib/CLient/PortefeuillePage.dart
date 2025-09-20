import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'PaiementPortefeuille.dart';

class PortefeuillePage extends StatefulWidget {
  final int clientId;

  const PortefeuillePage({Key? key, required this.clientId}) : super(key: key);

  @override
  _PortefeuillePageState createState() => _PortefeuillePageState();
}

class _PortefeuillePageState extends State<PortefeuillePage> {
  double solde = 0.0;
  List<dynamic> transactions = [];
  bool isLoading = true;
  String? error;

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
    loadPortefeuilleData();
  }

  Future<void> loadPortefeuilleData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      await Future.wait([
        getSolde(),
        getHistorique(),
      ]);
    } catch (e) {
      setState(() {
        error = 'Erreur de chargement: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getSolde() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/portefeuille/solde/${widget.clientId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        solde = data['solde'].toDouble();
      });
    } else {
      throw Exception('Erreur récupération solde');
    }
  }

  Future<void> getHistorique() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/portefeuille/historique/${widget.clientId}'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        transactions = data['transactions'];
      });
    } else {
      throw Exception('Erreur récupération historique');
    }
  }

  Future<void> rechargerCredits(int montant) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse('$baseUrl/api/portefeuille/recharger'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'clientId': widget.clientId,
          'montant': montant,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
        await loadPortefeuilleData();
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message']);
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
        isLoading = false;
      });
    }
  }

  void showRechargeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Recharger mon portefeuille'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Choisissez un montant de recharge :'),
              const SizedBox(height: 20),
              _buildRechargeOption(50, 15),
              const SizedBox(height: 10),
              _buildRechargeOption(100, 35),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRechargeOption(int montant, int bonus) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaiementPortefeuillePage(
              montant: montant.toDouble(),
              bonus: bonus.toDouble(),
            ),
          ),
        );
        
        // Si le paiement a réussi, recharger les données
        if (result == true) {
          await loadPortefeuilleData();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue),
        ),
        child: Column(
          children: [
            Text(
              '${montant}€ + ${bonus}€ de bonus',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Total: ${montant + bonus}€',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF022519);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec solde
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Mon Portefeuille',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Pour équilibrer le titre
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Solde disponible',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${solde.toStringAsFixed(2)} €',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : showRechargeDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Recharger'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Section historique
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Historique des transactions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: Colors.red,
                                        size: 48,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        error!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: loadPortefeuilleData,
                                        child: const Text('Réessayer'),
                                      ),
                                    ],
                                  ),
                                )
                              : transactions.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.account_balance_wallet_outlined,
                                            color: Colors.grey,
                                            size: 48,
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'Aucune transaction',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: loadPortefeuilleData,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.only(bottom: 20),
                                        itemCount: transactions.length,
                                        itemBuilder: (context, index) {
                                          final transaction = transactions[index];
                                          final montant = (transaction['montant'] is int) 
                                              ? (transaction['montant'] as int).toDouble()
                                              : double.tryParse(transaction['montant'].toString()) ?? 0.0;
                                          final montantBonus = (transaction['montant_bonus'] is int) 
                                              ? (transaction['montant_bonus'] as int).toDouble()
                                              : double.tryParse(transaction['montant_bonus'].toString()) ?? 0.0;
                                          
                                          return Container(
                                            margin: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 4,
                                            ),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        transaction['description'] ?? 'Recharge ${montant.toStringAsFixed(0)}€ + ${montantBonus.toStringAsFixed(0)}€ de bonus',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (montantBonus > 0) 
                                                        Text(
                                                          'Bonus: +${montantBonus.toStringAsFixed(2)}€',
                                                          style: const TextStyle(
                                                            color: Colors.green,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      Text(
                                                        transaction['date_creation'] ?? '',
                                                        style: TextStyle(
                                                          color: Colors.grey[600],
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '+${(montant + montantBonus).toStringAsFixed(2)}€',
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 