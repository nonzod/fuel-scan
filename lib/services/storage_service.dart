import 'package:hive_flutter/hive_flutter.dart';
import 'package:fuel_scan/models/fuel_station.dart';

class StorageService {
  static const String _stationsBox = 'stations';
  static const String _settingsBox = 'settings';
  static const String _lastUpdateKey = 'last_update';
  
  // Aggiorna i dati ogni 24 ore
  static const Duration _updateInterval = Duration(hours: 24);
  
  // Metodo per salvare le stazioni nel database locale
  Future<void> saveStations(List<FuelStation> stations) async {
    try {
      final box = await Hive.openBox<FuelStation>(_stationsBox);
      
      // Svuota il box e inserisci i nuovi dati
      await box.clear();
      await box.addAll(stations);
      
      // Aggiorna la data dell'ultimo aggiornamento
      final settingsBox = await Hive.openBox(_settingsBox);
      await settingsBox.put(_lastUpdateKey, DateTime.now().toIso8601String());
      
      await box.close();
      
      print('Salvate ${stations.length} stazioni nel database locale');
    } catch (e) {
      print('Errore nel salvataggio delle stazioni: $e');
    }
  }
  
  // Metodo per caricare le stazioni dal database locale
  Future<List<FuelStation>> loadStations() async {
    try {
      final box = await Hive.openBox<FuelStation>(_stationsBox);
      
      final stations = box.values.toList();
      
      await box.close();
      return stations;
    } catch (e) {
      print('Errore nel caricamento delle stazioni: $e');
      return []; // In caso di errore, restituisci una lista vuota
    }
  }
  
  // Metodo per verificare se è necessario un aggiornamento
  Future<bool> needsUpdate() async {
    try {
      final settingsBox = await Hive.openBox(_settingsBox);
      final lastUpdateStr = settingsBox.get(_lastUpdateKey) as String?;
      
      if (lastUpdateStr == null) {
        return true;
      }
      
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();
      
      return now.difference(lastUpdate) > _updateInterval;
    } catch (e) {
      print('Errore nel controllo della data di aggiornamento: $e');
      return true; // In caso di errore, meglio aggiornare
    }
  }
  
  // Metodo per cancellare tutti i dati
  Future<void> clearAllData() async {
    final stationsBox = await Hive.openBox<FuelStation>(_stationsBox);
    final settingsBox = await Hive.openBox(_settingsBox);
    
    await stationsBox.clear();
    await settingsBox.clear();
    
    await stationsBox.close();
  }
}