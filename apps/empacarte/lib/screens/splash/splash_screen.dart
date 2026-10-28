import 'package:flutter/material.dart';
import '../../core/guide/guide_controller.dart';
import '../../core/localization/locale_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';
import '../../repositories/storage_repository.dart';
import '../home_navigation_screen.dart';
import '../onboarding/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  final StorageRepository storage;
  final ThemeController themeController;
  final LocaleController localeController;
  final GuideController guideController;

  const SplashScreen({
    super.key,
    required this.storage,
    required this.themeController,
    required this.localeController,
    required this.guideController,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // After animation, navigate smoothly
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      final isConfigured = widget.storage.profile.isConfigured;
      final targetScreen = isConfigured
          ? HomeNavigationScreen(
              storage: widget.storage,
              themeController: widget.themeController,
              localeController: widget.localeController,
              guideController: widget.guideController,
            )
          : ProfileSetupScreen(
              storage: widget.storage,
              onProfileComplete: () {
                Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    pageBuilder: (context, animation, secondaryAnimation) => HomeNavigationScreen(
                      storage: widget.storage,
                      themeController: widget.themeController,
                      localeController: widget.localeController,
                      guideController: widget.guideController,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ),
                );
              },
            );

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.burgundyDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Luxury Textured Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0xFF7A2036), // Vibrant rich burgundy center
                  Color(0xFF4A0E1C), // Deep burgundy mid
                  Color(0xFF2B0810), // Midnight burgundy edge
                ],
              ),
            ),
          ),

          // Vintage Compass / Cartographic Filigree Overlay
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Icon(
                Icons.explore_rounded,
                size: 380,
                color: AppColors.goldFoil,
              ),
            ),
          ),

          // Centered Animated Logo & Typography
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo standalone with transparent corners and smooth squircle clip
                    ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        'assets/images/app_icon_splash.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title with Gold Foil Gradient
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          AppColors.goldFoilLight,
                          AppColors.goldFoil,
                          Color(0xFFE5C158),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'EmpacArte',
                        style: AppTypography.displaySerif(color: Colors.white).copyWith(
                          fontSize: 34,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'EL ARTE DE VIAJAR Y EMPACAR',
                      style: AppTypography.monoCaption(
                        color: AppColors.goldFoilLight.withValues(alpha: 0.8),
                        medium: true,
                      ).copyWith(letterSpacing: 3, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Offline & Luxury Guarantee
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 14,
                      color: AppColors.goldFoil.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '100% OFFLINE & PRIVADO • OMNIVERSE LABS',
                      style: AppTypography.caption(
                        color: AppColors.goldFoil.withValues(alpha: 0.6),
                        medium: true,
                      ).copyWith(fontSize: 10, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
