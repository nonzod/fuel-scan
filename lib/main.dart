import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/home_screen.dart';

void main() async {
  // Assicuriamoci che Flutter sia inizializzato
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    print('Inizializzazione app Fuel Scan...');
    
    // Inizializzazione di Hive per lo storage locale
    await Hive.initFlutter();
    
    // Registriamo gli adapter di Hive per i nostri modelli
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(FuelStationAdapter());
    }
    
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(FuelPriceAdapter());
    }
    
    // Inizializziamo la box per le impostazioni
    await Hive.openBox('settings');
    
    print('Inizializzazione base completata, avvio UI');
  } catch (e) {
    print('Errore durante l\'inizializzazione: $e');
  }
  
  // Avviamo l'app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FuelStationsProvider()),
      ],
      child: const FuelScanApp(),
    ),
  );
}

class FuelScanApp extends StatelessWidget {
  const FuelScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fuel Scan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: Colors.orange,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}