import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class KinerjaPresensiScreen extends StatefulWidget {
  final Map<String, dynamic>? attendanceData;

  const KinerjaPresensiScreen({super.key, this.attendanceData});

  @override
  State<KinerjaPresensiScreen> createState() => _KinerjaPresensiScreenState();
}

class _KinerjaPresensiScreenState extends State<KinerjaPresensiScreen> {
  String _selectedMonth = 'Agustus 2026';
  bool _isLoading = false;
  Map<String, dynamic>? _kinerjaData;
  List<dynamic> _logKeterlambatanList = [];

  @override
  void initState() {
    super.initState();
    if (widget.attendanceData != null) {
      _kinerjaData = widget.attendanceData;
    } else {
      _fetchKinerjaData();
    }
  }

  Future<void> _fetchKinerjaData() async {
    setState(() => _isLoading = true);
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;
      // Mengambil data dashboard/summary yang sama
      final response = await dio.get('/dashboard');

      if (response.statusCode == 200) {
        final payload = response.data;
        final data = payload is Map && payload['data'] is Map
            ? Map<String, dynamic>.from(payload['data'])
            : payload is Map
                ? Map<String, dynamic>.from(payload)
                : null;

        if (mounted && data != null) {
          setState(() {
            _kinerjaData = data['attendance_month'];
            _logKeterlambatanList = data['log_keterlambatan'] ?? [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kinerja Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (val) {
                      setState(() => _selectedMonth = val!);
                      _fetchKinerjaData();
                    },
                    items: ['Agustus 2026', 'Juli 2026', 'Juni 2026'].map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kehadiran & Absensi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAttendanceGrid(),
                  const SizedBox(height: 16),

                  const Text(
                    'Log Keterlambatan & Pulang Awal',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildLogCards(),
                  const SizedBox(height: 14),

                  _buildPayrollWarningBanner(),
                ],
              ),
            ),
    );
  }

  Widget _buildAttendanceGrid() {
    final hadir = _kinerjaData?['hadir'] ?? 0;
    final terlambat = _kinerjaData?['terlambat'] ?? 0;
    final izin = _kinerjaData?['izin'] ?? 0;
    final cuti = _kinerjaData?['cuti'] ?? 0;
    final sakit = _kinerjaData?['sakit'] ?? 0;
    final alpha = _kinerjaData?['alpha'] ?? 0;
    final total = _kinerjaData?['total_hari_kerja'] ?? 13;

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
        _AttendanceCard(title: 'Hadir', count: '$hadir Hari', percentage: pct(hadir), color: Colors.teal),
        _AttendanceCard(title: 'Terlambat', count: '$terlambat Hari', percentage: pct(terlambat), color: Colors.orange),
        _AttendanceCard(title: 'Izin', count: '$izin Hari', percentage: pct(izin), color: Colors.blue),
        _AttendanceCard(title: 'Cuti', count: '$cuti Hari', percentage: pct(cuti), color: Colors.purple),
        _AttendanceCard(title: 'Sakit', count: '$sakit Hari', percentage: pct(sakit), color: Colors.amber),
        _AttendanceCard(title: 'Alpha', count: '$alpha Hari', percentage: pct(alpha), color: Colors.red),
      ],
    );
  }

  Widget _buildLogCards() {
    if (_logKeterlambatanList.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Center(
          child: Text(
            'Tidak ada log keterlambatan bulan ini.',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: _logKeterlambatanList.map((item) {
        final isPulangAwal = item['tipe'] == 'Pulang Awal';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildLogCard(
            date: item['tanggal'] ?? '-',
            badgeText: isPulangAwal ? 'Pulang Awal' : 'Terlambat',
            badgeBgColor: isPulangAwal ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
            badgeTextColor: isPulangAwal ? const Color(0xFFDC2626) : const Color(0xFFD97706),
            timeDiff: item['durasi'] ?? '-0m',
            atasanStatus: item['status_atasan'] ?? 'Pending',
            hrdStatus: item['status_hrd'] ?? 'Waiting',
            onTap: () {},
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogCard({
    required String date,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String timeDiff,
    required String atasanStatus,
    required String hrdStatus,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeDiff,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Persetujuan:   ',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
                Text(
                  'Atasan: ',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                Text(
                  atasanStatus,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: atasanStatus == 'OK' ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HRD: ',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                Text(
                  hrdStatus,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollWarningBanner() {
    final terlambatCount = _kinerjaData?['terlambat'] ?? 0;
    final hasPayrollImpact = terlambatCount > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasPayrollImpact ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPayrollImpact ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Column(
        children: [
          Text(
            hasPayrollImpact ? 'Potensi Dampak Payroll: Ya' : 'Potensi Dampak Payroll: Tidak Ada',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: hasPayrollImpact ? const Color(0xFFEF4444) : const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hasPayrollImpact
                ? 'Keterlambatan yang belum disetujui dapat memotong tunjangan kehadiran bulan ini.'
                : 'Presensi Anda baik. Tidak ada potensi pemotongan tunjangan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: hasPayrollImpact ? const Color(0xFF7F1D1D) : const Color(0xFF14532D),
              height: 1.3,
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