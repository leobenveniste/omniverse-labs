enum BagCompartment { personalItem, carryOn, checked }

enum PackingCategory {
  clothing,
  toiletries,
  tech,
  documents,
  health,
  home,
}

class PackingItem {
  final String id;
  final String tripId;
  final String name;
  final BagCompartment compartment;
  final PackingCategory category;
  final int quantity;
  final double weightKg;
  final bool isPacked;
  final bool isAlwaysPack;

  const PackingItem({
    required this.id,
    required this.tripId,
    required this.name,
    required this.compartment,
    required this.category,
    this.quantity = 1,
    this.weightKg = 0.2,
    this.isPacked = false,
    this.isAlwaysPack = false,
  });

  PackingItem copyWith({
    String? name,
    BagCompartment? compartment,
    PackingCategory? category,
    int? quantity,
    double? weightKg,
    bool? isPacked,
    bool? isAlwaysPack,
  }) {
    return PackingItem(
      id: id,
      tripId: tripId,
      name: name ?? this.name,
      compartment: compartment ?? this.compartment,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      weightKg: weightKg ?? this.weightKg,
      isPacked: isPacked ?? this.isPacked,
      isAlwaysPack: isAlwaysPack ?? this.isAlwaysPack,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tripId': tripId,
        'name': name,
        'compartment': compartment.name,
        'category': category.name,
        'quantity': quantity,
        'weightKg': weightKg,
        'isPacked': isPacked,
        'isAlwaysPack': isAlwaysPack,
      };

  factory PackingItem.fromJson(Map<String, dynamic> json) => PackingItem(
        id: json['id'] as String,
        tripId: json['tripId'] as String,
        name: json['name'] as String,
        compartment: BagCompartment.values.firstWhere(
          (e) => e.name == json['compartment'],
          orElse: () => BagCompartment.carryOn,
        ),
        category: PackingCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => PackingCategory.clothing,
        ),
        quantity: json['quantity'] as int? ?? 1,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0.2,
        isPacked: json['isPacked'] as bool? ?? false,
        isAlwaysPack: json['isAlwaysPack'] as bool? ?? false,
      );
}
