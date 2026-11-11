import '../models/guarded_item.dart';

/// Supported offline UI languages.
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

/// Supported currency symbols for zero-friction formatting.
const List<String> kSupportedCurrencies = [r'$', '€', '£', r'R$', r'ARS$'];

/// Bilingual (EN/ES) string dictionary for CancelGuard.
class AppStrings {
  const AppStrings(this.locale);

  final AppLocale locale;

  bool get isEs => locale == AppLocale.es;

  String get appTitle => 'CancelGuard';
  String get settingsTooltip => isEs ? 'Ajustes' : 'Settings';
  String get settingsTitle => isEs ? 'Ajustes' : 'Settings';

  String get atRisk30d => isEs ? 'EN RIESGO (30D)' : 'AT RISK (30D)';
  String get totalSaved => isEs ? 'TOTAL AHORRADO' : 'TOTAL SAVED';
  String roiBadge(double roi) {
    final formatted = roi >= 10 ? roi.toStringAsFixed(0) : roi.toStringAsFixed(1);
    return '${formatted}x ROI';
  }

  String get activeTab => isEs ? 'Activas' : 'Active';
  String get savedHistoryTab => isEs ? 'Historial' : 'Saved History';

  String get guardTrialCta => isEs ? 'Proteger Prueba' : 'Guard Trial';
  String get urgentSection =>
      isEs ? 'URGENTE — VENTANA DE CANCELACIÓN' : 'URGENT — CANCEL WINDOW OPEN';
  String get protectedSection =>
      isEs ? 'PROTEGIDAS — EN VENTANA SEGURA' : 'PROTECTED — SAFE WINDOW';
  String get historySection =>
      isEs ? 'CARGOS EVITADOS Y CANCELADAS' : 'DODGED CHARGES & CANCELLED';

  String get emptyActiveTitle =>
      isEs ? 'Tu bóveda está vacía' : 'Your Guardian Vault is clear';
  String get emptyActiveBody => isEs
      ? 'Agregá una prueba gratuita o renovación en 10 segundos. Te avisamos 48h y 24h antes de que te cobren.'
      : 'Log any free trial or auto-renewal in 10 seconds. We alert you 48h and 24h before your card is charged.';
  String get emptyHistoryTitle =>
      isEs ? 'Todavía no marcaste cancelaciones' : 'No dodged charges yet';
  String get emptyHistoryBody => isEs
      ? 'Cuando canceles una prueba a tiempo, tocá "Marcar Cancelada" para sumar el dinero ahorrado a tu trofeo ROI.'
      : 'When you cancel a trial in time, tap "Mark Cancelled" to bank the savings into your ROI trophy.';

  String get notificationsSection => isEs ? 'ALERTAS Y PERMISOS' : 'ALERTS & PERMISSIONS';
  String get notificationPermissionLabel =>
      isEs ? 'Notificaciones locales' : 'Local notifications';
  String get notificationsActiveDesc => isEs
      ? 'Activas para avisos 48h/24h antes del cobro'
      : 'Enabled for 48h/24h Cancel-By reminders';
  String get notificationsDisabledDesc => isEs
      ? 'Activa los permisos para recibir recordatorios antes del cobro'
      : 'Enable permission so Cancel-By reminders can fire on time';
  String get enableAction => isEs ? 'Activar' : 'Enable';
  String get enabledBadge => isEs ? 'Activas' : 'Active';

  String get appearanceSection => isEs ? 'APARIENCIA' : 'APPEARANCE';
  String get themeSystem => isEs ? 'Sistema' : 'System';
  String get themeLight => isEs ? 'Claro' : 'Light';
  String get themeDark => isEs ? 'Oscuro' : 'Dark';

  String get preferencesSection => isEs ? 'PREFERENCIAS' : 'PREFERENCES';
  String get languageLabel => isEs ? 'Idioma' : 'Language';
  String get currencyLabel => isEs ? 'Moneda' : 'Currency';

  String get aboutCompany => 'OMNIVERSE LABS';
  String get aboutMission => isEs
      ? 'Creadores de herramientas digitales, utilidades y experiencias móviles de alta calidad diseñadas para acompañar tu día a día.'
      : 'Creators of top-tier digital tools, daily utilities, and mobile experiences designed to elevate your everyday life.';
  String get appDetailsLabel => isEs ? 'Aplicación' : 'App';
  String get packageIdLabel => isEs ? 'Paquete' : 'Package';
  String get versionLabel => isEs ? 'Versión' : 'Version';
  String get privacyGuarantee => isEs
      ? '100% Fuera de Línea. Tus datos se almacenan exclusivamente en tu dispositivo, sin servidores ni rastreadores.'
      : '100% Offline. Your data lives exclusively on your device, with no external servers or trackers.';

  String get contactSection =>
      isEs ? 'CONTACTO Y SUGERENCIAS' : 'CONTACT & SUGGESTIONS';
  String get contactTitle =>
      isEs ? 'Escríbenos por correo' : 'Send us a message';
  String get contactDescription => isEs
      ? '¿Tienes sugerencias para mejorar CancelGuard o encontraste algún error? Escríbenos directamente y te responderemos a la brevedad:'
      : 'Have suggestions to improve CancelGuard or found an issue? Reach out directly and we will get back to you promptly:';
  String get copyEmailTooltip => isEs ? 'Copiar email' : 'Copy email';
  String get emailCopiedSnackbar => isEs
      ? 'Email copiado: leo.benveniste@gmail.com'
      : 'Email copied: leo.benveniste@gmail.com';
  String get sendEmailCta => isEs ? 'Enviar Correo' : 'Send Email';
  String get gotItCta => isEs ? 'Entendido' : 'Got it';

  String get openCancelLink => isEs ? 'Abrir Link de Baja' : 'Open Cancel Link';
  String get markCancelled => isEs ? 'Marcar Cancelada' : 'Mark Cancelled';
  String get restoreItem => isEs ? 'Reactivar' : 'Restore';
  String get deleteItem => isEs ? 'Eliminar' : 'Delete';

  String get sheetTitleNew =>
      isEs ? 'Proteger Prueba o Suscripción' : 'Guard Trial or Renewal';
  String get sheetTitleEdit =>
      isEs ? 'Editar Protección' : 'Edit Guarded Item';
  String get serviceNameLabel => isEs ? 'Servicio / App' : 'Service / App';
  String get serviceNameHint =>
      isEs ? 'Buscar o escribir servicio...' : 'Search or type any service...';
  String get serviceNameError =>
      isEs ? 'Ingresá el nombre del servicio' : 'Enter a service name';
  String get priceLabel => isEs ? 'Precio al renovar' : 'Renewal price';
  String get priceError =>
      isEs ? 'Ingresá un monto válido' : 'Enter a valid amount';
  String get typeLabel => isEs ? 'TIPO' : 'TYPE';
  String get trialType => isEs ? 'Prueba Gratis' : 'Free Trial';
  String get recurringType => isEs ? 'Renovación' : 'Recurring';
  String get cycleMonthly => isEs ? 'Mensual' : 'Monthly';
  String get cycleAnnual => isEs ? 'Anual' : 'Annual';
  String get chargeDateLabel =>
      isEs ? 'FECHA DE COBRO / FIN DE PRUEBA' : 'CHARGE / TRIAL END DATE';
  String get pickDate => isEs ? 'Elegir fecha' : 'Pick date';
  String get alertBufferLabel =>
      isEs ? 'AVISO PREVIO (CANCEL BY)' : 'CANCEL-BY BUFFER ALERTS';
  String get cancelUrlLabel =>
      isEs ? 'Link de cancelación (opcional)' : 'Cancel link (optional)';
  String get cancelUrlHint => 'https://...';
  String get notesLabel =>
      isEs ? 'Nota rápida (opcional)' : 'Quick note (optional)';
  String get notesHint => isEs
      ? 'Ej. Ajustes > Facturación > Cancelar'
      : 'e.g. Settings > Billing > Cancel plan';
  String get activateShieldCta =>
      isEs ? 'Activar Escudo' : 'Activate Shield';
  String get saveChangesCta => isEs ? 'Guardar Cambios' : 'Save Changes';

  String alertPresetLabel(AlertPreset preset) {
    return switch (preset) {
      AlertPreset.buffer48And24 => '48h + 24h',
      AlertPreset.buffer24Only => isEs ? 'Solo 24h' : '24h only',
      AlertPreset.buffer72And24 => '72h + 24h',
      AlertPreset.buffer7dAnd48h => '7d + 48h',
    };
  }

  String durationChipLabel(int days) => '${days}d';

  String formatMoney(String currency, double amount) =>
      '$currency${amount.toStringAsFixed(2)}';

  String cycleSuffix(BillingCycle cycle) {
    return switch (cycle) {
      BillingCycle.trialOnce => isEs ? '/prueba' : '/trial',
      BillingCycle.monthly => isEs ? '/mes' : '/mo',
      BillingCycle.annual => isEs ? '/año' : '/yr',
    };
  }

  String countdownText(GuardedItem item, [DateTime? now]) {
    final ref = now ?? DateTime.now();
    final diff = item.chargeAt.difference(ref);
    if (diff.isNegative) {
      return isEs ? 'Vence hoy / vencida' : 'Due now / past due';
    }
    if (diff.inHours < 1) {
      final mins = diff.inMinutes.clamp(1, 59);
      return isEs ? 'Cancela en ${mins}m' : 'Cancel in ${mins}m';
    }
    if (diff.inHours < 48) {
      return isEs ? 'Cancela en ${diff.inHours}h' : 'Cancel in ${diff.inHours}h';
    }
    final days = diff.inDays;
    final remHours = diff.inHours % 24;
    return isEs
        ? 'Cancela en ${days}d ${remHours}h'
        : 'Cancel in ${days}d ${remHours}h';
  }

  String bankedSnackbar(String name, String formattedAmount) {
    return isEs
        ? '$name cancelada — sumaste $formattedAmount al ahorro'
        : '$name cancelled — banked $formattedAmount saved';
  }

  String shieldActiveSnackbar(String name) {
    return isEs
        ? 'Escudo activo para $name'
        : 'Shield active for $name';
  }

  String couldNotOpenLinkSnackbar() {
    return isEs
        ? 'No se pudo abrir el enlace en este dispositivo'
        : 'Could not open link on this device';
  }
}
