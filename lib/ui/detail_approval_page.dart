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
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 18,
                  color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: Text(
          isCuti ? 'Detail Pengajuan Cuti' : 'Detail Pengajuan Lembur',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======== INFO KARYAWAN ========
            _buildSectionCard(
              title: 'Informasi Pengaju',
              children: [
                _infoRow('Nama', _getKaryawanName()),
                _infoRow(
                    'Jabatan',
                    data['karyawan']?['jabatan'] ??
                        data['jabatan'] ??
                        '-'),
                _infoRow('Diajukan',
                    _formatDate(data['created_at'])),
              ],
            ),
            const SizedBox(height: 12),

            // ======== DETAIL PENGAJUAN ========
            _buildSectionCard(
              title: 'Detail Pengajuan',
              children: isCuti
                  ? _buildCutiDetails()
                  : _buildLemburDetails(),
            ),
            const SizedBox(height: 12),

            // ======== ALASAN ========
            _buildSectionCard(
              title: 'Alasan',
              children: [
                Text(
                  data['alasan']?.toString() ?? '-',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF334155), height: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ======== CATATAN PERSETUJUAN ========
            const Text(
              'Catatan Persetujuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _catatanController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis catatan (wajib jika menolak)...',
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF009688)),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),

            // ======== TOMBOL AKSI ========
            Row(
              children: [
                // TOLAK
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed:
                          _isSubmitting ? null : () => _submitAction('reject'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Tolak',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // SETUJUI
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _submitAction('approve'),
                      icon: const Icon(Icons.check_rounded,
                          size: 18, color: Colors.white),
                      label: const Text('Setujui',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_isSubmitting) ...[
              const SizedBox(height: 16),
              const Center(
                child:
                    CircularProgressIndicator(color: Color(0xFF009688)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DETAIL BUILDERS
  // ============================================================

  List<Widget> _buildCutiDetails() {
    final jenis = _capitalize(data['jenis']?.toString() ?? 'Cuti');
    final mulai = _formatDate(data['tanggal_mulai']);
    final selesai = _formatDate(data['tanggal_selesai']);

    int durasi = 1;
    try {
      final m = DateTime.parse(data['tanggal_mulai'].toString());
      final s = DateTime.parse(data['tanggal_selesai'].toString());
      // Hitung hari kerja (skip weekend)
      DateTime current = m;
      int days = 0;
      while (!current.isAfter(s)) {
        if (current.weekday != DateTime.saturday &&
            current.weekday != DateTime.sunday) {
          days++;
        }
        current = current.add(const Duration(days: 1));
      }
      durasi = days;
    } catch (_) {}

    return [
      _infoRow('Jenis', jenis),
      _infoRow('Tanggal Mulai', mulai),
      _infoRow('Tanggal Selesai', selesai),
      _infoRow('Durasi', '$durasi hari kerja'),
    ];
  }

  List<Widget> _buildLemburDetails() {
    final tanggal = _formatDate(data['tanggal']);
    final jamMulai =
        data['jam_mulai_lembur']?.toString().substring(0, 5) ?? '-';
    final jamSelesai =
        data['jam_selesai_lembur']?.toString().substring(0, 5) ?? '-';
    final menit =
        int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;
    final jam = menit ~/ 60;
    final sisa = menit % 60;
    final durasiText =
        sisa == 0 ? '$jam jam' : '$jam jam $sisa menit';

    return [
      _infoRow('Tanggal', tanggal),
      _infoRow('Jam Mulai', jamMulai),
      _infoRow('Jam Selesai', jamSelesai),
      _infoRow('Durasi', durasiText),
    ];
  }

  // ============================================================
  // REUSABLE WIDGETS
  // ============================================================

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF334155),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }
}
