import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RiwayatLemburManagerScreen extends StatefulWidget {
  const RiwayatLemburManagerScreen({super.key});

  @override
  State<RiwayatLemburManagerScreen> createState() => _RiwayatLemburManagerScreenState();
}

class _RiwayatLemburManagerScreenState extends State<RiwayatLemburManagerScreen> {
  List<Map<String, dynamic>> _lemburList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchHistoryApprovals();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistoryApprovals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ApiService().dio;
      // TODO: Using /approval/pending as mock endpoint for now. 
      // Replace with /approval/history when backend is ready.
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

        final lembur = <Map<String, dynamic>>[];

        for (final item in data) {
          final map = Map<String, dynamic>.from(item);
          final type = (map['type'] ?? map['jenis_pengajuan'] ?? '').toString().toLowerCase();

          if (type == 'lembur') {
            lembur.add(map);
          }
        }

        if (mounted) {
          setState(() {
            _lemburList = lembur;
            _isLoading = false;
            _applyFilters();
          });
        }
      } else if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal mengambil data riwayat approval.';
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredList = _lemburList.where((item) {
        final nama = _getKaryawanName(item).toLowerCase();
        final matchesSearch = nama.contains(query);

        bool matchesFilter = true;
        final statusRaw = (item['status_approval_level1'] ?? item['status'] ?? 'pending').toString().toLowerCase();
        
        bool isApproved = statusRaw == 'disetujui' || statusRaw == 'approved' || statusRaw == 'approve';
        bool isRejected = statusRaw == 'ditolak' || statusRaw == 'rejected' || statusRaw == 'reject';

        if (_selectedFilter == 'Disetujui') {
          matchesFilter = isApproved;
        } else if (_selectedFilter == 'Ditolak') {
          matchesFilter = isRejected;
        }
        // Jika statusnya pending, dan filter bukan 'Semua', mungkin tidak tampil. 
        // Untuk mock data dari /pending, sementara tetap dimunculkan di filter 'Semua'.

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // ============================================================
  // FORMAT HELPERS
  // ============================================================

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

  String _getLemburDateRange(Map<String, dynamic> data) {
    final tanggal = _formatDate(data['tanggal']);
    return tanggal;
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Lembur',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Processed Log',
                style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat lembur...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Disetujui'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Ditolak'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.grey)))
                    : _filteredList.isEmpty
                        ? const Center(child: Text('Tidak ada riwayat lembur.', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            color: const Color(0xFF009688),
                            onRefresh: _fetchHistoryApprovals,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildRiwayatCard(_filteredList[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF009688) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    final nama = _getKaryawanName(item);
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final posisi = _getPosisi(item);
    
    final tanggal = _getLemburDateRange(item);
    final durasi = _getLemburDuration(item);
    final waktu = _getLemburTime(item);
    final alasan = item['alasan']?.toString() ?? '-';
    final catatan = item['catatan_approval_level1']?.toString() ?? 'Tidak ada catatan khusus';

    // Status Check
    final statusRaw = (item['status_approval_level1'] ?? item['status'] ?? 'pending').toString().toLowerCase();
    bool isApproved = statusRaw == 'disetujui' || statusRaw == 'approved' || statusRaw == 'approve';
    bool isRejected = statusRaw == 'ditolak' || statusRaw == 'rejected' || statusRaw == 'reject';
    
    String statusText = 'PENDING';
    Color badgeBg = Colors.grey.shade100;
    Color badgeColor = Colors.grey.shade600;

    if (isApproved) {
      statusText = 'DISETUJUI';
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF15803D);
    } else if (isRejected) {
      statusText = 'DITOLAK';
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
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
              const Text('Durasi Lembur', style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text('$durasi ($waktu)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009688))),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Alasan & Catatan', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            isRejected ? 'Ditolak karena: $catatan' : alasan, 
            style: TextStyle(fontSize: 12, color: isRejected ? Colors.red : const Color(0xFF0F172A))
          ),
        ],
      ),
    );
  }
}
