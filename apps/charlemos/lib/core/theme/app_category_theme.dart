import 'package:flutter/material.dart';

class CategoryStyle {
  final Color primary;
  final Color backgroundLight;
  final Color backgroundDark;
  final Color borderLight;
  final Color borderDark;
  final Color onPrimary;
  final IconData icon;

  const CategoryStyle({
    required this.primary,
    required this.backgroundLight,
    required this.backgroundDark,
    required this.borderLight,
    required this.borderDark,
    required this.onPrimary,
    required this.icon,
  });
}

class AppCategoryTheme {
  AppCategoryTheme._();

  // 1. Citas (dates)
  static const CategoryStyle dates = CategoryStyle(
    primary: Color(0xFFFF2E3A),          // Coral Vivo
    backgroundLight: Color(0xFFFFF1F2),  // Soft blush rose
    backgroundDark: Color(0xFF261014),   // Deep cherry velvet
    borderLight: Color(0xFFFFCCD1),
    borderDark: Color(0xFF661622),
    onPrimary: Colors.white,
    icon: Icons.favorite_rounded,
  );

  // 2. Parejas (couples)
  static const CategoryStyle couples = CategoryStyle(
    primary: Color(0xFF8B5CF6),          // Violeta Profundo
    backgroundLight: Color(0xFFF5F0FF),  // Lilac mist
    backgroundDark: Color(0xFF1E1430),   // Mystic amethyst
    borderLight: Color(0xFFDDD6FE),
    borderDark: Color(0xFF4C1D95),
    onPrimary: Colors.white,
    icon: Icons.volunteer_activism_rounded,
  );

  // 3. Fuego & Fantasías (spicy) - Íntimo & Erótico para Parejas
  static const CategoryStyle spicy = CategoryStyle(
    primary: Color(0xFFE11D48),          // Carmesí Fuego
    backgroundLight: Color(0xFFFFF1F4),  // Warm blush satin
    backgroundDark: Color(0xFF2D0B14),   // Crimson velvet night
    borderLight: Color(0xFFFFCCD6),
    borderDark: Color(0xFF881337),
    onPrimary: Colors.white,
    icon: Icons.local_fire_department_rounded,
  );

  // 4. Picante & Tabú (hot_takes) - Verdad o Trago / Confesiones
  static const CategoryStyle hotTakes = CategoryStyle(
    primary: Color(0xFF9333EA),          // Púrpura Eléctrico
    backgroundLight: Color(0xFFFAF5FF),  // Neon purple glow
    backgroundDark: Color(0xFF240E38),   // Dark ultraviolet
    borderLight: Color(0xFFE9D5FF),
    borderDark: Color(0xFF581C87),
    onPrimary: Colors.white,
    icon: Icons.whatshot_rounded,
  );

  // 5. La Previa & Fiesta (party)
  static const CategoryStyle party = CategoryStyle(
    primary: Color(0xFFEC4899),          // Rosa Neón Fiesta
    backgroundLight: Color(0xFFFDF2F8),  // Magenta breeze
    backgroundDark: Color(0xFF2E0D22),   // Neon nightlife
    borderLight: Color(0xFFFBCFE8),
    borderDark: Color(0xFF831843),
    onPrimary: Colors.white,
    icon: Icons.celebration_rounded,
  );

  // 6. Amigos (friends)
  static const CategoryStyle friends = CategoryStyle(
    primary: Color(0xFF10B981),          // Verde Esmeralda / Amigos
    backgroundLight: Color(0xFFECFDF5),  // Soft mint
    backgroundDark: Color(0xFF0D251C),   // Forest midnight
    borderLight: Color(0xFFA7F3D0),
    borderDark: Color(0xFF065F46),
    onPrimary: Colors.white,
    icon: Icons.groups_rounded,
  );

  // 7. Retos (challenges)
  static const CategoryStyle challenges = CategoryStyle(
    primary: Color(0xFFF59E0B),          // Oro Ámbar / Retos
    backgroundLight: Color(0xFFFFFBEB),  // Warm champagne
    backgroundDark: Color(0xFF2A1C06),   // Amber obsidian
    borderLight: Color(0xFFFDE68A),
    borderDark: Color(0xFF78350F),
    onPrimary: Color(0xFF1C1300),
    icon: Icons.bolt_rounded,
  );

  // 8. Dilemas & Filosofía (debates)
  static const CategoryStyle debates = CategoryStyle(
    primary: Color(0xFF6366F1),          // Índigo Cósmico
    backgroundLight: Color(0xFFEEF2FF),  // Soft indigo cloud
    backgroundDark: Color(0xFF131536),   // Deep night indigo
    borderLight: Color(0xFFC7D2FE),
    borderDark: Color(0xFF312E81),
    onPrimary: Colors.white,
    icon: Icons.psychology_rounded,
  );

  // 9. Viajes & Aventuras (travel)
  static const CategoryStyle travel = CategoryStyle(
    primary: Color(0xFF0D9488),          // Teal / Turquesa Marino
    backgroundLight: Color(0xFFF0FDFA),  // Seafoam breeze
    backgroundDark: Color(0xFF082623),   // Deep oceanic teal
    borderLight: Color(0xFF99F6E4),
    borderDark: Color(0xFF134E4A),
    onPrimary: Colors.white,
    icon: Icons.flight_takeoff_rounded,
  );

  // 10. Familia & Raíces (family)
  static const CategoryStyle family = CategoryStyle(
    primary: Color(0xFF0284C7),          // Celeste Océano Cálido
    backgroundLight: Color(0xFFF0F9FF),  // Sky soft
    backgroundDark: Color(0xFF0B2133),   // Harbor navy
    borderLight: Color(0xFFBAE6FD),
    borderDark: Color(0xFF0369A1),
    onPrimary: Colors.white,
    icon: Icons.family_restroom_rounded,
  );

  // 11. Personalizadas (custom)
  static const CategoryStyle custom = CategoryStyle(
    primary: Color(0xFF3B82F6),          // Azul Zafiro / Personalizadas
    backgroundLight: Color(0xFFEFF6FF),  // Soft sky
    backgroundDark: Color(0xFF0D1B36),   // Ocean navy
    borderLight: Color(0xFFBFDBFE),
    borderDark: Color(0xFF1E3A8A),
    onPrimary: Colors.white,
    icon: Icons.edit_note_rounded,
  );

  // 12. Retos Picantes (spicy_challenges)
  static const CategoryStyle spicyChallenges = CategoryStyle(
    primary: Color(0xFFFF0055),          // Hot Neon Rose / Rubí Picante
    backgroundLight: Color(0xFFFFF0F5),  // Soft blush neon
    backgroundDark: Color(0xFF310715),   // Crimson velvet night
    borderLight: Color(0xFFFFCCD9),
    borderDark: Color(0xFF8B0D36),
    onPrimary: Colors.white,
    icon: Icons.local_fire_department_rounded,
  );

  // 13. ¿Quién es más probable? (most_likely) - Grupos 5-10
  static const CategoryStyle mostLikely = CategoryStyle(
    primary: Color(0xFFF97316),          // Naranja Eléctrico / Votación
    backgroundLight: Color(0xFFFFF7ED),  // Warm cream
    backgroundDark: Color(0xFF2D1606),   // Deep amber obsidian
    borderLight: Color(0xFFFFEDD5),
    borderDark: Color(0xFF7C2D12),
    onPrimary: Colors.white,
    icon: Icons.how_to_vote_rounded,
  );

  // 14. Yo Nunca Nunca (never_have_i) - Grupos 5-10
  static const CategoryStyle neverHaveI = CategoryStyle(
    primary: Color(0xFF06B6D4),          // Cyan Neón / Nocturno
    backgroundLight: Color(0xFFECFEFF),  // Cyan mist
    backgroundDark: Color(0xFF05212A),   // Deep oceanic abyss
    borderLight: Color(0xFFCFFAFE),
    borderDark: Color(0xFF155E75),
    onPrimary: Colors.white,
    icon: Icons.sports_bar_rounded,
  );

  // 15. Retos en Pareja (couples_challenges) - Complicidad y Dinámicas Románticas
  static const CategoryStyle couplesChallenges = CategoryStyle(
    primary: Color(0xFFD946EF),          // Fucsia Pasión Radiante
    backgroundLight: Color(0xFFFDF4FF),  // Soft fuchsia glow
    backgroundDark: Color(0xFF2C0A33),   // Deep fuchsia velvet
    borderLight: Color(0xFFF5D0FE),
    borderDark: Color(0xFF701A75),
    onPrimary: Colors.white,
    icon: Icons.favorite_border_rounded,
  );

  static CategoryStyle of(String category) {
    switch (category) {
      case 'dates':
        return dates;
      case 'couples':
        return couples;
      case 'spicy':
        return spicy;
      case 'couples_challenges':
        return couplesChallenges;
      case 'hot_takes':
        return hotTakes;
      case 'party':
        return party;
      case 'friends':
        return friends;
      case 'challenges':
        return challenges;
      case 'spicy_challenges':
        return spicyChallenges;
      case 'most_likely':
        return mostLikely;
      case 'never_have_i':
        return neverHaveI;
      case 'debates':
        return debates;
      case 'travel':
        return travel;
      case 'family':
        return family;
      case 'custom':
        return custom;
      default:
        return dates;
    }
  }
}
