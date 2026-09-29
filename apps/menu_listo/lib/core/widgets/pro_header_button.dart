import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/premium/presentation/paywall_sheet.dart';
import '../../features/premium/providers/premium_provider.dart';

class ProHeaderButton extends ConsumerWidget {
  const ProHeaderButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(premiumProvider).isProUser;
    if (isPro) return const SizedBox.shrink();

    return IconButton(
      icon: const Text(
        '👑',
        style: TextStyle(fontSize: 18),
      ),
      tooltip: 'Menú Listo PRO',
      onPressed: () {
        HapticFeedback.lightImpact();
        PaywallSheet.show(context);
      },
    );
  }
}
