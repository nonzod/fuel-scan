import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  factory ConnectivityService() => _instance;
  
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  ConnectivityResult _lastResult = ConnectivityResult.none;
  
  // Funzione per verificare la connettività attuale
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _lastResult = result;
      return result != ConnectivityResult.none;
    } catch (e) {
      print('Connettività assente: $e');
      return false;
    }
  }
  
  // Funzione per iniziare a monitorare i cambiamenti di connettività
  void startMonitoring(Function(bool) onConnectivityChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _lastResult = result;
      onConnectivityChanged(result != ConnectivityResult.none);
    });
  }
  
  // Funzione per interrompere il monitoraggio
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }
  
  // Ottieni l'ultimo stato di connettività conosciuto
  bool get isOnline => _lastResult != ConnectivityResult.none;
}