import 'dart:convert';
import 'package:flutter/services.dart';

class KeysService {
  static KeysService? _instance;
  Map<String, dynamic>? _keys;

  // Singleton pattern
  static Future<KeysService> getInstance() async {
    if (_instance == null) {
      _instance = KeysService();
      await _instance!._loadKeys();
    }
    return _instance!;
  }

  Future<void> _loadKeys() async {
    try {
      final keysJson = await rootBundle.loadString('assets/config/keys.json');
      _keys = json.decode(keysJson);
    } catch (e) {
      print('Errore nel caricamento delle chiavi: $e');
      // Fallback a un dizionario vuoto
      _keys = {};
    }
  }

  String getGoogleMapsApiKey() {
    return _keys?['google_maps_api_key'] ?? '';
  }
}