import 'package:flutter/material.dart';
import 'package:fuel_scan/services/premium_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final PremiumService _premiumService = PremiumService();
  bool _isPremium = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    setState(() {
      _isLoading = true;
    });

    final isPremium = await _premiumService.checkPremiumStatus();

    setState(() {
      _isPremium = isPremium;
      _isLoading = false;
    });
  }

  Future<void> _purchasePremium() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _premiumService.purchasePremium();

      if (success) {
        setState(() {
          _isPremium = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acquisto premium completato con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Errore durante l\'acquisto.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _premiumService.restorePurchases();

      if (success) {
        setState(() {
          _isPremium = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Acquisti ripristinati con successo!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nessun acquisto da ripristinare.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Icona premium
                  const Icon(
                    Icons.workspace_premium,
                    size: 80,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 24),
                  
                  // Titolo
                  const Text(
                    'Fuel Scan Premium',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Stato attuale
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _isPremium ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isPremium ? Icons.check_circle : Icons.info,
                          color: _isPremium ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isPremium
                                ? 'Hai già la versione Premium!'
                                : 'Versione standard',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Vantaggi Premium
                  const Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vantaggi Premium',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.block,
                            text: 'Nessuna pubblicità',
                          ),
                          SizedBox(height: 8),
                          FeatureItem(
                            icon: Icons.brush,
                            text: 'Interfaccia pulita e senza distrazioni',
                          ),
                          SizedBox(height: 8),
                          FeatureItem(
                            icon: Icons.favorite,
                            text: 'Supporta lo sviluppo dell\'app',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Spacer(),
                  
                  // Bottone per acquistare
                  if (!_isPremium)
                    ElevatedButton.icon(
                      onPressed: _purchasePremium,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Acquista Premium - 2,99 €'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(height: 12),
                  
                  // Bottone per ripristinare gli acquisti
                  if (!_isPremium)
                    TextButton(
                      onPressed: _restorePurchases,
                      child: const Text('Ripristina acquisti'),
                    ),
                ],
              ),
            ),
    );
  }
}

class FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const FeatureItem({
    super.key,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.green),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }
}