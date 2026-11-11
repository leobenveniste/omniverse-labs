import 'package:flutter/material.dart';

import 'screens/sound_console_screen.dart';
import 'screens/splash_screen.dart';
import 'services/audio_meter_driver.dart';
import 'services/loud_controller.dart';
import 'services/loud_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LoudGuardBootstrap());
}

Future<LoudController> _defaultBootstrapLoader() async {
  final storage = await LoudStorage.open();
  final controller = LoudController(
    storage: storage,
    driver: NativeAudioMeterDriver(),
  );
  await controller.initialize();
  return controller;
}

/// Real async application bootstrap showing SplashScreen only until local storage finishes loading.
class LoudGuardBootstrap extends StatefulWidget {
  const LoudGuardBootstrap({
    super.key,
    this.loader,
  });

  final Future<LoudController> Function()? loader;

  @override
  State<LoudGuardBootstrap> createState() => _LoudGuardBootstrapState();
}

class _LoudGuardBootstrapState extends State<LoudGuardBootstrap> {
  LoudController? _controller;
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
        title: 'LoudGuard',
        debugShowCheckedModeBanner: false,
        theme: buildLoudGuardTheme(Brightness.light),
        darkTheme: buildLoudGuardTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      );
    }
    return LoudGuardApp(controller: controller);
  }
}

class LoudGuardApp extends StatelessWidget {
  const LoudGuardApp({
    super.key,
    required this.controller,
  });

  final LoudController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: controller.strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: buildLoudGuardTheme(Brightness.light),
          darkTheme: buildLoudGuardTheme(Brightness.dark),
          themeMode: controller.themeMode,
          home: SoundConsoleScreen(controller: controller),
        );
      },
    );
  }
}
