import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/vault_home_screen.dart';
import 'services/alert_scheduler.dart';
import 'services/vault_controller.dart';
import 'services/vault_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CancelGuardBootstrap());
}

/// Renders [SplashScreen] immediately while real storage & scheduler initialization completes.
class CancelGuardBootstrap extends StatefulWidget {
  const CancelGuardBootstrap({
    super.key,
    this.loader,
  });

  final Future<VaultController> Function()? loader;

  @override
  State<CancelGuardBootstrap> createState() => _CancelGuardBootstrapState();
}

class _CancelGuardBootstrapState extends State<CancelGuardBootstrap> {
  VaultController? _controller;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = widget.loader != null
        ? await widget.loader!()
        : await _defaultLoad();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  static Future<VaultController> _defaultLoad() async {
    final storage = await VaultStorage.open();
    final controller = VaultController(
      storage: storage,
      scheduler: LocalAlertScheduler(),
    );
    await controller.initialize();
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return MaterialApp(
        title: 'CancelGuard',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.dark,
        theme: buildCancelGuardTheme(Brightness.light),
        darkTheme: buildCancelGuardTheme(Brightness.dark),
        home: const SplashScreen(),
      );
    }
    return CancelGuardApp(controller: controller);
  }
}

/// Root offline-first application widget for CancelGuard.
class CancelGuardApp extends StatelessWidget {
  const CancelGuardApp({
    super.key,
    required this.controller,
  });

  final VaultController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'CancelGuard',
          debugShowCheckedModeBanner: false,
          themeMode: controller.themeMode,
          theme: buildCancelGuardTheme(Brightness.light),
          darkTheme: buildCancelGuardTheme(Brightness.dark),
          home: VaultHomeScreen(controller: controller),
        );
      },
    );
  }
}
