import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'fuel_price.g.dart';

@HiveType(typeId: 1)
class FuelPrice extends HiveObject {
  @HiveField(0)
  final String fuelType; // Benzina, Gasolio, GPL, etc.

  @HiveField(1)
  final double price;

  @HiveField(2)
  final bool isSelf; // Self service o servito

  @HiveField(3)
  final DateTime updatedAt;

  FuelPrice({
    required this.fuelType,
    required this.price,
    required this.isSelf,
    required this.updatedAt,
  });

  // Factory constructor per creare un oggetto FuelPrice da JSON
  factory FuelPrice.fromJson(Map<String, dynamic> json) {
    return FuelPrice(
      fuelType: json['descCarburante'] ?? '',
      price: double.tryParse(json['prezzo'] ?? '0') ?? 0,
      isSelf: (json['isSelf'] ?? 'true').toLowerCase() == 'true',
      updatedAt: DateFormat('dd/MM/yyyy HH:mm:ss').parse(json['dtComu'] ?? DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())),
    );
  }

  String get formattedPrice => '${price.toStringAsFixed(3)} €';
  
  String get serviceType => isSelf ? 'Self Service' : 'Servito';
}