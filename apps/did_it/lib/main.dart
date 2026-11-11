import 'package:flutter/material.dart';

import 'screens/home_shell_screen.dart';
import 'screens/splash_screen.dart';
import 'services/did_it_controller.dart';
import 'services/did_it_scheduler.dart';
import 'services/did_it_storage.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DidItBootstrap());
}

Future<DidItController> _defaultBootstrapLoader() async {
  final storage = await DidItStorage.open();
  final scheduler = LocalDidItScheduler();
  final controller = DidItController(
    storage: storage,
    scheduler: scheduler,
  );
  await controller.initialize();
  return controller;
}

/// Real async application bootstrap showing SplashScreen only while local persistence loads.
class DidItBootstrap extends StatefulWidget {
  const DidItBootstrap({
    super.key,
    this.loader,
  });

  final Future<DidItController> Function()? loader;

  @override
  State<DidItBootstrap> createState() => _DidItBootstrapState();
}

class _DidItBootstrapState extends State<DidItBootstrap> {
  DidItController? _controller;
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
        title: 'DidIt',
        debugShowCheckedModeBanner: false,
        theme: buildDidItTheme(Brightness.light),
        darkTheme: buildDidItTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
      );
    }
    return DidItApp(controller: controller);
  }
}

class DidItApp extends StatelessWidget {
  const DidItApp({
    super.key,
    required this.controller,
  });

  final DidItController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'DidIt',
          debugShowCheckedModeBanner: false,
          theme: buildDidItTheme(Brightness.light),
          darkTheme: buildDidItTheme(Brightness.dark),
          themeMode: controller.themeMode,
          home: HomeShellScreen(controller: controller),
        );
      },
    );
  }
}
