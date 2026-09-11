import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class SubscriptionService {
  final SharedPreferences _prefs;
  final InAppPurchase? iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _purchasedPro = false;
  bool _testProOverride = false;
  final VoidCallback? onEntitlementChanged;

  SubscriptionService(
    this._prefs, {
    this.iap,
    this.onEntitlementChanged,
  }) {
    _purchasedPro = _prefs.getBool(AppConstants.keyProPurchased) ?? false;
    _testProOverride = _prefs.getBool(AppConstants.keyProOverride) ?? false;
    if (iap != null) {
      _initIap();
    }
  }

  bool get isPro => _purchasedPro || _testProOverride;
  bool get isTestProOverride => _testProOverride;
  bool get isPurchasedPro => _purchasedPro;

  bool canLogTrade(int currentTotalTrades) {
    if (isPro) return true;
    return currentTotalTrades < AppConstants.maxFreeTrades;
  }

  int remainingFreeTrades(int currentTotalTrades) {
    if (isPro) return 999999;
    final remaining = AppConstants.maxFreeTrades - currentTotalTrades;
    return remaining > 0 ? remaining : 0;
  }

  Future<void> setTestProOverride(bool value) async {
    _testProOverride = value;
    await _prefs.setBool(AppConstants.keyProOverride, value);
    onEntitlementChanged?.call();
  }

  void _initIap() {
    try {
      final purchaseUpdated = iap!.purchaseStream;
      _subscription = purchaseUpdated.listen(
        _listenToPurchaseUpdated,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          debugPrint('IAP stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('IAP initialization bypassed: $e');
    }
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        if (purchaseDetails.productID == AppConstants.proProductId) {
          _setPurchasedPro(true);
        }
      }

      if (purchaseDetails.pendingCompletePurchase) {
        iap?.completePurchase(purchaseDetails);
      }
    }
  }

  Future<void> _setPurchasedPro(bool purchased) async {
    _purchasedPro = purchased;
    await _prefs.setBool(AppConstants.keyProPurchased, purchased);
    onEntitlementChanged?.call();
  }

  Future<bool> buyPro() async {
    if (iap == null) return false;
    try {
      final bool available = await iap!.isAvailable();
      if (!available) {
        debugPrint('IAP store unavailable');
        return false;
      }

      final ProductDetailsResponse response =
          await iap!.queryProductDetails({AppConstants.proProductId});

      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        debugPrint('Pro product not found in Google Play Console');
        return false;
      }

      final PurchaseParam purchaseParam =
          PurchaseParam(productDetails: response.productDetails.first);
      return await iap!.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('Error buying Pro: $e');
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (iap == null) return;
    try {
      await iap!.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}
