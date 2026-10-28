import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/municipality_config.dart';
import '../../widgets/municipality_logo.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const SplashScreen({super.key, this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  final Color _primaryBlue = const Color(0xFF1E6FD9);
  final Color _lightWaveBlue = const Color(0xFF8BB7F0);

  @override
  void initState() {
    super.initState();
    // Infinite gentle breathing glow animation for the civic shield
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleSkipOrStart() {
    HapticFeedback.lightImpact();
    widget.onFinish?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topWaveHeight = (size.height * 0.34).clamp(160.0, 280.0);
    final bottomWaveHeight = (size.height * 0.20).clamp(110.0, 160.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. TOP DUAL ORGANIC WAVES (Deep Royal Blue + Sky Blue + White transition)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: topWaveHeight,
            child: CustomPaint(
              painter: _ProportionedTopWavesPainter(
                primaryColor: _primaryBlue,
                secondaryColor: _lightWaveBlue,
              ),
            ),
          ),

          // 2. BOTTOM RISING WAVE
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: bottomWaveHeight,
            child: CustomPaint(
              painter: _ProportionedBottomWavePainter(
                color: _primaryBlue,
              ),
            ),
          ),

          // 3. MAIN CENTER CONTENT
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: topWaveHeight * 0.70),

                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated Center Municipality Shield with subtle pulsing glow
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.0 + (_pulseController.value * 0.04),
                                child: Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: _primaryBlue.withValues(
                                          alpha: 0.16 + (0.12 * _pulseController.value),
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: MunicipalityLogo(size: 58),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Municipality Header
                          Text(
                            MunicipalityConfig.shortName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // App Brand Name
                          Text(
                            MunicipalityConfig.appName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: -0.8,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Slogan / Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              MunicipalityConfig.slogan,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Indeterminate Infinite Loading Indicator (No fake percentages or bars)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Iniciando servicios cívicos...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. BOTTOM ACTION BUTTON ("Get Started" if skip/start is requested)
                Container(
                  height: bottomWaveHeight * 0.70,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: widget.onFinish != null
                      ? OutlinedButton(
                          onPressed: _handleSkipOrStart,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Ingresar',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// FAITHFUL PROPORTIONED TOP WAVES PAINTER
// ----------------------------------------------------
class _ProportionedTopWavesPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _ProportionedTopWavesPainter({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Fill base top with Solid Royal Blue
    final primaryPaint = Paint()..color = primaryColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), primaryPaint);

    // 2. Draw Middle Organic Light Blue River Wave
    final lightBluePaint = Paint()..color = secondaryColor;
    final lightBluePath = Path()
      ..moveTo(0, size.height * 0.52)
      ..cubicTo(
        size.width * 0.32, size.height * 0.28,
        size.width * 0.65, size.height * 0.88,
        size.width, size.height * 0.45,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lightBluePath, lightBluePaint);

    // 3. Draw Bottom White Wave Transition
    final whitePaint = Paint()..color = Colors.white;
    final whitePath = Path()
      ..moveTo(0, size.height * 0.80)
      ..cubicTo(
        size.width * 0.35, size.height * 0.98,
        size.width * 0.68, size.height * 0.58,
        size.width, size.height * 0.78,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(whitePath, whitePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// FAITHFUL PROPORTIONED BOTTOM WAVE PAINTER
// ----------------------------------------------------
class _ProportionedBottomWavePainter extends CustomPainter {
  final Color color;

  _ProportionedBottomWavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.62)
      ..cubicTo(
        size.width * 0.35, size.height * 0.78,
        size.width * 0.60, size.height * 0.14,
        size.width, size.height * 0.05,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
