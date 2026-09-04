import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kProLifetimeProductId = 'menu_listo_pro_unlock';

class PremiumState {
  final bool isProUser;
  final bool isLoading;
  final bool isStoreAvailable;
  final ProductDetails? proProduct;
  final String? errorMessage;

  const PremiumState({
    this.isProUser = false,
    this.isLoading = false,
    this.isStoreAvailable = false,
    this.proProduct,
    this.errorMessage,
  });

  PremiumState copyWith({
    bool? isProUser,
    bool? isLoading,
    bool? isStoreAvailable,
    ProductDetails? proProduct,
    String? errorMessage,
  }) {
    return PremiumState(
      isProUser: isProUser ?? this.isProUser,
      isLoading: isLoading ?? this.isLoading,
      isStoreAvailable: isStoreAvailable ?? this.isStoreAvailable,
      proProduct: proProduct ?? this.proProduct,
      errorMessage: errorMessage,
    );
  }
}

final premiumProvider = StateNotifierProvider<PremiumNotifier, PremiumState>((ref) {
  final notifier = PremiumNotifier();
  notifier.init();
  return notifier;
});

class PremiumNotifier extends StateNotifier<PremiumState> {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  PremiumNotifier() : super(const PremiumState());

  Future<void> init() async {
    // 1. Load local cached status
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('is_pro_unlocked') ?? false;
    state = state.copyWith(isProUser: isPro, isLoading: true);

    // 2. Set up purchase stream listener
    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _subscription?.cancel(),
      onError: (error) {
        state = state.copyWith(errorMessage: error.toString(), isLoading: false);
      },
    );

    // 3. Check store availability & load products
    try {
      final available = await _iap.isAvailable();
      if (!available) {
        state = state.copyWith(isStoreAvailable: false, isLoading: false);
        return;
      }

      state = state.copyWith(isStoreAvailable: true);
      final response = await _iap.queryProductDetails({kProLifetimeProductId});

      ProductDetails? product;
      if (response.productDetails.isNotEmpty) {
        final matches = response.productDetails.where((p) => p.id == kProLifetimeProductId);
        product = matches.isNotEmpty ? matches.first : response.productDetails.first;
      }

      state = state.copyWith(
        proProduct: product,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> buyPro() async {
    if (state.isProUser) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    ProductDetails? product = state.proProduct;
    if (product == null) {
      try {
        final available = await _iap.isAvailable();
        if (available) {
          final response = await _iap.queryProductDetails({kProLifetimeProductId});
          if (response.productDetails.isNotEmpty) {
            final matches = response.productDetails.where((p) => p.id == kProLifetimeProductId);
            product = matches.isNotEmpty ? matches.first : response.productDetails.first;
            state = state.copyWith(proProduct: product);
          }
        }
      } catch (_) {}
    }

    if (product == null) {
      // If store is offline or product is still propagating in Google Play Console
      if (kDebugMode || !state.isStoreAvailable) {
        await setProUser(true);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'El producto de Google Play se está sincronizando. Intenta de nuevo en unos momentos.',
      );
      return;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _iap.restorePurchases();
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  Future<void> setProUser(bool isPro) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro_unlocked', isPro);
    state = state.copyWith(isProUser: isPro, isLoading: false);
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: purchaseDetails.error?.message ?? 'Error en la compra',
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.productID == kProLifetimeProductId) {
            await setProUser(true);
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
