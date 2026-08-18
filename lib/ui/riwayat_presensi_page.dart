import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api_config.dart';
import '../services/api_service.dart';
import 'detail_log_page.dart'; // Diperbarui: Tambahkan import ini

class RiwayatPresensiScreen extends StatefulWidget {
  const RiwayatPresensiScreen({super.key});

  @override
  State<RiwayatPresensiScreen> createState() => _RiwayatPresensiScreenState();
}

class _RiwayatPresensiScreenState extends State<RiwayatPresensiScreen> {
  String _selectedMonth = 'Agustus 2026';
  String _selectedStatus = 'Semua Status';

  bool _isLoading = true;
  List<Map<String, dynamic>> _allHistoryData = [];

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;

      final response = await dio.get('/history');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final parsedData = data.map((item) {
          final isCuti = item['tipe'] != 'Kehadiran';
          Color bgColor = const Color(0xFFE8F5E9);
          Color txtColor = const Color(0xFF2E7D32);
          String statusTxt = item['status_kehadiran'] ?? '-';
          String statusCat = isCuti ? 'Izin' : statusTxt;

          if (statusTxt == 'terlambat' || statusTxt == 'rejected') {
            bgColor = const Color(0xFFFFF3E0);
            txtColor = const Color(0xFFE65100);
          } else if (statusTxt == 'pending') {
            bgColor = const Color(0xFFFFF9C4);
            txtColor = const Color(0xFFF57F17);
          }

          return {
            'month': 'Agustus 2026',
            'date': item['tanggal'] ?? '-',
            'statusText': statusTxt.toUpperCase(),
            'statusCategory': statusCat,
            'statusBgColor': bgColor,
            'statusTextColor': txtColor,
            'checkIn': item['jam_masuk'] ?? '-',
            'checkOut': item['jam_pulang'] ?? '-',
            'duration': '-',
            'hasDetailButton': true, // Diperbarui: Aktifkan tombol detail log
          };
        }).toList();

        setState(() {
          _allHistoryData = parsedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat presensi')),
        );
      }
    }
  }

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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
        : SingleChildScrollView(
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
                  // Diperbarui: Pindah ke halaman DetailLogPresensiScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DetailLogScreen(),
                    ),
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