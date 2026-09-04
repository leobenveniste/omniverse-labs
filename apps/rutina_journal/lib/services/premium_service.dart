import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kRitmoProProductId = 'ritmo_pro_unlock';

class PremiumService extends ChangeNotifier {
  static const String _keyIsPro = 'is_pro_unlocked';
  static const String _keyFocusDate = 'pref_focus_session_date';
  static const String _keyFocusCount = 'pref_focus_session_count';

  final SharedPreferences _prefs;
  final InAppPurchase? _customIap;
  InAppPurchase get _iap => _customIap ?? InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isPro = false;
  bool _isLoading = false;
  bool _isStoreAvailable = false;
  ProductDetails? _proProduct;
  String? _errorMessage;

  String _focusDate = '';
  int _focusCount = 0;

  PremiumService(this._prefs, {InAppPurchase? iap}) : _customIap = iap {
    _load();
  }

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  bool get isStoreAvailable => _isStoreAvailable;
  ProductDetails? get proProduct => _proProduct;
  String? get errorMessage => _errorMessage;

  /// Returns how many focus sessions have been completed today
  int get todayFocusSessionsCount {
    final today = _getTodayKey();
    if (_focusDate != today) {
      return 0;
    }
    return _focusCount;
  }

  /// Free version allows 1 focus session per day. Pro allows unlimited.
  bool get canStartFocusSession => _isPro || todayFocusSessionsCount < 1;

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _load() {
    _isPro = _prefs.getBool(_keyIsPro) ?? false;
    _focusDate = _prefs.getString(_keyFocusDate) ?? '';
    _focusCount = _prefs.getInt(_keyFocusCount) ?? 0;
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
      // Purchase stream listener
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
      final response = await _iap.queryProductDetails({kRitmoProProductId}).timeout(
        const Duration(seconds: 2),
        onTimeout: () => ProductDetailsResponse(
          productDetails: [],
          notFoundIDs: [kRitmoProProductId],
        ),
      );
      if (response.productDetails.isNotEmpty) {
        _proProduct = response.productDetails.firstWhere(
          (p) => p.id == kRitmoProProductId,
          orElse: () => response.productDetails.first,
        );
      }
    } catch (e) {
      _isStoreAvailable = false;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Record a focus session completed today
  Future<void> recordFocusSession() async {
    final today = _getTodayKey();
    if (_focusDate != today) {
      _focusDate = today;
      _focusCount = 1;
    } else {
      _focusCount++;
    }
    await _prefs.setString(_keyFocusDate, _focusDate);
    await _prefs.setInt(_keyFocusCount, _focusCount);
    notifyListeners();
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
          final response = await _iap.queryProductDetails({kRitmoProProductId});
          if (response.productDetails.isNotEmpty) {
            product = response.productDetails.firstWhere(
              (p) => p.id == kRitmoProProductId,
              orElse: () => response.productDetails.first,
            );
            _proProduct = product;
          }
        }
      } catch (_) {}
    }

    if (product == null) {
      if (kDebugMode || !_isStoreAvailable) {
        await setProUser(true);
        return;
      }
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
          _errorMessage = purchaseDetails.error?.message ?? 'Error en la compra';
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          if (purchaseDetails.productID == kRitmoProProductId) {
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
