import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app_shell.dart';
import '../../../core/localization/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);

    final slides = [
      _OnboardingSlide(
        emoji: '🗓️',
        title: strings.isSpanish ? 'Planifica tu Menú Semanal' : 'Plan Your Weekly Meals',
        description: strings.isSpanish
            ? 'Organiza tus comidas de la semana en segundos. Ahorra tiempo y dinero con una lista de compras inteligente y porciones automáticas.'
            : 'Organize your weekly meals in seconds. Save time and money with smart groceries and portion scaling.',
        badges: strings.isSpanish
            ? ['Calendario semanal', 'Lista de compras', 'Porciones inteligentes']
            : ['Weekly calendar', 'Smart grocery list', 'Dynamic portions'],
        color: theme.colorScheme.primary,
      ),
      _OnboardingSlide(
        emoji: '🖐️',
        title: strings.isSpanish ? 'Modo Cocina Manos Libres' : 'Hands-Free Cook Mode',
        description: strings.isSpanish
            ? 'Cocina cómodo sin manchar la pantalla. Pasa la mano frente a la cámara para avanzar o retroceder los pasos mientras cocinas.'
            : 'Cook comfortably without dirtying your screen. Wave your hand in front of the camera to navigate recipe steps.',
        badges: strings.isSpanish
            ? ['Sensor por gestos', 'Temporizador automático', 'Ingredientes a la vista']
            : ['Gesture control', 'Auto timer', 'Ingredients in view'],
        color: const Color(0xFF2E7D32),
      ),
      _OnboardingSlide(
        emoji: '🍳',
        title: strings.isSpanish ? '100% Privado y Offline' : '100% Private & Offline',
        description: strings.isSpanish
            ? 'Tus recetas son tuyas. Sin anuncios, sin pagos mensuales y funciona completamente sin conexión a internet.'
            : 'Your recipes stay with you. No ads, no monthly subscriptions, and works 100% offline.',
        badges: strings.isSpanish
            ? ['Pago único', 'Buscador de heladera', 'Escáner OCR & Web']
            : ['One-time purchase', 'Pantry matcher', 'OCR & Web import'],
        color: const Color(0xFFD84315),
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('✨', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Menú Listo',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: Text(
                        strings.isSpanish ? 'Saltar' : 'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Slide PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 12, 28, 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large Graphic Bubble
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slide.color.withValues(alpha: 0.12),
                            border: Border.all(color: slide.color.withValues(alpha: 0.3), width: 2),
                          ),
                          child: Center(
                            child: Text(slide.emoji, style: const TextStyle(fontSize: 68)),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Description
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Feature Badges
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: slide.badges.map((b) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.15)),
                              ),
                              child: Text(
                                '✓ $b',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Dots & Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  // Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(slides.length, (idx) {
                      final isSelected = _currentPage == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: isSelected ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        if (isLastPage) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isLastPage
                                ? (strings.isSpanish ? '¡Comenzar a Cocinar!' : 'Start Cooking!')
                                : (strings.isSpanish ? 'Siguiente' : 'Next'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Icon(isLastPage ? Icons.restaurant_menu_rounded : Icons.arrow_forward_rounded, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  final String emoji;
  final String title;
  final String description;
  final List<String> badges;
  final Color color;

  const _OnboardingSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.badges,
    required this.color,
  });
}
