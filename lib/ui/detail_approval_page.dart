import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class DetailApprovalScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String type; // 'cuti' atau 'lembur'

  const DetailApprovalScreen({
    super.key,
    required this.data,
    required this.type,
  });

  @override
  State<DetailApprovalScreen> createState() => _DetailApprovalScreenState();
}

class _DetailApprovalScreenState extends State<DetailApprovalScreen> {
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  Map<String, dynamic> get data => widget.data;
  bool get isCuti => widget.type == 'cuti';

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

  String _getKaryawanName() {
    return data['karyawan']?['nama'] ??
        data['karyawan_nama'] ??
        data['nama_karyawan'] ??
        data['user']?['name'] ??
        'Karyawan';
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // ============================================================
  // APPROVE / REJECT
  // ============================================================

  Future<void> _submitAction(String action) async {
    // Jika tolak, catatan wajib diisi
    if (action == 'reject' && _catatanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Catatan wajib diisi saat menolak pengajuan.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Konfirmasi dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          action == 'approve' ? 'Setujui Pengajuan?' : 'Tolak Pengajuan?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Text(
          action == 'approve'
              ? 'Apakah Anda yakin ingin menyetujui pengajuan ini?'
              : 'Apakah Anda yakin ingin menolak pengajuan ini?',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve'
                  ? const Color(0xFF009688)
                  : Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              action == 'approve' ? 'Setujui' : 'Tolak',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiService().dio;
      final id = data['id'];

      final body = <String, dynamic>{
        'type': widget.type,
        'action': action,
      };

      final catatan = _catatanController.text.trim();
      if (catatan.isNotEmpty) {
        body['catatan'] = catatan;
      }

      await dio.patch('/approval/$id', data: body);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'approve'
                ? 'Pengajuan berhasil disetujui.'
                : 'Pengajuan berhasil ditolak.',
          ),
          backgroundColor:
              action == 'approve' ? const Color(0xFF009688) : Colors.redAccent,
        ),
      );

      Navigator.pop(context, true); // true = refresh list
    } on DioException catch (e) {
      String msg = 'Gagal memproses approval.';
      if (e.response?.data is Map) {
        msg = e.response!.data['message']?.toString() ?? msg;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
      
      final int? statusCode = e.response?.statusCode;
      final bool isAlreadyDecided = msg.toLowerCase().contains('sudah diputuskan') || msg.toLowerCase().contains('tidak dapat diubah');
      
      if (statusCode == 422 || statusCode == 404 || statusCode == 400 || isAlreadyDecided) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan, coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final title = isCuti ? 'Detail Cuti' : 'Detail Lembur';

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
            Text(
              title,
              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ======== STATUS PENGAJUAN ========
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STATUS PENGAJUAN',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Menunggu Persetujuan',
                          style: TextStyle(color: Color(0xFFCA8A04), fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ======== INFO KARYAWAN CARD ========
                  _buildKaryawanCard(),
                  const SizedBox(height: 16),

                  // ======== DETAIL CARD ========
                  _buildDetailCard(),
                  const SizedBox(height: 16),

                  // ======== ALASAN CARD ========
                  _buildAlasanCard(),
                  const SizedBox(height: 16),
                  
                  // ======== CATATAN ATASAN CARD (OPSIONAL) ========
                  _buildCatatanAtasanCard(),
                  
                  // ======== LAMPIRAN CARD (OPSIONAL) ========
                  _buildLampiranCard(),

                  // ======== PESAN UNTUK KARYAWAN ========
                  _buildPesanCard(),
                ],
              ),
            ),
          ),
          
          // ======== TOMBOL AKSI ========
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: _isSubmitting 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: const Text(
                                'Sebagai Atasan (L1), setelah Anda menyetujui, pengajuan ini akan diteruskan ke HRD/Admin (L2) untuk validasi akhir.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _submitAction('reject'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2), // Light Red
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Tolak', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () => _submitAction('approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF009688), // Teal
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Setujui', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CARD BUILDERS
  // ============================================================

  Widget _buildKaryawanCard() {
    final nama = _getKaryawanName();
    final inisial = nama.isNotEmpty ? nama.substring(0, 1).toUpperCase() : '?';
    final jabatan = data['user']?['jabatan'] ?? data['karyawan']?['jabatan'] ?? data['jabatan'] ?? 'Karyawan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2F1),
            radius: 24,
            child: Text(
              inisial,
              style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text(
                  jabatan,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: isCuti ? _buildCutiRows() : _buildLemburRows(),
      ),
    );
  }
  
  List<Widget> _buildLemburRows() {
    // Tanggal pengajuan fallback ke tanggal hari ini jika tidak ada
    final tglPengajuan = _formatDate(data['created_at'] ?? DateTime.now().toIso8601String());
    final tglLembur = _formatDate(data['tanggal']);
    
    final jamMulai = data['jam_mulai_lembur']?.toString().substring(0, 5) ?? '-';
    final jamSelesai = data['jam_selesai_lembur']?.toString().substring(0, 5) ?? '-';
    final waktu = '$jamMulai - $jamSelesai';
    
    final menit = int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;
    final jam = menit ~/ 60;
    final sisa = menit % 60;
    final durasi = sisa == 0 ? '$jam Jam' : '$jam Jam $sisa Menit';

    return [
      _detailRow('Tanggal Pengajuan', tglPengajuan),
      const SizedBox(height: 16),
      _detailRow('Tanggal Lembur', tglLembur),
      const SizedBox(height: 16),
      _detailRow('Rencana Waktu', waktu),
      const SizedBox(height: 16),
      _detailRow('Total Durasi', durasi, valueColor: const Color(0xFF009688)),
    ];
  }

  List<Widget> _buildCutiRows() {
    final jenis = _capitalize(data['jenis']?.toString() ?? 'Cuti Tahunan');
    final tglPengajuan = _formatDate(data['created_at'] ?? DateTime.now().toIso8601String());
    
    final mulaiRaw = _formatDate(data['tanggal_mulai']);
    final selesaiRaw = _formatDate(data['tanggal_selesai']);
    
    String rentang = '$mulaiRaw - $selesaiRaw';
    if (mulaiRaw == selesaiRaw) {
       rentang = mulaiRaw;
    } else {
       try {
         final dM = DateTime.parse(data['tanggal_mulai'].toString());
         final dS = DateTime.parse(data['tanggal_selesai'].toString());
         if (dM.month == dS.month && dM.year == dS.year) {
           const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
           rentang = '${dM.day} - ${dS.day} ${months[dM.month - 1]} ${dM.year}';
         }
       } catch (_) {}
    }

    int durasiHari = 1;
    if (data['jumlah_hari_kerja'] != null) {
      durasiHari = int.tryParse(data['jumlah_hari_kerja'].toString()) ?? 1;
    } else {
      try {
        final m = DateTime.parse(data['tanggal_mulai'].toString());
        final s = DateTime.parse(data['tanggal_selesai'].toString());
        durasiHari = s.difference(m).inDays + 1;
      } catch (_) {}
    }
    
    final sisaKuota = data['sisa_kuota_cuti'] ?? '-'; 

    return [
      _detailRow('Jenis Cuti', jenis, valueColor: const Color(0xFF009688)),
      const SizedBox(height: 16),
      _detailRow('Tanggal Pengajuan', tglPengajuan),
      const SizedBox(height: 16),
      _detailRow('Rentang Tanggal', rentang),
      const SizedBox(height: 16),
      _detailRow('Durasi Cuti', '$durasiHari Hari Kerja'),
      const SizedBox(height: 16),
      _detailRow('Sisa Kuota Cuti', '$sisaKuota Hari Kerja'),
    ];
  }

  Widget _buildAlasanCard() {
    final title = isCuti ? 'ALASAN CUTI' : 'ALASAN LEMBUR';
    final alasan = data['alasan']?.toString() ?? '-';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            alasan,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanAtasanCard() {
    final catatan = data['catatan_atasan'] ?? data['catatan_approval_level1'];
    if (catatan == null || catatan.toString().trim().isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATATAN ATASAN',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            catatan.toString(),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLampiranCard() {
    final lampiranUrl = data['lampiran_url'] ?? data['file_lampiran_url'];
    
    if (lampiranUrl == null) return const SizedBox();

    final lampiranName = data['lampiran_nama'] ?? data['file_lampiran_nama'] ?? 'Lampiran Dokumen';
    final lampiranSize = data['lampiran_ukuran'] ?? 'Tidak diketahui';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAMPIRAN',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.grey, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lampiranName,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lampiranSize,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () {
                    // Download action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mengunduh lampiran...')),
                    );
                  },
                  child: const Text(
                    'Unduh',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF009688)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PESAN UNTUK KARYAWAN',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis pesan opsional untuk karyawan...',
              hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF009688)),
              ),
            ),
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: valueColor ?? const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }
}
