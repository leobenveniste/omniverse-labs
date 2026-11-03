import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../services/settings_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_header.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class WelcomeGuideScreen extends StatefulWidget {
  final bool isModal;

  const WelcomeGuideScreen({super.key, this.isModal = false});

  @override
  State<WelcomeGuideScreen> createState() => _WelcomeGuideScreenState();
}

class _WelcomeGuideScreenState extends State<WelcomeGuideScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() async {
    HapticFeedback.mediumImpact();
    final settings = context.read<SettingsService>();
    await settings.markWelcomeGuideSeen();
    if (mounted) {
      if (widget.isModal) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsService>();
    final primary = AppTheme.primaryColor(context);
    final textPrimary = AppTheme.textPrimaryColor(context);
    final textSecondary = AppTheme.textSecondaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slides = [
      _GuideSlideData(
        icon: Icons.groups_rounded,
        title: l10n.get('guideSlide1Title'),
        body: l10n.get('guideSlide1Body'),
        accentColor: primary,
      ),
      _GuideSlideData(
        icon: Icons.people_outline_rounded,
        title: l10n.get('guideSlide2Title'),
        body: l10n.get('guideSlide2Body'),
        accentColor: AppTheme.vibrantCoral,
      ),
      _GuideSlideData(
        icon: Icons.psychology_rounded,
        title: l10n.get('guideSlide3Title'),
        body: l10n.get('guideSlide3Body'),
        accentColor: AppTheme.warmAmber,
      ),
      _GuideSlideData(
        icon: Icons.verified_rounded,
        title: l10n.get('guideSlide4Title'),
        body: l10n.get('guideSlide4Body'),
        accentColor: AppTheme.emeraldMint,
      ),
      _GuideSlideData(
        icon: Icons.lock_open_rounded,
        title: l10n.get('guideSlide5Title'),
        body: l10n.get('guideSlide5Body'),
        accentColor: isDark ? AppTheme.violetLight : AppTheme.deepViolet,
      ),
    ];

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior: Selectores rápidos de Idioma y Tema
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const CirculoLogoIcon(size: 22),
                        const SizedBox(width: 8),
                        Text(
                          l10n.get('appName'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Selector Idioma Rápido
                        PopupMenuButton<String>(
                          tooltip: 'Cambiar idioma',
                          initialValue: settings.localeCode,
                          onSelected: (code) => settings.setLocaleCode(code),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: AppTheme.borderColor(context)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.language_rounded, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  settings.localeCode.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(
                                value: 'auto',
                                child: Text('🌐 Automático (Sistema)')),
                            const PopupMenuItem(
                                value: 'es', child: Text('🇪🇸 Español')),
                            const PopupMenuItem(
                                value: 'en', child: Text('🇺🇸 English')),
                            const PopupMenuItem(
                                value: 'pt', child: Text('🇧🇷 Português')),
                            const PopupMenuItem(
                                value: 'fr', child: Text('🇫🇷 Français')),
                            const PopupMenuItem(
                                value: 'it', child: Text('🇮🇹 Italiano')),
                            const PopupMenuItem(
                                value: 'de', child: Text('🇩🇪 Deutsch')),
                          ],
                        ),
                        const SizedBox(width: 8),

                        // Selector Tema Rápido
                        IconButton(
                          tooltip: 'Alternar Tema',
                          style: AppTheme.headerIconButtonStyle(context),
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                            size: 20,
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            settings.setThemeModePreference(
                                isDark ? 'light' : 'dark');
                          },
                        ),

                        if (widget.isModal)
                          IconButton(
                            tooltip: l10n.get('cancel'),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // PageView de los 5 slides
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, index) {
                    final slide = slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slide.accentColor.withValues(alpha: 0.16),
                              border: Border.all(
                                color: slide.accentColor.withValues(alpha: 0.4),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              slide.icon,
                              size: 48,
                              color: slide.accentColor,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicador de Puntos
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(slides.length, (index) {
                  final isSelected = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isSelected ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary
                          : AppTheme.borderColor(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Botón inferior
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    if (_currentPage < slides.length - 1) ...[
                      TextButton(
                        onPressed: _onFinish,
                        child: Text(
                          l10n.get('guideSkip'),
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: AppTheme.onPrimaryColor(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          l10n.get('continueBtn'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: LoadingPrimaryButton(
                          label: l10n.get('guideStart'),
                          onPressed: _onFinish,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSlideData {
  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;

  _GuideSlideData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });
}
