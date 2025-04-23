import 'package:geolocator/geolocator.dart';
import 'package:fuel_scan/models/fuel_station.dart';

class LocationService {
  // Metodo per richiedere il permesso di localizzazione
  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Controlla se i servizi di localizzazione sono abilitati
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Metodo per ottenere la posizione attuale
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await requestPermission();
    
    if (!hasPermission) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      print('Errore nel recupero della posizione: $e');
      return null;
    }
  }

  // Metodo per calcolare la distanza tra la posizione attuale e le stazioni
  Future<List<FuelStation>> calculateDistances(
    List<FuelStation> stations, {
    Position? currentPosition,
  }) async {
    // Se non viene fornita la posizione attuale, tentiamo di ottenerla
    final position = currentPosition ?? await getCurrentPosition();
    
    if (position == null) {
      return stations;
    }

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
  }
}