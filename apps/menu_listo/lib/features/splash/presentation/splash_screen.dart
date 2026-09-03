import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_shell.dart';
import '../../../core/database/app_database.dart';
import '../../../core/localization/app_localizations.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );

    _animController.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();

    // 1. Preload database and check data
    await AppDatabase.instance.seedInitialDataIfEmpty();

    // 2. Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    // 3. Guarantee minimum smooth display duration (1400ms)
    final elapsed = DateTime.now().difference(startTime);
    const minSplashDuration = Duration(milliseconds: 1400);
    if (elapsed < minSplashDuration) {
      await Future.delayed(minSplashDuration - elapsed);
    }

    if (!mounted) return;

    // 4. Smooth fade transition to the target destination
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) {
          return hasSeenOnboarding
              ? const AppShell()
              : const OnboardingScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Centered Animated Logo, Title and Loader
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Logo Card with subtle drop shadow
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Brand App Name
                      Text(
                        'Menú Listo',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle / Tagline
                      Text(
                        strings.isSpanish
                            ? 'Tu Asistente Culinario & Planificador'
                            : 'Your Culinary Assistant & Meal Planner',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Refined Brand Loader
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Brand Attribution
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'OMNIVERSE LABS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
