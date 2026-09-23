import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/absensi.dart';
import '../services/api_service.dart';
import 'detail_log_page.dart';
import 'detail_workflow_page.dart';
import 'detail_kunjungan_page.dart';
import 'detail_koreksi_page.dart';

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

  final List<String> _filterOptions = [
    'Semua',
    'Presensi',
    'Cuti & Izin',
    'Lembur',
    'Perjalanan Dinas',
    'Pengajuan Koreksi',
  ];

  @override
  void initState() {
    super.initState();
    _selectedPeriod = DateTime(_now.year, _now.month);
    _fetchData();
  }

  static const _monthNames = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
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

      // Fetch others
      final lemburRes = await dio.get('/lembur');
      final kunjunganRes = await dio.get('/kunjungan');
      final koreksiRes = await dio.get('/koreksi-presensi');

      if (historyRes.statusCode == 200) {
        final List<dynamic> historyData = historyRes.data['data'] ?? [];
        final List<dynamic> lemburData = lemburRes.statusCode == 200
            ? (lemburRes.data['data'] ?? [])
            : [];
        final List<dynamic> kunjunganData = kunjunganRes.statusCode == 200
            ? (kunjunganRes.data['data'] ?? [])
            : [];
        final List<dynamic> koreksiData = koreksiRes.statusCode == 200
            ? (koreksiRes.data['data'] ?? [])
            : [];

        // Map lembur by date (YYYY-MM-DD)
        final Map<String, dynamic> lemburMap = {};
        for (var l in lemburData) {
          if (l['tanggal'] != null) {
            lemburMap[l['tanggal']] = l;
          }
        }

        List<Map<String, dynamic>> parsedData = [];

        // 1. Parse History
        for (var item in historyData) {
          final absensiObj = Absensi.fromJson(item);
          final tipe = item['tipe'] as String? ?? 'Kehadiran';
          final rawStatus = (absensiObj.status ?? item['status'] ?? 'hadir')
              .toString()
              .toLowerCase();

          Color bgColor = const Color(0xFFD1FAE5);
          Color txtColor = const Color(0xFF059669);
          String statusTxt = 'Hadir';

          if (tipe == 'Lembur') {
            statusTxt = 'Lembur';
            bgColor = const Color(0xFFF3E8FF);
            txtColor = const Color(0xFF7E22CE);
          } else if (tipe != 'Kehadiran') {
            statusTxt = 'Izin';
            bgColor = const Color(0xFFDBEAFE);
            txtColor = const Color(0xFF2563EB);
            if (rawStatus.contains('cuti')) {
              statusTxt = 'Cuti';
            }
          } else if (rawStatus.contains('terlambat') ||
              rawStatus.contains('late') ||
              rawStatus.contains('pulang_awal') ||
              rawStatus.contains('pulang awal')) {
            statusTxt = 'Terlambat';
            bgColor = const Color(0xFFFEF3C7);
            txtColor = const Color(0xFFD97706);
          } else if (rawStatus.contains('tidak_absen') ||
              rawStatus.contains('alpha') ||
              rawStatus.contains('tidak hadir')) {
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

          parsedData.add({
            'type': 'history',
            'rawDate': tanggal,
            'statusText': statusTxt,
            'statusBgColor': bgColor,
            'statusTextColor': txtColor,
            'checkIn': _formatTime(absensiObj.jamMasuk),
            'checkOut': _formatTime(absensiObj.jamPulang),
            'durasi':
                absensiObj.jamMasuk != null && absensiObj.jamPulang != null
                ? '${absensiObj.jamPulang!.difference(absensiObj.jamMasuk!).inHours}j ${absensiObj.jamPulang!.difference(absensiObj.jamMasuk!).inMinutes.remainder(60)}m'
                : null,
            'lemburJam': lemburJam,
            'raw_data': item,
            'tipe': tipe,
            'absensi': absensiObj,
          });
        }

        // 2. Parse Kunjungan (Filter locally by month/year)
        for (var k in kunjunganData) {
          try {
            final dtStr = k['tanggal']?.toString() ?? '';
            if (dtStr.isNotEmpty) {
              final dt = DateTime.parse(dtStr).toLocal();
              if (dt.month == _selectedPeriod.month && dt.year == _selectedPeriod.year) {
                parsedData.add({
                  'type': 'kunjungan',
                  'rawDate': dt,
                  'raw_data': k,
                });
              }
            }
          } catch (_) {}
        }

        // 3. Parse Koreksi (Filter locally by month/year)
        for (var k in koreksiData) {
          try {
            final dtStr = k['tanggal']?.toString() ?? '';
            if (dtStr.isNotEmpty) {
              final dt = DateTime.parse(dtStr).toLocal();
              if (dt.month == _selectedPeriod.month && dt.year == _selectedPeriod.year) {
                parsedData.add({
                  'type': 'koreksi',
                  'rawDate': dt,
                  'raw_data': k,
                });
              }
            }
          } catch (_) {}
        }

        // Sort descending
        parsedData.sort((a, b) {
          final da = a['rawDate'] as DateTime?;
          final db = b['rawDate'] as DateTime?;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return db.compareTo(da);
        });

        if (mounted) {
          setState(() {
            _allHistoryData = parsedData;
            _isLoading = false;
            _errorMessage = null;
          });
        }
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
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF0F172A),
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Histori Absensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            )
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
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  onChanged: (val) {
                    final index = _periodOptions
                        .map(_formatMonth)
                        .toList()
                        .indexOf(val!);
                    if (index < 0) return;
                    setState(() {
                      _selectedPeriod = _periodOptions[index];
                      _isLoading = true;
                    });
                    _fetchData();
                  },
                  items: _periodOptions.map((date) {
                    final str = _formatMonth(date);
                    return DropdownMenuItem<String>(
                      value: str,
                      child: Text(str),
                    );
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF009688)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF009688)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
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
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    final filteredData = _allHistoryData.where((item) {
      if (_selectedStatus == 'Semua') return true;
      if (_selectedStatus == 'Lembur') {
        return item['type'] == 'history' && (item['lemburJam'] as String?)?.isNotEmpty == true;
      }
      if (_selectedStatus == 'Presensi') {
        return item['type'] == 'history' && (item['statusText'] == 'Hadir' || item['statusText'] == 'Terlambat' || item['statusText'] == 'Alpha' || item['statusText'] == 'Pending'); 
      }
      if (_selectedStatus == 'Cuti & Izin') {
        return item['type'] == 'history' && (item['statusText'] == 'Cuti' || item['statusText'] == 'Izin');
      }
      if (_selectedStatus == 'Perjalanan Dinas') {
        return item['type'] == 'kunjungan';
      }
      if (_selectedStatus == 'Pengajuan Koreksi') {
        return item['type'] == 'koreksi';
      }
      return false;
    }).toList();

    if (filteredData.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data absensi',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      itemBuilder: (context, index) {
        final item = filteredData[index];
        final type = item['type'];

        if (type == 'kunjungan') {
            final raw = item['raw_data'];
            final status = raw['status_final']?.toString().toLowerCase() ?? '';
            Color badgeBg = Colors.grey.shade200;
            Color badgeText = Colors.grey.shade800;
            String badgeStr = 'Pending';
            if (status == 'approved' || status == 'disetujui') {
               badgeBg = const Color(0xFFD1FAE5);
               badgeText = const Color(0xFF059669);
               badgeStr = 'Disetujui';
            } else if (status == 'rejected' || status == 'ditolak') {
               badgeBg = const Color(0xFFFEE2E2);
               badgeText = const Color(0xFFDC2626);
               badgeStr = 'Ditolak';
            }

            return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                   children: [
                      Row(
                         children: [
                            Container(
                               width: 48,
                               height: 48,
                               decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                               child: const Icon(Icons.directions_car, color: Color(0xFF009688)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                               child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     Text(raw['judul'] ?? 'Perjalanan Dinas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                     const SizedBox(height: 4),
                                     Text('Tujuan: ${raw['tujuan'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ]
                               )
                            ),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                               child: Text(badgeStr, style: TextStyle(fontSize: 11, color: badgeText, fontWeight: FontWeight.bold)),
                            )
                         ]
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                         width: double.infinity,
                         child: OutlinedButton(
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => DetailKunjunganScreen(data: raw)));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF009688),
                              side: const BorderSide(color: Color(0xFF009688)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Detail Perjalanan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                         )
                      )
                   ]
                )
            );
        }

        if (type == 'koreksi') {
            final raw = item['raw_data'];
            final status = raw['status']?.toString().toLowerCase() ?? '';
            Color badgeBg = const Color(0xFFFEF9C3);
            Color badgeText = const Color(0xFFA16207);
            String badgeStr = 'Pending';
            if (status == 'approved' || status == 'disetujui') {
               badgeBg = const Color(0xFFD1FAE5);
               badgeText = const Color(0xFF059669);
               badgeStr = 'Disetujui';
            } else if (status == 'rejected' || status == 'ditolak') {
               badgeBg = const Color(0xFFFEE2E2);
               badgeText = const Color(0xFFDC2626);
               badgeStr = 'Ditolak';
            }

            return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                   children: [
                      Row(
                         children: [
                            Container(
                               width: 48,
                               height: 48,
                               decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade200)),
                               child: const Icon(Icons.edit_calendar, color: Color(0xFF009688)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                               child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                     const Text('Koreksi Presensi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                     const SizedBox(height: 4),
                                     Text('Masuk: ${raw['jam_masuk_baru'] ?? '-'} | Pulang: ${raw['jam_pulang_baru'] ?? '-'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ]
                               )
                            ),
                            Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                               decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                               child: Text(badgeStr, style: TextStyle(fontSize: 11, color: badgeText, fontWeight: FontWeight.bold)),
                            )
                         ]
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                         width: double.infinity,
                         child: OutlinedButton(
                            onPressed: () {
                               Navigator.push(context, MaterialPageRoute(builder: (context) => DetailKoreksiScreen(data: raw)));
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF009688),
                              side: const BorderSide(color: Color(0xFF009688)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Detail Koreksi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                         )
                      )
                   ]
                )
            );
        }

        // History Type
        final date = item['rawDate'] as DateTime?;
        final hariStr = date != null
            ? ['MIN', 'SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB'][date.weekday %
                  7]
            : '-';
        final tanggalStr = date != null
            ? date.day.toString().padLeft(2, '0')
            : '-';

        final checkIn = item['checkIn'];
        final checkOut = item['checkOut'];
        final timeStr = (checkIn == '- - -' && checkOut == '- - -')
            ? '- - -'
            : '$checkIn - $checkOut';

        final hasLembur = (item['lemburJam'] as String).isNotEmpty;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              Row(
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
                        Text(
                          hariStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tanggalStr,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Center Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Masuk / Pulang',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item['durasi'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Durasi Kerja: ${item['durasi']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (hasLembur) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Lembur: ${item['lemburJam']}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF009688),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    if (item['tipe'] == 'Kehadiran' ||
                        item['statusText'] == 'Hadir' ||
                        item['statusText'] == 'Terlambat' ||
                        item['statusText'] == 'Alpha') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailLogScreen(absensi: item['absensi']),
                        ),
                      );
                    } else if (item['tipe'] == 'Cuti' ||
                        item['statusText'] == 'Cuti' ||
                        item['statusText'] == 'Izin' ||
                        item['tipe'] == 'Lembur' ||
                        item['statusText'] == 'Lembur') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailWorkflowScreen(
                            data: item['raw_data'],
                            type: item['tipe'] ?? 'Cuti',
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              DetailLogScreen(absensi: item['absensi']),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF009688),
                    side: const BorderSide(color: Color(0xFF009688)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Detail ${item['tipe'] == 'Kehadiran' ? 'Log' : item['tipe']}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
