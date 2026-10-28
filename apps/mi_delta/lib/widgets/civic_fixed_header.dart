import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/config/municipality_config.dart';
import '../core/navigation/app_shell_scope.dart';
import '../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import '../features/beneficios/credencial_screen.dart';
import '../features/emergency/emergency_sheet.dart';
import '../features/profile/profile_screen.dart';
import 'municipality_logo.dart';

class CivicFixedHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onCredencialTap;
  final VoidCallback? onSosTap;
  final VoidCallback? onSosLongPressStart;
  final VoidCallback? onSosLongPressEnd;
  final double? sosHoldProgress;
  final bool? showBackButton;
  final bool showActions;
  final VoidCallback? onBack;

  const CivicFixedHeader({
    super.key,
    this.title = MunicipalityConfig.appName,
    this.onAvatarTap,
    this.onCredencialTap,
    this.onSosTap,
    this.onSosLongPressStart,
    this.onSosLongPressEnd,
    this.sosHoldProgress,
    this.showBackButton,
    this.showActions = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final canPop = showBackButton == true || (showBackButton == null && Navigator.canPop(context));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = AppShellScope.maybeOf(context);

    final effectiveSosHoldProgress = sosHoldProgress ?? scope?.sosHoldProgress ?? 0.0;

    void handleAvatarTap() {
      HapticFeedback.selectionClick();
      if (onAvatarTap != null) {
        onAvatarTap!();
      } else if (scope != null) {
        scope.onOpenProfile();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    }

    void handleCredencialTap() {
      HapticFeedback.selectionClick();
      if (onCredencialTap != null) {
        onCredencialTap!();
      } else if (scope != null) {
        scope.onOpenCredencial();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CredencialScreen()),
        );
      }
    }

    void handleSosTap() {
      HapticFeedback.heavyImpact();
      if (onSosTap != null) {
        onSosTap!();
      } else if (scope != null) {
        scope.onSosTap();
      } else {
        EmergencySheet.show(context);
      }
    }

    void handleSosLongPressStart() {
      if (onSosLongPressStart != null) {
        onSosLongPressStart!();
      } else if (scope != null) {
        scope.onSosLongPressStart();
      }
    }

    void handleSosLongPressEnd() {
      if (onSosLongPressEnd != null) {
        onSosLongPressEnd!();
      } else if (scope != null) {
        scope.onSosLongPressEnd();
      }
    }

    return AppBar(
      toolbarHeight: 64,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: isDark ? AppColors.darkCardBorder : AppColors.cardBorder,
          height: 1,
        ),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          if (canPop) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? AppColors.darkPrimary : AppColors.primary, size: 22),
              onPressed: () {
                HapticFeedback.selectionClick();
                if (onBack != null) {
                  onBack!();
                } else {
                  Navigator.maybePop(context);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              tooltip: 'Volver',
            ),
            const SizedBox(width: 4),
          ],
          const MunicipalityLogo(size: 32),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  MunicipalityConfig.shortName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkSecondary : AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkOnSurface : AppColors.primary,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: showActions
          ? [
              // 1. SOS Button in Header (with tap and hold)
              Center(
                child: Semantics(
                  button: true,
                  label: 'Alerta SOS Emergencias',
                  child: Tooltip(
                    message: 'Emergencias SOS (Mantené presionado)',
                    child: GestureDetector(
                      onTap: handleSosTap,
                      onLongPressStart: (_) => handleSosLongPressStart(),
                      onLongPressEnd: (_) => handleSosLongPressEnd(),
                      onLongPressCancel: () => handleSosLongPressEnd(),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (effectiveSosHoldProgress > 0)
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: effectiveSosHoldProgress,
                                strokeWidth: 3,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.emergency,
                                  AppColors.emergencyLight,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emergency.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                effectiveSosHoldProgress > 0
                                    ? '${(3 - effectiveSosHoldProgress * 3).ceil()}s'
                                    : 'SOS',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 2. Credencial Digital Button in Header
              Center(
                child: Semantics(
                  button: true,
                  label: 'Credencial Digital Soy Delta',
                  child: Tooltip(
                    message: 'Credencial Digital',
                    child: InkWell(
                      onTap: handleCredencialTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? AppColors.darkSurfaceContainerHigh : AppColors.surfaceContainerHigh,
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.badge_rounded,
                            color: AppColors.secondary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // 3. User Profile Avatar in Header
              Center(
                child: Semantics(
                  button: true,
                  label: 'Ir a Mi Perfil',
                  child: Tooltip(
                    message: 'Mi Perfil',
                    child: InkWell(
                      onTap: handleAvatarTap,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryContainer],
                          ),
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (user?.name ?? 'V').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ]
          : null,
    );
  }
}
