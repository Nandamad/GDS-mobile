import 'package:flutter/material.dart';
import '../model/izin_cuti.dart';
import '../model/lembur.dart';

class DetailWorkflowScreen extends StatefulWidget {
  final IzinCuti? izinCuti;
  final Lembur? lembur;

  const DetailWorkflowScreen({super.key, this.izinCuti, this.lembur});

  @override
  State<DetailWorkflowScreen> createState() => _DetailWorkflowScreenState();
}

class _DetailWorkflowScreenState extends State<DetailWorkflowScreen> {
  int _selectedNavIndex = 2; // Index Pengajuan

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final List<String> bulan = [
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
    return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
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
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Ringkasan Cuti / Lembur
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Section Title Status Persetujuan
            const Text(
              'Status Persetujuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // Timeline Steps
            _buildTimeline(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSummaryCard() {
    final bool isCuti = widget.izinCuti != null;
    final String jenis = isCuti
        ? (widget.izinCuti?.jenis != null
              ? widget.izinCuti!.jenis!.toUpperCase()
              : 'Cuti Tahunan')
        : 'Pengajuan Lembur';
    final String status = isCuti
        ? (widget.izinCuti?.status ?? 'pending')
        : (widget.lembur?.status ?? 'pending');
    final String alasan = isCuti
        ? (widget.izinCuti?.alasan ?? 'Liburan keluarga')
        : (widget.lembur?.alasanLembur ?? 'Deadline tugas urgent');
    final String tanggalDiajukan = _formatDate(
      isCuti ? widget.izinCuti?.createdAt : widget.lembur?.createdAt,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                jenis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: status == 'approved'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'approved' ? 'Disetujui' : 'Pending Approval L2',
                  style: TextStyle(
                    color: status == 'approved'
                        ? const Color(0xFF15803D)
                        : const Color(0xFFC2410C),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildSummaryRow('Jenis', jenis),
          const SizedBox(height: 4),
          _buildSummaryRow(
            'Periode',
            isCuti
                ? '${_formatDate(widget.izinCuti?.tanggalMulai)} - ${_formatDate(widget.izinCuti?.tanggalSelesai)}'
                : _formatDate(widget.lembur?.tanggal),
          ),
          const SizedBox(height: 4),
          _buildSummaryRow('Diajukan', tanggalDiajukan),
          const SizedBox(height: 4),
          _buildSummaryRow('Alasan', alasan),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Column(
        children: [
          // Step 1: Pengajuan Dikirim
          _buildTimelineStep(
            title: 'Pengajuan Dikirim',
            subtitle: _formatDate(
              widget.izinCuti?.createdAt ?? widget.lembur?.createdAt,
            ),
            badgeText: 'Selesai',
            badgeBgColor: const Color(0xFFDCFCE7),
            badgeTextColor: const Color(0xFF15803D),
            isDone: true,
            isCurrent: false,
            isFirst: true,
            isLast: false,
          ),

          // Step 2: Persetujuan Atasan (L1)
          _buildTimelineStep(
            title: 'Persetujuan Atasan (Level 1)',
            subtitle:
                'Ahmad Fauzi (Manager IT)\n${_formatDate(widget.izinCuti?.approvedAt ?? widget.lembur?.approvedAtL1)}',
            note: widget.izinCuti?.catatanPersetujuan != null
                ? 'Catatan: ${widget.izinCuti?.catatanPersetujuan}'
                : 'Catatan: Silakan, selamat berlibur',
            badgeText: 'Disetujui',
            badgeBgColor: const Color(0xFFDCFCE7),
            badgeTextColor: const Color(0xFF15803D),
            isDone: true,
            isCurrent: false,
            isFirst: false,
            isLast: false,
          ),

          // Step 3: Persetujuan HRD (L2)
          _buildTimelineStep(
            title: 'Persetujuan HRD (Level 2)',
            subtitle: 'Siti Rahayu (HR Manager)',
            badgeText: 'Pending',
            badgeBgColor: const Color(0xFFFFEDD5),
            badgeTextColor: const Color(0xFFC2410C),
            isDone: false,
            isCurrent: true,
            isFirst: false,
            isLast: false,
          ),

          // Step 4: Selesai
          _buildTimelineStep(
            title: 'Selesai',
            subtitle: 'Proses Akhir Workflow',
            badgeText: 'Menunggu',
            badgeBgColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF94A3B8),
            isDone: false,
            isCurrent: false,
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    String? note,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required bool isDone,
    required bool isCurrent,
    required bool isFirst,
    required bool isLast,
  }) {
    Color lineColor = isDone ? const Color(0xFF009688) : Colors.grey.shade300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line & Indicator Icon
          Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 8,
                  color: isDone || isCurrent
                      ? const Color(0xFF009688)
                      : Colors.grey.shade300,
                ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? const Color(0xFF009688)
                      : isCurrent
                      ? Colors.orange
                      : Colors.white,
                  border: Border.all(
                    color: isDone
                        ? const Color(0xFF009688)
                        : isCurrent
                        ? Colors.orange
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: lineColor)),
            ],
          ),
          const SizedBox(width: 10),

          // Content Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: isDone || isCurrent
                              ? const Color(0xFF0F172A)
                              : Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) => setState(() => _selectedNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF009688),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      iconSize: 20,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Pengajuan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Notifikasi',
        ),
      ],
    );
  }
}
