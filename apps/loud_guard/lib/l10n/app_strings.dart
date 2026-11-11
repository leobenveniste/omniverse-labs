import '../models/loud_models.dart';

class AppStrings {
  const AppStrings._(this.locale);

  final AppLocale locale;

  bool get isEs => locale == AppLocale.es;

  static AppStrings of(AppLocale locale) => AppStrings._(locale);

  String get appTitle => 'LoudGuard';

  // AppBar & Navigation
  String get savedChecksTooltip =>
      isEs ? 'Historial de mediciones' : 'Saved sound checks';
  String get settingsTooltip => isEs ? 'Ajustes' : 'Settings';

  // Sound Console
  String get statusListening => isEs ? 'MIDIENDO EN RAM' : 'LIVE IN RAM';
  String get statusPaused => isEs ? 'EN PAUSA' : 'PAUSED';
  String get statusReady => isEs ? 'LISTO' : 'READY';
  String get dbUnit => 'dB SPL';
  String get minLabel => isEs ? 'MÍN' : 'MIN';
  String get avgLabel => isEs ? 'PROM' : 'AVG';
  String get peakLabel => isEs ? 'PICO' : 'PEAK';

  String zoneBadgeLabel(SafetyZone zone) {
    switch (zone) {
      case SafetyZone.safe:
        return isEs ? 'SEGURO (< 70 dB)' : 'SAFE (< 70 dB)';
      case SafetyZone.moderate:
        return isEs ? 'MODERADO (70–84 dB)' : 'MODERATE (70–84 dB)';
      case SafetyZone.caution:
        return isEs ? 'PRECAUCIÓN (85–94 dB)' : 'CAUTION (85–94 dB)';
      case SafetyZone.damageRisk:
        return isEs ? 'RIESGO AUDITIVO (95+ dB)' : 'DAMAGE RISK (95+ dB)';
    }
  }

  String contextReference(double db) {
    if (db < 40) {
      return isEs
          ? 'Referencia: Habitación silenciosa / Biblioteca'
          : 'Reference: Quiet room / Library';
    }
    if (db < 55) {
      return isEs
          ? 'Referencia: Cuarto de bebé seguro / Hogar tranquilo'
          : 'Reference: Nursery safe / Calm home';
    }
    if (db < 70) {
      return isEs
          ? 'Referencia: Conversación normal / Oficina'
          : 'Reference: Normal conversation / Office';
    }
    if (db < 85) {
      return isEs
          ? 'Referencia: Tráfico urbano / Restaurante ruidoso'
          : 'Reference: City traffic / Busy restaurant';
    }
    if (db < 95) {
      return isEs
          ? 'Referencia: Taller / Moto — Límite WHO 8h en 85 dB'
          : 'Reference: Workshop / Traffic — WHO 8h limit at 85 dB';
    }
    return isEs
        ? 'Referencia: Concierto / Club — Se recomienda protección'
        : 'Reference: Live concert / Club — Ear protection advised';
  }

  // WHO Safe-Exposure Card
  String get exposureSectionTitle =>
      isEs ? 'EXPOSICIÓN SEGURA (WHO / NIOSH)' : 'WHO / NIOSH SAFE EXPOSURE';
  String get safeLimitLabel =>
      isEs ? 'Límite seguro actual' : 'Safe limit now';
  String get unlimitedSafe => isEs ? '24h+ Seguro' : '24h+ Safe';
  String get sessionTimeLabel => isEs ? 'Sesión' : 'Session';
  String get dailyDoseLabel => isEs ? 'Dosis diaria' : 'Daily dose';
  String get doseWarningText => isEs
      ? 'Superaste el 100% de dosis diaria recomendada.'
      : 'Exceeded 100% of recommended daily noise dose.';

  // Controls
  String get startMeterCta => isEs ? 'MEDIR AHORA' : 'START METER';
  String get pauseMeterCta => isEs ? 'PAUSAR' : 'PAUSE';
  String get logCheckCta => isEs ? 'GUARDAR' : 'LOG CHECK';
  String get resetCta => isEs ? 'REINICIAR' : 'RESET';
  String get micPermissionNeeded => isEs
      ? 'Permiso de micrófono requerido para medir dB en tiempo real (sin grabar audio).'
      : 'Microphone permission needed for live dB readings (audio is never recorded).';
  String get grantMicCta => isEs ? 'PERMITIR MIC' : 'ALLOW MIC';
  String get micUnavailableMessage => isEs
      ? 'No se pudo iniciar el micrófono en este dispositivo.'
      : 'Could not start the microphone on this device.';
  String get sessionResetSnackbar =>
      isEs ? 'Medición reiniciada.' : 'Session metrics reset.';
  String get needSampleFirst => isEs
      ? 'Iniciá el medidor unos segundos antes de guardar.'
      : 'Run the meter briefly before logging a check.';

  // Saved Checks Modal
  String get savedChecksTitle =>
      isEs ? 'Mediciones guardadas' : 'Saved Sound Checks';
  String get saveCurrentCheckTitle =>
      isEs ? 'Guardar medición actual' : 'Save Current Check';
  String get checkLabelHint =>
      isEs ? 'Ej. Cuarto bebé, Escenario, Taller' : 'e.g. Nursery, Main Stage, Shop';
  List<String> get quickContextLabels => isEs
      ? const ['Cuarto bebé', 'Concierto', 'Ensayo', 'Taller', 'Oficina']
      : const ['Nursery', 'Concert', 'Rehearsal', 'Workshop', 'Office'];
  String get saveCheckButton => isEs ? 'Guardar medición' : 'Save Check';
  String get checkSavedSnackbar =>
      isEs ? 'Medición guardada sin conexión.' : 'Sound check saved offline.';
  String get noSavedChecksYet => isEs
      ? 'Todavía no guardaste mediciones. Tocá GUARDAR durante una sesión.'
      : 'No saved checks yet. Tap LOG CHECK during a session to store one locally.';
  String get deleteCheckTooltip => isEs ? 'Eliminar medición' : 'Delete check';

  // Settings Screen
  String get settingsTitle => isEs ? 'Ajustes' : 'Settings';
  String get appearanceSection => isEs ? 'APARIENCIA' : 'APPEARANCE';
  String get themeSystem => isEs ? 'Sistema' : 'System';
  String get themeLight => isEs ? 'Claro' : 'Light';
  String get themeDark => isEs ? 'Oscuro' : 'Dark';

  String get preferencesSection => isEs ? 'PREFERENCIAS' : 'PREFERENCES';
  String get languageLabel => isEs ? 'Idioma' : 'Language';
  String get calibrationLabel =>
      isEs ? 'Calibración del micrófono' : 'Microphone Calibration';
  String get calibrationDesc => isEs
      ? 'Ajustá el desplazamiento si comparás con un sonómetro de referencia.'
      : 'Fine-tune dB offset to match a reference SPL meter.';
  String get resetOffsetCta => isEs ? '0 dB' : 'Reset';
  String get hapticThresholdLabel =>
      isEs ? 'Alerta háptica de umbral' : 'Haptic Threshold Alert';
  String get hapticThresholdDesc => isEs
      ? 'Vibra suavemente una vez si el sonido supera este nivel.'
      : 'Gently vibrate once when live sound crosses this ceiling.';
  String hapticThresholdChip(HapticThreshold t) {
    switch (t) {
      case HapticThreshold.off:
        return isEs ? 'No' : 'Off';
      case HapticThreshold.db85:
        return '85 dB';
      case HapticThreshold.db90:
        return '90 dB';
      case HapticThreshold.db95:
        return '95 dB';
    }
  }

  String get keepAwakeLabel =>
      isEs ? 'Mantener pantalla encendida' : 'Keep Screen Awake';
  String get keepAwakeDesc => isEs
      ? 'Evita que la pantalla se apague mientras medís en vivo.'
      : 'Prevent display sleep while the live meter is active.';

  // Contact Us
  String get contactSection =>
      isEs ? 'CONTACTO Y SUGERENCIAS' : 'CONTACT & SUGGESTIONS';
  String get contactTitle => isEs ? 'Escribinos' : 'Contact Us';
  String get contactDescription => isEs
      ? '¿Tenés ideas para mejorar LoudGuard o encontraste algún error? Escribinos directo por correo.'
      : 'Have feature ideas for LoudGuard or spotted a bug? Reach out directly by email.';
  String get copyEmailTooltip => isEs ? 'Copiar correo' : 'Copy email';
  String get emailCopiedSnackbar =>
      isEs ? 'Correo copiado al portapapeles.' : 'Email copied to clipboard.';
  String get gotItCta => isEs ? 'Entendido' : 'Got it';
  String get sendEmailCta => isEs ? 'Enviar correo' : 'Send Email';

  // About Omniverse Labs
  String get aboutCompany => 'OMNIVERSE LABS';
  String get aboutMission => isEs
      ? 'Utilidades móviles 100% offline, sin cuentas, sin rastreo y sin anuncios.'
      : '100% offline mobile utilities with zero accounts, zero tracking, and zero ads.';
  String get appDetailsLabel => isEs ? 'Aplicación' : 'App';
  String get packageIdLabel => isEs ? 'Paquete' : 'Package';
  String get versionLabel => isEs ? 'Versión' : 'Version';
  String get privacyGuarantee => isEs
      ? '100% sin conexión ni permiso de internet. El audio se procesa en memoria RAM y nunca se graba ni se envía.'
      : '100% offline with zero internet permission. Audio amplitude is processed in RAM and never recorded or transmitted.';
}
