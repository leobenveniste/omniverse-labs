class Ingredient {
  final String id;
  final double amount;
  final String unit;
  final String name;
  final String notes;

  Ingredient({
    String? id,
    this.amount = 0.0,
    this.unit = '',
    required this.name,
    this.notes = '',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Ingredient scale(double factor) {
    if (amount <= 0) return this;
    return copyWith(amount: amount * factor);
  }

  Ingredient copyWith({
    String? id,
    double? amount,
    String? unit,
    String? name,
    String? notes,
  }) {
    return Ingredient(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      name: name ?? this.name,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'unit': unit,
      'name': name,
      'notes': notes,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id']?.toString() ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      unit: map['unit']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      notes: map['notes']?.toString() ?? '',
    );
  }
}
