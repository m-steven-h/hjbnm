import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;
import 'dart:async';
import 'home_screen.dart';
import 'welcome_screen.dart';
import '../providers/theme_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _timer = Timer(const Duration(seconds: 3), () async {
      final prefs = await SharedPreferences.getInstance();
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      final userName = prefs.getString('userName');

      if (mounted) {
        if (isFirstTime || userName == null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: themeProvider.backgroundColor,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'دقيقة صلاة',
                  style: GoogleFonts.cairo(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4ADE80),
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 60),
                LoadingSpinner(
                  controller: _controller,
                  color: const Color(0xFF4ADE80),
                ),
                const SizedBox(height: 35),
                Text(
                  'جاري التحميل...',
                  style: GoogleFonts.cairo(
                    color: themeProvider.secondaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class LoadingSpinner extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  const LoadingSpinner({
    super.key,
    required this.controller,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: controller.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(46, 46),
                painter: SpinnerPainter(color: color, isAfter: false),
              ),
            ),
            Transform.rotate(
              angle: -controller.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(46, 46),
                painter: SpinnerPainter(
                    color: color.withOpacity(0.5), isAfter: true),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SpinnerPainter extends CustomPainter {
  final Color color;
  final bool isAfter;

  SpinnerPainter({required this.color, required this.isAfter});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    if (!isAfter) {
      canvas.drawArc(rect, -math.pi / 2, math.pi, false, paint);
    } else {
      canvas.drawArc(rect, math.pi / 2, math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
