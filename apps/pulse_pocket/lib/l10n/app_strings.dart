import '../models/pulse_models.dart';

/// Supported offline UI languages matching CancelGuard.
enum AppLocale {
  en('English'),
  es('Español');

  const AppLocale(this.label);
  final String label;

  static AppLocale fromName(String? value) => AppLocale.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppLocale.en,
      );
}

/// Bilingual (EN/ES) string dictionary for PulsePocket.
class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  bool get isEs => locale == AppLocale.es;

  String get appTitle => 'PulsePocket';
  String get settingsTooltip => isEs ? 'Ajustes' : 'Settings';
  String get settingsTitle => isEs ? 'Ajustes' : 'Settings';

  String get setlistSection => isEs ? 'SETLIST RÁPIDO' : 'SETLIST SLOTS';
  String get saveSlotCta => isEs ? 'Guardar' : 'Save Slot';
  String get slotHint =>
      isEs ? 'Toca un tema para cargar BPM · Mantén para editar' : 'Tap a slot to load BPM · Long-press to edit';
  String get emptySlotsHint =>
      isEs ? 'Guarda tus temas para saltar de tempo en 1 toque.' : 'Save song slots to switch tempo in 1 tap.';

  String get bpmUnit => 'BPM';
  String get meterLabel => isEs ? 'COMPÁS' : 'METER';
  String get tapTempoLabel => 'TAP TEMPO';
  String get tapTempoHint =>
      isEs ? 'Toca 2 o más veces al ritmo' : 'Tap 2+ times to lock BPM';
  String get startCta => isEs ? 'INICIAR' : 'START';
  String get stopCta => isEs ? 'DETENER' : 'STOP';
  String get pocketLockCta => isEs ? 'BOLSILLO' : 'POCKET LOCK';

  String get pocketLockTitle => isEs ? 'BOLSILLO BLOQUEADO' : 'POCKET LOCKED';
  String get pocketLockHint => isEs
      ? 'Mantén presionado 1.2s para desbloquear'
      : 'Hold anywhere for 1.2s to unlock';
  String get beatOneAccent => isEs ? 'ACENTO COMPÁS 1' : 'BEAT 1 ACCENT';
  String get silentModeBadge =>
      isEs ? 'HÁPTICO SILENCIOSO · SIN AUDIO' : 'SILENT HAPTIC · ZERO AUDIO';

  String get slotSheetTitleNew => isEs ? 'Guardar en Setlist' : 'Save Setlist Slot';
  String get slotSheetTitleEdit => isEs ? 'Editar Tema' : 'Edit Setlist Slot';
  String get slotNameLabel => isEs ? 'Nombre del tema o sección' : 'Song or section name';
  String get slotNameHint => isEs ? 'Ej. Apertura, Balada, Bis' : 'e.g. Opener, Ballad, Encore';
  String get slotNameError =>
      isEs ? 'Ingresa un nombre para este slot' : 'Enter a slot name';
  String get updateToCurrentTempo =>
      isEs ? 'Usar tempo actual' : 'Use current tempo';
  String get saveChangesCta => isEs ? 'Guardar Cambios' : 'Save Changes';
  String get deleteSlotCta => isEs ? 'Eliminar Slot' : 'Delete Slot';
  String get maxSlotsReached => isEs
      ? 'Límite de $kMaxSetlistSlots slots alcanzado'
      : 'Maximum $kMaxSetlistSlots setlist slots reached';

  String slotLoadedSnackbar(SetlistSlot slot) => isEs
      ? '${slot.name} — ${slot.bpm} BPM (${slot.signature.label})'
      : '${slot.name} — ${slot.bpm} BPM (${slot.signature.label})';

  String slotSavedSnackbar(String name) =>
      isEs ? 'Guardado en Setlist: $name' : 'Saved to Setlist: $name';

  String get appearanceSection => isEs ? 'APARIENCIA' : 'APPEARANCE';
  String get themeSystem => isEs ? 'Sistema' : 'System';
  String get themeLight => isEs ? 'Claro' : 'Light';
  String get themeDark => isEs ? 'Oscuro' : 'Dark';

  String get preferencesSection => isEs ? 'PREFERENCIAS' : 'PREFERENCES';
  String get languageLabel => isEs ? 'Idioma' : 'Language';
  String get hapticStrengthLabel =>
      isEs ? 'Fuerza háptica' : 'Haptic strength';
  String get testPulseCta => isEs ? 'Probar Pulso' : 'Test Pulse';
  String get visualFlashLabel => isEs ? 'Destello visual de pulso' : 'Visual beat flash';
  String get visualFlashDesc => isEs
      ? 'Ilumina los puntos de compás con cada pulso'
      : 'Highlight beat dots in sync with each pulse';
  String get keepAwakeLabel => isEs ? 'Mantener pantalla activa' : 'Keep screen awake';
  String get keepAwakeDesc => isEs
      ? 'Evita que el teléfono se suspenda mientras marca el ritmo'
      : 'Prevent sleep lock while the metronome is running';

  String hapticStrengthLabelOf(HapticStrength strength) {
    return switch (strength) {
      HapticStrength.normal => isEs ? 'Normal' : 'Normal',
      HapticStrength.strong => isEs ? 'Fuerte' : 'Strong',
      HapticStrength.stageMax => isEs ? 'Escenario' : 'Stage Max',
    };
  }

  String get contactSection =>
      isEs ? 'CONTACTO Y SUGERENCIAS' : 'CONTACT & SUGGESTIONS';
  String get contactTitle =>
      isEs ? 'Escríbenos por correo' : 'Send us a message';
  String get contactDescription => isEs
      ? '¿Tienes sugerencias para mejorar PulsePocket o encontraste algún error? Escríbenos directamente y te responderemos a la brevedad:'
      : 'Have suggestions to improve PulsePocket or found an issue? Reach out directly and we will get back to you promptly:';
  String get copyEmailTooltip => isEs ? 'Copiar email' : 'Copy email';
  String get emailCopiedSnackbar => isEs
      ? 'Email copiado: leo.benveniste@gmail.com'
      : 'Email copied: leo.benveniste@gmail.com';
  String get sendEmailCta => isEs ? 'Enviar Correo' : 'Send Email';
  String get gotItCta => isEs ? 'Entendido' : 'Got it';

  String get aboutCompany => 'OMNIVERSE LABS';
  String get aboutMission => isEs
      ? 'Creadores de herramientas digitales, utilidades y experiencias móviles de alta calidad diseñadas para acompañar tu día a día.'
      : 'Creators of top-tier digital tools, daily utilities, and mobile experiences designed to elevate your everyday life.';
  String get appDetailsLabel => isEs ? 'Aplicación' : 'App';
  String get packageIdLabel => isEs ? 'Paquete' : 'Package';
  String get versionLabel => isEs ? 'Versión' : 'Version';
  String get privacyGuarantee => isEs
      ? '100% Fuera de Línea y Sin Audio. Cero sonido en micrófonos, cero servidores y cero rastreadores.'
      : '100% Offline & Zero Audio. Zero bleed into microphones, no external servers, and zero trackers.';
}
