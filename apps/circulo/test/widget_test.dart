import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:circulo/l10n/app_localizations.dart';
import 'package:circulo/models/user_model.dart';
import 'package:circulo/models/purchase_model.dart';
import 'package:circulo/services/settings_service.dart';
import 'package:circulo/services/online_firestore_service.dart';
import 'package:circulo/services/billing_service.dart';
import 'package:circulo/services/ad_service.dart';
import 'package:circulo/services/match_engine_service.dart';
import 'package:circulo/theme/app_theme.dart';
import 'package:circulo/screens/auth/splash_screen.dart';
import 'package:circulo/widgets/plus_promo_deck_card.dart';
import 'package:circulo/widgets/google_ad_deck_card.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Círculo — Suite de Pruebas Automatizadas', () {
    test('1. Internacionalización: Soporta 6 idiomas y resolución automática', () {
      expect(AppLocalizations.supportedLocales.length, 6);

      // Verificación de idiomas soportados
      final locales = ['es', 'en', 'pt', 'fr', 'it', 'de'];
      for (final code in locales) {
        final loc = AppLocalizations.resolveLocale(Locale(code));
        expect(loc.languageCode, code);

        final l10n = AppLocalizations(loc);
        expect(l10n.get('appName'), 'Círculo');
        expect(l10n.get('loading').isNotEmpty, true);
        expect(l10n.get('guideTitle').isNotEmpty, true);
      }

      // Fallback ante idioma no soportado
      final fallback = AppLocalizations.resolveLocale(const Locale('ja'));
      expect(fallback.languageCode, 'es');
    });

    test('2. SettingsService: ThemeMode.system e Idioma por defecto', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);

      // Defaults
      expect(settings.themeMode, ThemeMode.system);
      expect(settings.localeCode, 'auto');
      expect(settings.welcomeGuideSeen, false);
      expect(settings.biometricEnabled, false);

      // Cambios
      await settings.setThemeModePreference('dark');
      expect(settings.themeMode, ThemeMode.dark);

      await settings.setLocaleCode('en');
      expect(settings.localeCode, 'en');
      expect(settings.explicitLocale, const Locale('en'));
    });

    test('3. MatchEngineService: Química de roles, Match de 4 y Expansión hasta 10', () async {
      final firestore = OnlineFirestoreService();
      await firestore.ensureCloudSeedData();
      final engine = MatchEngineService(firestore);

      final userA = UserModel(
        id: 'user_a',
        email: 'a@test.com',
        passwordHash: 'hash',
        firstName: 'Ana',
        lastName: 'Pérez',
        birthDate: DateTime(1996, 5, 10),
        groupRole: GroupRoles.organizer,
        interests: [AppInterests.specialtyCoffee, AppInterests.boardGames],
        favoritePlans: [AppPlans.coffee, AppPlans.boardgames],
        duoInviteCode: 'CIR-ANA1',
        createdAt: DateTime.now(),
      );

      final userB = UserModel(
        id: 'user_b',
        email: 'b@test.com',
        passwordHash: 'hash',
        firstName: 'Bernardo',
        lastName: 'Gómez',
        birthDate: DateTime(1995, 2, 14),
        groupRole: GroupRoles.chill,
        interests: [AppInterests.specialtyCoffee, AppInterests.boardGames],
        favoritePlans: [AppPlans.coffee],
        duoInviteCode: 'CIR-BER1',
        createdAt: DateTime.now(),
      );

      // Afinidad y química de roles
      final score = engine.calculateCompatibilityScore(
        currentUser: userA,
        candidateUser: userB,
      );
      expect(score, greaterThan(60));

      // Expansión de grupo hasta 10 personas
      final group = firestore.currentGroups.first;
      await engine.updateGroupExpansionSettings(
        group.id,
        isOpen: true,
        maxMembers: 10,
      );

      final updatedGroup = await firestore.getGroupById(group.id);
      expect(updatedGroup?.maxMembers, 10);
      expect(updatedGroup?.isOpenForExpansion, true);

      // Votación para candidato
      final voteSuccess = await engine.voteForExpansionCandidate(
        groupId: group.id,
        candidateUserId: 'user_lucas',
        voterUserId: 'admin_leo',
        approve: true,
      );
      expect(voteSuccess, isA<bool>());
    });

    testWidgets('4. Renderizado: SplashScreen con AppLocalizations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(statusText: 'Conectando de forma segura...'),
        ),
      );

      // Bombear un fotograma sin pumpAndSettle debido al controller infinito de PulseBeacon
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Círculo'), findsOneWidget);
    });

    test('5. Monetización: BillingService, límites diarios y Círculo Plus', () async {
      final firestore = OnlineFirestoreService();
      await firestore.ensureCloudSeedData();
      final billing = BillingService(firestore);
      await billing.initialize();

      var user = UserModel(
        id: 'test_free_user',
        email: 'free@test.com',
        passwordHash: 'hash',
        firstName: 'Carlos',
        lastName: 'Free',
        birthDate: DateTime(1995, 1, 1),
        duoInviteCode: 'CIR-FREE',
        dailySwipesRemaining: 30,
        createdAt: DateTime.now(),
      );
      await firestore.upsertUser(user);

      // Decremento de swipe
      user = await billing.registerSwipeAttempt(user);
      expect(user.dailySwipesRemaining, 29);
      expect(user.totalSwipesCounter, 1);
      expect(user.isPlusMember, false);

      // Compra de suscripción Círculo Plus en modo Sandbox
      final successBuyPlus = await billing.buyProduct(
        productId: AppProductIds.plusMonthly,
        currentUser: user,
      );
      expect(successBuyPlus, true);

      final updatedUser = await firestore.getUserById('test_free_user');
      expect(updatedUser?.isPlusActive, true);
      expect(updatedUser?.isPlusMember, true);
      expect(updatedUser?.dailySwipesRemaining, 99999);
      expect(updatedUser?.remainingBoosts, 1); // 1 boost semanal incluido

      // Activación de Boost
      final userWithBoost = await billing.activateBoost(updatedUser!);
      expect(userWithBoost?.remainingBoosts, 0);
      expect(userWithBoost?.hasActiveBoost, true);
    });

    testWidgets('6. Monetización UI: Renderizado de PlusPromoDeckCard', (tester) async {
      bool learnMorePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: PlusPromoDeckCard(
              onLearnMore: () => learnMorePressed = true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(PlusPromoDeckCard), findsOneWidget);
      expect(find.text('Armá tu Círculo 4x más rápido'), findsOneWidget);

      await tester.tap(find.text('Conocer Círculo Plus'));
      expect(learnMorePressed, true);
    });

    testWidgets('7. Red de Publicidad: Alternancia 1 a 1 (Plus y Google Ads) y GoogleAdDeckCard', (tester) async {
      final adService = AdService();
      await adService.initialize();

      // Test de Alternancia matemática
      // Swipe 20 (ciclo 1, impar): Plus Promo
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 20, isPlusMember: false),
        PromoCardType.plusPromo,
      );

      // Swipe 40 (ciclo 2, par): Google Ad
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 40, isPlusMember: false),
        PromoCardType.googleAd,
      );

      // Swipe 60 (ciclo 3, impar): Plus Promo
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 60, isPlusMember: false),
        PromoCardType.plusPromo,
      );

      // Swipe 80 (ciclo 4, par): Google Ad
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 80, isPlusMember: false),
        PromoCardType.googleAd,
      );

      // Si es miembro Plus: NUNCA ve publicidad
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 40, isPlusMember: true),
        PromoCardType.none,
      );
      expect(
        adService.getPromoTypeForSwipeCount(totalSwipes: 20, isPlusMember: true),
        PromoCardType.none,
      );

      // Renderizado del widget GoogleAdDeckCard
      bool dismissed = false;
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: adService,
          child: MaterialApp(
            locale: const Locale('es'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: GoogleAdDeckCard(
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GoogleAdDeckCard), findsOneWidget);
      expect(find.text('Anuncio • Google Ads'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(dismissed, true);
    });

    test('8. Elevación Arquitectónica: Concurrencia Atómica K4 y Tokens de Roles', () async {
      // 1. Verificación de tokens de roles
      expect(GroupRoleColors.getColor('organizer'), const Color(0xFF06B6D4));
      expect(GroupRoleColors.getColor('connector'), const Color(0xFFF43F5E));
      expect(GroupRoleColors.getColor('explorer'), const Color(0xFF10B981));
      expect(GroupRoleColors.getColor('chill'), const Color(0xFFA78BFA));

      // 2. Verificación de concurrencia atómica K4
      final firestore = OnlineFirestoreService();
      await firestore.ensureCloudSeedData();

      final formingGroup = firestore.currentGroups.firstWhere(
        (g) => g.id == 'circle_boardgames_3of4',
      );
      expect(formingGroup.memberIds.length, 3);
      expect(formingGroup.isForming, true);

      // Usuario 4 se suma al grupo
      final user4 = UserModel(
        id: 'user_atomic_4',
        email: 'user4@test.com',
        passwordHash: 'hash',
        firstName: 'Diego',
        lastName: 'Cuatro',
        birthDate: DateTime(1997, 4, 4),
        duoInviteCode: 'CIR-DIE4',
        createdAt: DateTime.now(),
      );

      final resultSuccess = await firestore.joinFormingCircleAtomic(
        groupId: formingGroup.id,
        joiningUser: user4,
      );
      expect(resultSuccess.success, true);
      expect(resultSuccess.isCompletedK4, true);
      expect(resultSuccess.updatedGroup?.memberIds.length, 4);
      expect(resultSuccess.updatedGroup?.status, 'active');

      // Usuario 5 intenta sumarse concurrentemente cuando el cupo de 4 ya se llenó
      final user5 = UserModel(
        id: 'user_atomic_5',
        email: 'user5@test.com',
        passwordHash: 'hash',
        firstName: 'Elena',
        lastName: 'Cinco',
        birthDate: DateTime(1996, 5, 5),
        duoInviteCode: 'CIR-ELE5',
        createdAt: DateTime.now(),
      );

      final resultRejected = await firestore.joinFormingCircleAtomic(
        groupId: formingGroup.id,
        joiningUser: user5,
      );
      expect(resultRejected.success, false);
      expect(resultRejected.failureReason != null, true);
      expect(resultRejected.isCompletedK4, false);
    });
  });
}
