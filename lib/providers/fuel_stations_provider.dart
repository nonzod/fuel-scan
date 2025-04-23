import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fuel_scan/models/fuel_station.dart';
import 'package:fuel_scan/models/fuel_price.dart';
import 'package:fuel_scan/services/api_service.dart';
import 'package:fuel_scan/services/location_service.dart';
import 'package:fuel_scan/services/storage_service.dart';

enum LoadingStatus { idle, loading, success, error }

enum FuelType { benzina, gasolio, gpl, metano }

enum SortOption { distance, price, name }

class FuelStationsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final StorageService _storageService = StorageService();

  List<FuelStation> _stations = [];
  List<FuelStation> _filteredStations = [];
  Position? _currentPosition;
  LoadingStatus _status = LoadingStatus.idle;
  String _errorMessage = '';

  // Filtri e opzioni di ordinamento
  String _searchQuery = '';
  FuelType _selectedFuelType = FuelType.benzina;
  SortOption _sortOption = SortOption.distance;
  double _maxDistance = 10.0; // km
  bool _onlySelfService = false;

  // Getters
  List<FuelStation> get stations => _stations;
  List<FuelStation> get filteredStations => _filteredStations;
  Position? get currentPosition => _currentPosition;
  LoadingStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  FuelType get selectedFuelType => _selectedFuelType;
  SortOption get sortOption => _sortOption;
  double get maxDistance => _maxDistance;
  bool get onlySelfService => _onlySelfService;

  // Inizializzazione
  Future<void> initialize() async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      // Carica i dati dal database locale
      _stations = await _storageService.loadStations();

      // Controlla se è necessario un aggiornamento
      if (await _storageService.needsUpdate() || _stations.isEmpty) {
        await refreshData();
      } else {
        // Aggiorna le distanze
        _currentPosition = await _locationService.getCurrentPosition();
        _stations = await _locationService.calculateDistances(
          _stations,
          currentPosition: _currentPosition,
        );

        // Applica i filtri
        _applyFilters();
      }

      _status = LoadingStatus.success;
    } catch (e) {
      _errorMessage = 'Errore durante l\'inizializzazione: $e';
      _status = LoadingStatus.error;
    }

    notifyListeners();
  }

  // Aggiornamento dati dalle API
  Future<void> refreshData() async {
    _status = LoadingStatus.loading;
    notifyListeners();

    try {
      // Ottieni la posizione attuale
      _currentPosition = await _locationService.getCurrentPosition();

      // Scarica i dati delle stazioni
      _stations = await _apiService.fetchFuelStations();

      // Scarica i prezzi
      final prices = await _apiService.fetchFuelPrices();

      // Aggiorna le stazioni con i prezzi
      for (var stationId in prices.keys) {
        final stationIndex = _stations.indexWhere((s) => s.id == stationId);

        if (stationIndex >= 0) {
          _stations[stationIndex].updatePrices(prices[stationId]!);
        }
      }

      // Calcola le distanze
      _stations = await _locationService.calculateDistances(
        _stations,
        currentPosition: _currentPosition,
      );

      // Salva i dati localmente
      await _storageService.saveStations(_stations);

      // Applica i filtri
      _applyFilters();

      _status = LoadingStatus.success;
    } catch (e) {
      _errorMessage = 'Errore durante l\'aggiornamento: $e';
      _status = LoadingStatus.error;
    }

    notifyListeners();
  }

  // Metodo per filtrare le stazioni
  void _applyFilters() {
    _filteredStations =
        _stations.where((station) {
          // Filtra per distanza
          if (station.distance != null && station.distance! > _maxDistance) {
            return false;
          }

          // Filtra per query di ricerca
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesName = station.name.toLowerCase().contains(query);
            final matchesCity = station.city.toLowerCase().contains(query);
            final matchesAddress = station.address.toLowerCase().contains(
              query,
            );

            if (!matchesName && !matchesCity && !matchesAddress) {
              return false;
            }
          }

          // Filtra per tipo di carburante
          final fuelTypeStr = _selectedFuelType.toString().split('.').last;
          final price = station.prices.firstWhere(
            (p) =>
                p.fuelType.toLowerCase().contains(fuelTypeStr) &&
                (!_onlySelfService || p.isSelf),
            orElse:
                () => FuelPrice(
                  id: '',
                  fuelType: '',
                  price: 0,
                  isSelf: false,
                  updatedAt: DateTime.now(),
                ),
          );

          return price.id.isNotEmpty;
        }).toList();

    // Ordinamento
    switch (_sortOption) {
      case SortOption.distance:
        _filteredStations.sort(
          (a, b) => (a.distance ?? double.infinity).compareTo(
            b.distance ?? double.infinity,
          ),
        );
        break;
      case SortOption.price:
        final fuelTypeStr = _selectedFuelType.toString().split('.').last;
        _filteredStations.sort((a, b) {
          final priceA =
              a.getPriceByFuelType(fuelTypeStr)?.price ?? double.infinity;
          final priceB =
              b.getPriceByFuelType(fuelTypeStr)?.price ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case SortOption.name:
        _filteredStations.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    notifyListeners();
  }

  // Metodi per aggiornare i filtri
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSelectedFuelType(FuelType type) {
    _selectedFuelType = type;
    _applyFilters();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
  }

  void setMaxDistance(double distance) {
    _maxDistance = distance;
    _applyFilters();
  }

  void setOnlySelfService(bool value) {
    _onlySelfService = value;
    _applyFilters();
  }
}
