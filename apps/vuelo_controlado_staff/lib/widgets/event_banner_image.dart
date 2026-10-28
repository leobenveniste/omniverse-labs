import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class EventBannerImage extends StatelessWidget {
  final String? imageSource;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const EventBannerImage({
    super.key,
    required this.imageSource,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final raw = imageSource?.trim();
    if (raw == null || raw.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget imageWidget;

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      imageWidget = Image.network(
        raw,
        height: height,
        width: width ?? double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    } else {
      // Intentar decodificar como Base64 (con o sin prefijo data:image/...;base64,)
      Uint8List? bytes;
      try {
        final cleanBase64 = raw.contains(',') ? raw.split(',').last.trim() : raw;
        bytes = base64Decode(cleanBase64);
      } catch (_) {
        bytes = null;
      }

      if (bytes != null && bytes.isNotEmpty) {
        imageWidget = Image.memory(
          bytes,
          height: height,
          width: width ?? double.infinity,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      } else {
        return const SizedBox.shrink();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
