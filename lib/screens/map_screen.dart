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
  bool _mapInitialized = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<FuelStationsProvider>(
      builder: (context, provider, child) {
        // Aggiorniamo i marker quando i dati filtrati cambiano
        if (provider.filteredStations.isNotEmpty) {
          _updateMarkers(provider.filteredStations);
        }
        
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
                  setState(() {
                    _mapInitialized = true;
                  });
                  
                  if (provider.filteredStations.isNotEmpty) {
                    _updateMarkers(provider.filteredStations);
                  }
                  
                  if (provider.currentPosition != null) {
                    _centerOnUserLocation();
                  }
                },
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                mapToolbarEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: true,
              ),
              if (provider.status == LoadingStatus.loading)
                const Center(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 8),
                          Text('Caricamento...'),
                        ],
                      ),
                    ),
                  ),
                ),
              if (provider.status == LoadingStatus.error)
                Center(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error, size: 50, color: Colors.red),
                          const SizedBox(height: 8),
                          Text(provider.errorMessage),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              provider.initialize();
                            },
                            child: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_mapInitialized && _markers.isEmpty && provider.status == LoadingStatus.success)
                Center(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.info, size: 50, color: Colors.blue),
                          const SizedBox(height: 8),
                          const Text('Nessuna stazione trovata'),
                          const SizedBox(height: 8),
                          const Text('Prova a modificare i filtri'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _showFilterBottomSheet(context);
                            },
                            child: const Text('Filtri'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _centerOnUserLocation,
            tooltip: 'Vai alla mia posizione',
            child: const Icon(Icons.my_location),
          ),
        );
      },
    );
  }

  void _updateMarkers(List<FuelStation> stations) {
    try {
      print('Aggiornamento marker sulla mappa: ${stations.length} stazioni');
      final markers = <Marker>{};
      
      for (var station in stations) {
        final marker = Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: _getInfoSnippet(station),
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
            try {
              _mapController?.showMarkerInfoWindow(MarkerId(station.id));
            } catch (e) {
              print('Errore nel mostrare la finestra info del marker: $e');
            }
          },
        );
        
        markers.add(marker);
      }
      
      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    } catch (e) {
      print('Errore nell\'aggiornamento dei marker: $e');
    }
  }
  
  String _getInfoSnippet(FuelStation station) {
    final provider = Provider.of<FuelStationsProvider>(context, listen: false);
    final fuelType = provider.selectedFuelType.toString().split('.').last;
    
    String snippet = station.brand;
    
    // Aggiungiamo il prezzo se disponibile
    final price = station.getPriceByFuelType(fuelType);
    if (price != null) {
      snippet += ' - ${fuelType.toUpperCase()}: ${price.formattedPrice}';
    }
    
    // Aggiungiamo la distanza se disponibile
    if (station.distance != null) {
      snippet += ' - ${station.distance!.toStringAsFixed(1)} km';
    }
    
    return snippet;
  }

  void _centerOnUserLocation() {
    try {
      final provider = Provider.of<FuelStationsProvider>(context, listen: false);
      
      if (provider.currentPosition != null) {
        print('Centratura mappa su posizione utente: ${provider.currentPosition!.latitude}, ${provider.currentPosition!.longitude}');
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(
              provider.currentPosition!.latitude,
              provider.currentPosition!.longitude,
            ),
            14.0, // Livello di zoom
          ),
        );
      } else {
        print('Impossibile centrare: posizione utente non disponibile');
        // Mostra un messaggio all'utente
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Posizione non disponibile'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Errore nella centratura sulla posizione utente: $e');
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      builder: (context) => const FilterBottomSheet(),
    );
  }
}