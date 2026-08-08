import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';
import 'ajukan_cuti_page.dart';
import 'ajukan_lembur_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.get('/dashboard');
      if (response.statusCode == 200) {
        setState(() {
          _dashboardData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data dashboard')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 12),
              _buildStatusBanners(),
              const SizedBox(height: 14),
              _buildQuickActionButtons(),
              const SizedBox(height: 14),
              const Text(
                'Ringkasan Kehadiran Bulan Ini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              _buildAttendanceGrid(),
              const SizedBox(height: 14),
              _buildAttendanceChart(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    final user = _dashboardData?['user'] ?? {};
    final nama = user['nama'] ?? 'Pengguna';
    final jabatan = user['jabatan'] ?? 'Karyawan';
    final avatar = user['avatar'] ?? 'https://i.pravatar.cc/150';

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: NetworkImage(avatar),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Pagi, $nama!',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                jabatan,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            setState(() => _selectedIndex = 4); // Pindah ke tab Notifikasi
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.notifications_none, size: 18, color: Colors.grey),
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatusBanners() {
    final sisaCuti = _dashboardData?['summary']?['sisa_cuti'] ?? 0;
    final statusKes = _dashboardData?['summary']?['status_kesehatan'] ?? 'Baik';

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 15),
                const SizedBox(width: 5),
                Text(
                  'Sisa Cuti: $sisaCuti Hari',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
              child: Row(
              children: [
                const Icon(Icons.check, color: Colors.green, size: 15),
                const SizedBox(width: 5),
                Text(
                  'Status: $statusKes',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tombol aksi cepat untuk memicu Modal Bottom Sheet Cuti/Lembur
  Widget _buildQuickActionButtons() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => AjukanCutiSheet.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.beach_access_rounded, size: 16, color: Color(0xFF009688)),
                  SizedBox(width: 6),
                  Text(
                    'Ajukan Cuti',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009688),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () => AjukanLemburSheet.show(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF009688).withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time_filled_rounded, size: 16, color: Color(0xFF009688)),
                  SizedBox(width: 6),
                  Text(
                    'Ajukan Lembur',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009688),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceGrid() {
    final attn = _dashboardData?['attendance_month'] ?? {};
    final hadir = attn['hadir'] ?? 0;
    final terlambat = attn['terlambat'] ?? 0;
    final izin = attn['izin'] ?? 0;
    final cuti = attn['cuti'] ?? 0;
    final sakit = attn['sakit'] ?? 0;
    final alpha = attn['alpha'] ?? 0;
    final total = attn['total_hari_kerja'] ?? 22;

    String pct(int val) => total > 0 ? '(${(val / total * 100).toStringAsFixed(0)}%)' : '(0%)';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        _AttendanceCard(title: 'Hadir', count: '$hadir Hari', percentage: pct(hadir), color: Colors.teal),
        _AttendanceCard(title: 'Terlambat', count: '$terlambat Hari', percentage: pct(terlambat), color: Colors.orange),
        _AttendanceCard(title: 'Izin', count: '$izin Hari', percentage: pct(izin), color: Colors.blue),
        _AttendanceCard(title: 'Cuti', count: '$cuti Hari', percentage: pct(cuti), color: Colors.purple),
        _AttendanceCard(title: 'Sakit', count: '$sakit Hari', percentage: pct(sakit), color: Colors.amber),
        _AttendanceCard(title: 'Alpha', count: '$alpha Hari', percentage: pct(alpha), color: Colors.red),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final heights = [0.8, 0.9, 0.82, 0.88, 0.85, 0.08, 0.08];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tren Kehadiran (7 Hari Terakhir)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              ),
              Text(
                'Jam Kerja',
                style: TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final isWeekend = index >= 5;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 10,
                      height: 60 * heights[index],
                      decoration: BoxDecoration(
                        color: isWeekend ? Colors.grey.shade200 : const Color(0xFF009688),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: const TextStyle(color: Colors.grey, fontSize: 9),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() => _selectedIndex = index);

        // Aksi Buka Sheet atau Pindah Halaman saat Bottom Nav diklik
        if (index == 2) {
          // Klik Tab 'Pengajuan' -> Tampilkan pilihan Cuti / Lembur
          _showPengajuanModal(context);
        }
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF009688),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      iconSize: 20,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          activeIcon: Icon(Icons.check_circle),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          activeIcon: Icon(Icons.assignment),
          label: 'Pengajuan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          activeIcon: Icon(Icons.notifications),
          label: 'Notifikasi',
        ),
      ],
    );
  }

  // Dialog Pilihan Pengajuan saat Tab 'Pengajuan' diklik
  void _showPengajuanModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.beach_access, color: Color(0xFF009688)),
                title: const Text('Ajukan Izin / Cuti'),
                onTap: () {
                  Navigator.pop(context);
                  AjukanCutiSheet.show(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time_filled, color: Color(0xFF009688)),
                title: const Text('Ajukan Lembur'),
                onTap: () {
                  Navigator.pop(context);
                  AjukanLemburSheet.show(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String title;
  final String count;
  final String percentage;
  final Color color;

  const _AttendanceCard({
    required this.title,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '$count ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                TextSpan(
                  text: percentage,
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}