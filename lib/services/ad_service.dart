import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fuel_scan/services/premium_service.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  
  factory AdService() => _instance;
  
  AdService._internal();
  
  final PremiumService _premiumService = PremiumService();
  
  // Contatore per gli annunci interstiziali
  int _interstitialCounter = 0;
  int _interstitialThreshold = 3; // Mostra un interstiziale ogni 3 azioni
  
  // ID degli annunci
  late String _bannerAdUnitId;
  late String _interstitialAdUnitId;
  
  // Cache degli annunci interstiziali
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  
  // Inizializza il servizio
  Future<void> initialize() async {
    // Inizializza il servizio premium
    await _premiumService.initialize();
    
    // Inizializza Mobile Ads SDK solo se l'utente non è premium
    if (!_premiumService.isPremium) {
      await MobileAds.instance.initialize();
      
      // Imposta gli ID degli annunci per test o produzione
      if (kDebugMode) {
        // ID di test
        _bannerAdUnitId = Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/6300978111'
            : 'ca-app-pub-3940256099942544/2934735716';
        
        _interstitialAdUnitId = Platform.isAndroid
            ? 'ca-app-pub-3940256099942544/1033173712'
            : 'ca-app-pub-3940256099942544/4411468910';
      } else {
        // ID di produzione (da sostituire con quelli reali)
        _bannerAdUnitId = Platform.isAndroid
            ? 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy'
            : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
        
        _interstitialAdUnitId = Platform.isAndroid
            ? 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy'
            : 'ca-app-pub-xxxxxxxxxxxxxxxx/yyyyyyyyyy';
      }
      
      // Precarica un annuncio interstiziale
      _loadInterstitialAd();
    }
  }
  
  // Crea un banner
  BannerAd? createBannerAd() {
    // Non mostrare annunci se l'utente è premium
    if (_premiumService.isPremium) {
      return null;
    }
    
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Banner ad loaded: ${ad.adUnitId}');
        },
        onAdFailedToLoad: (ad, error) {
          print('Banner ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
  }
  
  // Carica un annuncio interstiziale
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          
          // Imposta il callback di chiusura per precaricare il prossimo annuncio
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // Precarica il prossimo annuncio
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isInterstitialAdReady = false;
              ad.dispose();
              _loadInterstitialAd(); // Riprova a caricare l'annuncio
            },
          );
          
          print('Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdReady = false;
          // Riprova a caricare dopo un ritardo
          Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
        },
      ),
    );
  }
  
  // Metodo per incrementare il contatore e mostrare un interstiziale se necessario
  Future<bool> showInterstitialAd() async {
    // Non mostrare annunci se l'utente è premium
    if (_premiumService.isPremium) {
      return false;
    }
    
    _interstitialCounter++;
    
    if (_interstitialCounter >= _interstitialThreshold && _isInterstitialAdReady) {
      _interstitialCounter = 0;
      
      if (_interstitialAd != null) {
        await _interstitialAd!.show();
        return true;
      }
    }
    
    return false;
  }
  
  // Imposta la soglia per gli annunci interstiziali
  void setInterstitialThreshold(int threshold) {
    _interstitialThreshold = threshold > 0 ? threshold : 3;
  }
  
  // Resetta il contatore degli interstiziali
  void resetInterstitialCounter() {
    _interstitialCounter = 0;
  }
  
  // Dispose degli annunci
  void dispose() {
    _interstitialAd?.dispose();
  }
}