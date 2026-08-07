import 'package:flutter/material.dart';

void main() {
  runApp(
    const MaterialApp(
      home: PresensiScreen(),
      debugShowCheckedModeBanner: false,
    ),
  );
}

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  // Warna tema utama dari gambar
  final Color primaryTeal = const Color(0xFF009688);
  final Color lightTealAccent = const Color(0xFFE0F2F1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // Status Bar terintegrasi
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '08:45',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Row(
                children: const [
                  Icon(
                    Icons.signal_cellular_alt,
                    color: Colors.black,
                    size: 18,
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.wifi, color: Colors.black, size: 18),
                  SizedBox(width: 4),
                  Icon(Icons.battery_std, color: Colors.black, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Judul dan Waktu
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Presensi Harian',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF263238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '08:45:12 WIB',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryTeal,
                    ),
                  ),
                ],
              ),
            ),

            // Card Informasi Lokasi, Shift, Radius
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.location_on_outlined,
                        'Lokasi Kantor',
                        'Kantor Pusat (Jl. Sudirman No. 123)',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.access_time_outlined,
                        'Jadwal Shift',
                        '08:00 - 17:00 WIB (8 Jam)',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.not_listed_location_outlined,
                        'Radius Toleransi: 100 Meter',
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bagian Peta
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 2.2, // Sesuaikan proporsi gambar peta
                  child: Container(
                    color: Colors.grey[200], // Placeholder untuk loading peta
                    // Di implementasi nyata, gunakan paket google_maps_flutter di sini
                    // Untuk replikasi UI, kita pakai Image.asset atau placeholder
                    child: Stack(
                      children: [
                        // Gambar latar peta (placeholder)
                        Image.network(
                          'https://via.placeholder.com/600x300.png?text=Peta+Lokasi', // Ganti dengan gambar peta nyata
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        // Efek melingkar di tengah
                        Center(
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: primaryTeal, width: 2),
                              color: primaryTeal.withOpacity(0.1),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.location_history,
                                color: primaryTeal,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                        // Pin Lokasi Merah
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ),
                        // Titik Biru Pengguna
                        Positioned(
                          top: 60,
                          left: 160, // Sesuaikan posisi
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Label Status Radius (Hijau Terang)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9), // Warna hijau sangat muda
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Dalam Radius Kantor (52m < 100m)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2E7D32), // Warna hijau tua untuk teks
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Baris Jam Masuk / Jam Pulang
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTimeStatusCard('Jam Masuk', 'Belum Absen'),
                  const SizedBox(width: 16),
                  _buildTimeStatusCard('Jam Pulang', 'Belum Absen'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Absen Masuk (Aktif)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Logika untuk Absen Masuk
                    print('Absen Masuk Ditekan');
                  },
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text(
                    'ABSEN MASUK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Tombol Absen Keluar (Tidak Aktif/Disabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: null, // 'null' membuat tombol menjadi disabled
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[400],
                  ),
                  label: Text(
                    'ABSEN KELUAR',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    side: BorderSide(color: Colors.grey[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 80), // Ruang ekstra untuk scrolling
          ],
        ),
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryTeal,
          unselectedItemColor: Colors.grey[500],
          currentIndex: 1, // Set index ke 'Presensi'
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle),
              label: 'Presensi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              label: 'Pengajuan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_none),
              label: 'Notifikasi',
            ),
          ],
        ),
      ),
    );
  }

  // Widget Pembantu untuk Baris Informasi (Card Atas)
  Widget _buildInfoRow(IconData icon, String title, [String? subtitle]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: primaryTeal, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF546E7A),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Widget Pembantu untuk Card Jam Masuk/Pulang
  Widget _buildTimeStatusCard(String title, String status) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF78909C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD32F2F), // Warna merah untuk 'Belum Absen'
              ),
            ),
          ],
        ),
      ),
    );
  }
}
