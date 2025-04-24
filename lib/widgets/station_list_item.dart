import 'package:flutter/material.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';

class StationListItem extends StatelessWidget {
  final FuelStation station;
  final VoidCallback onTap;
  final FuelType selectedFuelType;

  const StationListItem({
    super.key,
    required this.station,
    required this.onTap,
    required this.selectedFuelType,
  });

  @override
  Widget build(BuildContext context) {
    final price = _getPriceForSelectedFuelType();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.brand,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${station.address}, ${station.city}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (price != null)
                    Text(
                      price.formattedPrice,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getPriceColor(price),
                      ),
                    ),
                  if (price != null)
                    Text(
                      price.serviceType,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  if (station.distance != null)
                    Text(
                      '${station.distance!.toStringAsFixed(2)} km',
                      style: const TextStyle(fontSize: 14),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  FuelPrice? _getPriceForSelectedFuelType() {
    final fuelTypeStr = selectedFuelType.toString().split('.').last;
    return station.getPriceByFuelType(fuelTypeStr);
  }

  Color _getPriceColor(FuelPrice price) {
    // Logica semplificata per il colore del prezzo
    if (price.price < 1.5) {
      return Colors.green;
    } else if (price.price < 1.8) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}