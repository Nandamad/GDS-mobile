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
    _animation = Tween<double>(begin: -4, end: 8).animate(
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
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 80,
                          height: 80,
                          child: CustomPaint(
                            painter: ClockPainter(_animation.value),
                          ),
                        );
                      },
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

    // Draw background squircle
    final paintBg = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.fill;
    
    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      const Radius.circular(12),
    );
    canvas.drawRRect(rrect, paintBg);

    // Inner clock circle
    final innerRadius = radius * 0.55;
    
    final paintWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    // Draw clock circle
    canvas.drawCircle(center, innerRadius, paintWhite);

    final checkCenter = Offset(center.dx + innerRadius * 0.75, center.dy + innerRadius * 0.75);
    // Draw green circle to cut out the clock border for the checkmark
    canvas.drawCircle(checkCenter, 8, paintBg);

    // Calculate angles (-pi/2 is 12 o'clock / top)
    final hourAngle = -math.pi / 2 + (time / 12) * 2 * math.pi;
    final minuteAngle = -math.pi / 2 + (time % 1) * 2 * math.pi;

    // Draw hour hand
    final hourLength = innerRadius * 0.45;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAngle) * hourLength,
        center.dy + math.sin(hourAngle) * hourLength,
      ),
      paintWhite,
    );

    // Draw minute hand
    final minuteLength = innerRadius * 0.65;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minuteAngle) * minuteLength,
        center.dy + math.sin(minuteAngle) * minuteLength,
      ),
      paintWhite,
    );

    // Draw center dot
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);

    // Draw checkmark
    final checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;
      
    final path = Path();
    path.moveTo(checkCenter.dx - 3.5, checkCenter.dy);
    path.lineTo(checkCenter.dx - 1, checkCenter.dy + 3.5);
    path.lineTo(checkCenter.dx + 4.5, checkCenter.dy - 3);
    canvas.drawPath(path, checkPaint);
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.time != time;
  }
}
