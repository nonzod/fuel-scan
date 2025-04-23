import 'package:geolocator/geolocator.dart';
import 'package:fuel_scan/models/fuel_station.dart';

class LocationService {
  // Metodo per richiedere il permesso di localizzazione
  Future<bool> requestPermission() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;
  
      // Controlla se i servizi di localizzazione sono abilitati
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Servizi di localizzazione disabilitati');
        // Non possiamo abilitare il servizio di localizzazione programmaticamente
        // quindi restituiamo false e gestiamo questo caso nell'UI
        return false;
      }
  
      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        print('Richiedo permesso di localizzazione');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Permesso di localizzazione negato');
          return false;
        }
      }
  
      if (permission == LocationPermission.deniedForever) {
        print('Permesso di localizzazione negato permanentemente');
        return false;
      }
  
      print('Permesso di localizzazione concesso');
      return true;
    } catch (e) {
      print('Errore nella richiesta dei permessi di localizzazione: $e');
      return false;
    }
  }

  // Metodo per ottenere la posizione attuale
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      
      if (!hasPermission) {
        print('Impossibile ottenere la posizione: permesso non concesso');
        // Usa una posizione di default per Roma
        return Position(
          longitude: 12.4964,
          latitude: 41.9028,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          // Questi campi potrebbero non essere necessari a seconda della versione di geolocator
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
  
      print('Ottenendo la posizione attuale...');
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // Timeout dopo 5 secondi
      );
    } catch (e) {
      print('Errore nel recupero della posizione: $e');
      
      // Ottieni l'ultima posizione nota invece
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          print('Usata ultima posizione nota');
          return lastPosition;
        }
      } catch (e2) {
        print('Errore nel recupero dell\'ultima posizione nota: $e2');
      }
      
      // Usa una posizione di default per Roma
      print('Usata posizione di default (Roma)');
      return Position(
        longitude: 12.4964,
        latitude: 41.9028,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        // Questi campi potrebbero non essere necessari a seconda della versione di geolocator
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // Metodo per calcolare la distanza tra la posizione attuale e le stazioni
  Future<List<FuelStation>> calculateDistances(
    List<FuelStation> stations, {
    Position? currentPosition,
  }) async {
    try {
      // Se non viene fornita la posizione attuale, tentiamo di ottenerla
      final position = currentPosition ?? await getCurrentPosition();
      
      if (position == null) {
        print('Impossibile calcolare le distanze: posizione non disponibile');
        return stations;
      }
  
      print('Calcolo delle distanze per ${stations.length} stazioni da lat: ${position.latitude}, long: ${position.longitude}');
      
      // Calcola la distanza per ogni stazione
      for (var station in stations) {
        final distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          station.latitude,
          station.longitude,
        );
        
        station.distance = distanceInMeters / 1000; // Convertiamo in km
      }
  
      return stations;
    } catch (e) {
      print('Errore nel calcolo delle distanze: $e');
      return stations;
    }
  }
}