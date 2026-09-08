class Ingredient {
  final String id;
  final double amount;
  final String unit;
  final String? unitEn;
  final String name;
  final String? nameEn;
  final String notes;
  final String? notesEn;
  final bool isSectionHeader;

  Ingredient({
    String? id,
    this.amount = 0.0,
    this.unit = '',
    this.unitEn,
    required this.name,
    this.nameEn,
    this.notes = '',
    this.notesEn,
    this.isSectionHeader = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  String localizedName(bool isSpanish) {
    if (!isSpanish && nameEn != null && nameEn!.trim().isNotEmpty) {
      return nameEn!.trim();
    }
    return name;
  }

  String localizedUnit(bool isSpanish) {
    if (!isSpanish && unitEn != null && unitEn!.trim().isNotEmpty) {
      return unitEn!.trim();
    }
    return unit;
  }

  String localizedNotes(bool isSpanish) {
    if (!isSpanish && notesEn != null && notesEn!.trim().isNotEmpty) {
      return notesEn!.trim();
    }
    return notes;
  }

  Ingredient scale(double factor) {
    if (isSectionHeader || amount <= 0) return this;
    return copyWith(amount: amount * factor);
  }

  Ingredient copyWith({
    String? id,
    double? amount,
    String? unit,
    String? unitEn,
    String? name,
    String? nameEn,
    String? notes,
    String? notesEn,
    bool? isSectionHeader,
  }) {
    return Ingredient(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      unitEn: unitEn ?? this.unitEn,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      notes: notes ?? this.notes,
      notesEn: notesEn ?? this.notesEn,
      isSectionHeader: isSectionHeader ?? this.isSectionHeader,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'unit': unit,
      'unitEn': unitEn,
      'name': name,
      'nameEn': nameEn,
      'notes': notes,
      'notesEn': notesEn,
      'isSectionHeader': isSectionHeader ? 1 : 0,
    };
  }

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: (map['id'] != null && map['id'].toString().isNotEmpty) ? map['id'].toString() : null,
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      unit: map['unit']?.toString() ?? '',
      unitEn: map['unitEn']?.toString() ?? map['unit_en']?.toString(),
      name: map['name']?.toString() ?? '',
      nameEn: map['nameEn']?.toString() ?? map['name_en']?.toString(),
      notes: map['notes']?.toString() ?? '',
      notesEn: map['notesEn']?.toString() ?? map['notes_en']?.toString(),
      isSectionHeader: map['isSectionHeader'] == 1 || map['isSectionHeader'] == true || (map['name'] != null && map['name'].toString().trim().endsWith(':')),
    );
  }
}
