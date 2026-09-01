class ShoppingItem {
  final String id;
  final String name;
  final double amount;
  final String unit;
  final bool isCompleted;
  final String category;
  final String sourceRecipeTitle;
  final DateTime createdAt;

  ShoppingItem({
    required this.id,
    required this.name,
    this.amount = 0.0,
    this.unit = '',
    this.isCompleted = false,
    this.category = 'General',
    this.sourceRecipeTitle = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  ShoppingItem copyWith({
    String? id,
    String? name,
    double? amount,
    String? unit,
    bool? isCompleted,
    String? category,
    String? sourceRecipeTitle,
    DateTime? createdAt,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      sourceRecipeTitle: sourceRecipeTitle ?? this.sourceRecipeTitle,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'unit': unit,
      'isCompleted': isCompleted ? 1 : 0,
      'category': category,
      'sourceRecipeTitle': sourceRecipeTitle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      unit: map['unit']?.toString() ?? '',
      isCompleted: (map['isCompleted'] == 1 || map['isCompleted'] == true),
      category: map['category']?.toString() ?? 'General',
      sourceRecipeTitle: map['sourceRecipeTitle']?.toString() ?? '',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
