import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';

class ApiService {
  // URL dei dati del MISE
  static const String pricesUrl = 'https://www.mise.gov.it/images/exportCSV/prezzo_alle_8.csv';
  static const String stationsUrl = 'https://www.mise.gov.it/images/exportCSV/anagrafica_impianti_attivi.csv';

  // Metodo per scaricare le stazioni di servizio
  Future<List<FuelStation>> fetchFuelStations() async {
    try {
      final response = await http.get(Uri.parse(stationsUrl));
      
      if (response.statusCode == 200) {
        // Qui dovremmo fare il parsing del CSV
        // Per ora ritorniamo una lista vuota
        return _parseStationsCSV(response.body);
      } else {
        throw Exception('Errore nel download delle stazioni: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella richiesta HTTP: $e');
    }
  }

  // Metodo per scaricare i prezzi
  Future<Map<String, List<FuelPrice>>> fetchFuelPrices() async {
    try {
      final response = await http.get(Uri.parse(pricesUrl));
      
      if (response.statusCode == 200) {
        // Qui dovremmo fare il parsing del CSV
        // Per ora ritorniamo una mappa vuota
        return _parsePricesCSV(response.body);
      } else {
        throw Exception('Errore nel download dei prezzi: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Errore nella richiesta HTTP: $e');
    }
  }

  // Metodo per il parsing del CSV delle stazioni
  List<FuelStation> _parseStationsCSV(String csvData) {
    // Implementazione temporanea
    // Qui dovremmo fare il parsing del CSV reale
    
    // Dividiamo per righe e saltiamo l'intestazione
    final lines = csvData.split('\n');
    if (lines.length <= 1) return [];
    
    lines.removeAt(0); // Rimuoviamo l'intestazione
    
    final stations = <FuelStation>[];
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      final fields = line.split(';');
      if (fields.length < 7) continue;
      
      try {
        stations.add(FuelStation(
          id: fields[0],
          name: fields[1],
          brand: fields[2],
          address: fields[3],
          city: fields[4],
          province: fields[5],
          latitude: double.tryParse(fields[6]) ?? 0,
          longitude: double.tryParse(fields[7]) ?? 0,
        ));
      } catch (e) {
        print('Errore nel parsing della stazione: $e');
      }
    }
    
    return stations;
  }

  // Metodo per il parsing del CSV dei prezzi
  Map<String, List<FuelPrice>> _parsePricesCSV(String csvData) {
    // Implementazione temporanea
    // Qui dovremmo fare il parsing del CSV reale
    
    final prices = <String, List<FuelPrice>>{};
    
    // Dividiamo per righe e saltiamo l'intestazione
    final lines = csvData.split('\n');
    if (lines.length <= 1) return prices;
    
    lines.removeAt(0); // Rimuoviamo l'intestazione
    
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      
      final fields = line.split(';');
      if (fields.length < 5) continue;
      
      try {
        final stationId = fields[0];
        final price = FuelPrice(
          id: fields[1],
          fuelType: fields[2],
          price: double.tryParse(fields[3].replaceAll(',', '.')) ?? 0,
          isSelf: fields[4].toLowerCase() == 'self',
          updatedAt: DateTime.now(),
        );
        
        if (!prices.containsKey(stationId)) {
          prices[stationId] = [];
        }
        
        prices[stationId]!.add(price);
      } catch (e) {
        print('Errore nel parsing del prezzo: $e');
      }
    }
    
    return prices;
  }
}