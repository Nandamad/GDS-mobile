import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
    _controller.forward();
    _checkSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    // Memberikan waktu minimal untuk splash screen (UX)
    await Future.delayed(const Duration(seconds: 3));

    final token = await ApiService().getToken();

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Ada token, auto login ke dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      // Tidak ada token, ke halaman login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'PresensiPlus',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sistem Absensi Digital',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 64),
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 48,
                          height: 48,
                          child: CustomPaint(
                            painter: ClockPainter(_animation.value),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'v1.2.3',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final double time; // in hours

  ClockPainter(this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintHour = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;

    final paintMinute = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    // Draw clock circle
    canvas.drawCircle(center, radius, paintCircle);

    // Calculate angles (-pi/2 is 12 o'clock / top)
    final hourAngle = -math.pi / 2 + (time / 12) * 2 * math.pi;
    final minuteAngle = -math.pi / 2 + (time % 1) * 2 * math.pi;

    // Draw hour hand
    final hourLength = radius * 0.5;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAngle) * hourLength,
        center.dy + math.sin(hourAngle) * hourLength,
      ),
      paintHour,
    );

    // Draw minute hand
    final minuteLength = radius * 0.75;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minuteAngle) * minuteLength,
        center.dy + math.sin(minuteAngle) * minuteLength,
      ),
      paintMinute,
    );

    // Draw center dot
    canvas.drawCircle(center, 4, Paint()..color = const Color(0xFF0F172A));
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
