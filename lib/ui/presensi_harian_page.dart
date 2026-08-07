import 'dart:async';
import 'package:flutter/material.dart';
import 'kamera_page.dart';
import 'konfirmasi_foto_page.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  // Warna tema utama
  final Color primaryTeal = const Color(0xFF009688);
  final Color lightTealAccent = const Color(0xFFE0F2F1);

  // Realtime Clock State
  late Timer _timer;
  String _currentTime = '';

  // Status Absensi
  String _jamMasuk = 'Belum Absen';
  String _jamKeluar = 'Belum Absen';
  bool _isSudahAbsenMasuk = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');
    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute:$second WIB';
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Alur Navigasi Presensi: Presensi -> Kamera -> Konfirmasi
  Future<void> _handleAbsenMasuk() async {
    // 1. Buka Kamera
    final resultImage = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const KameraScreen()),
    );

    if (resultImage != null && mounted) {
      // 2. Buka Konfirmasi Foto jika mengambil foto
      final isConfirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => KonfirmasiFotoScreen(imageBase64: resultImage),
        ),
      );

      // 3. Update UI jika konfirmasi sukses
      if (isConfirmed == true && mounted) {
        final now = DateTime.now();
        final timeString =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';
        setState(() {
          _jamMasuk = timeString;
          _isSudahAbsenMasuk = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _currentTime.length >= 5 ? _currentTime.substring(0, 5) : '08:45',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Row(
                children: [
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
                    _currentTime.isEmpty ? '08:45:12 WIB' : _currentTime,
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
                  aspectRatio: 2.2,
                  child: Container(
                    color: Colors.grey[200],
                    child: Stack(
                      children: [
                        Image.network(
                          'https://via.placeholder.com/600x300.png?text=Peta+Lokasi',
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
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
                        Positioned(
                          top: 60,
                          left: 160,
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
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Dalam Radius Kantor (52m < 100m)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF2E7D32),
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
                  _buildTimeStatusCard('Jam Masuk', _jamMasuk, isDone: _isSudahAbsenMasuk),
                  const SizedBox(width: 16),
                  _buildTimeStatusCard('Jam Pulang', _jamKeluar, isDone: false),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Tombol Absen Masuk
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSudahAbsenMasuk ? null : _handleAbsenMasuk,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _isSudahAbsenMasuk ? 'SUDAH ABSEN MASUK' : 'ABSEN MASUK',
                    style: const TextStyle(
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

            // Tombol Absen Keluar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isSudahAbsenMasuk ? () {} : null,
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: _isSudahAbsenMasuk ? primaryTeal : Colors.grey[400],
                  ),
                  label: Text(
                    'ABSEN KELUAR',
                    style: TextStyle(
                      color: _isSudahAbsenMasuk ? primaryTeal : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _isSudahAbsenMasuk ? lightTealAccent : Colors.grey[100],
                    side: BorderSide(
                        color: _isSudahAbsenMasuk ? primaryTeal : Colors.grey[200]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      // PERHATIAN: bottomNavigationBar dihapus dari sini
    );
  }

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

  Widget _buildTimeStatusCard(String title, String status, {bool isDone = false}) {
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDone ? const Color(0xFF2E7D32) : const Color(0xFFD32F2F),
              ),
            ),
          ],
        ),
      ),
    );
  }
}