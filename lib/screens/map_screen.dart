import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/providers/fuel_stations_provider.dart';
import 'package:fuel_scan/screens/details_screen.dart';
import 'package:fuel_scan/widgets/filter_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  @override
  Widget build(BuildContext context) {
    return Consumer<FuelStationsProvider>(
      builder: (context, provider, child) {
        _updateMarkers(provider.filteredStations);
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Fuel Scan - Mappa'),
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
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: provider.currentPosition != null
                      ? LatLng(
                          provider.currentPosition!.latitude,
                          provider.currentPosition!.longitude)
                      : const LatLng(41.9028, 12.4964), // Roma come fallback
                  zoom: 12.0,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
              ),
              if (provider.status == LoadingStatus.loading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (provider.status == LoadingStatus.error)
                Center(
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
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _centerOnUserLocation,
            child: const Icon(Icons.my_location),
          ),
        );
      },
    );
  }

  void _updateMarkers(List<FuelStation> stations) {
    final markers = <Marker>{};
    
    for (var station in stations) {
      final marker = Marker(
        markerId: MarkerId(station.id),
        position: LatLng(station.latitude, station.longitude),
        infoWindow: InfoWindow(
          title: station.name,
          snippet: station.brand,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(station: station),
              ),
            );
          },
        ),
        onTap: () {
          _mapController?.showMarkerInfoWindow(MarkerId(station.id));
        },
      );
      
      markers.add(marker);
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _centerOnUserLocation() {
    final provider = Provider.of<FuelStationsProvider>(context, listen: false);
    
    if (provider.currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            provider.currentPosition!.latitude,
            provider.currentPosition!.longitude,
          ),
        ),
      );
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}