import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../premium/providers/premium_provider.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AboutDialogWidget(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Omniverse Labs Logo
            Image.asset(
              isDark
                  ? 'assets/images/omniverse_labs_white.png'
                  : 'assets/images/omniverse_labs_color.png',
              width: 90,
              height: 90,
            ),
            const SizedBox(height: 16),
            const Text(
              'OMNIVERSE LABS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creadores de herramientas digitales, utilidades y experiencias móviles de alta calidad diseñadas para acompañar tu día a día.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // App Name & Version Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Aplicación:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Menú Listo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, _) {
                int tapCount = 0;
                DateTime? lastTap;

                return StatefulBuilder(
                  builder: (context, setInnerState) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        final now = DateTime.now();
                        if (lastTap == null || now.difference(lastTap!) > const Duration(seconds: 2)) {
                          tapCount = 1;
                        } else {
                          tapCount++;
                        }
                        lastTap = now;

                        if (tapCount >= 7) {
                          tapCount = 0;
                          HapticFeedback.heavyImpact();
                          await ref.read(premiumProvider.notifier).toggleDevMode();
                          final isDev = ref.read(premiumProvider).isDevMode;
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: isDev ? const Color(0xFF2D7A4F) : const Color(0xFF475569),
                                content: Text(
                                  isDev
                                      ? '🧪 Modo Desarrollador activado'
                                      : '🔒 Modo Desarrollador desactivado',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        } else if (tapCount >= 4) {
                          HapticFeedback.lightImpact();
                          final remaining = 7 - tapCount;
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              duration: const Duration(milliseconds: 600),
                              content: Text(
                                'Estás a $remaining pasos de desbloquear el modo desarrollador',
                              ),
                            ),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Versión:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            FutureBuilder<PackageInfo>(
                              future: PackageInfo.fromPlatform(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final info = snapshot.data!;
                                  return Text(
                                    '${info.version} (Build ${info.buildNumber})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  );
                                }
                                return const Text(
                                  '1.2.15 (Build 32)',
                                  style: TextStyle(fontSize: 13, color: Colors.grey),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 6),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Lanzamiento:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Septiembre 2026', style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
