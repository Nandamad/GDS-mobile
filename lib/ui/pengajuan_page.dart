import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../ui/ajukan_cuti_page.dart';
import '../ui/ajukan_lembur_page.dart';
import '../ui/detail_workflow_page.dart';

List<Map<String, dynamic>> normalizeSubmissionList(
  dynamic body, {
  String? preferredKey,
}) {
  if (body == null) {
    return const [];
  }

  if (body is List) {
    return body
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  if (body is Map) {
    final itemMap = Map<String, dynamic>.from(body);
    final candidateKeys = [
      preferredKey,
      'data',
      'items',
      'result',
      'records',
      'pengajuan',
      'cuti',
      'lembur',
    ];

    for (final key in candidateKeys) {
      if (key == null || !itemMap.containsKey(key)) {
        continue;
      }

      final value = itemMap[key];
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      if (value is Map) {
        final nested = value['data'] ?? value['items'] ?? value['records'];
        if (nested is List) {
          return nested
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }
    }

    final directSubmission =
        itemMap.containsKey('id') ||
        itemMap.containsKey('tanggal') ||
        itemMap.containsKey('tanggal_mulai') ||
        itemMap.containsKey('jam_mulai_lembur');

    if (directSubmission) {
      return [itemMap];
    }
  }

  return const [];
}

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  int _selectedFilter = 0;

  bool _isLoading = true;
  String _errorMessage = '';

  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  // ============================================================
  // FETCH DATA
  // ============================================================

  Future<void> _fetchHistory() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }

    try {
      final token = await ApiService().getToken();

      if (token == null) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
          _errorMessage = 'Token login tidak ditemukan.';
        });

        return;
      }

      final dio = ApiService().dio;

      final List<Map<String, dynamic>> result = [];

      // ----------------------------------------------------------
      // CUTI
      // ----------------------------------------------------------

      try {
        final response = await dio.get('/cuti');

        final body = response.data;
        final entries = normalizeSubmissionList(body, preferredKey: 'data');

        for (final item in entries) {
          final raw = Map<String, dynamic>.from(item);

          result.add({
            'id': raw['id'],
            'type': 'Cuti/Izin',
            'rawData': raw,
            'title': _getCutiTitle(raw),
            'badgeText': _getJenisCuti(raw),
            'badgeBgColor': const Color(0xFFE0F2FE),
            'badgeTextColor': const Color(0xFF0284C7),
            'statusText': _getCutiStatus(raw),
            'dateRange': _getCutiDateRange(raw),
            'submittedDate': 'Diajukan: ${_formatDate(raw['created_at'])}',
            'sortDate': _parseDate(raw['created_at']),
          });
        }
      } on DioException catch (e) {
        debugPrint('GET /cuti ERROR: ${e.response?.data}');
      }

      // ----------------------------------------------------------
      // LEMBUR
      // ----------------------------------------------------------

      try {
        final response = await dio.get('/lembur');

        final body = response.data;
        final entries = normalizeSubmissionList(body, preferredKey: 'data');

        for (final item in entries) {
          final raw = Map<String, dynamic>.from(item);

          result.add({
            'id': raw['id'],
            'type': 'Lembur',
            'rawData': raw,
            'title': _getLemburTitle(raw),
            'badgeText': 'Lembur',
            'badgeBgColor': const Color(0xFFFEF3C7),
            'badgeTextColor': const Color(0xFFD97706),
            'statusText': _getLemburStatus(raw),
            'dateRange': _getLemburDateRange(raw),
            'submittedDate': 'Diajukan: ${_formatDate(raw['created_at'])}',
            'sortDate': _parseDate(raw['created_at']),
          });
        }
      } on DioException catch (e) {
        debugPrint('GET /lembur ERROR: ${e.response?.data}');
      }

      // ----------------------------------------------------------
      // SORT TERBARU
      // ----------------------------------------------------------

      result.sort((a, b) {
        final aDate = a['sortDate'] as DateTime;

        final bDate = b['sortDate'] as DateTime;

        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        _history
          ..clear()
          ..addAll(result);

        _isLoading = false;

        if (result.isEmpty) {
          _errorMessage = 'Belum ada data pengajuan.';
        }
      });
    } on DioException catch (e) {
      debugPrint('PENGAJUAN ERROR: ${e.response?.data}');

      String message = 'Gagal mengambil data pengajuan.';

      if (e.response?.statusCode == 401) {
        message = 'Sesi login sudah berakhir.';
      }

      if (!mounted) return;

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PENGAJUAN ERROR: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Terjadi kesalahan saat mengambil data.';
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // DETAIL WORKFLOW
  // ============================================================

  void _openDetailWorkflow(Map<String, dynamic> item) {
    final raw = item['rawData'];

    if (raw is! Map) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data pengajuan tidak ditemukan.')),
      );

      return;
    }

    final data = Map<String, dynamic>.from(raw);

    final type = item['type']?.toString() ?? 'Cuti/Izin';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return DetailWorkflowScreen(data: data, type: type);
        },
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _normalizeStatus(dynamic value) {
    if (value == null) return '';

    return value.toString().trim().toLowerCase().replaceAll(' ', '_');
  }

  bool _isApproved(dynamic value) {
    final status = _normalizeStatus(value);

    return status == 'disetujui' || status == 'approved' || status == 'approve';
  }

  bool _isRejected(dynamic value) {
    final status = _normalizeStatus(value);

    return status == 'ditolak' || status == 'rejected' || status == 'reject';
  }

  String _getCutiStatus(Map<String, dynamic> data) {
    final status = data['status'];

    final atasan = data['status_verifikasi_atasan'];

    final hrd = data['status_verifikasi_hrd'];

    if (_isRejected(status) || _isRejected(atasan) || _isRejected(hrd)) {
      return 'Ditolak';
    }

    if (_isApproved(status) && _isApproved(atasan) && _isApproved(hrd)) {
      return 'Disetujui';
    }

    if (_isApproved(atasan)) {
      return 'L1 Disetujui, L2 Pending';
    }

    return 'Pending Approval L1';
  }

  String _getLemburStatus(Map<String, dynamic> data) {
    final l1 = data['status_approval_level1'];

    final l2 = data['status_approval_level2'];

    final finalStatus = data['status_final'];

    if (_isRejected(l1) || _isRejected(l2) || _isRejected(finalStatus)) {
      return 'Ditolak';
    }

    if (_isApproved(l1) && _isApproved(l2) && _isApproved(finalStatus)) {
      return 'Disetujui';
    }

    if (_isApproved(l1)) {
      return 'L1 Disetujui, L2 Pending';
    }

    return 'Pending Approval L1';
  }

  // ============================================================
  // CUTI
  // ============================================================

  String _getJenisCuti(Map<String, dynamic> data) {
    final jenis = data['jenis']?.toString().toLowerCase() ?? 'cuti';

    if (jenis == 'izin') {
      return 'Izin';
    }

    if (jenis == 'sakit') {
      return 'Sakit';
    }

    return 'Cuti';
  }

  String _getCutiTitle(Map<String, dynamic> data) {
    final jenis = _capitalize(data['jenis']?.toString() ?? 'Cuti');

    final hari = _calculateDays(data);

    return '$jenis - $hari Hari';
  }

  String _getCutiDateRange(Map<String, dynamic> data) {
    final mulai = _formatDate(data['tanggal_mulai']);

    final selesai = _formatDate(data['tanggal_selesai']);

    if (mulai == selesai) {
      return mulai;
    }

    return '$mulai - $selesai';
  }

  int _calculateDays(Map<String, dynamic> data) {
    try {
      final mulai = DateTime.parse(data['tanggal_mulai'].toString());

      final selesai = DateTime.parse(data['tanggal_selesai'].toString());

      return selesai.difference(mulai).inDays + 1;
    } catch (_) {
      return 1;
    }
  }

  // ============================================================
  // LEMBUR
  // ============================================================

  String _getLemburTitle(Map<String, dynamic> data) {
    final menit =
        int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;

    final jam = menit ~/ 60;
    final sisa = menit % 60;

    if (sisa == 0) {
      return '$jam Jam Lembur';
    }

    return '$jam Jam $sisa Menit Lembur';
  }

  String _getLemburDateRange(Map<String, dynamic> data) {
    final tanggal = _formatDate(data['tanggal']);

    final mulai = _formatTime(data['jam_mulai_lembur']);

    final selesai = _formatTime(data['jam_selesai_lembur']);

    return '$tanggal, $mulai - $selesai';
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];

      return '${date.day.toString().padLeft(2, '0')} '
          '${months[date.month - 1]} '
          '${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.contains(':')) {
      final parts = text.split(':');

      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:'
            '${parts[1].padLeft(2, '0')}';
      }
    }

    return text;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) {
      return DateTime(2000);
    }

    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime(2000);
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;

    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Text(
          'Pengajuan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF009688)),
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _fetchHistory,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

          children: [
            InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AjukanCutiScreen(),
                  ),
                );

                if (mounted && result == true) {
                  _fetchHistory();
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ajukan Cuti',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sakit, cuti tahunan, atau izin pribadi',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Riwayat Pengajuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 12),


            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF009688)),
                ),
              )
            else if (_errorMessage.isNotEmpty)
              _buildError()
            else
              _buildHistoryList(),
          ],
        ),
      ),
    );
  }


  // ============================================================
  // HISTORY
  // ============================================================

  Widget _buildHistoryList() {
    final filtered = _history; // Show all since filter is removed

    if (filtered.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(
          child: Text(
            'Tidak ada riwayat pengajuan',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: filtered.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildHistoryCard(item),
        );
      }).toList(),
    );
  }

  // ============================================================
  // HISTORY CARD
  // ============================================================

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['statusText']?.toString() ?? 'Pending';

    Color statusBg;
    Color statusColor;

    if (status == 'Disetujui') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF15803D);
    } else if (status == 'Ditolak') {
      statusBg = const Color(0xFFFEE2E2);
      statusColor = const Color(0xFFDC2626);
    } else {
      statusBg = const Color(0xFFFFEDD5);
      statusColor = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item['badgeBgColor'] as Color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item['badgeText']?.toString() ?? '',
                  style: TextStyle(
                    color: item['badgeTextColor'] as Color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item['title']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['dateRange']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['submittedDate']?.toString() ?? '-',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  _openDetailWorkflow(item);
                },
                child: const Text(
                  'Detail Workflow >',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF009688),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(30),

      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),

          const SizedBox(height: 8),

          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),

          const SizedBox(height: 10),

          ElevatedButton(
            onPressed: _fetchHistory,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}
