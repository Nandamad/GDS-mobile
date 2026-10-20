import 'package:flutter/material.dart';
import 'login_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _OnboardingPageData(
      title: 'Presensi mudah,\nsetiap hari',
      description:
          'Catat kehadiran harian lewat PresensiPlus. Praktis, rapi, dan mudah digunakan.',
      icon: Icons.phone_iphone_rounded,
      accent: Color(0xFF0D9B89),
    ),
    _OnboardingPageData(
      title: 'Catat masuk\ndan pulang',
      description:
          'Lakukan absen masuk saat mulai bekerja dan absen keluar saat selesai bekerja.',
      icon: Icons.login_rounded,
      accent: Color(0xFF0D9B89),
    ),
    _OnboardingPageData(
      title: 'Riwayat kehadiran,\nmudah dilihat',
      description:
          'Lihat kembali catatan masuk dan keluar dalam riwayat presensi yang tertata.',
      icon: Icons.fact_check_outlined,
      accent: Color(0xFF0D9B89),
    ),
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _continue() {
    if (_currentPage == _pages.length - 1) {
      _openLogin();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/Logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.access_time_filled_rounded,
                              color: Color(0xFF0D9B89),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text.rich(
                            TextSpan(
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Presensi',
                                  style: TextStyle(color: Color(0xFF1E293B)),
                                ),
                                TextSpan(
                                  text: 'Plus+',
                                  style: TextStyle(color: Color(0xFF059669)),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _openLogin,
                            child: const Text(
                              'Lewati',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _pages.length,
                          onPageChanged: (index) =>
                              setState(() => _currentPage = index),
                          itemBuilder: (context, index) =>
                              _IllustratedPage(page: _pages[index]),
                        ),
                      ),
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 20,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 38,
                        child: Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            width: index == _currentPage ? 15 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: index == _currentPage
                                  ? const Color(0xFF0D9B89)
                                  : const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: _continue,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9B89),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1
                                    ? 'Mulai Sekarang'
                                    : 'Lanjut',
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}

class _IllustratedPage extends StatelessWidget {
  const _IllustratedPage({required this.page});

  final _OnboardingPageData page;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.85).clamp(
          210.0,
          330.0,
        );

        return Center(
          child: SizedBox(
            height: illustrationHeight,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: illustrationHeight * 0.78,
                  height: illustrationHeight * 0.78,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F5F2),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: illustrationHeight * 0.45,
                  height: illustrationHeight * 0.78,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x220F172A),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Icon(page.icon, size: 58, color: page.accent),
                        const SizedBox(height: 10),
                        Text(
                          _screenLabel(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1E293B),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 66,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: page.accent,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            '08:00',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: illustrationHeight * 0.05,
                  bottom: illustrationHeight * 0.18,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D9B89),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Positioned(
                  left: illustrationHeight * 0.04,
                  top: illustrationHeight * 0.20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Color(0x140F172A), blurRadius: 12),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(page.icon, color: page.accent, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _cardLabel(),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _screenLabel() {
    if (page.icon == Icons.fact_check_outlined) return 'Riwayat Presensi';
    return 'Presensi hari ini';
  }

  String _cardLabel() {
    if (page.icon == Icons.fact_check_outlined) return 'Kehadiran tercatat';
    if (page.icon == Icons.login_rounded) return 'Absen Masuk';
    return 'Presensi mudah';
  }
}
