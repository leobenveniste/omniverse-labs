import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/stage_console_screen.dart';
import 'services/haptic_driver.dart';
import 'services/pulse_controller.dart';
import 'services/pulse_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PulsePocketBootstrap());
}

Future<PulseController> _defaultBootstrapLoader() async {
  final storage = await PulseStorage.open();
  final controller = PulseController(
    storage: storage,
    hapticDriver: PlatformHapticDriver(),
  );
  await controller.initialize();
  return controller;
}

/// Real async application bootstrap showing SplashScreen only until local storage finishes loading.
class PulsePocketBootstrap extends StatefulWidget {
  const PulsePocketBootstrap({
    super.key,
    this.loader,
  });

  final Future<PulseController> Function()? loader;

  @override
  State<PulsePocketBootstrap> createState() => _PulsePocketBootstrapState();
}

class _PulsePocketBootstrapState extends State<PulsePocketBootstrap> {
  PulseController? _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = await (widget.loader ?? _defaultBootstrapLoader)();
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _ownsController = true;
    });
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return MaterialApp(
        title: 'PulsePocket',
        debugShowCheckedModeBanner: false,
        theme: buildPulsePocketTheme(Brightness.light),
        darkTheme: buildPulsePocketTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      );
    }
    return PulsePocketApp(controller: controller);
  }
}

class PulsePocketApp extends StatelessWidget {
  const PulsePocketApp({
    super.key,
    required this.controller,
  });

  final PulseController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: controller.strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildPulsePocketTheme(Brightness.light),
          darkTheme: buildPulsePocketTheme(Brightness.dark),
          themeMode: controller.themeMode,
          home: StageConsoleScreen(controller: controller),
        );
      },
    );
  }
}
