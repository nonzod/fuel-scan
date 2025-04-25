import 'dart:convert';
import 'dart:io';

void main() async {
  try {
    // Leggi il file delle chiavi
    final keysFile = File('assets/config/keys.json');
    if (!await keysFile.exists()) {
      print('Il file keys.json non esiste');
      exit(1);
    }
    
    final keysJson = await keysFile.readAsString();
    final keys = json.decode(keysJson);
    
    // Verifica la chiave Google Maps API
    final googleMapsApiKey = keys['google_maps_api_key'];
    if (googleMapsApiKey == null || googleMapsApiKey.isEmpty) {
      print('La chiave API di Google Maps non è definita');
      exit(1);
    }
    
    // Verifica le chiavi AdMob
    final admobAndroidAppId = keys['admob_android_app_id'];
    final admobIosAppId = keys['admob_ios_app_id'];
    
    if (admobAndroidAppId == null || admobAndroidAppId.isEmpty) {
      print('ID App AdMob per Android non definito - usando l\'ID di test');
    }
    
    if (admobIosAppId == null || admobIosAppId.isEmpty) {
      print('ID App AdMob per iOS non definito - usando l\'ID di test');
    }
    
    // Aggiorna strings.xml per Android
    final stringsFile = File('android/app/src/main/res/values/strings.xml');
    if (await stringsFile.exists()) {
      String content = await stringsFile.readAsString();
      content = content.replaceAll('GOOGLE_MAPS_API_KEY', googleMapsApiKey);
      await stringsFile.writeAsString(content);
      print('Aggiornato strings.xml per Android con Google Maps API Key');
    }
    
    // Aggiorna AndroidManifest.xml per AdMob
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    if (await manifestFile.exists()) {
      String content = await manifestFile.readAsString();
      
      // Usa l'ID personalizzato o quello di test
      final adMobId = (admobAndroidAppId != null && admobAndroidAppId.isNotEmpty)
          ? admobAndroidAppId
          : 'ca-app-pub-3940256099942544~3347511713'; // ID di test
          
      content = content.replaceAll(
          'ca-app-pub-3940256099942544~3347511713', adMobId);
      await manifestFile.writeAsString(content);
      print('Aggiornato AndroidManifest.xml con ID AdMob per Android');
    }
    
    // Aggiorna Info.plist per iOS
    final infoPlistFile = File('ios/Runner/Info.plist');
    if (await infoPlistFile.exists()) {
      String content = await infoPlistFile.readAsString();
      
      // Google Maps API Key
      content = content.replaceAll('IOS_GOOGLE_MAPS_API_KEY', googleMapsApiKey);
      
      // AdMob App ID
      final adMobId = (admobIosAppId != null && admobIosAppId.isNotEmpty)
          ? admobIosAppId
          : 'ca-app-pub-3940256099942544~1458002511'; // ID di test
          
      content = content.replaceAll(
          'ca-app-pub-3940256099942544~1458002511', adMobId);
      
      await infoPlistFile.writeAsString(content);
      print('Aggiornato Info.plist per iOS con Google Maps API Key e ID AdMob');
    }
    
    print('Pre-build completato con successo');
  } catch (e) {
    print('Errore durante il pre-build: $e');
    exit(1);
  }
}