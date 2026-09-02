import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/icon_style_provider.dart';

class EmojiOrIcon extends ConsumerWidget {
  final String emoji;
  final IconData icon;
  final double size;
  final Color? color;

  const EmojiOrIcon({
    super.key,
    required this.emoji,
    required this.icon,
    this.size = 22,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = ref.watch(iconStyleProvider);
    if (style == AppIconStyle.emojis) {
      return Text(
        emoji,
        style: TextStyle(fontSize: size - 2, height: 1.1),
      );
    }
    return Icon(
      icon,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
    );
  }
}
