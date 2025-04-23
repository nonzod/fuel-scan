import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_scan/models/fuel_station.dart';

class StorageService {
  static const String stationsBoxName = 'fuel_stations';
  static const String settingsBoxName = 'settings';
  static const String lastUpdateKey = 'last_update';
  
  // Metodo per salvare le stazioni nel database locale
  Future<void> saveStations(List<FuelStation> stations) async {
    final box = await Hive.openBox<FuelStation>(stationsBoxName);
    
    // Prima cancella tutti i dati
    await box.clear();
    
    // Poi inserisci le nuove stazioni
    await box.addAll(stations);
    
    // Aggiorna la data dell'ultimo aggiornamento
    final settingsBox = await Hive.openBox(settingsBoxName);
    await settingsBox.put(lastUpdateKey, DateTime.now().toIso8601String());
    
    await box.close();
  }
  
  // Metodo per caricare le stazioni dal database locale
  Future<List<FuelStation>> loadStations() async {
    final box = await Hive.openBox<FuelStation>(stationsBoxName);
    final stations = box.values.toList();
    await box.close();
    return stations;
  }
  
  // Metodo per verificare se è necessario un aggiornamento
  // Per ora, aggiorniamo ogni 24 ore
  Future<bool> needsUpdate() async {
    final settingsBox = await Hive.openBox(settingsBoxName);
    final lastUpdateStr = settingsBox.get(lastUpdateKey);
    
    if (lastUpdateStr == null) {
      return true;
    }
    
    final lastUpdate = DateTime.parse(lastUpdateStr);
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    
    return difference.inHours >= 24;
  }
}