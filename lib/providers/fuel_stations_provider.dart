import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fuel_scan/models/fuel_station.dart';
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
  bool _isInitializing = false;
  
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
  bool get isInitializing => _isInitializing;
  
  // Inizializzazione ottimizzata
  Future<void> initialize() async {
    // Evitiamo di inizializzare più volte
    if (_isInitializing || _status != LoadingStatus.idle) return;
    _isInitializing = true;
    
    // Prima impostiamo lo stato di loading e notifichiamo
    _status = LoadingStatus.loading;
    notifyListeners();
    
    try {
      print('Inizializzazione FuelStationsProvider...');
      
      // Carica i dati dal database locale prima di tutto
      _stations = await _storageService.loadStations();
      print('Caricate ${_stations.length} stazioni dal database locale');
      
      // Se non ci sono stazioni locali, fai subito una chiamata all'API
      bool needsUpdate = true;
      if (_stations.isNotEmpty) {
        // Controlla se è necessario un aggiornamento solo se abbiamo dati locali
        needsUpdate = await _storageService.needsUpdate();
      }
      print('È necessario un aggiornamento? $needsUpdate');
      
      // Obtieni la posizione utente
      try {
        _currentPosition = await _locationService.getCurrentPosition();
        print('Posizione utente ottenuta: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      } catch (e) {
        print('Errore nel recupero della posizione: $e');
        // Continuiamo comunque, anche senza posizione
      }
      
      // Aggiorna le distanze delle stazioni caricate dal DB locale
      if (_stations.isNotEmpty) {
        _stations = await _locationService.calculateDistances(
          _stations, 
          currentPosition: _currentPosition
        );
      }
      
      // Se è necessario un aggiornamento o non abbiamo stazioni, scarica i dati
      if (needsUpdate || _stations.isEmpty) {
        print('Aggiornamento dati...');
        await _updateData();
      }
      
      // Applica i filtri
      _applyFilters();
      
      _status = LoadingStatus.success;
    } catch (e) {
      print('Errore durante l\'inizializzazione: $e');
      _errorMessage = 'Errore durante l\'inizializzazione: $e';
      _status = LoadingStatus.error;
      
      // In caso di errore, assicuriamoci comunque di avere qualche dato da mostrare
      if (_stations.isEmpty) {
        try {
          print('Tentativo di recupero dati di emergenza...');
          _stations = await _apiService.fetchFuelStations();
          if (_stations.isNotEmpty) {
            _applyFilters();
            _status = LoadingStatus.success;
          }
        } catch (e2) {
          print('Anche il recupero dati di emergenza è fallito: $e2');
        }
      }
    } finally {
      _isInitializing = false;
      // Assicuriamoci che ci siano sempre stazioni filtrate, anche vuote
      if (_filteredStations.isEmpty && _stations.isNotEmpty) {
        _filteredStations = List.from(_stations);
      }
      notifyListeners();
    }
  }
  
  // Metodo interno per aggiornamento dati
  Future<void> _updateData() async {
    try {
      // Scarica i dati delle stazioni
      print('Scaricamento stazioni...');
      final newStations = await _apiService.fetchFuelStations();
      print('Scaricate ${newStations.length} stazioni');
      
      if (newStations.isEmpty) {
        throw Exception('Nessuna stazione scaricata dall\'API');
      }
      
      // Scarica i prezzi
      print('Scaricamento prezzi...');
      final prices = await _apiService.fetchFuelPrices();
      print('Scaricati prezzi per ${prices.length} stazioni');
      
      // Aggiorna le stazioni con i prezzi
      print('Aggiornamento stazioni con i prezzi...');
      int updatedStations = 0;
      for (var stationId in prices.keys) {
        final stationIndex = newStations.indexWhere((s) => s.id == stationId);
        
        if (stationIndex >= 0) {
          newStations[stationIndex].updatePrices(prices[stationId]!);
          updatedStations++;
        }
      }
      print('Aggiornate $updatedStations stazioni con i prezzi');
      
      // Calcola le distanze
      print('Calcolo delle distanze...');
      if (_currentPosition != null) {
        _stations = await _locationService.calculateDistances(
          newStations,
          currentPosition: _currentPosition
        );
      } else {
        _stations = newStations;
      }
      
      // Salva i dati localmente
      print('Salvataggio dati localmente...');
      await _storageService.saveStations(_stations);
    } catch (e) {
      print('Errore durante l\'aggiornamento dati: $e');
      rethrow;
    }
  }
  
  // Aggiornamento dati dalle API (esposto pubblicamente)
  Future<void> refreshData() async {
    if (_isInitializing) return;
    _isInitializing = true;
    _status = LoadingStatus.loading;
    notifyListeners();
    
    try {
      print('Aggiornamento dati...');
      
      // Ottieni la posizione attuale
      try {
        _currentPosition = await _locationService.getCurrentPosition();
        print('Posizione attuale aggiornata: ${_currentPosition?.latitude}, ${_currentPosition?.longitude}');
      } catch (e) {
        print('Errore nel recupero della posizione durante l\'aggiornamento: $e');
        // Continuiamo comunque, anche senza posizione
      }
      
      // Esegui l'aggiornamento dei dati
      await _updateData();
      
      // Applica i filtri
      _applyFilters();
      
      _status = LoadingStatus.success;
      print('Aggiornamento completato con successo');
    } catch (e) {
      print('Errore durante l\'aggiornamento: $e');
      _errorMessage = 'Errore durante l\'aggiornamento: $e';
      _status = LoadingStatus.error;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }
  
  // Metodo per filtrare le stazioni
  void _applyFilters() {
    try {
      print('Applicazione filtri alle ${_stations.length} stazioni...');
      
      // Se non ci sono stazioni, evitiamo di filtrare
      if (_stations.isEmpty) {
        _filteredStations = [];
        return;
      }
      
      _filteredStations = _stations.where((station) {
        // Filtra per distanza
        if (station.distance != null && station.distance! > _maxDistance) {
          return false;
        }
        
        // Filtra per query di ricerca
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesName = station.name.toLowerCase().contains(query);
          final matchesCity = station.city.toLowerCase().contains(query);
          final matchesAddress = station.address.toLowerCase().contains(query);
          final matchesBrand = station.brand.toLowerCase().contains(query);
          
          if (!matchesName && !matchesCity && !matchesAddress && !matchesBrand) {
            return false;
          }
        }
        
        // Se non ci sono prezzi e non stiamo cercando, mostriamola comunque
        if (station.prices.isEmpty) {
          return true;
        }
        
        // Se stiamo filtrando per tipo di carburante
        final fuelTypeStr = _selectedFuelType.toString().split('.').last.toLowerCase();
        
        // Verifichiamo se ha il tipo di carburante richiesto
        bool hasFuelType = false;
        for (var price in station.prices) {
          if (price.fuelType.toLowerCase().contains(fuelTypeStr)) {
            if (!_onlySelfService || price.isSelf) {
              hasFuelType = true;
              break;
            }
          }
        }
        
        return hasFuelType;
      }).toList();
      
      print('Stazioni filtrate: ${_filteredStations.length}');
      
      // Ordinamento
      _sortFilteredStations();
    } catch (e) {
      print('Errore nell\'applicazione dei filtri: $e');
      // In caso di errore, mostriamo tutte le stazioni
      _filteredStations = List.from(_stations);
    }
  }
  
  // Metodo per ordinare le stazioni filtrate
  void _sortFilteredStations() {
    try {
      print('Ordinamento stazioni per: ${_sortOption.toString().split('.').last}');
      
      switch (_sortOption) {
        case SortOption.distance:
          _filteredStations.sort((a, b) => 
            (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
          break;
          
        case SortOption.price:
          final fuelTypeStr = _selectedFuelType.toString().split('.').last.toLowerCase();
          
          _filteredStations.sort((a, b) {
            double priceA = double.infinity;
            double priceB = double.infinity;
            
            // Trova il prezzo per il tipo di carburante selezionato
            for (var price in a.prices) {
              if (price.fuelType.toLowerCase().contains(fuelTypeStr)) {
                if (!_onlySelfService || price.isSelf) {
                  if (price.price < priceA) {
                    priceA = price.price;
                  }
                }
              }
            }
            
            for (var price in b.prices) {
              if (price.fuelType.toLowerCase().contains(fuelTypeStr)) {
                if (!_onlySelfService || price.isSelf) {
                  if (price.price < priceB) {
                    priceB = price.price;
                  }
                }
              }
            }
            
            return priceA.compareTo(priceB);
          });
          break;
          
        case SortOption.name:
          _filteredStations.sort((a, b) => a.name.compareTo(b.name));
          break;
      }
    } catch (e) {
      print('Errore nell\'ordinamento delle stazioni: $e');
      // In caso di errore non cambiamo l'ordine
    }
  }
  
  // Metodi per aggiornare i filtri
  void setSearchQuery(String query) {
    print('Impostazione query di ricerca: $query');
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }
  
  void setSelectedFuelType(FuelType type) {
    print('Impostazione tipo carburante: ${type.toString().split('.').last}');
    _selectedFuelType = type;
    _applyFilters();
    notifyListeners();
  }
  
  void setSortOption(SortOption option) {
    print('Impostazione opzione ordinamento: ${option.toString().split('.').last}');
    _sortOption = option;
    _applyFilters();
    notifyListeners();
  }
  
  void setMaxDistance(double distance) {
    print('Impostazione distanza massima: $distance km');
    _maxDistance = distance;
    _applyFilters();
    notifyListeners();
  }
  
  void setOnlySelfService(bool value) {
    print('Impostazione solo self service: $value');
    _onlySelfService = value;
    _applyFilters();
    notifyListeners();
  }
}