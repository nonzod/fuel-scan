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
        // Determinare la codifica corretta
        String responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        return _parseStationsCSV(responseBody);
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
        // Determinare la codifica corretta
        String responseBody = utf8.decode(response.bodyBytes, allowMalformed: true);
        return _parsePricesCSV(responseBody);
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

  // Metodo migliorato per il parsing del CSV delle stazioni con maggiore robustezza
  List<FuelStation> _parseStationsCSV(String csvData) {
    try {
      // Dividiamo per righe e saltiamo le prime due righe (titolo e intestazione)
      final lines = csvData.split('\n');
      if (lines.length <= 2) {
        print('CSV stazioni vuoto o malformato');
        return [];
      }
      
      // Rimuoviamo le prime due righe (titolo e intestazione)
      lines.removeAt(0); // Rimuove il titolo
      if (lines.isNotEmpty) {
        lines.removeAt(0); // Rimuove l'intestazione
      }
      
      final stations = <FuelStation>[];
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          // Utilizziamo un parser CSV più robusto
          final fields = _parseCSVLineRobust(line, separator: ';');
          
          // Verifichiamo che abbiamo abbastanza campi
          if (fields.length < 8) {
            print('Riga CSV stazione malformata (campi insufficienti): ${fields.length} campi - $line');
            continue;
          }
          
          final id = fields[0].trim();
          final name = fields[1].trim();
          final brand = fields[2].trim();
          final address = fields.length > 5 ? fields[5].trim() : '';
          final city = fields.length > 6 ? fields[6].trim() : '';
          final province = fields.length > 7 ? fields[7].trim() : '';
          
          // Gestione più robusta delle coordinate, correzione per valori NULL
          double? latitude;
          double? longitude;
          
          if (fields.length > 8) {
            final latStr = fields[8].trim().toUpperCase();
            latitude = latStr == "NULL" ? null : double.tryParse(latStr.replaceAll(',', '.'));
          }
          
          if (fields.length > 9) {
            final longStr = fields[9].trim().toUpperCase();
            longitude = longStr == "NULL" ? null : double.tryParse(longStr.replaceAll(',', '.'));
          }
          
          // Validazione
          if (id.isEmpty) {
            print('ID vuoto, ignorato: $line');
            continue;
          }
          
          if (latitude == null || longitude == null) {
            print('Coordinate mancanti o non valide, usando valori di default: $line');
            // Usiamo coordinate di default per Roma invece di saltare la stazione
            latitude = latitude ?? 41.9028;
            longitude = longitude ?? 12.4964;
          }
          
          stations.add(FuelStation(
            id: id,
            name: name,
            brand: brand,
            address: address,
            city: city,
            province: province,
            latitude: latitude,
            longitude: longitude,
          ));
        } catch (e) {
          print('Errore nel parsing della stazione: $e - Riga: $line');
        }
      }
      
      print('Trovate ${stations.length} stazioni');
      return stations;
    } catch (e) {
      print('Errore nel parsing delle stazioni: $e');
      return [];
    }
  }

  // Metodo migliorato per il parsing del CSV dei prezzi
  Map<String, List<FuelPrice>> _parsePricesCSV(String csvData) {
    try {
      final prices = <String, List<FuelPrice>>{};
      
      // Dividiamo per righe e saltiamo le prime due righe (titolo e intestazione)
      final lines = csvData.split('\n');
      if (lines.length <= 2) {
        print('CSV prezzi vuoto o malformato');
        return prices;
      }
      
      // Rimuoviamo le prime due righe (titolo e intestazione)
      lines.removeAt(0); // Rimuove il titolo
      if (lines.isNotEmpty) {
        lines.removeAt(0); // Rimuove l'intestazione
      }
      
      print('Analisi di ${lines.length} righe di prezzi...');
      
      for (var line in lines) {
        if (line.trim().isEmpty) continue;
        
        try {
          // Utilizziamo un parser CSV più robusto
          final fields = _parseCSVLineRobust(line, separator: ';');
          
          if (fields.length < 4) {
            print('Riga CSV prezzo malformata (campi insufficienti): ${fields.length} campi - $line');
            continue;
          }
          
          final stationId = fields[0].trim();
          if (stationId.isEmpty) {
            print('ID stazione mancante: $line');
            continue;
          }
          
          // Ricaviamo i dati dai campi appropriati
          String fuelType = fields.length > 1 ? fields[1].trim() : '';
          String priceStr = fields.length > 2 ? fields[2].trim().replaceAll(',', '.') : '0';
          String isSelfStr = fields.length > 3 ? fields[3].trim().toLowerCase() : 'true';
          
          double priceValue = double.tryParse(priceStr) ?? 0;
          // Interpretiamo correttamente il campo isSelf
          bool isSelf = isSelfStr == '1' || isSelfStr == 'true' || isSelfStr == 'self';
          
          if (fuelType.isEmpty) {
            print('Tipo carburante incompleto: $line');
            continue;
          }
          
          DateTime updateDate;
          try {
            if (fields.length > 4) {
              final dateStr = fields[4].trim();
              updateDate = DateTime.parse(dateStr);
            } else {
              updateDate = DateTime.now();
            }
          } catch (e) {
            updateDate = DateTime.now();
          }
          
          final fuelPrice = FuelPrice(
            fuelType: fuelType,
            price: priceValue,
            isSelf: isSelf,
            updatedAt: updateDate,
          );
          
          if (!prices.containsKey(stationId)) {
            prices[stationId] = [];
          }
          
          prices[stationId]!.add(fuelPrice);
        } catch (e) {
          print('Errore nel parsing del prezzo: $e - Riga: $line');
        }
      }
      
      print('Trovati prezzi per ${prices.length} stazioni');
      return prices;
    } catch (e) {
      print('Errore nel parsing dei prezzi: $e');
      return {};
    }
  }

  // Metodo migliorato per dividere correttamente le linee CSV (gestendo le virgolette)
  List<String> _parseCSVLineRobust(String line, {String separator = ';'}) {
    List<String> result = [];
    
    int i = 0;
    bool inQuotes = false;
    String currentField = '';
    
    // Gestiamo il caso in cui la riga sia vuota
    if (line.isEmpty) {
      return [];
    }
    
    while (i < line.length) {
      final char = line[i];
      
      if (char == '"') {
        // Se abbiamo una virgoletta, controlliamo se è escapata o se è di chiusura/apertura
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Virgoletta escapata all'interno di un campo tra virgolette
          currentField += '"';
          i++; // Saltiamo la seconda virgoletta
        } else {
          // Cambio dello stato delle virgolette (apriamo o chiudiamo)
          inQuotes = !inQuotes;
        }
      } else if (char == separator && !inQuotes) {
        // Abbiamo trovato un separatore fuori dalle virgolette, fine del campo
        result.add(currentField);
        currentField = '';
      } else {
        // Carattere normale, aggiungilo al campo corrente
        currentField += char;
      }
      
      i++;
    }
    
    // Aggiungi l'ultimo campo
    result.add(currentField);
    
    // Rimuoviamo gli eventuali spazi e virgolette iniziali/finali
    return result.map((field) {
      field = field.trim();
      // Rimuoviamo le virgolette iniziali e finali se presenti
      if (field.startsWith('"') && field.endsWith('"') && field.length >= 2) {
        field = field.substring(1, field.length - 1);
      }
      return field;
    }).toList();
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
            fuelType: 'Benzina',
            price: 1.799,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
          FuelPrice(
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
            fuelType: 'Benzina',
            price: 1.849,
            isSelf: true,
            updatedAt: DateTime.now(),
          ),
          FuelPrice(
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
          fuelType: 'Benzina',
          price: 1.799,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
        FuelPrice(
          fuelType: 'Gasolio',
          price: 1.699,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
      ],
      '2': [
        FuelPrice(
          fuelType: 'Benzina',
          price: 1.849,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
        FuelPrice(
          fuelType: 'Gasolio',
          price: 1.749,
          isSelf: true,
          updatedAt: DateTime.now(),
        ),
      ],
    };
  }
}