import 'dart:convert';
import 'dart:io';

/*
 * Questo script genera o aggiorna il file keys.json per includere le chiavi AdMob
 * Utilizzo: dart scripts/generate_admob_keys.dart [android_app_id] [ios_app_id]
 * 
 * Esempio:
 * dart scripts/generate_admob_keys.dart ca-app-pub-1234567890123456~1234567890 ca-app-pub-1234567890123456~0987654321
 */

void main(List<String> args) async {
  if (args.length < 2) {
    print('Utilizzo: dart scripts/generate_admob_keys.dart [android_app_id] [ios_app_id]');
    exit(1);
  }

  final androidAppId = args[0];
  final iosAppId = args[1];
  
  // Percorso al file keys.json
  final keysPath = 'assets/config/keys.json';
  
  try {
    // Assicurati che la directory esista
    final directory = Directory('assets/config');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      print('Creata directory assets/config');
    }
    
    // Verifica se il file esiste già
    final keysFile = File(keysPath);
    Map<String, dynamic> keysData = {};
    
    if (await keysFile.exists()) {
      print('Il file keys.json esiste già, lo aggiorno...');
      final String content = await keysFile.readAsString();
      keysData = json.decode(content);
    } else {
      print('Creo un nuovo file keys.json...');
    }
    
    // Aggiungi o aggiorna le chiavi AdMob
    keysData['admob_android_app_id'] = androidAppId;
    keysData['admob_ios_app_id'] = iosAppId;
    
    // Se manca la chiave di Google Maps, aggiungi un placeholder
    if (!keysData.containsKey('google_maps_api_key')) {
      keysData['google_maps_api_key'] = 'YOUR_GOOGLE_MAPS_API_KEY';
    }
    
    // Salva il file
    await keysFile.writeAsString(json.encode(keysData, indent: 2));
    
    print('File keys.json aggiornato con successo!');
    print('Percorso: ${keysFile.absolute.path}');
    print('Contenuto:');
    print(json.encode(keysData, indent: 2));
  } catch (e) {
    print('Errore durante la generazione del file keys.json: $e');
    exit(1);
  }
}