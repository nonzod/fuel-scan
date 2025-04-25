import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fuel_scan/services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdService().createBannerAd();
    
    // Se l'utente è premium o c'è stato un problema nella creazione dell'annuncio
    if (_bannerAd == null) {
      return;
    }
    
    // Aggiorniamo lo stato quando l'annuncio è caricato utilizzando il listener corretto
    _bannerAd!.load()
      .whenComplete(() {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded) {
      return SizedBox(
        height: 0,
        width: 0,
      );
    }

    return Container(
      alignment: Alignment.bottomCenter,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}