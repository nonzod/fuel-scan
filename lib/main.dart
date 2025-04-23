import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/home_screen.dart';
import 'package:fuel_scan/services/keys_service.dart';

void main() async {
  // Assicuriamoci che Flutter sia inizializzato
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inizializzazione del servizio chiavi
  await KeysService.getInstance();
  
  // Inizializzazione di Hive per lo storage locale
  await Hive.initFlutter();
  
  // Registriamo gli adapter di Hive per i nostri modelli
  Hive.registerAdapter(FuelStationAdapter());
  Hive.registerAdapter(FuelPriceAdapter());
  
  // Inizializziamo la box per le impostazioni
  await Hive.openBox('settings');
  
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