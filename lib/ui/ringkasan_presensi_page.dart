import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RingkasanPresensiPage extends StatefulWidget {
  const RingkasanPresensiPage({super.key});

  @override
  State<RingkasanPresensiPage> createState() => _RingkasanPresensiPageState();
}

class _RingkasanPresensiPageState extends State<RingkasanPresensiPage> {
  bool _isLoading = true;
  Map<String, dynamic> _attendanceSummary = {};
  List<dynamic> _riwayatLembur = [];
  
  String _currentMonthStr = '';

  @override
  void initState() {
    super.initState();
    _currentMonthStr = _formatMonth(DateTime.now());
    _fetchData();
  }

  String _formatMonth(DateTime date) {
    const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final dayStr = date.day.toString().padLeft(2, '0');
    return '$dayStr ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _fetchData() async {
    try {
      final dio = ApiService().dio;
      
      // Fetch Dashboard (for attendance summary)
      final dashRes = await dio.get('/dashboard');
      if (dashRes.statusCode == 200) {
        final payload = dashRes.data;
        Map<String, dynamic>? data;
        if (payload is Map) {
          data = payload['data'] is Map ? Map<String, dynamic>.from(payload['data']) : Map<String, dynamic>.from(payload);
        }
        if (data != null && data['attendance_month'] != null) {
          _attendanceSummary = Map<String, dynamic>.from(data['attendance_month']);
        }
      }

      // Fetch Lembur History
      final lemburRes = await dio.get('/lembur');
      if (lemburRes.statusCode == 200) {
        final lemburPayload = lemburRes.data;
        if (lemburPayload['data'] is List) {
          // Filter out lembur that matches current month (optional, assuming api returns all or current month)
          final now = DateTime.now();
          _riwayatLembur = (lemburPayload['data'] as List).where((item) {
             if (item['tanggal'] == null) return false;
             try {
                final date = DateTime.parse(item['tanggal']);
                return date.month == now.month && date.year == now.year;
             } catch (_) {
                return false;
             }
          }).toList();
          
          // Sort by date descending
          _riwayatLembur.sort((a, b) {
            final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime.now();
            final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime.now();
            return dateA.compareTo(dateB);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching ringkasan data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back_ios_new, size: 14, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: const Text(
          'Ringkasan Presensi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMonthPicker(),
                const SizedBox(height: 24),
                
                const Text(
                  'Statistik Kehadiran',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 12),
                _buildStatistikGrid(),
                const SizedBox(height: 24),
                
                _buildRataRataMingguan(),
                const SizedBox(height: 16),
                
                _buildJamKerjaSummary(),
                const SizedBox(height: 24),
                
                _buildRiwayatLembur(),
                const SizedBox(height: 24),
                
                _buildUnduhButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildMonthPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _currentMonthStr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          const Icon(Icons.calendar_today_outlined, color: Color(0xFF009688), size: 18),
        ],
      ),
    );
  }

  Widget _buildStatistikGrid() {
    final Map<String, Map<String, dynamic>> items = {
      'Hadir': {
        'val': _attendanceSummary['hadir'] ?? 0,
        'color': const Color(0xFF009688),
      },
      'Terlambat': {
        'val': _attendanceSummary['terlambat'] ?? 0,
        'color': const Color(0xFFF59E0B),
      },
      'Izin': {
        'val': _attendanceSummary['izin'] ?? 0,
        'color': const Color(0xFF3B82F6),
      },
      'Cuti': {
        'val': _attendanceSummary['cuti'] ?? 0,
        'color': const Color(0xFFF97316),
      },
      'Sakit': {
        'val': _attendanceSummary['sakit'] ?? 0,
        'color': const Color(0xFF64748B),
      },
      'Alpha': {
        'val': _attendanceSummary['alpha'] ?? 0,
        'color': const Color(0xFFEF4444),
      },
    };

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: items.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.key,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${entry.value['val']} ${entry.key == 'Terlambat' ? 'Kali' : 'Hari'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: entry.value['color'],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRataRataMingguan() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rata-rata Kehadiran Mingguan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBarChart(80, 'W1'),
              _buildBarChart(100, 'W2'),
              _buildBarChart(65, 'W3'),
              _buildBarChart(95, 'W4'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBarChart(double heightFactor, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: heightFactor, // max height around 100
          decoration: BoxDecoration(
            color: const Color(0xFF009688),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildJamKerjaSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Jam Kerja', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              Text(
                 // Provide a rough estimation based on kehadiran, or hardcode if not available in API
                '${(_attendanceSummary['hadir'] ?? 0) * 8} Jam', 
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold)
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Rata-rata Jam Masuk', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              Text('08:42 WIB', style: TextStyle(color: Color(0xFF009688), fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatLembur() {
    int totalJamLembur = 0;
    for (var l in _riwayatLembur) {
       final durasi = l['estimasi_jam'] != null 
           ? int.tryParse(l['estimasi_jam'].toString()) ?? 0 
           : 0;
       totalJamLembur += durasi;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.calendar_today_outlined, color: Color(0xFF009688), size: 16),
              SizedBox(width: 8),
              Text(
                'Riwayat Lembur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Lembur Bulan Ini', style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
              Text('$totalJamLembur Jam', style: const TextStyle(color: Color(0xFF009688), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          
          if (_riwayatLembur.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('Belum ada riwayat lembur bulan ini', style: TextStyle(color: Colors.grey, fontSize: 12))),
            )
          else
            ..._riwayatLembur.map((item) {
               final dateStr = item['tanggal'] ?? '';
               String formattedDate = dateStr;
               try {
                  final date = DateTime.parse(dateStr);
                  formattedDate = _formatDate(date);
               } catch (_) {}
               
               final durasi = item['estimasi_jam']?.toString() ?? '0';
               final status = item['status']?.toString() ?? 'Menunggu';
               
               Color badgeColor = const Color(0xFFFFF3E0);
               Color badgeText = const Color(0xFFF59E0B);
               
               if (status.toLowerCase().contains('setuju')) {
                  badgeColor = const Color(0xFFE8F5E9);
                  badgeText = const Color(0xFF009688);
               } else if (status.toLowerCase().contains('tolak')) {
                  badgeColor = const Color(0xFFFEE2E2);
                  badgeText = const Color(0xFFEF4444);
               }

               return Padding(
                 padding: const EdgeInsets.only(top: 8),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: Colors.grey.shade100),
                   ),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       SizedBox(
                         width: 90,
                         child: Text(formattedDate, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                       ),
                       Text('$durasi Jam', style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                         decoration: BoxDecoration(
                           color: badgeColor,
                           borderRadius: BorderRadius.circular(20),
                         ),
                         child: Text(
                           status,
                           style: TextStyle(fontSize: 10, color: badgeText, fontWeight: FontWeight.bold),
                         ),
                       ),
                     ],
                   ),
                 ),
               );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildUnduhButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur unduh laporan akan segera hadir')));
        },
        icon: const Icon(Icons.share_outlined, color: Colors.white, size: 18),
        label: const Text('Unduh Laporan Bulanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009688),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
