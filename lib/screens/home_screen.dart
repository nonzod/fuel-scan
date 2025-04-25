import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/map_screen.dart';
import 'package:fuel_scan/screens/list_screen.dart';
import 'package:fuel_scan/services/premium_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _initialized = false;
  bool _isPremium = false;
  late FuelStationsProvider _provider;
  final List<Widget> _screens = [
    const MapScreen(),
    const ListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Controlla lo stato premium
    _checkPremiumStatus();
    // Posticipa l'inizializzazione dopo il build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  
  Future<void> _checkPremiumStatus() async {
    _isPremium = await PremiumService().checkPremiumStatus();
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Otteniamo l'istanza del provider qui, così da averla disponibile per tutto il ciclo di vita del widget
    _provider = Provider.of<FuelStationsProvider>(context, listen: false);
  }
  
  Future<void> _initializeData() async {
    try {
      // Inizializzazione dei dati solo se necessario
      if (_provider.status == LoadingStatus.idle) {
        await _provider.initialize();
      }
      
      // Aggiorniamo lo stato UI solo quando l'inizializzazione è completa
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    } catch (e) {
      print('Errore durante l\'inizializzazione home: $e');
      if (mounted) {
        setState(() {
          _initialized = true; // Impostiamo comunque a true per mostrare la UI
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FuelStationsProvider>(
        builder: (context, provider, child) {
          // Usiamo i dati del provider per decidere cosa mostrare
          if (!_initialized || provider.status == LoadingStatus.loading) {
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
          
          return IndexedStack(
            index: _selectedIndex,
            children: _screens,
          );
        },
      ),
      bottomNavigationBar: _initialized
        ? BottomNavigationBar(
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
          )
        : null,
      appBar: _initialized 
        ? AppBar(
            title: const Text('Fuel Scan'),
          )
        : null,
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}