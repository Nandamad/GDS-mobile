import 'package:flutter/material.dart';

class RiwayatPresensiScreen extends StatefulWidget {
  const RiwayatPresensiScreen({super.key});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  String _selectedMonth = 'Agustus 2026';
  String _selectedStatus = 'Semua Status';

  // Master Data Riwayat
  final List<Map<String, dynamic>> _allHistoryData = [
    {
      'month': 'Agustus 2026',
      'date': 'Rabu, 05 Agt 2026',
      'statusText': 'Terlambat +15m',
      'statusCategory': 'Terlambat',
      'statusBgColor': const Color(0xFFFFF3E0),
      'statusTextColor': const Color(0xFFE65100),
      'checkIn': '08:15',
      'checkOut': '17:05',
      'duration': '8h 50m',
      'hasDetailButton': true,
    },
    {
      'month': 'Agustus 2026',
      'date': 'Selasa, 04 Agt 2026',
      'statusText': 'On Time',
      'statusCategory': 'On Time',
      'statusBgColor': const Color(0xFFE8F5E9),
      'statusTextColor': const Color(0xFF2E7D32),
      'checkIn': '08:00',
      'checkOut': '17:00',
      'duration': '8h 00m',
      'hasDetailButton': false,
    },
    {
      'month': 'Agustus 2026',
      'date': 'Senin, 03 Agt 2026',
      'statusText': 'On Time',
      'statusCategory': 'On Time',
      'statusBgColor': const Color(0xFFE8F5E9),
      'statusTextColor': const Color(0xFF2E7D32),
      'checkIn': '07:55',
      'checkOut': '17:10',
      'duration': '8h 15m',
      'hasDetailButton': false,
    },
    {
      'month': 'Juli 2026',
      'date': 'Jumat, 31 Jul 2026',
      'statusText': 'Terlambat +30m',
      'statusCategory': 'Terlambat',
      'statusBgColor': const Color(0xFFFFF3E0),
      'statusTextColor': const Color(0xFFE65100),
      'checkIn': '08:30',
      'checkOut': '17:00',
      'duration': '8h 30m',
      'hasDetailButton': true,
    },
    {
      'month': 'Juli 2026',
      'date': 'Kamis, 30 Jul 2026',
      'statusText': 'Izin Ditolak',
      'statusCategory': 'Izin',
      'statusBgColor': const Color(0xFFFFEBEE),
      'statusTextColor': const Color(0xFFC62828),
      'checkIn': '-',
      'checkOut': '-',
      'duration': '0m',
      'hasDetailButton': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Presensi',
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
          children: [
            // Dropdown Filter
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    value: _selectedMonth,
                    items: ['Agustus 2026', 'Juli 2026', 'Juni 2026'],
                    onChanged: (val) => setState(() => _selectedMonth = val!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDropdown(
                    value: _selectedStatus,
                    items: ['Semua Status', 'On Time', 'Terlambat', 'Izin'],
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // List Cards Riwayat
            _buildHistoryList(),
          ],
        ),
      ),
      // bottomNavigationBar dihapus dari sini
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryList() {
    // Filter data berdasar Bulan dan Status
    final filteredData = _allHistoryData.where((item) {
      final matchesMonth = item['month'] == _selectedMonth;
      final matchesStatus = _selectedStatus == 'Semua Status' ||
          item['statusCategory'] == _selectedStatus;
      return matchesMonth && matchesStatus;
    }).toList();

    if (filteredData.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Column(
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 40, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Tidak ada data riwayat presensi',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredData.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: _buildAttendanceCard(
            date: item['date'],
            statusText: item['statusText'],
            statusBgColor: item['statusBgColor'],
            statusTextColor: item['statusTextColor'],
            checkIn: item['checkIn'],
            checkOut: item['checkOut'],
            duration: item['duration'],
            hasDetailButton: item['hasDetailButton'],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAttendanceCard({
    required String date,
    required String statusText,
    required Color statusBgColor,
    required Color statusTextColor,
    required String checkIn,
    required String checkOut,
    required String duration,
    bool hasDetailButton = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          // Row Header Card: Tanggal & Badge Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row Informasi Masuk, Pulang, Durasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn('Masuk', checkIn),
              _buildTimeColumn('Pulang', checkOut),
              _buildTimeColumn('Durasi', duration),
            ],
          ),

          // Tombol Detail Log
          if (hasDetailButton) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Membuka Detail Log...')),
                  );
                },
                icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
                label: const Text(
                  'Detail Log',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE0F2F1),
                  foregroundColor: const Color(0xFF009688),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}