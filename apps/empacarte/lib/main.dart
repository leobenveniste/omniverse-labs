import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/guide/guide_controller.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'repositories/storage_repository.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final themeController = ThemeController();
  final localeController = LocaleController();
  final storageRepository = StorageRepository();
  final guideController = GuideController();

  await Future.wait([
    themeController.loadTheme(),
    localeController.loadLocale(),
    storageRepository.init(),
    guideController.init(),
  ]);

  runApp(
    EmpacArteApp(
      themeController: themeController,
      localeController: localeController,
      storageRepository: storageRepository,
      guideController: guideController,
    ),
  );
}

class EmpacArteApp extends StatelessWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final StorageRepository storageRepository;
  final GuideController guideController;

  const EmpacArteApp({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.storageRepository,
    required this.guideController,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([themeController, localeController, storageRepository, guideController]),
      builder: (context, _) {
        return MaterialApp(
          title: 'EmpacArte',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeController.themeMode,
          locale: localeController.isAutoDetect ? null : localeController.currentLocale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SplashScreen(
            storage: storageRepository,
            themeController: themeController,
            localeController: localeController,
            guideController: guideController,
          ),
        );
      },
    );
  }
}
