import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailKoreksiScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKoreksiScreen({super.key, required this.data});

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${hari[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '--';
    final text = value.toString();
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return text;
  }

  String get _status {
    final status = data['status'] ?? data['status_approval_level1'] ?? 'menunggu_verifikasi';
    return status.toString().toLowerCase().trim();
  }

  List<Color> _getBadgeColors(String status) {
    if (status == 'selesai' || status == 'disetujui' || status == 'approved') return [const Color(0xFFDCFCE7), const Color(0xFF15803D)];
    if (status == 'ditolak' || status == 'rejected') return [const Color(0xFFFEE2E2), const Color(0xFFDC2626)];
    if (status == 'menunggu' || status == 'menunggu_verifikasi' || status == 'pending') return [const Color(0xFFDBEAFE), const Color(0xFF1D4ED8)]; // Blue badge for Menunggu
    return [const Color(0xFFF1F5F9), const Color(0xFF475569)]; 
  }

  String _formatStatus(String status) {
    if (status == 'menunggu_verifikasi' || status == 'pending') return 'MENUNGGU';
    return status.toUpperCase();
  }

  Widget _buildBanner() {
    Color bgColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData icon;
    String text;

    if (_status == 'disetujui' || _status == 'approved') {
      bgColor = const Color(0xFFF0FDF4); // Light green
      borderColor = const Color(0xFFBBF7D0);
      iconColor = const Color(0xFF16A34A);
      textColor = const Color(0xFF166534);
      icon = Icons.check_circle_outline;
      text = 'Pengajuan koreksi presensi Anda telah disetujui oleh Atasan.';
    } else if (_status == 'ditolak' || _status == 'rejected') {
      bgColor = const Color(0xFFFEF2F2); // Light red
      borderColor = const Color(0xFFFECACA);
      iconColor = const Color(0xFFDC2626);
      textColor = const Color(0xFF991B1B);
      icon = Icons.error_outline;
      text = 'Pengajuan koreksi presensi Anda ditolak oleh Atasan.';
    } else {
      bgColor = const Color(0xFFEFF6FF); // Light blue
      borderColor = const Color(0xFFBFDBFE);
      iconColor = const Color(0xFF2563EB);
      textColor = const Color(0xFF1E40AF);
      icon = Icons.access_time;
      text = 'Pengajuan koreksi sedang menunggu persetujuan dari Atasan.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

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
        title: const Text(
          'Detail Koreksi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBanner(),
            const SizedBox(height: 16),
            _buildTopCard(),
            const SizedBox(height: 16),
            _buildDetailBox(),
            const SizedBox(height: 16),
            _buildTimeline(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    final badgeColors = _getBadgeColors(_status);
    final badgeText = _formatStatus(_status);
    
    // Parse jenis_koreksi if backend passes it as "[Jenis] Alasan"
    String jenisKoreksi = data['jenis_koreksi'] ?? '-';
    String alasan = data['alasan'] ?? '';
    if (alasan.startsWith('[') && alasan.contains(']')) {
      final parts = alasan.split(']');
      if (jenisKoreksi == '-') {
        jenisKoreksi = parts[0].substring(1).trim();
      }
    }

    return Container(
      width: double.infinity,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(data['tanggal']),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jenis Koreksi: $jenisKoreksi',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColors[0], borderRadius: BorderRadius.circular(20)),
                child: Text(badgeText, style: TextStyle(color: badgeColors[1], fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Lama', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(data['jam_lama']),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, color: Color(0xFF94A3B8), size: 16),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Jam Baru', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(data['jam_baru']),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), // Green color for Jam Baru
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Pemohon', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    const SizedBox(height: 4),
                    Text(
                      'Anda',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailBox() {
    String alasan = data['alasan'] ?? data['alasan_koreksi'] ?? '-';
    if (alasan.startsWith('[') && alasan.contains(']')) {
      alasan = alasan.substring(alasan.indexOf(']') + 1).trim();
    }

    final String? buktiUrl = data['bukti_pendukung'] ?? data['lampiran'];
    String fileName = 'Bukti Pendukung.jpg';
    if (buktiUrl != null) {
      fileName = buktiUrl.split('/').last;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alasan Koreksi', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text('"$alasan"', style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500, height: 1.4)),
          const SizedBox(height: 16),
          const Text('Bukti Pendukung', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          if (buktiUrl != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE), // Light blue
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.image_outlined, color: Color(0xFF0284C7), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text('Format: IMAGE • 1.2 MB', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                    ),
                  ),
                  const Icon(Icons.download_outlined, color: Color(0xFF64748B), size: 20),
                ],
              ),
            )
          else
            const Text('-', style: TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
          
          if (_status == 'ditolak' || _status == 'rejected') ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Catatan Penolakan:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                  const SizedBox(height: 4),
                  Text(
                    '"${data['catatan_penolakan'] ?? data['rejection_reason'] ?? 'Tidak ada catatan.'}"',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                  ),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final bool isApproved = _status == 'disetujui' || _status == 'approved';
    final bool isRejected = _status == 'ditolak' || _status == 'rejected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Timeline Persetujuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _timelineStep(
            title: 'Koreksi Diajukan',
            subtitle: 'Diajukan oleh Anda',
            time: _formatDateTime(data['created_at']),
            isCompleted: true,
            isLast: false,
          ),
          _timelineStep(
            title: isApproved ? 'Disetujui Atasan' : (isRejected ? 'Pengajuan Ditolak' : 'Menunggu Persetujuan'),
            subtitle: isApproved || isRejected 
                ? '${isApproved ? 'Disetujui' : 'Ditolak'} oleh ${data['approved_by_l1_name'] ?? 'Budi Santoso (Manager)'}'
                : 'Menunggu tindakan dari ${data['atasan_name'] ?? 'Budi Santoso (Manager)'}',
            time: isApproved || isRejected ? _formatDateTime(data['updated_at']) : '',
            isCompleted: isApproved || isRejected,
            isRejected: isRejected,
            isWaiting: !isApproved && !isRejected,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _timelineStep({
    required String title,
    required String subtitle,
    required String time,
    required bool isCompleted,
    bool isRejected = false,
    bool isWaiting = false,
    required bool isLast,
  }) {
    Color dotColor = const Color(0xFF10B981); // Green
    if (isRejected) dotColor = const Color(0xFFEF4444); // Red
    else if (isWaiting) dotColor = const Color(0xFF2563EB); // Blue

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: const Color(0xFF10B981), // Green line connects to next step
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (time.isNotEmpty)
                  Text(
                    time,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
