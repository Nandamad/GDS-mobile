import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../model/absensi.dart';
import 'detail_log_page.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  const RiwayatPresensiScreen({super.key});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  final DateTime _now = DateTime.now();
  late DateTime _selectedPeriod;
  String _selectedStatus = 'Semua Status';

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allHistoryData = [];

  // Summary counts
  int _countHadir = 0;
  int _countTerlambat = 0;
  int _countIzin = 0;
  int _countCuti = 0;

  @override
  void initState() {
    super.initState();
    _selectedPeriod = DateTime(_now.year, _now.month);
    _fetchHistoryData();
  }

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _formatMonth(DateTime date) {
    final localDate = date.toLocal();
    return '${_monthNames[localDate.month - 1]} ${localDate.year}';
  }

  String _formatDateString(DateTime date) {
    final localDate = date.toLocal(); 
    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${hari[localDate.weekday - 1]}, ${localDate.day.toString().padLeft(2, '0')} ${bulan[localDate.month - 1]} ${localDate.year}';
  }

  List<DateTime> get _periodOptions =>
      List.generate(12, (index) => DateTime(_now.year, _now.month - index));

  String _formatTime(DateTime? date) {
    if (date == null) return '-';
    final localDate = date.toLocal(); 
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _calculateDuration(DateTime? inTime, DateTime? outTime) {
    if (inTime == null || outTime == null) return '-';
    final diff = outTime.difference(inTime);
    if (diff.isNegative) return '-';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '${hours}j ${minutes}m';
  }

  Future<void> _fetchHistoryData() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;
      final response = await dio.get(
        '/history',
        queryParameters: {
          'month': _selectedPeriod.month,
          'year': _selectedPeriod.year,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        
        int cHadir = 0;
        int cTerlambat = 0;
        int cIzin = 0;
        int cCuti = 0;

        final parsedData = data.map((item) {
          final absensiObj = Absensi.fromJson(item);
          final isCuti = item['tipe'] != null && item['tipe'] != 'Kehadiran';
          final rawStatus = (absensiObj.status ?? item['status'] ?? 'hadir').toString().toLowerCase();

          Color bgColor = const Color(0xFFDCFCE7);
          Color txtColor = const Color(0xFF15803D);
          String statusTxt = 'HADIR';
          String statusCat = 'On Time';
          Color dotColor = const Color(0xFF10B981); // Green

          if (isCuti) {
            statusCat = 'Izin';
            statusTxt = 'IZIN / CUTI';
            bgColor = const Color(0xFFDBEAFE);
            txtColor = const Color(0xFF1D4ED8);
            dotColor = const Color(0xFF3B82F6); // Blue
            if (rawStatus.contains('cuti')) {
              cCuti++;
            } else {
              cIzin++;
            }
          } else if (rawStatus.contains('terlambat') || rawStatus.contains('late')) {
            statusCat = 'Terlambat';
            statusTxt = 'TERLAMBAT';
            bgColor = const Color(0xFFFFEDD5);
            txtColor = const Color(0xFFC2410C);
            dotColor = const Color(0xFFF59E0B); // Orange
            cTerlambat++;
          } else if (rawStatus.contains('pulang_awal') || rawStatus.contains('pulang awal')) {
            statusCat = 'Terlambat';
            statusTxt = 'PULANG AWAL';
            bgColor = const Color(0xFFFFEDD5);
            txtColor = const Color(0xFFC2410C);
            dotColor = const Color(0xFFF59E0B);
            cTerlambat++;
          } else if (rawStatus.contains('tidak_absen') || rawStatus.contains('alpha') || rawStatus.contains('tidak hadir')) {
            statusCat = 'Alpha';
            statusTxt = 'TIDAK HADIR';
            bgColor = const Color(0xFFF1F5F9);
            txtColor = const Color(0xFF64748B);
            dotColor = const Color(0xFF94A3B8); // Grey
          } else if (rawStatus.contains('pending')) {
            statusCat = 'Pending';
            statusTxt = 'PENDING';
            bgColor = const Color(0xFFFEF9C3);
            txtColor = const Color(0xFFA16207);
            dotColor = const Color(0xFFEAB308);
          } else {
             cHadir++;
          }

          final tanggal = absensiObj.tanggal?.toLocal();

          return {
            'absensi_model': absensiObj,
            'rawDate': tanggal,
            'month': tanggal == null ? _formatMonth(_selectedPeriod) : _formatMonth(tanggal),
            'date': tanggal != null
                ? _formatDateString(tanggal)
                : (item['tanggal'] ?? '-'),
            'statusText': statusTxt,
            'statusCategory': statusCat,
            'statusBgColor': bgColor,
            'statusTextColor': txtColor,
            'dotColor': dotColor,
            'checkIn': _formatTime(absensiObj.jamMasuk),
            'checkOut': _formatTime(absensiObj.jamPulang),
            'duration': _calculateDuration(absensiObj.jamMasuk, absensiObj.jamPulang),
            'hasDetailButton': item['tipe'] == 'Kehadiran',
          };
        }).toList();

        setState(() {
          _allHistoryData = parsedData;
          _countHadir = cHadir;
          _countTerlambat = cTerlambat;
          _countIzin = cIzin;
          _countCuti = cCuti;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_allHistoryData.isEmpty) {
            _errorMessage = 'Gagal memperbarui log.\nPeriksa koneksi internet Anda.';
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat presensi')),
        );
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Presensi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : RefreshIndicator(
              onRefresh: _fetchHistoryData,
              color: const Color(0xFF009688),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCalendarHeader(),
                    const SizedBox(height: 16),
                    _buildCalendarGrid(),
                    const SizedBox(height: 16),
                    _buildLegend(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Ringkasan bulan ini'),
                    const SizedBox(height: 12),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Entri terbaru'),
                    const SizedBox(height: 12),
                    _buildFilters(),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      _buildErrorView()
                    else
                      _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
    );
  }

  Widget _buildCalendarHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: () {
            setState(() {
               _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month - 1);
               _isLoading = true;
            });
            _fetchHistoryData();
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_back_ios, size: 14, color: Color(0xFF0F172A)),
          ),
        ),
        Text(
          _formatMonth(_selectedPeriod),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
        InkWell(
          onTap: () {
            setState(() {
               _selectedPeriod = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1);
               _isLoading = true;
            });
            _fetchHistoryData();
          },
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    // Generate days for the selected month
    final firstDay = DateTime(_selectedPeriod.year, _selectedPeriod.month, 1);
    final lastDay = DateTime(_selectedPeriod.year, _selectedPeriod.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    
    // Day headers
    final List<String> weekDays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    
    List<Widget> gridItems = [];
    
    // Add headers
    for (var day in weekDays) {
      gridItems.add(
        Center(
          child: Text(
            day,
            style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
    
    // Add empty slots before the 1st of month
    for (int i = 1; i < firstWeekday; i++) {
      gridItems.add(const SizedBox());
    }
    
    // Add days
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDay = DateTime(_selectedPeriod.year, _selectedPeriod.month, i);
      final bool isToday = currentDay.year == _now.year && currentDay.month == _now.month && currentDay.day == _now.day;
      
      // Find history data for this day
      Color? dotColor;
      for (var item in _allHistoryData) {
        final d = item['rawDate'] as DateTime?;
        if (d != null && d.year == currentDay.year && d.month == currentDay.month && d.day == currentDay.day) {
           dotColor = item['dotColor'] as Color?;
           break;
        }
      }
      
      gridItems.add(
        Container(
           margin: const EdgeInsets.all(4),
           decoration: isToday ? BoxDecoration(
             color: const Color(0xFFF1F5F9),
             borderRadius: BorderRadius.circular(8),
           ) : null,
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text(
                 '$i',
                 style: TextStyle(
                   fontSize: 13,
                   fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                   color: isToday ? const Color(0xFF0F172A) : Colors.black87,
                 ),
               ),
               const SizedBox(height: 4),
               Container(
                 width: 6,
                 height: 6,
                 decoration: BoxDecoration(
                   color: dotColor ?? Colors.transparent,
                   shape: BoxShape.circle,
                 ),
               ),
             ],
           ),
        ),
      );
    }
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.0,
      children: gridItems,
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(const Color(0xFF10B981), 'Hadir'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFFF59E0B), 'Terlambat'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFF3B82F6), 'Izin/Cuti'),
        const SizedBox(width: 12),
        _buildLegendItem(const Color(0xFF94A3B8), 'Alpha'),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('Hadir', '$_countHadir hari', const Color(0xFFDCFCE7), const Color(0xFF15803D))),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Terlambat', '$_countTerlambat hari', const Color(0xFFFFEDD5), const Color(0xFFC2410C))),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Izin', '$_countIzin hari', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8))),
        const SizedBox(width: 8),
        Expanded(child: _buildSummaryCard('Cuti', '$_countCuti hari', const Color(0xFFDBEAFE), const Color(0xFF1D4ED8))),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: textColor)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: _buildDropdown(
            value: _formatMonth(_selectedPeriod),
            items: _periodOptions.map(_formatMonth).toList(),
            onChanged: (val) async {
              final index = _periodOptions.map(_formatMonth).toList().indexOf(val!);
              if (index < 0) return;
              setState(() {
                _selectedPeriod = _periodOptions[index];
                _isLoading = true;
              });
              await _fetchHistoryData();
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildDropdown(
            value: _selectedStatus,
            items: ['Semua Status', 'On Time', 'Terlambat', 'Izin'],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.w500),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchHistoryData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
            child: const Text('Coba Lagi', style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final DateTime oneWeekAgo = DateTime(_now.year, _now.month, _now.day).subtract(const Duration(days: 7));
    
    final filteredData = _allHistoryData.where((item) {
      // Filter by Month and Status
      final matchesMonth = item['month'] == _formatMonth(_selectedPeriod);
      final matchesStatus = _selectedStatus == 'Semua Status' || item['statusCategory'] == _selectedStatus;
      
      // Filter by 1-Week rule (Only show past 7 days)
      final DateTime? d = item['rawDate'] as DateTime?;
      bool matchesWeek = false;
      if (d != null) {
         final pureDate = DateTime(d.year, d.month, d.day);
         if (pureDate.isAfter(oneWeekAgo) || pureDate.isAtSameMomentAs(oneWeekAgo)) {
           matchesWeek = true;
         }
      }
      
      return matchesMonth && matchesStatus && matchesWeek;
    }).toList();

    if (filteredData.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text('Tidak ada data riwayat presensi (1 minggu terakhir)', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      );
    }

    return Column(
      children: filteredData.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildAttendanceCard(
            absensi: item['absensi_model'] as Absensi,
            date: item['date'],
            statusText: item['statusText'],
            statusBgColor: item['statusBgColor'],
            statusTextColor: item['statusTextColor'],
            checkIn: item['checkIn'],
            checkOut: item['checkOut'],
            duration: item['duration'],
            hasDetailButton: item['hasDetailButton'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceCard({
    required Absensi absensi,
    required String date,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String checkIn,
    required String checkOut,
    required String duration,
    bool hasDetailButton = false,
  }) {
    return Container(
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
              Text(
                date,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusBgColor, borderRadius: BorderRadius.circular(6)),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusTextColor, fontWeight: FontWeight.bold, fontSize: 9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Masuk', checkIn),
              _buildTimeColumn('Pulang', checkOut),
              _buildTimeColumn('Durasi', duration),
            ],
          ),
          if (hasDetailButton) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DetailLogScreen(absensi: absensi)),
                  );
                  _fetchHistoryData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Detail Log', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
