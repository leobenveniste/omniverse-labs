class AppProductIds {
  // Suscripciones
  static const String plusMonthly = 'circulo_plus_monthly';
  static const String plusAnnual = 'circulo_plus_annual';

  // Consumibles
  static const String boost1 = 'circulo_boost_1';
  static const String boost5 = 'circulo_boost_5';
  static const String superOnda3 = 'circulo_superonda_3';
  static const String superOnda10 = 'circulo_superonda_10';

  static const List<String> allSubscriptions = [
    plusMonthly,
    plusAnnual,
  ];

  static const List<String> allConsumables = [
    boost1,
    boost5,
    superOnda3,
    superOnda10,
  ];

  static const List<String> all = [
    ...allSubscriptions,
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
