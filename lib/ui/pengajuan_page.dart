import 'package:flutter/material.dart';
import 'ajukan_cuti_page.dart';
import 'ajukan_lembur_page.dart';
import 'detail_workflow_page.dart';

// Notifier Global untuk menyimpan data riwayat pengajuan secara realtime
final ValueNotifier<List<Map<String, dynamic>>> submissionHistoryList = ValueNotifier<List<Map<String, dynamic>>>([
  {
    'type': 'Cuti/Izin',
    'badgeText': 'Cuti',
    'badgeBgColor': const Color(0xFFE0F2FE),
    'badgeTextColor': const Color(0xFF0284C7),
    'title': 'Cuti Tahunan - 5 Hari',
    'statusText': 'Pending Approval L1',
    'statusBgColor': const Color(0xFFFFEDD5),
    'statusTextColor': const Color(0xFFC2410C),
    'dateRange': '06-10 Agt 2026',
    'submittedDate': 'Diajukan: 01 Agt 2026',
  },
  {
    'type': 'Lembur',
    'badgeText': 'Lembur',
    'badgeBgColor': const Color(0xFFFEF3C7),
    'badgeTextColor': const Color(0xFFD97706),
    'title': '2 Jam Lembur',
    'statusText': 'L1 Disetujui, L2 Pending',
    'statusBgColor': const Color(0xFFFFEDD5),
    'statusTextColor': const Color(0xFFC2410C),
    'dateRange': '04 Agt 2026, 17:00-19:00',
    'submittedDate': 'Diajukan: 04 Agt 2026',
  },
  {
    'type': 'Cuti/Izin',
    'badgeText': 'Izin',
    'badgeBgColor': const Color(0xFFE0E7FF),
    'badgeTextColor': const Color(0xFF4338CA),
    'title': 'Izin Pribadi - 1 Hari',
    'statusText': 'Pending Approval L1',
    'statusBgColor': const Color(0xFFFFEDD5),
    'statusTextColor': const Color(0xFFC2410C),
    'dateRange': '15 Agt 2026',
    'submittedDate': 'Diajukan: 01 Agt 2026',
  },
]);

class PengajuanScreen extends StatefulWidget {
  const PengajuanScreen({super.key});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  int _selectedFilter = 0; // 0: Semua, 1: Cuti/Izin, 2: Lembur

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Pengajuan',
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
            _buildActionCard(
              icon: Icons.assignment_outlined,
              iconBgColor: const Color(0xFFE0F2FE),
              iconColor: const Color(0xFF0284C7),
              title: 'Ajukan Cuti / Izin',
              subtitle: 'Permohonan cuti, izin, atau sakit',
              onTap: () => AjukanCutiSheet.show(context),
            ),
            const SizedBox(height: 10),
            _buildActionCard(
              icon: Icons.access_time_rounded,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Ajukan Lembur',
              subtitle: 'Permohonan jam kerja tambahan',
              onTap: () => AjukanLemburSheet.show(context),
            ),
            const SizedBox(height: 18),

            const Text(
              'Riwayat Pengajuan Terbaru',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),

            _buildFilterTabs(),
            const SizedBox(height: 12),

            // Menggunakan ValueListenableBuilder agar daftar otomatis bertambah saat data di-push
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: submissionHistoryList,
              builder: (context, history, _) {
                return _buildHistoryList(history);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final labels = ['Semua', 'Cuti/Izin', 'Lembur'];
    return Row(
      children: List.generate(labels.length, (index) {
        final isSelected = _selectedFilter == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == labels.length - 1 ? 0 : 8),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF009688) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  labels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> allHistory) {
    final filteredList = allHistory.where((item) {
      if (_selectedFilter == 1) return item['type'] == 'Cuti/Izin';
      if (_selectedFilter == 2) return item['type'] == 'Lembur';
      return true;
    }).toList();

    if (filteredList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Tidak ada riwayat pengajuan',
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: filteredList.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildHistoryCard(
            badgeText: item['badgeText'],
            badgeBgColor: item['badgeBgColor'],
            badgeTextColor: item['badgeTextColor'],
            title: item['title'],
            statusText: item['statusText'],
            statusBgColor: item['statusBgColor'],
            statusTextColor: item['statusTextColor'],
            dateRange: item['dateRange'],
            submittedDate: item['submittedDate'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryCard({
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String title,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String dateRange,
    required String submittedDate,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dateRange,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    submittedDate,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DetailWorkflowScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Detail Workflow >',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF009688),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}