import 'package:flutter/material.dart';
import '../services/image_url_service.dart';

class DetailWorkflowScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  final String type;

  const DetailWorkflowScreen({
    super.key,
    required this.data,
    required this.type,
  });

  bool get isCuti => type == 'Cuti/Izin';

  // ============================================================
  // HELPER
  // ============================================================

  String _value(dynamic value) {
    if (value == null) return '-';

    final text = value.toString().trim();

    if (text.isEmpty || text == 'null') {
      return '-';
    }

    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      const bulan = [
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
          '${bulan[date.month - 1]} '
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

    try {
      final date = DateTime.parse(text).toLocal();

      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return text;
    }
  }

  String _normalize(dynamic value) {
    return _value(value).toLowerCase().replaceAll(' ', '_');
  }

  bool _approved(dynamic value) {
    final status = _normalize(value);

    return status == 'disetujui' || status == 'approved' || status == 'approve';
  }

  bool _rejected(dynamic value) {
    final status = _normalize(value);

    return status == 'ditolak' || status == 'rejected' || status == 'reject';
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _overallStatus() {
    if (isCuti) {
      final status = data['status'];
      final l1 = data['status_verifikasi_atasan'];
      final l2 = data['status_verifikasi_hrd'];

      if (_rejected(status) || _rejected(l1) || _rejected(l2)) {
        return 'Ditolak';
      }

      if (_approved(status) && _approved(l1) && _approved(l2)) {
        return 'Disetujui';
      }

      if (_approved(l1)) {
        return 'L1 Disetujui, L2 Pending';
      }

      return 'Pending Approval L1';
    }

    final finalStatus = data['status_final'];
    final l1 = data['status_approval_level1'];
    final l2 = data['status_approval_level2'];

    if (_rejected(finalStatus) || _rejected(l1) || _rejected(l2)) {
      return 'Ditolak';
    }

    if (_approved(finalStatus) && _approved(l1) && _approved(l2)) {
      return 'Disetujui';
    }

    if (_approved(l1)) {
      return 'L1 Disetujui, L2 Pending';
    }

    return 'Pending Approval L1';
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Detail Workflow',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),

            const SizedBox(height: 18),

            const Text(
              'Status Persetujuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 12),

            _buildWorkflow(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildSummaryCard() {
    final status = _overallStatus();

    final jenis = isCuti ? _value(data['jenis']) : 'Lembur';

    final alasan = _value(data['alasan']);

    String periode;

    if (isCuti) {
      final mulai = _formatDate(data['tanggal_mulai']);

      final selesai = _formatDate(data['tanggal_selesai']);

      periode = mulai == selesai ? mulai : '$mulai - $selesai';
    } else {
      final tanggal = _formatDate(data['tanggal']);

      final mulai = _formatTime(data['jam_mulai_lembur']);

      final selesai = _formatTime(data['jam_selesai_lembur']);

      periode = '$tanggal, $mulai - $selesai';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jenis.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _statusBadge(status),
            ],
          ),

          const SizedBox(height: 12),

          _summaryRow('Jenis', jenis),

          const SizedBox(height: 5),

          _summaryRow(isCuti ? 'Periode' : 'Tanggal', periode),

          const SizedBox(height: 5),

          _summaryRow('Diajukan', _formatDate(data['created_at'])),

          const SizedBox(height: 5),

          _summaryRow('Alasan', alasan),

          if (!isCuti) ...[
            const SizedBox(height: 5),
            _summaryRow('Durasi', _durasiLembur()),
          ],

          if (data['dokumen_pendukung'] != null) ...[
            const SizedBox(height: 12),
            const Text(
              'Lampiran:',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                ImageUrlService.resolve(
                      data['dokumen_pendukung']?.toString(),
                    ) ??
                    '',
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Text('Gambar tidak dapat dimuat'),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),

        const Text(': ', style: TextStyle(fontSize: 10, color: Colors.grey)),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color text;

    if (status == 'Disetujui') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (status == 'Ditolak') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFFFFEDD5);
      text = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        status,
        style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 8),
      ),
    );
  }

  String _durasiLembur() {
    final menit =
        int.tryParse(data['durasi_lembur_menit']?.toString() ?? '0') ?? 0;

    final jam = menit ~/ 60;
    final sisa = menit % 60;

    if (sisa == 0) {
      return '$jam Jam';
    }

    return '$jam Jam $sisa Menit';
  }

  // ============================================================
  // WORKFLOW
  // ============================================================

  Widget _buildWorkflow() {
    if (isCuti) {
      return _buildCutiWorkflow();
    }

    return _buildLemburWorkflow();
  }

  // ============================================================
  // WORKFLOW CUTI
  // ============================================================

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
          subtitle: _formatDate(data['created_at']),
          badge: 'Selesai',
          done: true,
          current: false,
          first: true,
          last: false,
        ),

        _step(
          title: 'Persetujuan Atasan (Level 1)',
          subtitle: _approvalInfo(level1: true),
          note: _approvalNote(level1: true),
          badge: _stepStatus(l1, rejected: rejected),
          done: l1Approved,
          current: !l1Approved && !rejected,
          first: false,
          last: false,
        ),

        _step(
          title: 'Persetujuan HRD (Level 2)',
          subtitle: _approvalInfo(level1: false),
          note: _approvalNote(level1: false),
          badge: _stepStatus(l2, rejected: rejected),
          done: l2Approved,
          current: l1Approved && !l2Approved && !rejected,
          first: false,
          last: false,
        ),

        _step(
          title: 'Selesai',
          subtitle: selesai
              ? _formatDate(data['updated_at'])
              : 'Proses akhir workflow',
          badge: selesai
              ? 'Selesai'
              : rejected
              ? 'Ditolak'
              : 'Menunggu',
          done: selesai,
          current: false,
          first: false,
          last: true,
        ),
      ],
    );
  }

  // ============================================================
  // WORKFLOW LEMBUR
  // ============================================================

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
          subtitle: _formatDate(data['created_at']),
          badge: 'Selesai',
          done: true,
          current: false,
          first: true,
          last: false,
        ),

        _step(
          title: 'Persetujuan Atasan (Level 1)',
          subtitle: _approvalInfo(level1: true),
          note: _approvalNote(level1: true),
          badge: _stepStatus(l1, rejected: rejected),
          done: l1Approved,
          current: !l1Approved && !rejected,
          first: false,
          last: false,
        ),

        _step(
          title: 'Persetujuan HRD (Level 2)',
          subtitle: _approvalInfo(level1: false),
          note: _approvalNote(level1: false),
          badge: _stepStatus(l2, rejected: rejected),
          done: l2Approved,
          current: l1Approved && !l2Approved && !rejected,
          first: false,
          last: false,
        ),

        _step(
          title: 'Selesai',
          subtitle: selesai
              ? _formatDate(data['updated_at'])
              : 'Proses akhir workflow',
          badge: selesai
              ? 'Selesai'
              : rejected
              ? 'Ditolak'
              : 'Menunggu',
          done: selesai,
          current: false,
          first: false,
          last: true,
        ),
      ],
    );
  }

  // ============================================================
  // DATA APPROVAL
  // ============================================================

  String _approvalInfo({required bool level1}) {
    dynamic nama;
    dynamic tanggal;

    if (isCuti || !isCuti) {
      // Sama untuk cuti maupun lembur (berdasarkan backend BE-12 & BE-13)
      if (level1) {
        nama =
            data['approved_by_l1']?['name'] ??
            data['approved_by_atasan_name'] ??
            data['nama_atasan'];
        tanggal =
            data['approved_at_l1'] ??
            data['approved_at_atasan'] ??
            data['tanggal_verifikasi_atasan'];
      } else {
        nama =
            data['approved_by_l2']?['name'] ??
            data['approved_by_hrd_name'] ??
            data['nama_hrd'];
        tanggal =
            data['approved_at_l2'] ??
            data['approved_at_hrd'] ??
            data['tanggal_verifikasi_hrd'];
      }
    }

    if (nama == null && tanggal == null) {
      return level1
          ? 'Menunggu persetujuan atasan'
          : 'Menunggu persetujuan HRD';
    }

    return '${_value(nama)}\n${_formatDate(tanggal)}';
  }

  String? _approvalNote({required bool level1}) {
    dynamic note;

    if (isCuti) {
      if (level1) {
        note =
            data['catatan_verifikasi_atasan'] ??
            data['catatan_atasan'] ??
            data['catatan_persetujuan'];
      } else {
        note = data['catatan_verifikasi_hrd'] ?? data['catatan_hrd'];
      }
    } else {
      if (level1) {
        note =
            data['catatan_approval_level1'] ??
            data['catatan_level1'] ??
            data['catatan_atasan'];
      } else {
        note =
            data['catatan_approval_level2'] ??
            data['catatan_level2'] ??
            data['catatan_hrd'];
      }
    }

    if (note == null || note.toString().trim().isEmpty) {
      return null;
    }

    return 'Catatan: ${note.toString()}';
  }

  String _stepStatus(dynamic value, {required bool rejected}) {
    if (_rejected(value)) {
      return 'Ditolak';
    }

    if (_approved(value)) {
      return 'Disetujui';
    }

    return 'Pending';
  }

  // ============================================================
  // TIMELINE STEP
  // ============================================================

  Widget _step({
    required String title,
    required String subtitle,
    String? note,
    required String badge,
    required bool done,
    required bool current,
    required bool first,
    required bool last,
  }) {
    final isRejected = badge == 'Ditolak';

    final Color badgeBg = done
        ? const Color(0xFFDCFCE7)
        : isRejected
        ? const Color(0xFFFEE2E2)
        : current
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFF1F5F9);

    final Color badgeColor = done
        ? const Color(0xFF15803D)
        : isRejected
        ? const Color(0xFFDC2626)
        : current
        ? const Color(0xFFC2410C)
        : const Color(0xFF94A3B8);

    final Color lineColor = done || current
        ? const Color(0xFF009688)
        : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              if (!first) Container(width: 2, height: 8, color: lineColor),

              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done
                      ? const Color(0xFF009688)
                      : current
                      ? Colors.orange
                      : Colors.white,
                  border: Border.all(
                    color: done
                        ? const Color(0xFF009688)
                        : current
                        ? Colors.orange
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : current
                    ? Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),

              if (!last) Container(width: 2, height: 70, color: lineColor),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: done || current
                              ? const Color(0xFF0F172A)
                              : Colors.grey,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: badgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 3),

                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 9,
                    color: Colors.grey,
                    height: 1.3,
                  ),
                ),

                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: const TextStyle(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF334155),
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
}
