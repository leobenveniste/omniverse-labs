import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kCharlemosProProductId = 'charlemos_pro_lifetime';

class PremiumService extends ChangeNotifier {
  static const String _keyIsPro = 'charlemos_is_pro_unlocked';

  final SharedPreferences _prefs;
  final InAppPurchase? _customIap;
  InAppPurchase get _iap => _customIap ?? InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = false;
  bool _isLoading = false;
  bool _isStoreAvailable = false;
  ProductDetails? _proProduct;
  String? _errorMessage;

  PremiumService(this._prefs, {InAppPurchase? iap}) : _customIap = iap {
    _load();
  }

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  bool get isStoreAvailable => _isStoreAvailable;
  ProductDetails? get proProduct => _proProduct;
  String? get errorMessage => _errorMessage;

  void _load() {
    _isPro = _prefs.getBool(_keyIsPro) ?? false;
  }

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _isStoreAvailable = false;
      _isLoading = false;
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _subscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (error) {
          _errorMessage = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );

      final available = await _iap.isAvailable().timeout(
        const Duration(seconds: 2),
        onTimeout: () => false,
      );
      if (!available) {
        _isStoreAvailable = false;
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isStoreAvailable = true;
      final response = await _iap.queryProductDetails({kCharlemosProProductId}).timeout(
        const Duration(seconds: 2),
        onTimeout: () => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [kCharlemosProProductId],
        ),
      );
      if (response.productDetails.isNotEmpty) {
        final matches = response.productDetails.where((p) => p.id == kCharlemosProProductId);
        _proProduct = matches.isNotEmpty ? matches.first : response.productDetails.first;
      }
    } catch (e) {
      _isStoreAvailable = false;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> buyPro() async {
    if (_isPro) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    ProductDetails? product = _proProduct;
    if (product == null) {
      try {
        final available = await _iap.isAvailable();
        if (available) {
          final response = await _iap.queryProductDetails({kCharlemosProProductId});
          if (response.productDetails.isNotEmpty) {
            final matches = response.productDetails.where((p) => p.id == kCharlemosProProductId);
            product = matches.isNotEmpty ? matches.first : response.productDetails.first;
            _proProduct = product;
          }
        }
      } catch (_) {}
    }

    if (product == null) {
      _isLoading = false;
      _errorMessage = 'proSyncing';
      notifyListeners();
      return;
    }

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
      _isLoading = false;
      notifyListeners();
      return _isPro;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setProUser(bool isPro) async {
    _isPro = isPro;
    await _prefs.setBool(_keyIsPro, isPro);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _isLoading = false;
          _errorMessage = purchaseDetails.error?.message ?? 'Error';
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.productID == kCharlemosProProductId) {
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
