import 'dart:convert';
import 'package:uuid/uuid.dart';

class MealPlanTemplateItem {
  final int dayOffset; // 0 = Lunes, 6 = Domingo
  final String mealType; // breakfast, lunch, snack, dinner
  final String? recipeId;
  final String recipeTitle;
  final String? recipeCategory;
  final int servings;
  final String customNote;

  const MealPlanTemplateItem({
    required this.dayOffset,
    required this.mealType,
    this.recipeId,
    required this.recipeTitle,
    this.recipeCategory,
    this.servings = 2,
    this.customNote = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOffset': dayOffset,
      'mealType': mealType,
      'recipeId': recipeId,
      'recipeTitle': recipeTitle,
      'recipeCategory': recipeCategory,
      'servings': servings,
      'customNote': customNote,
    };
  }

  factory MealPlanTemplateItem.fromMap(Map<String, dynamic> map) {
    return MealPlanTemplateItem(
      dayOffset: (map['dayOffset'] as num?)?.toInt() ?? 0,
      mealType: map['mealType']?.toString() ?? 'lunch',
      recipeId: map['recipeId']?.toString(),
      recipeTitle: map['recipeTitle']?.toString() ?? '',
      recipeCategory: map['recipeCategory']?.toString(),
      servings: (map['servings'] as num?)?.toInt() ?? 2,
      customNote: map['customNote']?.toString() ?? '',
    );
  }
}

class MealPlanTemplate {
  final String id;
  final String name;
  final DateTime createdAt;
  final List<MealPlanTemplateItem> items;

  MealPlanTemplate({
    String? id,
    required this.name,
    DateTime? createdAt,
    required this.items,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'itemsJson': json.encode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory MealPlanTemplate.fromMap(Map<String, dynamic> map) {
    List<MealPlanTemplateItem> parsedItems = [];
    if (map['itemsJson'] != null) {
      try {
        final List<dynamic> list = json.decode(map['itemsJson']);
        parsedItems = list.map((i) => MealPlanTemplateItem.fromMap(Map<String, dynamic>.from(i))).toList();
      } catch (_) {}
    }
    return MealPlanTemplate(
      id: map['id']?.toString() ?? const Uuid().v4(),
      name: map['name']?.toString() ?? 'Plantilla',
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
      items: parsedItems,
    );
  }
}
