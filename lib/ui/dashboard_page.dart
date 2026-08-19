import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'kinerja_presensi_page.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const DashboardScreen({super.key, this.onNotificationTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Sesi login tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      final dio = ApiService().dio;
      final response = await dio.get('/dashboard');

      if (response.statusCode == 200) {
        final payload = response.data;
        final data = payload is Map && payload['data'] is Map
            ? Map<String, dynamic>.from(payload['data'])
            : payload is Map
            ? Map<String, dynamic>.from(payload)
            : null;

        if (data == null) {
          throw Exception('Format data dashboard tidak valid');
        }

        if (!mounted) return;

        setState(() {
          _dashboardData = data;
          _errorMessage = '';
          _isLoading = false;
        });
        return;
      }

      throw DioException(
        requestOptions: RequestOptions(path: '/dashboard'),
        response: response,
        error: 'Dashboard request failed',
      );
    } on DioException catch (e) {
      debugPrint('DASHBOARD ERROR: ${e.response?.statusCode} ${e.response?.data}');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.response?.data is Map
            ? e.response?.data['message']?.toString() ?? 'Gagal memuat dashboard.'
            : 'Gagal memuat dashboard.';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DASHBOARD ERROR: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Format data dashboard tidak valid.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: Color(0xFF009688)),
        )
            : _errorMessage.isNotEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchDashboardData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                  ),
                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              ],
            ),
          ),
        )
            : RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: const Color(0xFF009688),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildStatusBanners(),
                const SizedBox(height: 14),

                // Header Ringkasan Kehadiran yang bisa diklik
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KinerjaPresensiScreen(
                          attendanceData: _dashboardData?['attendance_month'],
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          'Ringkasan Kehadiran Bulan Ini',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ],
                    ),
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
      ),
    );
  }

  Widget _buildHeader() {
    final user = _dashboardData?['user'] ?? {};
    final nama = (user['nama'] ?? user['name'] ?? 'Pengguna').toString();
    final jabatan = (user['jabatan'] ?? user['role'] ?? 'Karyawan').toString();

    return Row(
      children: [
        // BAGIAN PROFIL (CUMA PAJANGAN - TIDAK BISA DIKLIK)
        Expanded(
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFFCCFBF1),
                child: Icon(Icons.person, size: 20, color: Color(0xFF009688)),
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
            ],
          ),
        ),

        // ICON NOTIFIKASI
        InkWell(
          onTap: widget.onNotificationTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 18,
                  color: Colors.grey,
                ),
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
        ),
      ],
    );
  }

  Widget _buildStatusBanners() {
    final summary = _dashboardData?['summary'] ?? {};
    final sisaCuti = summary['sisa_cuti'] ?? 0;
    final statusKes = summary['status_kesehatan'] ?? 'Baik';

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
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 15,
                ),
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

  Widget _buildAttendanceGrid() {
    final attn = _dashboardData?['attendance_month'] ?? {};
    final hadir = attn['hadir'] ?? 0;
    final terlambat = attn['terlambat'] ?? 0;
    final izin = attn['izin'] ?? 0;
    final cuti = attn['cuti'] ?? 0;
    final sakit = attn['sakit'] ?? 0;
    final alpha = attn['alpha'] ?? 0;
    final total = attn['total_hari_kerja'] ?? 13;

    String pct(int val) =>
        total > 0 ? '(${(val / total * 100).toStringAsFixed(0)}%)' : '(0%)';

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        _AttendanceCard(
          title: 'Hadir',
          count: '$hadir Hari',
          percentage: pct(hadir),
          color: Colors.teal,
        ),
        _AttendanceCard(
          title: 'Terlambat',
          count: '$terlambat Hari',
          percentage: pct(terlambat),
          color: Colors.orange,
        ),
        _AttendanceCard(
          title: 'Izin',
          count: '$izin Hari',
          percentage: pct(izin),
          color: Colors.blue,
        ),
        _AttendanceCard(
          title: 'Cuti',
          count: '$cuti Hari',
          percentage: pct(cuti),
          color: Colors.purple,
        ),
        _AttendanceCard(
          title: 'Sakit',
          count: '$sakit Hari',
          percentage: pct(sakit),
          color: Colors.amber,
        ),
        _AttendanceCard(
          title: 'Alpha',
          count: '$alpha Hari',
          percentage: pct(alpha),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAttendanceChart() {
    final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    final List<dynamic> chartData = _dashboardData?['weekly_chart'] ?? [0.8, 0.9, 0.82, 0.88, 0.85, 0.08, 0.08];

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
                final double heightVal = (index < chartData.length)
                    ? (double.tryParse(chartData[index].toString()) ?? 0.1)
                    : 0.1;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 10,
                      height: (60 * heightVal).clamp(4.0, 60.0),
                      decoration: BoxDecoration(
                        color: isWeekend
                            ? Colors.grey.shade200
                            : const Color(0xFF009688),
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
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
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