import 'package:flutter/widgets.dart';

class AppShellScope extends InheritedWidget {
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenCredencial;
  final VoidCallback onSosTap;
  final VoidCallback onSosLongPressStart;
  final VoidCallback onSosLongPressEnd;
  final double sosHoldProgress;
  final void Function(int) onSelectTab;

  const AppShellScope({
    super.key,
    required this.onOpenProfile,
    required this.onOpenCredencial,
    required this.onSosTap,
    required this.onSosLongPressStart,
    required this.onSosLongPressEnd,
    required this.sosHoldProgress,
    required this.onSelectTab,
    required super.child,
  });

  static AppShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppShellScope>();

  @override
  bool updateShouldNotify(AppShellScope oldWidget) =>
      sosHoldProgress != oldWidget.sosHoldProgress;
}
