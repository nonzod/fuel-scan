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
        return _parseStationsCSV(response.body);
      } else {
        print('Errore nel download delle stazioni: ${response.statusCode}');
        throw Exception('Errore nel download delle stazioni: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore nella richiesta HTTP delle stazioni: $e');
      
      // Per debug e test, crea una stazione fittizia se ci sono errori
      if (e.toString().contains('Failed host lookup')) {
        print('Generando dati di test...');
        return _generateTestStations();
      }
      
      throw Exception('Errore nella richiesta HTTP: $e');
    }
  }

  // Metodo per scaricare i prezzi
  Future<Map<String, List<FuelPrice>>> fetchFuelPrices() async {
    try {
      final response = await http.get(Uri.parse(pricesUrl));
      
      if (response.statusCode == 200) {
        return _parsePricesCSV(response.body);
      } else {
        print('Errore nel download dei prezzi: ${response.statusCode}');
        throw Exception('Errore nel download dei prezzi: ${response.statusCode}');
      }
    } catch (e) {
      print('Errore nella richiesta HTTP dei prezzi: $e');
      
      // Per debug e test, crea prezzi fittizi se ci sono errori
      if (e.toString().contains('Failed host lookup')) {
        print('Generando prezzi di test...');
        return _generateTestPrices();
      }
      
      throw Exception('Errore nella richiesta HTTP: $e');
    }
  }

  // Metodo per il parsing del CSV delle stazioni
  List<FuelStation> _parseStationsCSV(String csvData) {
    try {
      // Dividiamo per righe e saltiamo l'intestazione
      final lines = csvData.split('\n');
      if (lines.length <= 1) {
        print('CSV stazioni vuoto o malformato');
        return [];
      }
      
      lines.removeAt(0); // Rimuoviamo l'intestazione
      
      final stations = <FuelStation>[];
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Gestisci correttamente le virgolette nei CSV
        final fields = _parseCSVLine(line);
        if (fields.length < 8) {
          print('Riga CSV stazione malformata: $line');
          continue;
        }
        
        try {
          stations.add(FuelStation(
            id: fields[0],
            name: fields[1],
            brand: fields[2],
            address: fields[3],
            city: fields[4],
            province: fields[5],
            latitude: double.tryParse(fields[6].replaceAll(',', '.')) ?? 0,
            longitude: double.tryParse(fields[7].replaceAll(',', '.')) ?? 0,
          ));
        } catch (e) {
          print('Errore nel parsing della stazione: $e');
        }
      }
      
      print('Trovate ${stations.length} stazioni');
      return stations;
    } catch (e) {
      print('Errore nel parsing delle stazioni: $e');
      return [];
    }
  }

  // Metodo per il parsing del CSV dei prezzi
  Map<String, List<FuelPrice>> _parsePricesCSV(String csvData) {
    try {
      final prices = <String, List<FuelPrice>>{};
      
      // Dividiamo per righe e saltiamo l'intestazione
      final lines = csvData.split('\n');
      if (lines.length <= 1) {
        print('CSV prezzi vuoto o malformato');
        return prices;
      }
      
      lines.removeAt(0); // Rimuoviamo l'intestazione
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        // Gestisci correttamente le virgolette nei CSV
        final fields = _parseCSVLine(line);
        if (fields.length < 5) {
          print('Riga CSV prezzo malformata: $line');
          continue;
        }
        
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
      
      print('Trovati prezzi per ${prices.length} stazioni');
      return prices;
    } catch (e) {
      print('Errore nel parsing dei prezzi: $e');
      return {};
    }
  }

  // Metodo per dividere correttamente le linee CSV (gestendo le virgolette)
  List<String> _parseCSVLine(String line) {
    List<String> result = [];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ';' && !inQuotes) {
        result.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    // Aggiungi l'ultimo campo
    result.add(currentField.trim());
    
    return result;
  }
  
  // Dati di test per il debug
  List<FuelStation> _generateTestStations() {
    return [
      FuelStation(
        id: '1',
        name: 'Distributore Test 1',
        brand: 'Q8',
        address: 'Via Roma 123',
        city: 'Roma',
        province: 'RM',
        latitude: 41.9028,
        longitude: 12.4964,
        prices: [
          FuelPrice(
            id: '1',
            fuelType: 'Benzina',
            price: 1.799,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
          FuelPrice(
            id: '2',
            fuelType: 'Gasolio',
            price: 1.699,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
        ],
      ),
      FuelStation(
        id: '2',
        name: 'Distributore Test 2',
        brand: 'ENI',
        address: 'Via Milano 456',
        city: 'Roma',
        province: 'RM',
        latitude: 41.9100,
        longitude: 12.5000,
        prices: [
          FuelPrice(
            id: '3',
            fuelType: 'Benzina',
            price: 1.849,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
          FuelPrice(
            id: '4',
            fuelType: 'Gasolio',
            price: 1.749,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
        ],
      ),
    ];
  }
  
  // Dati di test per i prezzi
  Map<String, List<FuelPrice>> _generateTestPrices() {
    return {
      '1': [
        FuelPrice(
          id: '1',
          fuelType: 'Benzina',
          price: 1.799,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
        FuelPrice(
          id: '2',
          fuelType: 'Gasolio',
          price: 1.699,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
      ],
      '2': [
        FuelPrice(
          id: '3',
          fuelType: 'Benzina',
          price: 1.849,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
        FuelPrice(
          id: '4',
          fuelType: 'Gasolio',
          price: 1.749,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
      ],
    };
  }
}