import 'package:flutter/material.dart';

class CardItem {
  final String id;
  final int level; // 1: Hielo/Icebreaker, 2: Vínculo/Values, 3: Intimidad/Deep, 4: Retos/Challenges
  final String category; // dates, couples, friends, challenges, custom
  final String textEs;
  final String textEn;
  final String textPt;
  final String textFr;
  final String textIt;
  final bool isFavorite;
  final bool isCustom;

  const CardItem({
    required this.id,
    required this.level,
    required this.category,
    required this.textEs,
    required this.textEn,
    this.textPt = '',
    this.textFr = '',
    this.textIt = '',
    this.isFavorite = false,
    this.isCustom = false,
  });

  String getText(String languageCode) {
    if (languageCode.startsWith('es')) {
      return textEs.isNotEmpty ? textEs : textEn;
    } else if (languageCode.startsWith('pt')) {
      return textPt.isNotEmpty ? textPt : (textEs.isNotEmpty ? textEs : textEn);
    } else if (languageCode.startsWith('fr')) {
      return textFr.isNotEmpty ? textFr : (textEn.isNotEmpty ? textEn : textEs);
    } else if (languageCode.startsWith('it')) {
      return textIt.isNotEmpty ? textIt : (textEs.isNotEmpty ? textEs : textEn);
    } else {
      return textEn.isNotEmpty ? textEn : textEs;
    }
  }

  CardItem copyWith({
    String? id,
    int? level,
    String? category,
    String? textEs,
    String? textEn,
    String? textPt,
    String? textFr,
    String? textIt,
    bool? isFavorite,
    bool? isCustom,
  }) {
    return CardItem(
      id: id ?? this.id,
      level: level ?? this.level,
      category: category ?? this.category,
      textEs: textEs ?? this.textEs,
      textEn: textEn ?? this.textEn,
      textPt: textPt ?? this.textPt,
      textFr: textFr ?? this.textFr,
      textIt: textIt ?? this.textIt,
      isFavorite: isFavorite ?? this.isFavorite,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level,
        'category': category,
        'text_es': textEs,
        'text_en': textEn,
        'text_pt': textPt,
        'text_fr': textFr,
        'text_it': textIt,
        'is_favorite': isFavorite,
        'is_custom': isCustom,
      };

  factory CardItem.fromJson(Map<String, dynamic> json) => CardItem(
        id: json['id'] as String,
        level: (json['level'] as num?)?.toInt() ?? 1,
        category: (json['category'] as String?) ?? 'dates',
        textEs: (json['text_es'] as String?) ?? '',
        textEn: (json['text_en'] as String?) ?? '',
        textPt: (json['text_pt'] as String?) ?? '',
        textFr: (json['text_fr'] as String?) ?? '',
        textIt: (json['text_it'] as String?) ?? '',
        isFavorite: (json['is_favorite'] as bool?) ?? false,
        isCustom: (json['is_custom'] as bool?) ?? false,
      );

  Color get levelColor {
    switch (level) {
      case 1:
        return const Color(0xFF4CAF50);
      case 2:
        return const Color(0xFFFF9800);
      case 3:
        return const Color(0xFFE91E63);
      case 4:
      default:
        return const Color(0xFF9C27B0);
    }
  }
}
