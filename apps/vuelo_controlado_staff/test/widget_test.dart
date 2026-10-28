import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vuelo_controlado_staff/models/event_model.dart';
import 'package:vuelo_controlado_staff/models/user_model.dart';
import 'package:vuelo_controlado_staff/services/storage_service.dart';
import 'package:vuelo_controlado_staff/services/auth_service.dart';
import 'package:vuelo_controlado_staff/services/event_service.dart';
import 'package:vuelo_controlado_staff/services/case_service.dart';
import 'package:vuelo_controlado_staff/services/settings_service.dart';
import 'package:vuelo_controlado_staff/theme/app_theme.dart';
import 'package:vuelo_controlado_staff/screens/login_screen.dart';
import 'package:vuelo_controlado_staff/screens/home_screen.dart';
import 'package:vuelo_controlado_staff/screens/events/events_list_screen.dart';
import 'package:vuelo_controlado_staff/screens/events/create_event_screen.dart';
import 'package:vuelo_controlado_staff/screens/splash_screen.dart';
import 'package:vuelo_controlado_staff/screens/profile/profile_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  testWidgets('Login screen smoke test renders branding and fields in Deep Obsidian theme',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const LoginScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ErrorWidget), findsNothing);
    expect(find.text('PORTAL DE STAFF'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });

  testWidgets('EventsListScreen renders event cards with timing capsules and no ErrorWidgets',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final superAdmin = UserModel(
      id: 'superadmin_1',
      email: AppRoles.superAdminEmail,
      password: 'admin',
      firstName: 'Leo',
      lastName: 'Benveniste',
      documentType: 'DNI',
      documentNumber: '12345678',
      birthDate: DateTime(1990, 1, 1),
      phone: '1234',
      roles: AppRoles.allRoles,
      createdAt: DateTime.now(),
    );
    await storageService.saveUsers([superAdmin]);
    await storageService.saveSessionUser(superAdmin);

    final sampleEvent = EventModel(
      id: 'event_test_1',
      name: 'Festival Under Vuelo Controlado',
      date: DateTime.now(),
      startTime: '22:00',
      doorsOpenTime: '21:00',
      endTime: '06:00',
      location: 'Costanera Norte, CABA',
      staffIds: ['superadmin_1'],
      createdBy: 'superadmin_1',
      createdByName: 'Leo Benveniste',
      createdAt: DateTime.now(),
      isManuallyStarted: true,
    );
    await storageService.saveEvents([sampleEvent]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'AR')],
          home: const EventsListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Comprobar que no hay ningún ErrorWidget
    expect(find.byType(ErrorWidget), findsNothing);

    // Comprobar que se renderiza el título, el evento y las cápsulas de horarios
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Festival Under Vuelo Controlado'), findsOneWidget);
    expect(find.byTooltip('Crear Nuevo Evento'), findsOneWidget);
    expect(find.text('Próximos'), findsOneWidget);
    expect(find.text('Pasados'), findsOneWidget);
    expect(find.text('Puertas: '), findsNothing);
    expect(find.text('Inicio: '), findsWidgets);
    expect(find.text('22:00 hs'), findsWidgets);
    expect(find.text('Cierre: '), findsWidgets);
    expect(find.text('06:00 hs'), findsWidgets);
  });

  testWidgets('CreateEventScreen renders properly without crashes or overflow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final superAdmin = UserModel(
      id: 'superadmin_1',
      email: AppRoles.superAdminEmail,
      password: 'admin',
      firstName: 'Leo',
      lastName: 'Benveniste',
      documentType: 'DNI',
      documentNumber: '12345678',
      birthDate: DateTime(1990, 1, 1),
      phone: '1234',
      roles: AppRoles.allRoles,
      createdAt: DateTime.now(),
    );
    await storageService.saveUsers([superAdmin]);
    await storageService.saveSessionUser(superAdmin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'AR')],
          home: const CreateEventScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Comprobar ausencia de ErrorWidget
    expect(find.byType(ErrorWidget), findsNothing);

    // Comprobar elementos principales
    expect(find.text('Crear Nuevo Evento'), findsOneWidget);
    expect(find.text('Nombre del Evento *'), findsOneWidget);
    expect(find.text('Publicar'), findsOneWidget);
  });

  testWidgets('HomeScreen shell renders Menú Listo style header and navigation tabs',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final superAdmin = UserModel(
      id: 'superadmin_1',
      email: AppRoles.superAdminEmail,
      password: 'admin',
      firstName: 'Leo',
      lastName: 'Benveniste',
      documentType: 'DNI',
      documentNumber: '12345678',
      birthDate: DateTime(1990, 1, 1),
      phone: '1234',
      roles: AppRoles.allRoles,
      createdAt: DateTime.now(),
    );
    await storageService.saveUsers([superAdmin]);
    await storageService.saveSessionUser(superAdmin);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('es', 'AR')],
          home: const HomeScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Comprobar ausencia de errores
    expect(find.byType(ErrorWidget), findsNothing);

    // Comprobar que no hay badge de STAFF en el header
    expect(find.text('STAFF'), findsNothing);

    // Comprobar los 5 links de navegación:
    // Eventos, Casos, Perfil (Center Hero FAB), Ayuda, Ajustes
    expect(find.text('Eventos'), findsWidgets);
    expect(find.text('Casos'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.byTooltip('Mi Credencial y Perfil'), findsOneWidget);
  });

  testWidgets('SplashScreen renders centered logo and loading indicator in dark and light themes',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // Switch to light theme
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
  });

  testWidgets('ProfileScreen renders compact info without document number or phone',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final testUser = UserModel(
      id: 'user_test_profile',
      email: 'test@vuelocontrolado.org',
      password: 'password',
      firstName: 'Camila',
      lastName: 'Pérez',
      documentType: 'DNI',
      documentNumber: '44123987',
      birthDate: DateTime(1995, 5, 20),
      phone: '+5491122334455',
      roles: ['Staff'],
      createdAt: DateTime.now(),
    );
    await storageService.saveUsers([testUser]);
    await storageService.saveSessionUser(testUser);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService(storageService)),
          ChangeNotifierProvider(create: (_) => EventService(storageService)),
          ChangeNotifierProvider(create: (_) => CaseService(storageService)),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify name and email are present, while role tags and staff badges are removed
    expect(find.text('Camila Pérez'), findsOneWidget);
    expect(find.text('test@vuelocontrolado.org'), findsOneWidget);
    expect(find.text('Staff'), findsNothing);
    expect(find.text('STAFF OFICIAL'), findsNothing);
    expect(find.text('STAFF OFICIAL • VUELO CONTROLADO'), findsNothing);
    expect(find.text('IDENTIFICACIÓN DIGITAL DE VOLUNTARIADO'), findsNothing);
    expect(find.text('Editar Datos Personales'), findsNothing);

    // Verify document number and phone are NOT rendered in profile
    expect(find.textContaining('44123987'), findsNothing);
    expect(find.textContaining('+5491122334455'), findsNothing);

    // Verify both QR sections are rendered
    expect(find.text('MI INSTAGRAM'), findsOneWidget);
    expect(find.text('VUELO CONTROLADO'), findsOneWidget);
  });
}
