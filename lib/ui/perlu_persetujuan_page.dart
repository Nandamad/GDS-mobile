import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'detail_approval_page.dart';

class PerluPersetujuanScreen extends StatefulWidget {
  const PerluPersetujuanScreen({super.key});

  @override
  State<PerluPersetujuanScreen> createState() => _PerluPersetujuanScreenState();
}

class _PerluPersetujuanScreenState extends State<PerluPersetujuanScreen> {
  List<Map<String, dynamic>> _cutiList = [];
  List<Map<String, dynamic>> _lemburList = [];
  List<Map<String, dynamic>> _kunjunganList = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovals();
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
        dynamic data = payload;
        if (payload is Map) {
          data = payload['data'] ?? payload['items'] ?? payload['result'] ?? [];
          if (data is Map) {
            if (data['cuti'] is List || data['lembur'] is List) {
              data = [
                ...(data['cuti'] is List ? data['cuti'] as List : const []),
                ...(data['lembur'] is List ? data['lembur'] as List : const []),
              ];
            } else {
              data = data['data'] ?? data['items'] ?? data['records'] ?? [];
            }
          }
        }
        if (data is! List) data = [];

        final cuti = <Map<String, dynamic>>[];
        final lembur = <Map<String, dynamic>>[];
        final kunjungan = <Map<String, dynamic>>[];

        for (final item in data) {
          final map = Map<String, dynamic>.from(item);
          final type = (map['type'] ?? map['jenis_pengajuan'] ?? '').toString().toLowerCase();

          if (type == 'lembur') {
            lembur.add(map);
          } else if (type == 'kunjungan') {
            kunjungan.add(map);
          } else {
            cuti.add(map);
          }
        }

        if (mounted) {
          setState(() {
            _cutiList = cuti;
            _lemburList = lembur;
            _kunjunganList = kunjungan;
            _isLoading = false;
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengambil data approval.';
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

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
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
  
  String _getPosisi(Map<String, dynamic> data) {
    return data['karyawan']?['jabatan'] ?? 
           data['posisi'] ?? 
           'Karyawan';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // --- CUTI HELPERS ---

  String _getCutiDateRange(Map<String, dynamic> data) {
    final mulai = _formatDate(data['tanggal_mulai']);
    final selesai = _formatDate(data['tanggal_selesai']);
    if (mulai == selesai) return mulai;
    
    try {
      final dMulai = DateTime.parse(data['tanggal_mulai'].toString());
      final dSelesai = DateTime.parse(data['tanggal_selesai'].toString());
      if (dMulai.month == dSelesai.month && dMulai.year == dSelesai.year) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
        return '${dMulai.day} - ${dSelesai.day} ${months[dMulai.month - 1]} ${dMulai.year}';
      }
    } catch (_) {}

    return '$mulai - $selesai';
  }

  String _getCutiDuration(Map<String, dynamic> data) {
    int days = 1;
    if (data['jumlah_hari'] != null) {
      days = int.tryParse(data['jumlah_hari'].toString()) ?? 1;
    } else if (data['jumlah_hari_kerja'] != null) {
      days = int.tryParse(data['jumlah_hari_kerja'].toString()) ?? 1;
    } else {
      try {
        final mulai = DateTime.parse(data['tanggal_mulai'].toString());
        final selesai = DateTime.parse(data['tanggal_selesai'].toString());
        days = selesai.difference(mulai).inDays + 1;
      } catch (_) {}
    }
    return '$days Hari';
  }

  // --- LEMBUR HELPERS ---

  String _getLemburDateRange(Map<String, dynamic> data) {
    return _formatDate(data['tanggal']);
  }
  
  String _getLemburTime(Map<String, dynamic> data) {
    final mulai = data['jam_mulai_lembur']?.toString().substring(0, 5) ?? '-';
    final selesai = data['jam_selesai_lembur']?.toString().substring(0, 5) ?? '-';
    return '$mulai - $selesai';
  }

  String _getLemburDuration(Map<String, dynamic> data) {
     final menit = int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;
     final jam = menit ~/ 60;
     return '$jam Jam';
  }

  // --- BUILDERS ---

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCutiCard(Map<String, dynamic> item) {
    final nama = _getKaryawanName(item);
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final posisi = _getPosisi(item);
    
    final tipe = _capitalize(item['jenis']?.toString() ?? 'Cuti Tahunan');
    final tanggal = _getCutiDateRange(item);
    final durasi = _getCutiDuration(item);
    final alasan = item['alasan']?.toString() ?? '-';

    final isMedis = tipe.toLowerCase().contains('sakit') || tipe.toLowerCase().contains('medis');
    final badgeBg = isMedis ? const Color(0xFFDCFCE7) : Colors.grey.shade100;
    final badgeColor = isMedis ? const Color(0xFF15803D) : const Color(0xFF475569);

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F2F1),
                radius: 20,
                child: Text(
                  inisial,
                  style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      posisi,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tipe Cuti', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tipe,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rentang Tanggal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(tanggal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Durasi Pengajuan', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(durasi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Alasan Cuti', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(alasan, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailApprovalScreen(data: item, type: 'cuti'),
                  ),
                );
                if (result == true) _fetchPendingApprovals();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Detail', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLemburCard(Map<String, dynamic> item) {
    final nama = _getKaryawanName(item);
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final posisi = _getPosisi(item);
    final tanggal = _getLemburDateRange(item);
    final durasi = _getLemburDuration(item);
    final waktu = _getLemburTime(item);
    final alasan = item['alasan']?.toString() ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F2F1),
                radius: 20,
                child: Text(
                  inisial,
                  style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      posisi,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tanggal Lembur', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(tanggal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rencana Durasi', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('$durasi ($waktu)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Alasan Lembur', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(alasan, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailApprovalScreen(data: item, type: 'lembur'),
                  ),
                );
                if (result == true) _fetchPendingApprovals();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Detail', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKunjunganCard(Map<String, dynamic> item) {
    final nama = _getKaryawanName(item);
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final posisi = _getPosisi(item);
    final klien = item['nama_klien']?.toString() ?? '-';
    final tanggal = _formatDate(item['tanggal']);
    final tujuan = item['tujuan_kunjungan']?.toString() ?? '-';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE0F2F1),
                radius: 20,
                child: Text(
                  inisial,
                  style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      posisi,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Klien', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(klien, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tanggal', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(tanggal, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Tujuan', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(tujuan, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailApprovalScreen(data: item, type: 'kunjungan'),
                  ),
                );
                if (result == true) _fetchPendingApprovals();
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Detail', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, Widget Function(Map<String, dynamic>) builder, String emptyMessage, IconData emptyIcon) {
    if (list.isEmpty) {
      return _buildEmptyState(emptyMessage, emptyIcon);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return builder(list[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Perlu Persetujuan Saya',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            labelColor: const Color(0xFF009688),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF009688),
            tabs: [
              Tab(text: 'Cuti / Izin (${_cutiList.length})'),
              Tab(text: 'Lembur (${_lemburList.length})'),
              Tab(text: 'Kunjungan (${_kunjunganList.length})'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
            : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : TabBarView(
                    children: [
                      // Cuti / Izin
                      _buildList(
                        _cutiList,
                        _buildCutiCard,
                        'Tidak ada pengajuan cuti/izin\nyang menunggu persetujuan.',
                        Icons.beach_access_outlined,
                      ),
                      // Lembur
                      _buildList(
                        _lemburList,
                        _buildLemburCard,
                        'Tidak ada pengajuan lembur\nyang menunggu persetujuan.',
                        Icons.access_time,
                      ),
                      // Kunjungan
                      _buildList(
                        _kunjunganList,
                        _buildKunjunganCard, 
                        'Tidak ada pengajuan kunjungan\nyang menunggu persetujuan.',
                        Icons.map_outlined,
                      ),
                    ],
                  ),
      ),
    );
  }
}
