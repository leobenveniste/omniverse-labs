import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/purchase_model.dart';
import 'online_firestore_service.dart';

class BillingService extends ChangeNotifier {
  final OnlineFirestoreService _firestoreService;
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _isAvailable = false;
  bool _isSandboxMode = true; // Activo por default para desarrollo y testing seguro
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductDetails> _products = [];

  BillingService(this._firestoreService);

  bool get isAvailable => _isAvailable;
  bool get isSandboxMode => _isSandboxMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ProductDetails> get products => _products;

  void setSandboxMode(bool enabled) {
    _isSandboxMode = enabled;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (!kIsWeb) {
        _isAvailable = await _iap.isAvailable();
      } else {
        _isAvailable = false;
      }

      if (_isAvailable) {
        final purchaseUpdated = _iap.purchaseStream;
        _subscription = purchaseUpdated.listen(
          _handlePurchaseUpdates,
          onDone: () => _subscription?.cancel(),
          onError: (error) {
            _errorMessage = error.toString();
            notifyListeners();
          },
        );

        await loadProducts();
      }
    } catch (e) {
      debugPrint('BillingService init notice: $e');
      _isAvailable = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    if (!_isAvailable) return;

    try {
      final ids = AppProductIds.all.toSet();
      final response = await _iap.queryProductDetails(ids);
      _products = response.productDetails;
      notifyListeners();
    } catch (e) {
      debugPrint('Error al consultar productos: $e');
    }
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _errorMessage = purchaseDetails.error?.message;
          _isLoading = false;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _isLoading = false;
          notifyListeners();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      }
    }
  }

  // --- PROCESO DE COMPRA (SUBSCRIPCIÓN O CONSUMIBLE) ---

  Future<bool> buyProduct({
    required String productId,
    required UserModel currentUser,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_isSandboxMode || !_isAvailable) {
        // Ejecución en modo Sandbox / Emulación para tests y desarrollo
        await Future.delayed(const Duration(milliseconds: 600));
        await _applyProductBenefit(productId, currentUser, isSandbox: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      // Flujo de producción In-App Purchase oficial
      ProductDetails? product;
      try {
        product = _products.firstWhere((p) => p.id == productId);
      } catch (_) {
        product = null;
      }

      if (product == null) {
        // Fallback a Sandbox si el ID aún no está publicado en la consola
        await _applyProductBenefit(productId, currentUser, isSandbox: true);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      if (AppProductIds.allConsumables.contains(productId)) {
        await _iap.buyConsumable(purchaseParam: purchaseParam);
      } else {
        await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      }

      // Aplicar beneficios para reflejar de inmediato
      await _applyProductBenefit(productId, currentUser, isSandbox: false);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _applyProductBenefit(
    String productId,
    UserModel user, {
    required bool isSandbox,
  }) async {
    UserModel updated = user;
    final now = DateTime.now();
    double price = 4.99;

    switch (productId) {
      case AppProductIds.plusMonthly:
        price = 4.99;
        updated = updated.copyWith(
          isPlusActive: true,
          plusExpiresAt: now.add(const Duration(days: 30)),
          dailySwipesRemaining: 99999, // Swipes ilimitados
          remainingBoosts: updated.remainingBoosts + 1, // 1 boost semanal incluido
        );
        break;

      case AppProductIds.plusAnnual:
        price = 39.99;
        updated = updated.copyWith(
          isPlusActive: true,
          plusExpiresAt: now.add(const Duration(days: 365)),
          dailySwipesRemaining: 99999,
          remainingBoosts: updated.remainingBoosts + 4,
        );
        break;

      case AppProductIds.boost1:
        price = 1.99;
        updated = updated.copyWith(
          remainingBoosts: updated.remainingBoosts + 1,
        );
        break;

      case AppProductIds.boost5:
        price = 7.99;
        updated = updated.copyWith(
          remainingBoosts: updated.remainingBoosts + 5,
        );
        break;

      case AppProductIds.superOnda3:
        price = 2.49;
        updated = updated.copyWith(
          remainingSuperOndas: updated.remainingSuperOndas + 3,
        );
        break;

      case AppProductIds.superOnda10:
        price = 6.99;
        updated = updated.copyWith(
          remainingSuperOndas: updated.remainingSuperOndas + 10,
        );
        break;
    }

    // Persistir el usuario actualizado en Firestore
    await _firestoreService.upsertUser(updated);

    // Registrar recibo de compra
    final record = PurchaseRecordModel(
      id: const Uuid().v4(),
      userId: user.id,
      productId: productId,
      transactionId: 'TX-${DateTime.now().millisecondsSinceEpoch}',
      price: price,
      currency: 'USD',
      status: 'completed',
      isSandbox: isSandbox,
      purchasedAt: now,
    );
    await _firestoreService.recordPurchase(record);
  }

  // --- BENEFICIOS CONSUMIBLES EN TIEMPO REAL ---

  Future<UserModel?> activateBoost(UserModel currentUser) async {
    if (currentUser.remainingBoosts <= 0) return null;

    final updated = currentUser.copyWith(
      remainingBoosts: currentUser.remainingBoosts - 1,
      activeBoostUntil: DateTime.now().add(const Duration(minutes: 60)),
    );

    await _firestoreService.upsertUser(updated);
    notifyListeners();
    return updated;
  }

  Future<UserModel?> consumeSuperOnda(UserModel currentUser) async {
    if (currentUser.remainingSuperOndas <= 0) return null;

    final updated = currentUser.copyWith(
      remainingSuperOndas: currentUser.remainingSuperOndas - 1,
    );

    await _firestoreService.upsertUser(updated);
    notifyListeners();
    return updated;
  }

  // --- CONTROL DE LÍMITES DIARIOS Y RECARGA 24H ---

  UserModel checkAndResetDailySwipes(UserModel user) {
    if (user.isPlusMember) return user;

    final now = DateTime.now();
    final lastReset = user.lastSwipeResetDate ?? user.createdAt;

    // Si pasaron más de 24 horas desde el último reset
    if (now.difference(lastReset).inHours >= 24) {
      return user.copyWith(
        dailySwipesRemaining: 30,
        lastSwipeResetDate: now,
      );
    }
    return user;
  }

  Future<UserModel> registerSwipeAttempt(UserModel user) async {
    UserModel current = checkAndResetDailySwipes(user);

    int remaining = current.dailySwipesRemaining;
    if (!current.isPlusMember) {
      remaining = (remaining > 0) ? remaining - 1 : 0;
    }

    final updated = current.copyWith(
      dailySwipesRemaining: remaining,
      totalSwipesCounter: current.totalSwipesCounter + 1,
      lastSwipeResetDate: current.lastSwipeResetDate ?? DateTime.now(),
    );

    await _firestoreService.upsertUser(updated);
    return updated;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
