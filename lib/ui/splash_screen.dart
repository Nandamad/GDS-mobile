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
  late Animation<double> _clockProgress;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // 0 to 0.5 (1.5 seconds) - Jam berputar
    _clockProgress = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // 0.5 to 1.0 (1.5 seconds) - Logo dan Teks muncul
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
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

    String? token;
    try {
      token = await ApiService().getToken();
    } catch (e) {
      debugPrint('Error getting token in splash screen: $e');
      // If error (e.g. secure storage keystore error), force login
      token = null; 
    }

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      // Ada token, auto login ke dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
      );
    } else {
      // Tidak ada token atau error, ke halaman login
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final showClock = _controller.value <= 0.5;

            return Stack(
              children: [
                // 1. Animasi Jam Berputar
                if (showClock)
                  Center(
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomPaint(
                        painter: SpinningClockPainter(_clockProgress.value),
                      ),
                    ),
                  ),

                // 2. Logo Ijo dan Teks PresensiPlus
                if (!showClock)
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback jika logo.png gagal dimuat
                              return Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF009688),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded, 
                                  color: Colors.white, 
                                  size: 50
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

                // Versi di bagian bawah
                if (!showClock)
                  Positioned(
                    bottom: 12.0,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: const Center(
                        child: Text(
                          'v1.1.6',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SpinningClockPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  SpinningClockPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Lingkaran border jam
    final paintBorder = Paint()
      ..color = const Color(0xFF009688).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, paintBorder);

    // Menggambar angka 1-12
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    for (int i = 1; i <= 12; i++) {
      final angle = -math.pi / 2 + (i / 12) * 2 * math.pi;
      final numberRadius = radius * 0.75;
      final offset = Offset(
        center.dx + math.cos(angle) * numberRadius,
        center.dy + math.sin(angle) * numberRadius,
      );
      
      textPainter.text = TextSpan(
        text: i.toString(),
        style: const TextStyle(
          color: Color(0xFF009688),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        offset - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }

    // Sudut jarum pendek (Jam): Mulai dari angka 8, muter 1 putaran penuh kembali ke angka 8
    final baseHourAngle = -math.pi / 2 + (8 / 12) * 2 * math.pi;
    final hourAngle = baseHourAngle + (progress * 2 * math.pi);

    // Sudut jarum panjang (Menit): Mulai dari angka 12, muter lebih lambat (setengah putaran)
    final baseMinuteAngle = -math.pi / 2;
    final minuteAngle = baseMinuteAngle + (progress * math.pi);

    // Gambar jarum panjang (Warna gelap)
    final paintMinute = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    final minuteLength = radius * 0.55;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(minuteAngle) * minuteLength,
        center.dy + math.sin(minuteAngle) * minuteLength,
      ),
      paintMinute,
    );

    // Gambar jarum pendek (Warna hijau, lebih tebal)
    final paintHour = Paint()
      ..color = const Color(0xFF009688)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    final hourLength = radius * 0.40;
    canvas.drawLine(
      center,
      Offset(
        center.dx + math.cos(hourAngle) * hourLength,
        center.dy + math.sin(hourAngle) * hourLength,
      ),
      paintHour,
    );

    // Titik pusat
    canvas.drawCircle(center, 3.5, Paint()..color = const Color(0xFF0F172A));
  }

  @override
  bool shouldRepaint(covariant SpinningClockPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
