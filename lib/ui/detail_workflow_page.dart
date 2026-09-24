import 'package:flutter/material.dart';
import '../services/image_url_service.dart';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailWorkflowScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;

  const DetailWorkflowScreen({
    super.key,
    required this.data,
    required this.type,
  });

  bool get isCuti => type.toLowerCase().contains('cuti') || type.toLowerCase().contains('izin');
  bool get isLembur => type.toLowerCase().contains('lembur');

  String _value(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return '-';
    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    try {
      final date = DateTime.parse(text).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return text;
    }
  }

  String _normalize(dynamic value) => _value(value).toLowerCase().replaceAll(' ', '_');
  bool _approved(dynamic value) {
    final status = _normalize(value);
    return status == 'disetujui' || status == 'approved' || status == 'approve';
  }
  bool _rejected(dynamic value) {
    final status = _normalize(value);
    return status == 'ditolak' || status == 'rejected' || status == 'reject';
  }
  bool _pending(dynamic value) {
    final status = _normalize(value);
    return status == 'pending' || status == 'menunggu';
  }

  String _overallStatus() {
    if (isCuti) {
      final status = data['status'];
      final l1 = data['status_verifikasi_atasan'];
      final l2 = data['status_verifikasi_hrd'];
      if (_rejected(status) || _rejected(l1) || _rejected(l2)) return 'Ditolak';
      if (_approved(status) && _approved(l1) && _approved(l2)) return 'Selesai';
      if (_approved(l1)) return 'Pending L2';
      return 'Menunggu';
    }
    final finalStatus = data['status_final'];
    final l1 = data['status_approval_level1'];
    final l2 = data['status_approval_level2'];
    if (_rejected(finalStatus) || _rejected(l1) || _rejected(l2)) return 'Ditolak';
    if (_approved(finalStatus) && _approved(l1) && _approved(l2)) return 'Selesai';
    if (_approved(l1)) return 'Pending L2';
    return 'Menunggu';
  }

  String _getAppbarTitle() {
    if (isCuti) {
      final jenisCuti = data['jenis_cuti']?.toString().toLowerCase() ?? '';
      final jenisIzin = data['jenis_izin']?.toString().toLowerCase() ?? '';
      if (jenisCuti.contains('tahunan')) return 'Detail Cuti Tahunan';
      if (jenisCuti.contains('khusus') || jenisCuti.contains('melahirkan')) return 'Detail Cuti Khusus';
      if (jenisCuti.contains('duka')) return 'Detail Cuti Duka';
      if (jenisIzin.contains('sakit')) return 'Detail Izin Sakit';
      return 'Detail Cuti/Izin';
    }
    return 'Detail Lembur';
  }

  List<Color> _getLeftBadgeColors(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('tahunan')) return [const Color(0xFFCCFBF1), const Color(0xFF0F766E)];
    if (lower.contains('khusus') || lower.contains('melahirkan')) return [const Color(0xFFE0F2FE), const Color(0xFF0284C7)];
    if (lower.contains('duka')) return [const Color(0xFFFCE7F3), const Color(0xFFBE185D)];
    if (lower.contains('izin') || lower.contains('sakit')) return [const Color(0xFFFFEDD5), const Color(0xFFC2410C)];
    return [const Color(0xFFF1F5F9), const Color(0xFF475569)]; // default gray
  }

  List<Color> _getRightBadgeColors(String status) {
    final lower = status.toLowerCase();
    if (lower == 'selesai' || lower == 'dibatalkan' || lower == 'pending') return [const Color(0xFFF1F5F9), const Color(0xFF475569)];
    if (lower == 'disetujui' || lower == 'approved') return [const Color(0xFFDCFCE7), const Color(0xFF15803D)];
    if (lower == 'ditolak' || lower == 'rejected') return [const Color(0xFFFEE2E2), const Color(0xFFDC2626)];
    if (lower == 'menunggu') return [const Color(0xFFFFEDD5), const Color(0xFFC2410C)];
    return [const Color(0xFFF1F5F9), const Color(0xFF475569)]; // default gray
  }

  String _getRightBadgeText() {
    final status = _overallStatus();
    if (status == 'Ditolak') return 'Ditolak';
    if (status == 'Selesai') return 'Selesai';
    return 'Menunggu';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getAppbarTitle(),
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            const Text(
              'Status Persetujuan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 16),
            _buildWorkflow(),
            if (data['dokumen_pendukung'] != null || data['file'] != null || data['lampiran'] != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Lampiran Dokumen',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 12),
              _buildAttachmentCard(
                data['dokumen_pendukung'] ?? data['file'] ?? data['lampiran'],
                data['created_at'],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final leftBadgeLabel = isCuti ? _value(data['jenis_cuti'] ?? data['jenis_izin'] ?? type) : 'Lembur';
    final leftColors = _getLeftBadgeColors(leftBadgeLabel);
    final rightBadgeLabel = _getRightBadgeText();
    final rightColors = _getRightBadgeColors(rightBadgeLabel);

    String periode;
    String durasi = '-';
    if (isCuti) {
      final mulai = _formatDate(data['tanggal_mulai']);
      final selesai = _formatDate(data['tanggal_selesai']);
      periode = mulai == selesai ? mulai : '$mulai - $selesai';
      
      // Hitung hari secara sederhana untuk mockup jika tidak ada field durasi
      if (data['durasi'] != null) {
        durasi = '${data['durasi']} Hari Kerja';
      } else {
        if (data['tanggal_mulai'] != null && data['tanggal_selesai'] != null) {
          try {
            final start = DateTime.parse(data['tanggal_mulai'].toString());
            final end = DateTime.parse(data['tanggal_selesai'].toString());
            final diff = end.difference(start).inDays + 1;
            durasi = '$diff Hari Kerja';
          } catch (_) {}
        }
      }
    } else {
      final tanggal = _formatDate(data['tanggal']);
      final mulai = _formatTime(data['jam_mulai_lembur']);
      final selesai = _formatTime(data['jam_selesai_lembur']);
      periode = '$tanggal, $mulai - $selesai';
      
      final menit = int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;
      final jam = menit ~/ 60;
      final sisa = menit % 60;
      durasi = sisa == 0 ? '$jam Jam' : '$jam Jam $sisa Menit';
    }

    final alasan = _value(isCuti ? data['alasan'] : data['alasan_lembur']);
    final diajukan = _formatDate(data['created_at']);
    final pemohon = _value(data['karyawan']?['nama'] ?? data['nama_karyawan'] ?? 'Saya');
    final sisaKuota = isCuti ? (data['sisa_kuota'] ?? 'N/A') : '-';

    return Container(
      width: double.infinity,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: leftColors[0], borderRadius: BorderRadius.circular(20)),
                child: Text(leftBadgeLabel, style: TextStyle(color: leftColors[1], fontWeight: FontWeight.bold, fontSize: 11)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: rightColors[0], borderRadius: BorderRadius.circular(20)),
                child: Text(rightBadgeLabel, style: TextStyle(color: rightColors[1], fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _summaryRow('Pemohon', pemohon),
          const SizedBox(height: 12),
          _summaryRow('Periode', periode),
          const SizedBox(height: 12),
          _summaryRow('Durasi', durasi),
          const SizedBox(height: 12),
          _summaryRow('Alasan', alasan),
          const SizedBox(height: 12),
          _summaryRow('Tanggal Pengajuan', diajukan),
          const SizedBox(height: 12),
          _summaryRow('Sisa Kuota', '$sisaKuota'),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkflow() {
    return isCuti ? _buildCutiWorkflow() : _buildLemburWorkflow();
  }

  Widget _buildCutiWorkflow() {
    final l1 = data['status_verifikasi_atasan'];
    final l2 = data['status_verifikasi_hrd'];
    final finalStatus = data['status'];

    final l1Approved = _approved(l1);
    final l2Approved = _approved(l2);
    final rejected = _rejected(l1) || _rejected(l2) || _rejected(finalStatus);
    final selesai = l1Approved && l2Approved && _approved(finalStatus);

    return Column(
      children: [
        _step(
          title: 'Pengajuan Dikirim',
          subtitle: _formatDateTime(data['created_at']),
          badge: 'SELESAI',
          statusType: 'done',
          first: true,
          last: false,
        ),
        _step(
          title: 'Persetujuan ${_getApproverName(level1: true)}',
          subtitle: _approvalInfo(level1: true, overallRejected: rejected),
          note: _approvalNote(level1: true),
          badge: _getStepBadgeText(l1, rejected, l1Approved),
          statusType: _getStepStatusType(l1, rejected, l1Approved, false),
          first: false,
          last: false,
        ),
        _step(
          title: 'Persetujuan ${_getApproverName(level1: false)}',
          subtitle: _approvalInfo(level1: false, overallRejected: rejected),
          note: _approvalNote(level1: false),
          badge: _getStepBadgeText(l2, rejected, l2Approved),
          statusType: _getStepStatusType(l2, rejected, l2Approved, l1Approved),
          first: false,
          last: false,
        ),
        _step(
          title: 'Selesai',
          subtitle: selesai ? 'Proses Akhir Selesai' : 'Proses Akhir Workflow',
          badge: selesai ? 'SELESAI' : (rejected ? 'DIBATALKAN' : 'MENUNGGU'),
          statusType: selesai ? 'done' : (rejected ? 'cancelled' : 'waiting'),
          first: false,
          last: true,
        ),
      ],
    );
  }

  Widget _buildLemburWorkflow() {
    final l1 = data['status_approval_level1'];
    final l2 = data['status_approval_level2'];
    final finalStatus = data['status_final'];

    final l1Approved = _approved(l1);
    final l2Approved = _approved(l2);
    final rejected = _rejected(l1) || _rejected(l2) || _rejected(finalStatus);
    final selesai = l1Approved && l2Approved && _approved(finalStatus);

    return Column(
      children: [
        _step(
          title: 'Pengajuan Dikirim',
          subtitle: _formatDateTime(data['created_at']),
          badge: 'SELESAI',
          statusType: 'done',
          first: true,
          last: false,
        ),
        _step(
          title: 'Persetujuan ${_getApproverName(level1: true)}',
          subtitle: _approvalInfo(level1: true, overallRejected: rejected),
          note: _approvalNote(level1: true),
          badge: _getStepBadgeText(l1, rejected, l1Approved),
          statusType: _getStepStatusType(l1, rejected, l1Approved, false),
          first: false,
          last: false,
        ),
        _step(
          title: 'Persetujuan ${_getApproverName(level1: false)}',
          subtitle: _approvalInfo(level1: false, overallRejected: rejected),
          note: _approvalNote(level1: false),
          badge: _getStepBadgeText(l2, rejected, l2Approved),
          statusType: _getStepStatusType(l2, rejected, l2Approved, l1Approved),
          first: false,
          last: false,
        ),
        _step(
          title: 'Selesai',
          subtitle: selesai ? 'Proses Akhir Selesai' : 'Proses Akhir Workflow',
          badge: selesai ? 'SELESAI' : (rejected ? 'DIBATALKAN' : 'MENUNGGU'),
          statusType: selesai ? 'done' : (rejected ? 'cancelled' : 'waiting'),
          first: false,
          last: true,
        ),
      ],
    );
  }

  String _getStepBadgeText(dynamic val, bool overallRejected, bool isApproved) {
    if (overallRejected && !_approved(val) && !_rejected(val)) return 'DIBATALKAN';
    if (_rejected(val)) return 'DITOLAK';
    if (isApproved) return 'DISETUJUI';
    return 'PENDING';
  }

  String _getStepStatusType(dynamic val, bool overallRejected, bool isApproved, bool prevApproved) {
    if (_rejected(val)) return 'rejected';
    if (overallRejected) return 'cancelled';
    if (isApproved) return 'done';
    if (prevApproved || (!_approved(val) && !_rejected(val))) return 'pending';
    return 'waiting';
  }

  String _getApproverName({required bool level1}) {
    if (level1) {
      return data['approved_by_l1']?['name'] ?? data['approved_by_atasan_name'] ?? data['nama_atasan'] ?? 'Atasan (L1)';
    } else {
      return data['approved_by_l2']?['name'] ?? data['approved_by_hrd_name'] ?? data['nama_hrd'] ?? 'HRD (L2)';
    }
  }

  String _approvalInfo({required bool level1, bool overallRejected = false}) {
    dynamic nama;
    dynamic tanggal;
    if (level1) {
      nama = data['approved_by_l1']?['name'] ?? data['approved_by_atasan_name'] ?? data['nama_atasan'];
      tanggal = data['approved_at_l1'] ?? data['approved_at_atasan'] ?? data['tanggal_verifikasi_atasan'];
    } else {
      nama = data['approved_by_l2']?['name'] ?? data['approved_by_hrd_name'] ?? data['nama_hrd'];
      tanggal = data['approved_at_l2'] ?? data['approved_at_hrd'] ?? data['tanggal_verifikasi_hrd'];
    }
    if (nama == null && tanggal == null) {
      if (overallRejected) return 'Proses dibatalkan';
      return level1 ? 'Menunggu persetujuan atasan' : 'Menunggu persetujuan HRD';
    }
    return '${_value(nama)} \u2022 ${_formatDateTime(tanggal)}';
  }

  String? _approvalNote({required bool level1}) {
    dynamic note;
    if (isCuti) {
      note = level1 ? (data['catatan_verifikasi_atasan'] ?? data['catatan_atasan'] ?? data['catatan_persetujuan'])
                    : (data['catatan_verifikasi_hrd'] ?? data['catatan_hrd']);
    } else {
      note = level1 ? (data['catatan_approval_level1'] ?? data['catatan_level1'] ?? data['catatan_atasan'])
                    : (data['catatan_approval_level2'] ?? data['catatan_level2'] ?? data['catatan_hrd']);
    }
    if (note == null || note.toString().trim().isEmpty) return null;
    return note.toString();
  }

  Widget _step({
    required String title,
    required String subtitle,
    String? note,
    required String badge,
    required String statusType, // 'done', 'pending', 'rejected', 'cancelled', 'waiting'
    required bool first,
    required bool last,
  }) {
    Color badgeBg = const Color(0xFFF1F5F9);
    Color badgeText = const Color(0xFF94A3B8);
    Color iconColor = Colors.grey.shade400;
    Color lineColor = Colors.grey.shade300;
    IconData? iconData;
    double iconSize = 12;

    if (statusType == 'done') {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      iconColor = const Color(0xFF10B981);
      lineColor = const Color(0xFF10B981);
      iconData = Icons.check;
    } else if (statusType == 'rejected') {
      badgeBg = const Color(0xFFFEE2E2);
      badgeText = const Color(0xFFDC2626);
      iconColor = const Color(0xFFEF4444);
      iconData = Icons.close;
    } else if (statusType == 'pending') {
      badgeBg = const Color(0xFFFFEDD5);
      badgeText = const Color(0xFFC2410C);
      iconColor = const Color(0xFFF97316);
      iconData = Icons.circle;
      iconSize = 8;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (!first) Container(width: 2, height: 12, color: statusType == 'done' || statusType == 'pending' ? lineColor : Colors.grey.shade300),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: iconData != null ? Center(child: Icon(iconData, size: iconSize, color: iconColor)) : null,
              ),
              if (!last) Container(width: 2, height: note != null ? 70 : 40, color: statusType == 'done' ? lineColor : Colors.grey.shade300),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusType == 'waiting' || statusType == 'cancelled' ? Colors.grey : const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (badge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                        child: Text(badge, style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 9)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                if (note != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                        children: [
                          const TextSpan(text: 'Catatan: ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          TextSpan(text: note),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentCard(dynamic attachment, dynamic dateUpload) {
    final imageUrl = ImageUrlService.resolve(attachment?.toString()) ?? '';
    final isPdf = imageUrl.toLowerCase().endsWith('.pdf');
    final fileName = attachment?.toString().split('/').last ?? 'document.pdf';

    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(20)),
                child: const Text('1 File Terlampir', style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              Text(isPdf ? 'PDF \u2022 1.2 MB' : 'IMAGE \u2022 1.5 MB', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: isPdf
                ? Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: const Center(child: Icon(Icons.picture_as_pdf, size: 48, color: Colors.red)),
                  )
                : FutureBuilder<String?>(
                    future: ApiService().getToken(),
                    builder: (context, snapshot) {
                      final token = snapshot.data;
                      return Image.network(
                        imageUrl,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
                        errorBuilder: (_, __, ___) => Container(
                          height: 140,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Diunggah pada ${_formatDateTime(dateUpload)}', style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(imageUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 16, color: Color(0xFF15803D)),
                  SizedBox(width: 8),
                  Text('Unduh', style: TextStyle(color: Color(0xFF15803D), fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
