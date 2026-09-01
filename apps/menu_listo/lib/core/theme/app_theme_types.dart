enum AppDesignTheme {
  modernBotanical,
  editorialGourmet,
  materialYouBento;

  String get displayName {
    switch (this) {
      case AppDesignTheme.modernBotanical:
        return '🌿 Modern Botanical Kitchen';
      case AppDesignTheme.editorialGourmet:
        return '🏛️ Editorial Gourmet Minimalist';
      case AppDesignTheme.materialYouBento:
        return '⚡ Material You Tech-Craft (Bento)';
    }
  }
}
