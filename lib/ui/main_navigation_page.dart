import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'presensi_harian_page.dart';
import 'pengajuan_page.dart';
import 'riwayat_presensi_page.dart';
import 'profil_page.dart';
import 'notifikasi_page.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _openNotifikasi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        onNotificationTap: _openNotifikasi,
      ),
      const PengajuanScreen(),
      const PresensiScreen(),
      const RiwayatPresensiScreen(),
      const ProfilPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),

      // FAB TOMBOL LINGKARAN HIJAU DI TENGAH
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => setState(() => _currentIndex = 2),
          backgroundColor: const Color(0xFF009688),
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(
            Icons.access_time_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // BOTTOM NAVBAR
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. HOME
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Home',
              ),

              // 2. PENGAJUAN
              _buildNavItem(
                index: 1,
                icon: Icons.send_outlined,
                activeIcon: Icons.send_rounded,
                label: 'Pengajuan',
              ),

              // SPACER UNTUK FAB TENGAH
              const SizedBox(width: 48),

              // 3. RIWAYAT
              _buildNavItem(
                index: 3,
                icon: Icons.format_list_bulleted_rounded,
                activeIcon: Icons.format_list_bulleted_rounded,
                label: 'Riwayat',
              ),

              // 4. PROFIL
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 22,
              color: isSelected ? const Color(0xFF009688) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF009688) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}