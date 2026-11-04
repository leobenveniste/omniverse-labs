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
import 'package:vuelo_controlado_staff/screens/settings/settings_screen.dart';
import 'package:vuelo_controlado_staff/screens/events/event_detail_screen.dart';

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
    // Eventos, Casos, Perfil (Center Hero FAB), Vuelos, Recursos
    expect(find.text('Eventos'), findsWidgets);
    expect(find.text('Casos'), findsOneWidget);
    expect(find.text('Vuelos'), findsOneWidget);
    expect(find.text('Recursos'), findsOneWidget);
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

  group('InstagramUtils Tests', () {
    test('cleanHandle sanitizes various Instagram input formats', () {
      expect(InstagramUtils.cleanHandle('@juan_perez'), equals('juan_perez'));
      expect(InstagramUtils.cleanHandle('  @maria.staff  '), equals('maria.staff'));
      expect(InstagramUtils.cleanHandle('pedro_staff'), equals('pedro_staff'));
      expect(InstagramUtils.cleanHandle('https://www.instagram.com/lucas_vc/'),
          equals('lucas_vc'));
      expect(InstagramUtils.cleanHandle('https://instagram.com/lucas_vc?igsh=xyz'),
          equals('lucas_vc'));
      expect(InstagramUtils.cleanHandle(''), equals(''));
      expect(InstagramUtils.cleanHandle(null), equals(''));
    });

    test('buildProfileUrl generates canonical URLs', () {
      expect(InstagramUtils.buildProfileUrl('lucas_vc'),
          equals('https://www.instagram.com/lucas_vc/'));
      expect(InstagramUtils.buildProfileUrl(''), equals(''));
      expect(InstagramUtils.vueloControladoUrl,
          equals('https://www.instagram.com/vuelocontrolado/'));
      expect(InstagramUtils.vueloControladoHandle, equals('@vuelocontrolado'));
    });
  });

  testWidgets(
      'ProfileScreen renders personal QR when instagram is configured and opens zoom dialog',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final testUser = UserModel(
      id: 'user_with_ig',
      email: 'staff@vuelocontrolado.org',
      password: 'password',
      firstName: 'Marcos',
      lastName: 'Gómez',
      documentType: 'DNI',
      documentNumber: '38123456',
      birthDate: DateTime(1996, 3, 15),
      phone: '+5491133445566',
      instagram: '@marcos_staff',
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

    expect(find.text('@marcos_staff'), findsOneWidget);
    expect(find.text('@vuelocontrolado'), findsOneWidget);
    expect(find.text('Sin configurar'), findsNothing);

    // Tap on personal QR card to open fullscreen zoom dialog
    await tester.tap(find.text('MI INSTAGRAM'));
    await tester.pumpAndSettle();

    // Verify dialog is opened with title and handle
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('@marcos_staff'), findsNWidgets(2));

    // Close dialog
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets(
      'ProfileScreen shows unconfigured state when user has no instagram',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final testUser = UserModel(
      id: 'user_without_ig',
      email: 'sin_ig@vuelocontrolado.org',
      password: 'password',
      firstName: 'Lucía',
      lastName: 'Fernández',
      documentType: 'DNI',
      documentNumber: '39123456',
      birthDate: DateTime(1997, 8, 10),
      phone: '+5491199887766',
      instagram: null,
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

    expect(find.text('Sin configurar'), findsOneWidget);
    expect(find.text('@sin_configurar'), findsOneWidget);
    expect(find.text('@vuelocontrolado'), findsOneWidget);

    // Tapping unconfigured card triggers snackbar
    await tester.tap(find.text('MI INSTAGRAM'));
    await tester.pump();

    expect(
      find.text('Configura tu usuario de Instagram en Ajustes > Mi Perfil'),
      findsOneWidget,
    );
  });

  group('DonationUtils Tests', () {
    test('donationUrl and shareMessage point to official DonarOnline campaign', () {
      expect(
        DonationUtils.donationUrl,
        equals(
          'https://donaronline.org/fundacion-vuelo-controlado/comunidad-de-vuelo-la-fiesta-la-cuidamos-entre-todos',
        ),
      );
      expect(
        DonationUtils.shareMessage,
        contains(
          'https://donaronline.org/fundacion-vuelo-controlado/comunidad-de-vuelo-la-fiesta-la-cuidamos-entre-todos',
        ),
      );
      expect(
        DonationUtils.shareMessage,
        contains('La fiesta la cuidamos entre todos'),
      );
    });
  });

  testWidgets(
      'ProfileScreen renders donation card with QR and share button and no direct donate button',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);

    final testUser = UserModel(
      id: 'user_donor_test',
      email: 'donor@vuelocontrolado.org',
      password: 'password',
      firstName: 'Sofía',
      lastName: 'Romero',
      documentType: 'DNI',
      documentNumber: '40123456',
      birthDate: DateTime(1998, 4, 12),
      phone: '+5491144556677',
      instagram: 'sofi_vc',
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

    // Verify donation action buttons (no card header/title/description)
    expect(find.text('Mostrar QR Donación'), findsOneWidget);
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Comunidad de Donantes'), findsNothing);
    expect(find.text('La fiesta la cuidamos entre todos'), findsNothing);

    // Verify NO direct donate button is rendered
    expect(find.text('Donar ahora'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Donar'), findsNothing);

    // Tap "Mostrar QR Donación" to open the fullscreen QR dialog
    await tester.ensureVisible(find.text('Mostrar QR Donación'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar QR Donación'));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('DONAR A VUELO'), findsOneWidget);
    expect(find.text('DonarOnline • Comunidad de Vuelo'), findsOneWidget);
    expect(find.text('Compartir Enlace'), findsOneWidget);

    // Close dialog
    await tester.tap(find.byTooltip('Cerrar'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('SettingsScreen renders unified list without category section headers',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storageService = StorageService(prefs);
    final settingsService = SettingsService(prefs);
    final authService = AuthService(storageService);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authService),
          ChangeNotifierProvider.value(value: settingsService),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ErrorWidget), findsNothing);

    // Verify category headers are removed
    expect(find.text('PREFERENCIAS'), findsNothing);
    expect(find.text('CUENTA'), findsNothing);
    expect(find.text('DATOS Y SINCRONIZACIÓN'), findsNothing);
    expect(find.text('SESIÓN'), findsNothing);

    // Verify all setting items exist in the single unified list
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Cambiar Contraseña'), findsOneWidget);
    expect(find.text('Sincronizar Datos en la Nube'), findsOneWidget);
    expect(find.text('Cerrar Sesión'), findsOneWidget);
  });

  testWidgets('EventDetailScreen renders horizontal participation banner cleanly without vertical deformation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    final auth = AuthService(storage);
    final eventService = EventService(storage);
    final caseService = CaseService(storage);
    final settings = SettingsService(prefs);

    final user = UserModel(
      id: 'staff_1',
      firstName: 'Leo',
      lastName: 'Ben',
      email: 'leobenveniste@vuelocontrolado.org',
      phone: '1122334455',
      documentType: 'DNI',
      documentNumber: '12345678',
      birthDate: DateTime(1990, 1, 1),
      password: 'pass',
      roles: [AppRoles.miembro],
      createdAt: DateTime.now(),
    );
    await storage.saveUsers([user]);
    auth.reloadUsersFromStorage();
    await auth.login('leobenveniste@vuelocontrolado.org', 'pass');

    await eventService.createEvent(
      name: 'Festival Test',
      location: 'Complejo Costanera',
      date: DateTime.now().add(const Duration(days: 2)),
      doorsOpenTime: '21:00',
      startTime: '22:00',
      endTime: '06:00',
      currentUser: user,
    );
    final eventId = eventService.events.first.id;
    await eventService.joinEvent(eventId, 'staff_1');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: eventService),
          ChangeNotifierProvider.value(value: caseService),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: EventDetailScreen(eventId: eventId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ErrorWidget), findsNothing);

    // Verify banner title and subtitle for registered (pending) user
    expect(find.text('Estás anotado'), findsOneWidget);
    expect(find.text('Pendiente de confirmación por Organización'), findsOneWidget);
    expect(find.text('Bajarse'), findsOneWidget);

    // Verify text renders with adequate horizontal width and is not squished
    final titleSize = tester.getSize(find.text('Estás anotado'));
    debugPrint('TITLE SIZE: $titleSize');
    expect(titleSize.width, greaterThan(80));

    // Verify Bajarse button renders properly
    final buttonSize = tester.getSize(find.text('Bajarse'));
    debugPrint('BUTTON SIZE: $buttonSize');
    expect(buttonSize.width, greaterThan(30));
  });
}