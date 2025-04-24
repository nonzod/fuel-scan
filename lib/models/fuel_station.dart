import 'package:hive/hive.dart';
import 'fuel_price.dart';

part 'fuel_station.g.dart';

@HiveType(typeId: 0)
class FuelStation extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String brand;

  @HiveField(3)
  final String address;

  @HiveField(4)
  final String city;

  @HiveField(5)
  final String province;

  @HiveField(6)
  final double latitude;

  @HiveField(7)
  final double longitude;

  @HiveField(8)
  List<FuelPrice> prices;

  @HiveField(9)
  DateTime? lastUpdate;

  // Distanza dalla posizione corrente dell'utente (non salvata in Hive)
  double? distance;

  FuelStation({
    required this.id,
    required this.name,
    required this.brand,
    required this.address,
    required this.city,
    required this.province,
    required this.latitude,
    required this.longitude,
    List<FuelPrice>? prices,
    this.lastUpdate,
    this.distance,
  }) : prices = prices != null ? List<FuelPrice>.from(prices) : [];

  // Metodo per trovare il prezzo di un tipo specifico di carburante
  FuelPrice? getPriceByFuelType(String fuelType) {
    try {
      // Cerca in modo case-insensitive e considera prezzi self-service se disponibili
      final selfPrices = prices.where(
        (price) => price.fuelType.toLowerCase().contains(fuelType.toLowerCase()) && price.isSelf
      ).toList();
      
      // Se ci sono prezzi self-service, restituisci il più basso
      if (selfPrices.isNotEmpty) {
        return selfPrices.reduce((curr, next) => curr.price < next.price ? curr : next);
      }
      
      // Altrimenti, cerca tra tutti i prezzi di quel tipo di carburante
      final allPrices = prices.where(
        (price) => price.fuelType.toLowerCase().contains(fuelType.toLowerCase())
      ).toList();
      
      if (allPrices.isNotEmpty) {
        return allPrices.reduce((curr, next) => curr.price < next.price ? curr : next);
      }
      
      return null;
    } catch (e) {
      print('Errore nella ricerca del prezzo: $e');
      return null;
    }
  }

  // Factory constructor per creare un oggetto FuelStation da JSON
  factory FuelStation.fromJson(Map<String, dynamic> json) {
    return FuelStation(
      id: json['idImpianto'] ?? '',
      name: json['nomeGestore'] ?? '',
      brand: json['bandiera'] ?? '',
      address: json['indirizzo'] ?? '',
      city: json['comune'] ?? '',
      province: json['provincia'] ?? '',
      latitude: double.tryParse(json['latitudine'] ?? '0') ?? 0,
      longitude: double.tryParse(json['longitudine'] ?? '0') ?? 0,
      lastUpdate: DateTime.now(),
    );
  }

  // Metodo per aggiungere o aggiornare i prezzi
  void updatePrices(List<FuelPrice> newPrices) {
    for (var newPrice in newPrices) {
      final existingIndex = prices.indexWhere(
        (p) => p.fuelType == newPrice.fuelType && p.isSelf == newPrice.isSelf
      );
      
      if (existingIndex >= 0) {
        prices[existingIndex] = newPrice;
      } else {
        prices.add(newPrice);
      }
    }
    lastUpdate = DateTime.now();
  }
}