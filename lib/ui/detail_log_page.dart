import 'package:flutter/material.dart';

class DetailLogScreen extends StatefulWidget {
  const DetailLogScreen({super.key});

  @override
  State<DetailLogScreen> createState() => _DetailLogScreenState();
}

class _DetailLogScreenState extends State<DetailLogScreen> {
  int _selectedNavIndex = 3; // Index Riwayat (Active)

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
          'Detail Log Presensi',
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
            // Header Info Card
            _buildHeaderCard(),
            const SizedBox(height: 14),

            // Section Rekap Waktu
            _buildSectionTitle('REKAP WAKTU'),
            const SizedBox(height: 6),
            _buildRekapWaktuRow(),
            const SizedBox(height: 14),

            // Section Total Durasi Kerja
            _buildSectionTitle('TOTAL DURASI KERJA'),
            const SizedBox(height: 6),
            _buildDurasiBanner(),
            const SizedBox(height: 14),

            // Section Detail Lokasi GPS
            _buildSectionTitle('DETAIL LOKASI GPS'),
            const SizedBox(height: 6),
            _buildGpsCard(),
            const SizedBox(height: 14),

            // Section Foto Verifikasi
            _buildSectionTitle('FOTO VERIFIKASI'),
            const SizedBox(height: 6),
            _buildFotoVerifikasiRow(),
            const SizedBox(height: 14),

            // Section Catatan
            _buildSectionTitle('CATATAN'),
            const SizedBox(height: 6),
            _buildCatatanCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rabu, 05 Agustus 2026',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Terlambat +15m',
                  style: TextStyle(
                    color: Color(0xFFC2410C),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                'Shift: ',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                '08:00 - 17:00 WIB (8 Jam)',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                'Lokasi: ',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'Kantor Pusat',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekapWaktuRow() {
    return Row(
      children: [
        // Card Jam Masuk
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JAM MASUK',
                  style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '08:15 WIB',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Terlambat 15m',
                    style: TextStyle(fontSize: 8, color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Card Jam Pulang
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JAM PULANG',
                  style: TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  '17:05 WIB',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Normal',
                    style: TextStyle(fontSize: 8, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurasiBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Text(
                'Durasi Aktual',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          Text(
            '8 Jam 50 Menit',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildGpsItem(
            title: 'Lokasi Masuk',
            address: 'Kantor Pusat (Jl. Sudirman No. 123)',
            distance: 'Jarak: 45m dari titik kantor',
          ),
          const Divider(height: 20),
          _buildGpsItem(
            title: 'Lokasi Pulang',
            address: 'Kantor Pusat (Jl. Sudirman No. 123)',
            distance: 'Jarak: 32m dari titik kantor',
          ),
        ],
      ),
    );
  }

  Widget _buildGpsItem({
    required String title,
    required String address,
    required String distance,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.near_me_outlined, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.check, size: 10, color: Color(0xFF16A34A)),
                  const SizedBox(width: 2),
                  Text(
                    distance,
                    style: const TextStyle(fontSize: 9, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoVerifikasiRow() {
    return Row(
      children: [
        _buildFotoCard('Foto Masuk', '08:15 WIB', 'https://i.pravatar.cc/300?img=11'),
        const SizedBox(width: 8),
        _buildFotoCard('Foto Pulang', '17:05 WIB', 'https://i.pravatar.cc/300?img=12'),
      ],
    );
  }

  Widget _buildFotoCard(String label, String time, String imageUrl) {
    return Expanded(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 9, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text(
        'Tidak ada catatan untuk hari ini.',
        style: TextStyle(fontSize: 10, color: Colors.grey),
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
          icon: Icon(Icons.assignment_outlined),
          label: 'Pengajuan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted),
          activeIcon: Icon(Icons.format_list_bulleted_sharp),
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