import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_page.dart';
import 'main_navigation_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Memberikan waktu minimal untuk splash screen (UX)
    await Future.delayed(const Duration(seconds: 2));

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFF009688),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'PresensiKu',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sistem Kehadiran Digital',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 64),
            const CircularProgressIndicator(color: Color(0xFF009688)),
          ],
        ),
      ),
    );
  }
}
