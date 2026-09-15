import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'detail_approval_page.dart';

class PengajuanCutiManagerScreen extends StatefulWidget {
  const PengajuanCutiManagerScreen({super.key});

  @override
  State<PengajuanCutiManagerScreen> createState() => _PengajuanCutiManagerScreenState();
}

class _PengajuanCutiManagerScreenState extends State<PengajuanCutiManagerScreen> {
  List<Map<String, dynamic>> _cutiList = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Semua Cuti';

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovals();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

        for (final item in data) {
          final map = Map<String, dynamic>.from(item);
          final type = (map['type'] ?? map['jenis_pengajuan'] ?? '').toString().toLowerCase();

          if (type != 'lembur') {
            cuti.add(map);
          }
        }

        if (mounted) {
          setState(() {
            _cutiList = cuti;
            _isLoading = false;
            _applyFilters();
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

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredList = _cutiList.where((item) {
        final nama = _getKaryawanName(item).toLowerCase();
        final tipeSearch = (item['jenis']?.toString() ?? 'Cuti').toLowerCase();
        final matchesSearch = nama.contains(query) || tipeSearch.contains(query);

        bool matchesFilter = true;
        final tipeFilter = (item['jenis']?.toString() ?? 'Cuti').toLowerCase();
        if (_selectedFilter == 'Cuti Tahunan') {
          matchesFilter = tipeFilter.contains('cuti') && !tipeFilter.contains('izin') && !tipeFilter.contains('sakit');
        } else if (_selectedFilter == 'Izin Medis') {
          matchesFilter = tipeFilter.contains('sakit') || tipeFilter.contains('medis');
        }

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

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  String _getCutiDateRange(Map<String, dynamic> data) {
    final mulai = _formatDate(data['tanggal_mulai']);
    final selesai = _formatDate(data['tanggal_selesai']);
    if (mulai == selesai) return mulai;
    
    // Simplification for formatting like "20 - 30 Jan 2026"
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
    return '$days Hari Kerja';
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
              'Pengajuan Cuti',
              style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Manager View',
                style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 10),
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
                    hintText: 'Cari nama atau tipe cuti...',
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
                      _buildFilterChip('Semua Cuti'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cuti Tahunan'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Izin Medis'),
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
                        ? const Center(child: Text('Tidak ada pengajuan cuti.', style: TextStyle(color: Colors.grey)))
                        : RefreshIndicator(
                            color: const Color(0xFF009688),
                            onRefresh: _fetchPendingApprovals,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredList.length,
                              itemBuilder: (context, index) {
                                return _buildCutiCard(_filteredList[index]);
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

  Widget _buildCutiCard(Map<String, dynamic> item) {
    final nama = _getKaryawanName(item);
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final posisi = _getPosisi(item);
    
    final tipe = _capitalize(item['jenis']?.toString() ?? 'Cuti Tahunan');
    final tanggal = _getCutiDateRange(item);
    final durasi = _getCutiDuration(item);
    final alasan = item['alasan']?.toString() ?? '-';

    // Different badge style based on cuti type
    final isMedis = tipe.toLowerCase().contains('sakit') || tipe.toLowerCase().contains('medis');
    final badgeBg = isMedis ? const Color(0xFFDCFCE7) : Colors.grey.shade100;
    final badgeColor = isMedis ? const Color(0xFF15803D) : const Color(0xFF475569);

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
}
