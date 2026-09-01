import 'ingredient_model.dart';
import 'recipe_step_model.dart';

class Recipe {
  final String id;
  final String title;
  final String? titleEn;
  final String description;
  final String? descriptionEn;
  final String category; // Desayuno, Almuerzo, Merienda, Cena, Postre, Otros
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int baseServings;
  final List<String> tags;
  final String imageUrl;
  final String sourceUrl;
  final bool isFavorite;
  final List<Ingredient> ingredients;
  final List<RecipeStep> steps;
  final DateTime createdAt;

  Recipe({
    required this.id,
    required this.title,
    this.titleEn,
    this.description = '',
    this.descriptionEn,
    this.category = 'Almuerzo',
    this.prepTimeMinutes = 15,
    this.cookTimeMinutes = 20,
    required this.baseServings,
    this.tags = const [],
    this.imageUrl = '',
    this.sourceUrl = '',
    this.isFavorite = false,
    this.ingredients = const [],
    this.steps = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  Recipe copyWith({
    String? id,
    String? title,
    String? titleEn,
    String? description,
    String? descriptionEn,
    String? category,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? baseServings,
    List<String>? tags,
    String? imageUrl,
    String? sourceUrl,
    bool? isFavorite,
    List<Ingredient>? ingredients,
    List<RecipeStep>? steps,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      titleEn: titleEn ?? this.titleEn,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      category: category ?? this.category,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      baseServings: baseServings ?? this.baseServings,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'titleEn': titleEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'category': category,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'baseServings': baseServings,
      'tags': tags.join(','),
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Recipe.fromMap(Map<String, dynamic> map, {
    List<Ingredient> ingredients = const [],
    List<RecipeStep> steps = const [],
  }) {
    final tagsRaw = map['tags']?.toString() ?? '';
    final tagsList = tagsRaw.isEmpty 
        ? <String>[] 
        : tagsRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

    return Recipe(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      titleEn: map['titleEn']?.toString(),
      description: map['description']?.toString() ?? '',
      descriptionEn: map['descriptionEn']?.toString(),
      category: map['category']?.toString() ?? 'Almuerzo',
      prepTimeMinutes: (map['prepTimeMinutes'] is num) ? (map['prepTimeMinutes'] as num).toInt() : 15,
      cookTimeMinutes: (map['cookTimeMinutes'] is num) ? (map['cookTimeMinutes'] as num).toInt() : 20,
      baseServings: (map['baseServings'] is num && (map['baseServings'] as num) > 0) 
          ? (map['baseServings'] as num).toInt() 
          : 2,
      tags: tagsList,
      imageUrl: map['imageUrl']?.toString() ?? '',
      sourceUrl: map['sourceUrl']?.toString() ?? '',
      isFavorite: (map['isFavorite'] == 1 || map['isFavorite'] == true),
      ingredients: ingredients,
      steps: steps,
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt']) ?? DateTime.now() : DateTime.now(),
    );
  }
}
