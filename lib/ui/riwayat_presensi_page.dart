import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../model/absensi.dart';
import 'package:intl/intl.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  final bool showBackButton;
  const RiwayatPresensiScreen({super.key, this.showBackButton = false});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  final DateTime _now = DateTime.now();
  late DateTime _selectedPeriod;
  String _selectedStatus = 'Semua';

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _allHistoryData = [];
  
  final List<String> _filterOptions = ['Semua', 'Hadir', 'Terlambat', 'Izin', 'Lembur', 'Alpha'];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = DateTime(_now.year, _now.month);
    _fetchData();
  }

  static const _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  String _formatMonth(DateTime date) {
    return '${_monthNames[date.month - 1]} ${date.year}';
  }

  List<DateTime> get _periodOptions =>
      List.generate(12, (index) => DateTime(_now.year, _now.month - index));

  String _formatTime(DateTime? date) {
    if (date == null) return '- - -';
    final localDate = date.toLocal(); 
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _fetchData() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;
      
      // Fetch History
      final historyRes = await dio.get(
        '/history',
        queryParameters: {
          'month': _selectedPeriod.month,
          'year': _selectedPeriod.year,
        },
      );

      // Fetch Lembur
      final lemburRes = await dio.get('/lembur');
      
      if (historyRes.statusCode == 200) {
        final List<dynamic> historyData = historyRes.data['data'] ?? [];
        final List<dynamic> lemburData = lemburRes.statusCode == 200 ? (lemburRes.data['data'] ?? []) : [];
        
        // Map lembur by date (YYYY-MM-DD)
        final Map<String, dynamic> lemburMap = {};
        for (var l in lemburData) {
          if (l['tanggal'] != null) {
            lemburMap[l['tanggal']] = l;
          }
        }

        final parsedData = historyData.map((item) {
          final absensiObj = Absensi.fromJson(item);
          final tipe = item['tipe'] as String? ?? 'Kehadiran';
          final rawStatus = (absensiObj.status ?? item['status'] ?? 'hadir').toString().toLowerCase();

          Color bgColor = const Color(0xFFD1FAE5);
          Color txtColor = const Color(0xFF059669);
          String statusTxt = 'Hadir';

          if (tipe != 'Kehadiran') {
            statusTxt = 'Izin';
            bgColor = const Color(0xFFDBEAFE);
            txtColor = const Color(0xFF2563EB);
            if (rawStatus.contains('cuti')) {
              statusTxt = 'Cuti';
            }
          } else if (rawStatus.contains('terlambat') || rawStatus.contains('late') || rawStatus.contains('pulang_awal') || rawStatus.contains('pulang awal')) {
            statusTxt = 'Terlambat';
            bgColor = const Color(0xFFFEF3C7);
            txtColor = const Color(0xFFD97706);
          } else if (rawStatus.contains('tidak_absen') || rawStatus.contains('alpha') || rawStatus.contains('tidak hadir')) {
            statusTxt = 'Alpha';
            bgColor = const Color(0xFFFEE2E2);
            txtColor = const Color(0xFFDC2626);
          } else if (rawStatus.contains('pending')) {
            statusTxt = 'Pending';
            bgColor = const Color(0xFFFEF9C3);
            txtColor = const Color(0xFFA16207);
          }

          final tanggal = absensiObj.tanggal?.toLocal();
          
          String lemburJam = '';
          if (tanggal != null) {
             final dateKey = DateFormat('yyyy-MM-dd').format(tanggal);
             if (lemburMap.containsKey(dateKey)) {
                final est = lemburMap[dateKey]['estimasi_jam'];
                if (est != null) {
                   lemburJam = '${est.toString()} Jam';
                }
             }
          }

          return {
            'rawDate': tanggal,
            'statusText': statusTxt,
            'statusBgColor': bgColor,
            'statusTextColor': txtColor,
            'checkIn': _formatTime(absensiObj.jamMasuk),
            'checkOut': _formatTime(absensiObj.jamPulang),
            'lemburJam': lemburJam,
          };
        }).toList();
        
        // Sort descending
        parsedData.sort((a, b) {
           final da = a['rawDate'] as DateTime?;
           final db = b['rawDate'] as DateTime?;
           if (da == null && db == null) return 0;
           if (da == null) return 1;
           if (db == null) return -1;
           return db.compareTo(da);
        });

        setState(() {
          _allHistoryData = parsedData;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (_allHistoryData.isEmpty) {
            _errorMessage = 'Gagal memuat riwayat absensi.';
          }
        });
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
        automaticallyImplyLeading: false,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Histori Absensi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: const Color(0xFF009688),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _errorMessage != null
                        ? _buildErrorView()
                        : _buildHistoryList(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _formatMonth(_selectedPeriod),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                  onChanged: (val) {
                    final index = _periodOptions.map(_formatMonth).toList().indexOf(val!);
                    if (index < 0) return;
                    setState(() {
                      _selectedPeriod = _periodOptions[index];
                      _isLoading = true;
                    });
                    _fetchData();
                  },
                  items: _periodOptions.map((date) {
                    final str = _formatMonth(date);
                    return DropdownMenuItem<String>(value: str, child: Text(str));
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedStatus == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedStatus = filter;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF009688) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : const Color(0xFF64748B),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(_errorMessage!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredData = _allHistoryData.where((item) {
      if (_selectedStatus == 'Semua') return true;
      if (_selectedStatus == 'Lembur') return (item['lemburJam'] as String).isNotEmpty;
      return item['statusText'] == _selectedStatus;
    }).toList();

    if (filteredData.isEmpty) {
      return const Center(
        child: Text('Tidak ada data absensi', style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final item = filteredData[index];
        final date = item['rawDate'] as DateTime?;
        final hariStr = date != null ? ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'][date.weekday % 7] : '-';
        final tanggalStr = date != null ? date.day.toString().padLeft(2, '0') : '-';
        
        final checkIn = item['checkIn'];
        final checkOut = item['checkOut'];
        final timeStr = (checkIn == '- - -' && checkOut == '- - -') ? '- - -' : '$checkIn - $checkOut';
        
        final hasLembur = (item['lemburJam'] as String).isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              // Date Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(hariStr, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    Text(tanggalStr, style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Center Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Masuk / Pulang', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
                    ),
                    if (hasLembur) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Lembur: ${item['lemburJam']}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF009688), fontWeight: FontWeight.w600),
                      ),
                    ]
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: item['statusBgColor'],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item['statusText'],
                  style: TextStyle(
                    fontSize: 11,
                    color: item['statusTextColor'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
