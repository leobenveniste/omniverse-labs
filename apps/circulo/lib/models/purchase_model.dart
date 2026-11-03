class AppProductIds {
  // Suscripción Círculo Plus (Google Play Subscriptions v2)
  static const String subscriptionCirculoPlus = 'circulo_plus';

  // Base Plans dentro de circulo_plus
  static const String plusMonthly = 'plus-monthly';
  static const String plusQuarterly = 'plus-quarterly';
  static const String plusBiannual = 'plus-biannual';
  static const String plusAnnual = 'plus-annual';

  // Consumibles (One-time products que pueden comprarse repetidas veces)
  // Producto 1: Boost de Perfil (x3 visibilidad durante 60 minutos)
  static const String boost1 = 'circulo_boost';
  static const String boost5 = 'circulo_boost_5';

  // Producto 2: Super-Onda (Notificación directa con halo dorado)
  static const String superOnda1 = 'circulo_superonda';
  static const String superOnda3 = 'circulo_superonda_3';
  static const String superOnda10 = 'circulo_superonda_10';

  static const List<String> allBasePlans = [
    plusMonthly,
    plusQuarterly,
    plusBiannual,
    plusAnnual,
  ];

  static const List<String> allSubscriptions = [
    subscriptionCirculoPlus,
    plusMonthly,
    plusQuarterly,
    plusBiannual,
    plusAnnual,
  ];

  static const List<String> allConsumables = [
    boost1,
    boost5,
    superOnda1,
    superOnda3,
    superOnda10,
  ];

  static const List<String> all = [
    subscriptionCirculoPlus,
    ...allBasePlans,
    ...allConsumables,
  ];
}

class PurchaseRecordModel {
  final String id;
  final String userId;
  final String productId;
  final String transactionId;
  final double price;
  final String currency;
  final String status; // 'pending', 'completed', 'failed', 'restored'
  final bool isSandbox;
  final DateTime purchasedAt;

  PurchaseRecordModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.transactionId,
    required this.price,
    this.currency = 'USD',
    required this.status,
    this.isSandbox = false,
    required this.purchasedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'transactionId': transactionId,
      'price': price,
      'currency': currency,
      'status': status,
      'isSandbox': isSandbox,
      'purchasedAt': purchasedAt.toIso8601String(),
    };
  }

  factory PurchaseRecordModel.fromJson(Map<String, dynamic> map) {
    return PurchaseRecordModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      transactionId: map['transactionId'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      status: map['status'] ?? 'completed',
      isSandbox: map['isSandbox'] ?? false,
      purchasedAt: map['purchasedAt'] != null
          ? DateTime.parse(map['purchasedAt'])
          : DateTime.now(),
    );
  }
}
