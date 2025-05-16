import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/map_screen.dart';
import 'package:fuel_scan/screens/list_screen.dart';
import 'package:fuel_scan/services/premium_service.dart';
import 'package:fuel_scan/services/keys_service.dart';
import 'package:fuel_scan/services/ad_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _initialized = false;
  bool _isPremium = false;
  bool _isInitializing = false;
  bool _dataInitialized = false; // Flag per il caricamento dei dati
  late FuelStationsProvider _provider;
  final List<Widget> _screens = [
    const MapScreen(),
    const ListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Posticipa l'inizializzazione dopo il build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Otteniamo l'istanza del provider qui
    _provider = Provider.of<FuelStationsProvider>(context, listen: false);
  }
  
  Future<void> _initializeServices() async {
    if (_isInitializing) return;
    _isInitializing = true;
    
    try {
      // Prima mostriamo l'UI di base
      setState(() {
        _initialized = true;
      });
      
      // Parallelizziamo le inizializzazioni non dipendenti tra loro
      await Future.wait([
        _checkPremiumStatus(),
        KeysService.getInstance(),
      ]);
      
      // Inizializza AdMob in background (non è necessario attendere)
      AdService().initialize();
      
      // Inizializza subito il provider dei dati (questa è la parte importante)
      if (_provider.status == LoadingStatus.idle) {
        await _provider.initialize();
        
        // Dopo l'inizializzazione del provider, aggiorniamo lo stato
        if (mounted) {
          setState(() {
            _dataInitialized = true; // Indichiamo che i dati sono stati caricati
          });
        }
      } else {
        setState(() {
          _dataInitialized = true;
        });
      }
    } catch (e) {
      print('Errore durante l\'inizializzazione home: $e');
      // Anche in caso di errore, indichiamo che abbiamo tentato l'inizializzazione
      if (mounted) {
        setState(() {
          _dataInitialized = true;
        });
      }
    } finally {
      _isInitializing = false;
    }
  }
  
  Future<void> _checkPremiumStatus() async {
    _isPremium = await PremiumService().checkPremiumStatus();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Se l'inizializzazione base non è ancora completata, mostriamo un indicatore di caricamento
    if (!_initialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Altrimenti, mostriamo la UI completa
    return Scaffold(
      body: Consumer<FuelStationsProvider>(
        builder: (context, provider, child) {
          // Se i dati non sono ancora inizializzati, mostriamo un indicatore di caricamento
          if (!_dataInitialized) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Caricamento stazioni di servizio...'),
                ],
              ),
            );
          }
          
          // Se il provider è ancora in caricamento, mostrane lo stato
          if (provider.status == LoadingStatus.loading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Aggiornamento dati...'),
                ],
              ),
            );
          }
          
          // Altrimenti mostriamo i contenuti normali
          return IndexedStack(
            index: _selectedIndex,
            children: _screens,
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mappa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
        ],
      ),
      appBar: AppBar(
        title: const Text('Il pieno giusto'),
        actions: [
          // Pulsante di ricarica dati
          if (_dataInitialized)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _provider.refreshData();
              },
            ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}