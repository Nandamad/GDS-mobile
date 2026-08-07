import 'package:flutter/material.dart';

class KinerjaPresensiScreen extends StatefulWidget {
  const KinerjaPresensiScreen({super.key});

  @override
  State<KinerjaPresensiScreen> createState() => _KinerjaPresensiScreenState();
}

class _KinerjaPresensiScreenState extends State<KinerjaPresensiScreen> {
  String _selectedMonth = 'Agustus 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Kinerja Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedMonth,
                    isDense: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 18),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                    items: ['Agustus 2026', 'Juli 2026', 'Juni 2026'].map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Kehadiran & Absensi
            const Text(
              'Kehadiran & Absensi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            _buildAttendanceGrid(),
            const SizedBox(height: 16),

            // Section Log Keterlambatan & Pulang Awal
            const Text(
              'Log Keterlambatan & Pulang Awal',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            _buildLogCards(),
            const SizedBox(height: 14),

            // Warning Banner Payroll Impact
            _buildPayrollWarningBanner(),
          ],
        ),
      ),
      // PERHATIAN: bottomNavigationBar dihapus dari sini
    );
  }

  Widget _buildAttendanceGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: const [
        _AttendanceCard(title: 'Hadir', count: '18 Hari', percentage: '(72%)', color: Colors.teal),
        _AttendanceCard(title: 'Terlambat', count: '3 Hari', percentage: '(12%)', color: Colors.orange),
        _AttendanceCard(title: 'Izin', count: '2 Hari', percentage: '(8%)', color: Colors.blue),
        _AttendanceCard(title: 'Cuti', count: '2 Hari', percentage: '(8%)', color: Colors.purple),
        _AttendanceCard(title: 'Sakit', count: '0 Hari', percentage: '(0%)', color: Colors.amber),
        _AttendanceCard(title: 'Alpha', count: '0 Hari', percentage: '(0%)', color: Colors.red),
      ],
    );
  }

  Widget _buildLogCards() {
    return Column(
      children: [
        _buildLogCard(
          date: '04 Agt',
          badgeText: 'Terlambat',
          badgeBgColor: const Color(0xFFFEF3C7),
          badgeTextColor: const Color(0xFFD97706),
          timeDiff: '-15m',
          atasanStatus: 'Pending',
          hrdStatus: 'Waiting',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detail Log Keterlambatan')),
            );
          },
        ),
        const SizedBox(height: 8),
        _buildLogCard(
          date: '01 Agt',
          badgeText: 'Pulang Awal',
          badgeBgColor: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFDC2626),
          timeDiff: '-30m',
          atasanStatus: 'OK',
          hrdStatus: 'Pending',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Detail Log Pulang Awal')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogCard({
    required String date,
    required String badgeText,
    required Color badgeBgColor,
    required Color badgeTextColor,
    required String timeDiff,
    required String atasanStatus,
    required String hrdStatus,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  date,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 6),
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
                      fontSize: 8,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  timeDiff,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Persetujuan:   ',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
                Text(
                  'Atasan: ',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                Text(
                  atasanStatus,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: atasanStatus == 'OK' ? Colors.green.shade700 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HRD: ',
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                Text(
                  hrdStatus,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: const Column(
        children: [
          Text(
            'Potensi Dampak Payroll: Ya',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Color(0xFFEF4444),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Keterlambatan yang belum disetujui dapat memotong tunjangan kehadiran bulan ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              color: Color(0xFF7F1D1D),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final String title;
  final String count;
  final String percentage;
  final Color color;

  const _AttendanceCard({
    required this.title,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '$count ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ),
                TextSpan(
                  text: percentage,
                  style: const TextStyle(color: Colors.grey, fontSize: 8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}