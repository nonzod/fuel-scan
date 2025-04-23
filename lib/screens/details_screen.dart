import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsScreen extends StatelessWidget {
  final FuelStation station;

  const DetailsScreen({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(station.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 16),
            _buildPricesCard(context),
            const SizedBox(height: 16),
            _buildNavigationButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    station.brand,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.location_on, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${station.address}, ${station.city} (${station.province})',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            if (station.distance != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Distanza: ${station.distance!.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPricesCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Prezzi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (station.lastUpdate != null)
                  Text(
                    'Aggiornato: ${DateFormat('dd/MM/yyyy').format(station.lastUpdate!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            const Divider(),
            if (station.prices.isEmpty)
              const Text('Nessun prezzo disponibile')
            else
              for (var price in station.prices)
                _buildPriceRow(context, price),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, FuelPrice price) {
    Color priceColor;
    
    // Logica semplificata per il colore del prezzo
    if (price.price < 1.5) {
      priceColor = Colors.green;
    } else if (price.price < 1.8) {
      priceColor = Colors.orange;
    } else {
      priceColor = Colors.red;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              price.fuelType,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price.serviceType,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              price.formattedPrice,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: priceColor,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _launchMapsUrl();
        },
        icon: const Icon(Icons.directions),
        label: const Text('Naviga'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _launchMapsUrl() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${station.latitude},${station.longitude}'
    );
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      // Se non possiamo aprire l'URL, potremmo mostrare un messaggio di errore
      // o provare con un'altra app di navigazione
    }
  }
}