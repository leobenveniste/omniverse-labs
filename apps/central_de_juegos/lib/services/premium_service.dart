import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kCentralJuegosProProductId = 'central_juegos_pro_unlock';

class PremiumService extends ChangeNotifier {
  static const String _keyIsPro = 'is_pro_unlocked';
  static PremiumService? _instance;

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

  static Future<PremiumService> getInstance() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = PremiumService(prefs);
      await _instance!.init();
    }
    return _instance!;
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
    // In-App Purchases are only supported on Android and iOS
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
      final response = await _iap.queryProductDetails({kCentralJuegosProProductId}).timeout(
        const Duration(seconds: 2),
        onTimeout: () => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [kCentralJuegosProProductId],
        ),
      );

      if (response.productDetails.isNotEmpty) {
        _proProduct = response.productDetails.firstWhere(
          (p) => p.id == kCentralJuegosProProductId,
          orElse: () => response.productDetails.first,
        );
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> buyPro() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      _errorMessage = 'In-app purchases not supported on this platform';
      notifyListeners();
      return false;
    }

    if (_proProduct == null) {
      _errorMessage = 'Producto no disponible en la tienda';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: _proProduct!);
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> restorePurchases() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _iap.restorePurchases();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (final purchase in purchaseDetailsList) {
      if (purchase.productID == kCentralJuegosProProductId) {
        switch (purchase.status) {
          case PurchaseStatus.pending:
            _isLoading = true;
            notifyListeners();
            break;

          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final valid = _verifyPurchase(purchase);
            if (valid) {
              await _setPro(true);
            }
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            _isLoading = false;
            notifyListeners();
            break;

          case PurchaseStatus.error:
            _errorMessage = purchase.error?.message ?? 'Error en la compra';
            _isLoading = false;
            notifyListeners();
            break;

          case PurchaseStatus.canceled:
            _isLoading = false;
            notifyListeners();
            break;
        }
      }
    }
  }

  bool _verifyPurchase(PurchaseDetails purchase) {
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> _setPro(bool value) async {
    _isPro = value;
    await _prefs.setBool(_keyIsPro, value);
    notifyListeners();
  }

  /// Strictly guarded testing toggle: only executable in debug builds.
  Future<void> setProForTesting(bool value) async {
    if (!kDebugMode) return;
    await _setPro(value);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
