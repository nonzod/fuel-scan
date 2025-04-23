import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/map_screen.dart';
import 'package:fuel_scan/screens/list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _initialized = false;
  final List<Widget> _screens = [
    const MapScreen(),
    const ListScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Inizializzazione dei dati
    _initializeData();
  }
  
  Future<void> _initializeData() async {
    try {
      final provider = context.read<FuelStationsProvider>();
      
      if (provider.status == LoadingStatus.idle) {
        await provider.initialize();
      }
      
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
      body: _initialized 
        ? IndexedStack(
            index: _selectedIndex,
            children: _screens,
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Caricamento stazioni di servizio...'),
              ],
            ),
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
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}