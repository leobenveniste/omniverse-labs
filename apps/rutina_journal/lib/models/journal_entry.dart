class JournalEntry {
  final String id;
  final String dateKey; // Format: "yyyy-MM-dd"
  final int moodLevel; // 1 to 5
  final int energyLevel; // 1 to 5
  final List<String> tags;
  final String gratitude1;
  final String gratitude2;
  final String gratitude3;
  final String dailyWin;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JournalEntry({
    required this.id,
    required this.dateKey,
    this.moodLevel = 4, // Default "Good"
    this.energyLevel = 3,
    this.tags = const [],
    this.gratitude1 = '',
    this.gratitude2 = '',
    this.gratitude3 = '',
    this.dailyWin = '',
    this.notes = '',
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEmpty =>
      gratitude1.trim().isEmpty &&
      gratitude2.trim().isEmpty &&
      gratitude3.trim().isEmpty &&
      dailyWin.trim().isEmpty &&
      notes.trim().isEmpty &&
      tags.isEmpty;

  JournalEntry copyWith({
    String? id,
    String? dateKey,
    int? moodLevel,
    int? energyLevel,
    List<String>? tags,
    String? gratitude1,
    String? gratitude2,
    String? gratitude3,
    String? dailyWin,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JournalEntry(
      id: id ?? this.id,
      dateKey: dateKey ?? this.dateKey,
      moodLevel: moodLevel ?? this.moodLevel,
      energyLevel: energyLevel ?? this.energyLevel,
      tags: tags ?? this.tags,
      gratitude1: gratitude1 ?? this.gratitude1,
      gratitude2: gratitude2 ?? this.gratitude2,
      gratitude3: gratitude3 ?? this.gratitude3,
      dailyWin: dailyWin ?? this.dailyWin,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateKey': dateKey,
        'moodLevel': moodLevel,
        'energyLevel': energyLevel,
        'tags': tags,
        'gratitude1': gratitude1,
        'gratitude2': gratitude2,
        'gratitude3': gratitude3,
        'dailyWin': dailyWin,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        dateKey: json['dateKey'] as String,
        moodLevel: (json['moodLevel'] as num?)?.toInt() ?? 4,
        energyLevel: (json['energyLevel'] as num?)?.toInt() ?? 3,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        gratitude1: json['gratitude1'] as String? ?? '',
        gratitude2: json['gratitude2'] as String? ?? '',
        gratitude3: json['gratitude3'] as String? ?? '',
        dailyWin: json['dailyWin'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
