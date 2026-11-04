import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum PromoCardType {
  none,
  plusPromo,
  googleAd,
}

class AdService extends ChangeNotifier {
  bool _isInitialized = false;
  BannerAd? _currentBannerAd;
  bool _isBannerAdLoaded = false;
  bool _isSimulationMode = false;

  AdService() {
    _isSimulationMode = kIsWeb || !(Platform.isAndroid || Platform.isIOS);
  }

  bool get isInitialized => _isInitialized;
  BannerAd? get currentBannerAd => _currentBannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isSimulationMode => _isSimulationMode;

  static String get bannerAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid) {
      // Test Ad Unit oficial de Google AdMob para Android
      return 'ca-app-pub-3940256099942544/6300978111';
    } else if (Platform.isIOS) {
      // Test Ad Unit oficial de Google AdMob para iOS
      return 'ca-app-pub-3940256099942544/2934735716';
    }
    return '';
  }

  Future<void> initialize() async {
    if (_isSimulationMode) {
      _isInitialized = true;
      notifyListeners();
      return;
    }

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AdService initialize notice: $e');
      _isSimulationMode = true;
      _isInitialized = true;
      notifyListeners();
    }
  }

  void loadBannerAd() {
    if (_isSimulationMode) return;

    _currentBannerAd?.dispose();
    _isBannerAdLoaded = false;

    try {
      _currentBannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.mediumRectangle, // 300x250 ideal para tarjetas del mazo
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            notifyListeners();
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed to load: $error');
            ad.dispose();
            _currentBannerAd = null;
            _isBannerAdLoaded = false;
            notifyListeners();
          },
        ),
      );

      _currentBannerAd?.load();
    } catch (e) {
      debugPrint('Error creating BannerAd: $e');
    }
  }

  /// Determina el tipo de tarjeta promocional a mostrar cada 20 swipes alternando:
  /// - Ciclo 1 (swipe 20): PlusPromo
  /// - Ciclo 2 (swipe 40): GoogleAd
  /// - Ciclo 3 (swipe 60): PlusPromo
  /// - Ciclo 4 (swipe 80): GoogleAd
  /// Si el usuario tiene Círculo Plus activo, no muestra nada (none).
  PromoCardType getPromoTypeForSwipeCount({
    required int totalSwipes,
    required bool isPlusMember,
  }) {
    if (isPlusMember || totalSwipes <= 0 || totalSwipes % 20 != 0) {
      return PromoCardType.none;
    }

    final cycle = totalSwipes ~/ 20;
    if (cycle.isOdd) {
      return PromoCardType.plusPromo;
    } else {
      if (_currentBannerAd == null && !_isSimulationMode) {
        loadBannerAd();
      }
      return PromoCardType.googleAd;
    }
  }

  @override
  void dispose() {
    _currentBannerAd?.dispose();
    super.dispose();
  }
}
