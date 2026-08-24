import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dashboard_page.dart';
import 'presensi_harian_page.dart';
import 'pengajuan_page.dart';
import 'riwayat_presensi_page.dart';
import 'profil_page.dart';
import 'notifikasi_page.dart';
import 'approval_page.dart';
import '../services/api_service.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  bool _isAtasan = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadAtasanStatus();
  }

  Future<void> _loadAtasanStatus() async {
    var isAtasan = await ApiService().getIsAtasan();

    try {
      final response = await ApiService().dio.get('/user');
      final payload = response.data;
      dynamic user = payload;
      if (payload is Map) {
        user = payload['user'] ?? payload['data'] ?? payload;
        if (user is Map && user['user'] is Map) user = user['user'];
      }
      if (user is Map && user.containsKey('is_atasan')) {
        final value = user['is_atasan'];
        isAtasan =
            value == true ||
            ['true', '1', 'yes'].contains(value.toString().toLowerCase());
        await ApiService().saveIsAtasan(isAtasan);
      }
    } on DioException catch (e) {
      debugPrint(
        'GET /user ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
    }

    if (!isAtasan) {
      try {
        final response = await ApiService().dio.get('/approval/pending');
        final payload = response.data;
        dynamic data = payload;
        if (payload is Map) {
          data = payload['data'] ?? payload['items'] ?? payload['result'] ?? [];
        }
        isAtasan =
            response.statusCode == 200 && data is List && data.isNotEmpty;
        if (isAtasan) await ApiService().saveIsAtasan(true);
      } on DioException catch (e) {
        debugPrint(
          'CHECK ATASAN ERROR: ${e.response?.statusCode} ${e.response?.data}',
        );
      }
    }

    if (mounted) {
      setState(() => _isAtasan = isAtasan);
    }
  }

  void _openNotifikasi() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotifikasiScreen()),
    );
  }

  /// Menghitung index halaman yang sebenarnya berdasarkan posisi navigasi.
  /// Jika atasan, ada 6 halaman (index 0-5), jika bukan ada 5 (index 0-4).
  /// Layout posisi:
  ///   Atasan:  Home(0) | Pengajuan(1) | [FAB=Presensi(2)] | Approval(3) | Riwayat(4) | Profil(5)
  ///   Biasa:   Home(0) | Pengajuan(1) | [FAB=Presensi(2)] | Riwayat(3)  | Profil(4)

  List<Widget> get _pages {
    final base = <Widget>[
      DashboardScreen(onNotificationTap: _openNotifikasi),
      const PengajuanScreen(),
      const PresensiScreen(),
    ];

    if (_isAtasan) {
      base.add(const ApprovalScreen());
    }

    base.addAll([const RiwayatPresensiScreen(), const ProfilPage()]);

    return base;
  }

  int get _presensiIndex => 2;
  int get _riwayatIndex => _isAtasan ? 4 : 3;
  int get _profilIndex => _isAtasan ? 5 : 4;
  int get _approvalIndex => 3; // Hanya berlaku saat _isAtasan

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),

      // FAB TOMBOL LINGKARAN HIJAU DI TENGAH
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: () => setState(() => _currentIndex = _presensiIndex),
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

              // 3. APPROVAL (hanya untuk atasan) atau RIWAYAT
              if (_isAtasan)
                _buildNavItem(
                  index: _approvalIndex,
                  icon: Icons.assignment_turned_in_outlined,
                  activeIcon: Icons.assignment_turned_in_rounded,
                  label: 'Approval',
                ),

              if (!_isAtasan)
                // 3. RIWAYAT (untuk karyawan biasa)
                _buildNavItem(
                  index: _riwayatIndex,
                  icon: Icons.format_list_bulleted_rounded,
                  activeIcon: Icons.format_list_bulleted_rounded,
                  label: 'Riwayat',
                ),

              // 4. PROFIL (atau RIWAYAT + PROFIL jika atasan, tapi ruang terbatas)
              // Jika atasan, kita ganti Profil dengan Riwayat di tab ke-4
              // dan Profil diakses dari Riwayat atau drawer.
              // NAMUN: Untuk menjaga UX yang konsisten, kita tetap tampilkan
              // 4 item navigasi. Untuk atasan: Home | Pengajuan | Approval | Profil
              // Riwayat bisa diakses dari dashboard atau menu profil.
              if (_isAtasan)
                _buildNavItem(
                  index: _profilIndex,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profil',
                ),

              if (!_isAtasan)
                _buildNavItem(
                  index: _profilIndex,
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
              color: isSelected
                  ? const Color(0xFF009688)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF009688)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
