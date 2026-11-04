import 'package:flutter/foundation.dart';

enum PromoCardType {
  none,
  plusPromo,
  googleAd,
}

class AdService extends ChangeNotifier {
  bool _isInitialized = false;
  final bool _isBannerAdLoaded = false;
  final bool _isSimulationMode = true;

  AdService();

  bool get isInitialized => _isInitialized;
  dynamic get currentBannerAd => null;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isSimulationMode => _isSimulationMode;

  static String get bannerAdUnitId => '';

  Future<void> initialize() async {
    _isInitialized = true;
    notifyListeners();
  }

  void loadBannerAd() {}

  /// Determina el tipo de tarjeta promocional a mostrar cada 20 swipes alternando:
  /// - Ciclo 1 (swipe 20): PlusPromo
  /// - Ciclo 2 (swipe 40): GoogleAd (Tarjeta Patrocinada de la Comunidad)
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
      return PromoCardType.googleAd;
    }
  }
}
