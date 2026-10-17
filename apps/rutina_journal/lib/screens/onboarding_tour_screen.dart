import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/haptics_helper.dart';
import 'main_navigation_screen.dart';

class OnboardingTourScreen extends StatefulWidget {
  final bool isReplay;

  const OnboardingTourScreen({super.key, this.isReplay = false});

  static Future<void> show(BuildContext context) {
    HapticsHelper.selection();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const OnboardingTourScreen(isReplay: true),
      ),
    );
  }

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeTour() async {
    HapticsHelper.medium();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    if (widget.isReplay) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
            opacity: animation,
            child: const MainNavigationScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSpanish = l10n.locale.languageCode == 'es';

    final slides = [
      _TourSlide(
        emoji: '🌿',
        title: isSpanish ? 'Construye Hábitos Positivos' : 'Build Positive Habits',
        description: isSpanish
            ? 'Monitorea hábitos diarios con deslizamiento suave, rachas motivadoras y recordatorios sin fricción.'
            : 'Track daily habits with smooth swipe gestures, motivating streaks, and friction-free reminders.',
        badges: isSpanish
            ? ['Desliza para completar', 'Rachas diarias', 'Meta numérica o simple']
            : ['Swipe to complete', 'Daily streaks', 'Counter or simple goal'],
        color: theme.colorScheme.primary,
      ),
      _TourSlide(
        emoji: '⚡',
        title: isSpanish ? 'Rutinas Guiadas y Rituales' : 'Guided Routines & Rituals',
        description: isSpanish
            ? 'Crea bloques de tiempo estructurados para tu mañana, jornada de trabajo y desconexión nocturna paso a paso.'
            : 'Create structured time blocks for your morning, deep work sessions, and evening wind-down.',
        badges: isSpanish
            ? ['Rituales matutinos', 'Foco profundo', 'Pausa activa']
            : ['Morning rituals', 'Deep focus', 'Active reset'],
        color: const Color(0xFFC85A3B),
      ),
      _TourSlide(
        emoji: '📖',
        title: isSpanish ? 'Micro-Diario & Reflexión' : 'Micro-Journal & Reflection',
        description: isSpanish
            ? 'Registra tu estado de ánimo, reflexiones rápidas y agradecimientos del día en segundos.'
            : 'Log your mood, quick reflections, and daily gratitude in seconds with zero clutter.',
        badges: isSpanish
            ? ['Estado de ánimo', 'Gratitud diaria', 'Notas rápidas']
            : ['Mood tracking', 'Daily gratitude', 'Quick notes'],
        color: const Color(0xFF4A6B82),
      ),
      _TourSlide(
        emoji: '🔒',
        title: isSpanish ? '100% Offline y Privado' : '100% Offline & Private',
        description: isSpanish
            ? 'Tus datos son completamente tuyos. Sin anuncios, sin servidores externos, sin suscripciones mensuales.'
            : 'Your data stays strictly with you. No ads, no cloud tracking, and no recurring monthly traps.',
        badges: isSpanish
            ? ['Pago único', 'Widgets de pantalla', 'Copia JSON offline']
            : ['One-time unlock', 'Home screen widgets', 'Offline JSON backup'],
        color: const Color(0xFF2E7D32),
      ),
    ];

    final isLastPage = _currentPage == slides.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/app_logo.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.spa_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Ritmo',
                        style: AppTypography.title(theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: _completeTour,
                      child: Text(
                        isSpanish ? 'Saltar' : 'Skip',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: slides.length,
                onPageChanged: (i) {
                  HapticsHelper.selection();
                  setState(() => _currentPage = i);
                },
                itemBuilder: (context, index) {
                  final s = slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Giant Animated Emoji Card
                        Container(
                          width: 130,
                          height: 130,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: s.color.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: Text(s.emoji, style: const TextStyle(fontSize: 64)),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Title
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: AppTypography.display(theme.colorScheme.onSurface).copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Description
                        Text(
                          s.description,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            theme.colorScheme.onSurfaceVariant,
                          ).copyWith(
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Pill Badges
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: s.badges.map((b) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                border: Border.all(
                                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                b,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
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

            // Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(slides.length, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Bottom Action CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  onPressed: () {
                    HapticsHelper.selection();
                    if (isLastPage) {
                      _completeTour();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    isLastPage
                        ? (isSpanish ? '¡Comenzar con Ritmo!' : 'Get Started with Ritmo!')
                        : (isSpanish ? 'Siguiente' : 'Next'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _TourSlide {
  final String emoji;
  final String title;
  final String description;
  final List<String> badges;
  final Color color;

  const _TourSlide({
    required this.emoji,
    required this.title,
    required this.description,
    required this.badges,
    required this.color,
  });
}
