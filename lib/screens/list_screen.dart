import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/details_screen.dart';
import 'package:fuel_scan/widgets/filter_bottom_sheet.dart';
import 'package:fuel_scan/widgets/station_list_item.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FuelStationsProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Fuel Scan - Lista'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  provider.refreshData();
                },
              ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () {
                  _showFilterBottomSheet(context);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    provider.setSearchQuery(value);
                  },
                  decoration: const InputDecoration(
                    labelText: 'Cerca',
                    hintText: 'Nome, città o indirizzo',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Expanded(
                child: _buildStationsList(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStationsList(
    BuildContext context, 
    FuelStationsProvider provider
  ) {
    if (provider.status == LoadingStatus.loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (provider.status == LoadingStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 16),
            Text(provider.errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                provider.initialize();
              },
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    if (provider.filteredStations.isEmpty) {
      return const Center(
        child: Text('Nessuna stazione trovata'),
      );
    }

    return ListView.builder(
      itemCount: provider.filteredStations.length,
      itemBuilder: (context, index) {
        final station = provider.filteredStations[index];
        return StationListItem(
          station: station,
          onTap: () => _navigateToDetails(context, station),
          selectedFuelType: provider.selectedFuelType,
        );
      },
    );
  }

  void _navigateToDetails(BuildContext context, FuelStation station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailsScreen(station: station),
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}