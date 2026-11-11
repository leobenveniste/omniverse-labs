/// Bilingual English/Spanish offline string catalog for DidIt.
class AppStrings {
  const AppStrings._(this.isEs);

  final bool isEs;

  static AppStrings of(String code) => AppStrings._(code.startsWith('es'));

  String get appTitle => 'DidIt';
  String get queueTab => isEs ? 'Cola' : 'Queue';
  String get flowsTab => isEs ? 'Flujos' : 'Flows';
  String get logbookTooltip => isEs ? 'Historial de confirmación' : 'Confirmation logbook';
  String get settingsTooltip => isEs ? 'Ajustes' : 'Settings';
  String get searchTooltip => isEs ? 'Buscar tareas' : 'Search items';
  String get searchHint => isEs ? 'Buscar tarea o flujo...' : 'Search item or flow...';
  String get addItemFab => isEs ? 'Nueva tarea' : 'New Item';
  String get addFlowFab => isEs ? 'Nuevo flujo' : 'New Flow';

  String summaryLine(int dueCount, int doneTodayCount) => isEs
      ? '$dueCount por hacer · $doneTodayCount confirmadas hoy'
      : '$dueCount due now · $doneTodayCount confirmed today';

  String get memoryBadge => isEs ? '100% OFFLINE · SIN DUDAS' : '100% OFFLINE · MEMORY PROOF';

  String get sectionDueNow => isEs ? 'PARA HACER AHORA' : 'DUE NOW';
  String get sectionRecentlyDone => isEs ? 'CONFIRMADO RECIENTEMENTE' : 'RECENTLY DONE';
  String get sectionUpcoming => isEs ? 'PRÓXIMAS Y CADENAS' : 'UPCOMING & CHAINS';

  String get didItCta => isEs ? 'HECHO' : 'DID IT';
  String get undoCta => isEs ? 'Deshacer' : 'Undo';
  String get snoozeCta => isEs ? 'Posponer' : 'Snooze';
  String snoozeMinutesLabel(int mins) => isEs ? '+${mins}m' : '+${mins}m';
  String get resetFlowCta => isEs ? 'Reiniciar flujo' : 'Reset Flow';

  String get overdueBadge => isEs ? 'VENCIDA' : 'OVERDUE';
  String get dueSoonBadge => isEs ? 'PRONTO' : 'DUE SOON';
  String get confirmedBadge => isEs ? 'CONFIRMADO' : 'CONFIRMED';
  String get waitingChainBadge => isEs ? 'CADENA' : 'CHAINED';
  String cooldownActiveLabel(String remaining) =>
      isEs ? 'Bloqueo anti-doble: $remaining' : 'Cooldown guard: $remaining';

  String doneAgoLabel(String ago) => isEs ? 'Hecho hace $ago' : 'Done $ago ago';
  String neverDoneLabel() => isEs ? 'Aún sin registrar' : 'Not logged yet';
  String nextInLabel(String duration) => isEs ? 'Próxima en $duration' : 'Next in $duration';
  String dueAgoLabel(String duration) => isEs ? 'Venció hace $duration' : 'Overdue by $duration';
  String snoozedUntilLabel(String hhmm) => isEs ? 'Pospuesta a $hhmm' : 'Snoozed until $hhmm';
  String chainPreview(String targetTitle, String delay) =>
      isEs ? 'Luego activa "$targetTitle" ($delay)' : 'Then triggers "$targetTitle" ($delay)';

  String get cooldownTitle => isEs ? '¿Ya lo hiciste recién?' : 'Already done recently?';
  String cooldownMessage(String title, String ago, String remaining) => isEs
      ? 'Marcaste "$title" hace $ago.\nEl bloqueo de seguridad sigue activo ($remaining).\n\n¿Seguro quieres volver a marcarlo?'
      : 'You confirmed "$title" $ago ago.\nDouble-tap protection is still active ($remaining).\n\nMark it done again anyway?';
  String get confirmAnyway => isEs ? 'Sí, marcar de nuevo' : 'Mark Again';
  String get cancel => isEs ? 'Cancelar' : 'Cancel';
  String get save => isEs ? 'Guardar' : 'Save';
  String get delete => isEs ? 'Eliminar' : 'Delete';

  String confirmedToast(String title) => isEs ? 'Confirmado: $title' : 'Confirmed: $title';
  String undoneToast(String title) => isEs ? 'Deshecho: $title' : 'Undone: $title';
  String snoozedToast(String title, int mins) =>
      isEs ? '$title pospuesto $mins min' : '$title snoozed $mins min';
  String chainTriggeredToast(String target, String delay) =>
      isEs ? 'Automatizado: "$target" ($delay)' : 'Automated: "$target" ($delay)';

  String get emptyQueueTitle => isEs ? 'Nada pendiente ahora' : 'All clear right now';
  String get emptyQueueSubtitle => isEs
      ? 'Agrega una tarea recurrente o importa una plantilla en Flujos para automatizar tu rutina.'
      : 'Add a repeating task or import a Starter Flow to automate recurring checklists.';

  // Flows
  String get starterTemplatesHeader => isEs ? 'PLANTILLAS RÁPIDAS' : 'STARTER TEMPLATES';
  String get activeFlowsHeader => isEs ? 'TUS FLUJOS AUTOMATIZADOS' : 'YOUR AUTOMATED FLOWS';
  String get importTemplate => isEs ? 'Agregar' : 'Import';
  String importedTemplateToast(String title) =>
      isEs ? 'Importado: $title' : 'Imported: $title';
  String stepsProgress(int done, int total) =>
      isEs ? '$done/$total pasos' : '$done/$total steps';
  String runsCompleted(int runs) =>
      isEs ? '$runs ciclos completados' : '$runs runs completed';

  String resetRuleLabel(String ruleName, int cooldownMin, String hhmm) {
    switch (ruleName) {
      case 'onAllComplete':
        return cooldownMin == 0
            ? (isEs ? 'Auto-reinicio inmediato' : 'Auto-resets immediately')
            : (isEs ? 'Auto-reinicio en ${cooldownMin}m' : 'Auto-resets in ${cooldownMin}m');
      case 'scheduledDaily':
        return isEs ? 'Reinicio diario $hhmm' : 'Resets daily at $hhmm';
      case 'scheduledWeekly':
        return isEs ? 'Reinicio semanal $hhmm' : 'Resets weekly at $hhmm';
      default:
        return isEs ? 'Reinicio manual' : 'Manual reset';
    }
  }

  // Editors
  String get newItemTitle => isEs ? 'Nueva tarea automática' : 'New Automated Item';
  String get editItemTitle => isEs ? 'Editar tarea' : 'Edit Item';
  String get itemNameLabel => isEs ? '¿Qué quieres recordar hacer?' : 'What needs to be done?';
  String get itemNameHint => isEs ? 'Ej: Tomar vitamina D, Regar plantas' : 'e.g., Take Vitamin D, Water plants';
  String get repeatModeLabel => isEs ? 'Modo de repetición' : 'Repetition Mode';
  String get repeatFromLastDone => isEs ? 'Desde el último hecho' : 'From Last Done';
  String get repeatDaily => isEs ? 'Diario fijo' : 'Daily Fixed';
  String get repeatWeekly => isEs ? 'Semanal fijo' : 'Weekly Fixed';
  String get repeatMonthly => isEs ? 'Mensual fijo' : 'Monthly Fixed';
  String get repeatChainOnly => isEs ? 'Solo por cadena' : 'Chain Trigger Only';

  String get intervalPresetLabel => isEs ? 'Repetir cada' : 'Repeat Every';
  String get cooldownLabel => isEs ? 'Bloqueo anti-doble toque' : 'Double-Tap Cooldown Guard';
  String get cooldownNone => isEs ? 'Sin bloqueo' : 'Off';
  String get chainTargetLabel => isEs ? 'Luego activar automáticamente (opcional)' : 'Then Trigger Next (Optional)';
  String get noChainTarget => isEs ? 'Ninguna tarea encadenada' : 'None';
  String get chainDelayLabel => isEs ? 'Espera antes de activar' : 'Delay Before Trigger';
  String get scheduleTimeLabel => isEs ? 'Hora del recordatorio' : 'Reminder Time';
  String get weekdaysLabel => isEs ? 'Días activos' : 'Active Days';
  String get monthDayLabel => isEs ? 'Día del mes' : 'Day of Month';
  String get notificationsToggle => isEs ? 'Notificación con botón Hecho/Posponer' : 'Notification with Did It / Snooze';
  String get iconLabel => isEs ? 'Ícono' : 'Icon';

  String get newFlowTitle => isEs ? 'Nuevo flujo automatizado' : 'New Automated Flow';
  String get editFlowTitle => isEs ? 'Editar flujo' : 'Edit Flow';
  String get flowNameLabel => isEs ? 'Nombre del flujo' : 'Flow Name';
  String get flowNameHint => isEs ? 'Ej: Al salir de casa, Rutina nocturna' : 'e.g., Leaving Home, Bedtime Lockup';
  String get flowResetRuleLabel => isEs ? 'Regla de reinicio automático' : 'Auto-Reset Rule';
  String get flowStepsLabel => isEs ? 'Pasos del flujo' : 'Flow Steps';
  String get addStepHint => isEs ? 'Agregar paso...' : 'Add step...';
  String get addStepBtn => isEs ? 'Añadir' : 'Add';

  // Logbook
  String get logbookTitle => isEs ? 'Historial de Confirmación' : 'Confirmation Logbook';
  String get logbookSubtitle =>
      isEs ? 'Prueba exacta de cuándo confirmaste cada tarea' : 'Timestamped proof of every completed action';
  String get logbookEmpty => isEs ? 'Aún no hay registros.' : 'No completions recorded yet.';
  String get clearLogbook => isEs ? 'Limpiar' : 'Clear';
  String logSourceBadge(String src) {
    if (src == 'notification') return isEs ? 'NOTIF' : 'NOTIF';
    if (src == 'flow') return isEs ? 'FLUJO' : 'FLOW';
    return 'APP';
  }

  // Notification copies
  String get notifChannelName => isEs ? 'Recordatorios DidIt' : 'DidIt Reminders';
  String get notifChannelDesc => isEs
      ? 'Alertas locales recurrentes y cadenas automatizadas con acciones rápidas.'
      : 'Offline recurring task & chain notifications with quick actions.';
  String get notifActionDone => isEs ? 'Hecho' : 'Did It';
  String get notifActionSnooze => isEs ? 'Posponer 30m' : 'Snooze 30m';
  String notifBodyDue(String repeatDesc) =>
      isEs ? 'Toca Hecho para confirmar y programar el siguiente ciclo ($repeatDesc).' : 'Tap Did It to confirm and schedule the next loop ($repeatDesc).';

  // Settings & Contact
  String get settingsTitle => isEs ? 'Ajustes' : 'Settings';
  String get appearanceSection => isEs ? 'APARIENCIA E IDIOMA' : 'APPEARANCE & LANGUAGE';
  String get themeLabel => isEs ? 'Tema visual' : 'Visual Theme';
  String get darkLabel => isEs ? 'Oscuro' : 'Dark';
  String get lightLabel => isEs ? 'Claro' : 'Light';
  String get languageLabel => isEs ? 'Idioma' : 'Language';
  String get automationSection => isEs ? 'AUTOMATIZACIÓN Y ALERTAS' : 'AUTOMATION & ALERTS';
  String get defaultSnoozeLabel => isEs ? 'Posposición rápida' : 'Quick Snooze Duration';
  String get notifPermissionLabel => isEs ? 'Permiso de notificaciones' : 'Notification Permission';
  String get grantedLabel => isEs ? 'Activo' : 'Granted';
  String get blockedLabel => isEs ? 'Pendiente' : 'Needed';
  String get enableBtn => isEs ? 'Activar' : 'Enable';
  String get privacyOfflineTitle => isEs ? '100% Offline · Cero Nube' : '100% Offline · Zero Cloud';
  String get privacyOfflineBody => isEs
      ? 'DidIt no usa permiso de internet, ni anuncios, ni servidores. Toda tu historia queda en tu dispositivo.'
      : 'DidIt requests zero internet permission, zero ads, and zero tracking. Your confirmation log stays strictly on your phone.';
  String get contactSupportBtn => isEs ? 'Soporte y Privacidad' : 'Support & Privacy';
  String get contactTitle => isEs ? 'Omniverse Labs · DidIt' : 'Omniverse Labs · DidIt';
  String get supportEmail => 'support@omniverselabs.com';

  String formatMinutesHuman(int mins) {
    if (mins <= 0) return isEs ? 'inmediato' : 'now';
    if (mins < 60) return isEs ? '${mins}m' : '${mins}m';
    if (mins % 1440 == 0) {
      final d = mins ~/ 1440;
      return isEs ? '${d}d' : '${d}d';
    }
    if (mins % 60 == 0) {
      final h = mins ~/ 60;
      return isEs ? '${h}h' : '${h}h';
    }
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }
}
