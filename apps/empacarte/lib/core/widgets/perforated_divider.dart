import 'package:flutter/material.dart';

class PerforatedDivider extends StatelessWidget {
  final double height;
  final Color notchColor;
  final Color dashColor;

  const PerforatedDivider({
    super.key,
    this.height = 24,
    required this.notchColor,
    required this.dashColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed perforation line
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth - 32;
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1.2,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                    color: dashColor,
                  );
                }),
              );
            },
          ),
          // Left punch-hole notch
          Positioned(
            left: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: notchColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right punch-hole notch
          Positioned(
            right: -12,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: notchColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
