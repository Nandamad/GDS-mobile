import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'detail_approval_page.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _cutiList = [];
  List<Map<String, dynamic>> _lemburList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchPendingApprovals();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchPendingApprovals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiService().dio;
      final response = await dio.get('/approval/pending');

      if (response.statusCode == 200) {
        final payload = response.data;
        final data = payload is Map && payload['data'] is List
            ? payload['data']
            : payload is List
                ? payload
                : [];

        final cuti = <Map<String, dynamic>>[];
        final lembur = <Map<String, dynamic>>[];

        for (final item in data) {
          final map = Map<String, dynamic>.from(item);
          final type = (map['type'] ?? map['jenis_pengajuan'] ?? '')
              .toString()
              .toLowerCase();

          if (type == 'lembur') {
            lembur.add(map);
          } else {
            cuti.add(map);
          }
        }

        if (mounted) {
          setState(() {
            _cutiList = cuti;
            _lemburList = lembur;
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data?['message']?.toString() ??
              'Gagal mengambil data approval.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan saat mengambil data.';
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // FORMAT HELPERS
  // ============================================================

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _getKaryawanName(Map<String, dynamic> data) {
    return data['karyawan']?['nama'] ??
        data['karyawan_nama'] ??
        data['nama_karyawan'] ??
        data['user']?['name'] ??
        'Karyawan';
  }

  String _getCutiDateRange(Map<String, dynamic> data) {
    final mulai = _formatDate(data['tanggal_mulai']);
    final selesai = _formatDate(data['tanggal_selesai']);
    if (mulai == selesai) return mulai;
    return '$mulai - $selesai';
  }

  String _getLemburDateRange(Map<String, dynamic> data) {
    final tanggal = _formatDate(data['tanggal']);
    final mulai = data['jam_mulai_lembur']?.toString().substring(0, 5) ?? '-';
    final selesai =
        data['jam_selesai_lembur']?.toString().substring(0, 5) ?? '-';
    return '$tanggal, $mulai - $selesai';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
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
          'Perlu Persetujuan Saya',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF009688),
          labelColor: const Color(0xFF009688),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'Cuti / Izin (${_cutiList.length})'),
            Tab(text: 'Lembur (${_lemburList.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.grey, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _fetchPendingApprovals,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildList(_cutiList, isCuti: true),
                    _buildList(_lemburList, isCuti: false),
                  ],
                ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items,
      {required bool isCuti}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCuti ? Icons.beach_access_outlined : Icons.timer_off_outlined,
              color: Colors.grey.shade300,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              isCuti
                  ? 'Tidak ada pengajuan cuti/izin\nyang menunggu persetujuan.'
                  : 'Tidak ada pengajuan lembur\nyang menunggu persetujuan.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF009688),
      onRefresh: _fetchPendingApprovals,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildApprovalCard(item, isCuti: isCuti);
        },
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> item,
      {required bool isCuti}) {
    final nama = _getKaryawanName(item);
    final jenis = isCuti
        ? _capitalize(item['jenis']?.toString() ?? 'Cuti')
        : 'Lembur';
    final dateRange =
        isCuti ? _getCutiDateRange(item) : _getLemburDateRange(item);
    final alasan = item['alasan']?.toString() ?? '-';
    final diajukan = _formatDate(item['created_at']);

    final badgeBg =
        isCuti ? const Color(0xFFE0F2F1) : const Color(0xFFFEF3C7);
    final badgeText =
        isCuti ? const Color(0xFF009688) : const Color(0xFFD97706);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => DetailApprovalScreen(
              data: item,
              type: isCuti ? 'cuti' : 'lembur',
            ),
          ),
        );
        if (result == true) {
          _fetchPendingApprovals();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris atas: Nama + Badge jenis
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    jenis,
                    style: TextStyle(
                      color: badgeText,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Tanggal range
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  dateRange,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Alasan (ringkas)
            Row(
              children: [
                const Icon(Icons.notes_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    alasan,
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Diajukan tanggal
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Diajukan: $diajukan',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
