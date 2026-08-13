import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Package untuk GPS
import 'package:flutter_map/flutter_map.dart'; // Package untuk Peta Interaktif
import 'package:latlong2/latlong.dart'; // Package titik koordinat
import 'kamera_page.dart';
import 'konfirmasi_foto_page.dart';

class PresensiScreen extends StatefulWidget {
  const PresensiScreen({super.key});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  final Color primaryTeal = const Color(0xFF009688);
  final Color lightTealAccent = const Color(0xFFE0F2F1);

  // Realtime Clock State
  late Timer _timer;
  String _currentTime = '';

  // Status Absensi
  String _jamMasuk = 'Belum Absen';
  String _jamKeluar = 'Belum Absen';
  bool _isSudahAbsenMasuk = false;

  // Koordinat Kantor (Contoh: Kantor Pusat)
  final LatLng _officeLocation = const LatLng(-6.2088, 106.8456);
  double _radiusMeters = 0.0;
  bool _isInRadius = false;

  // Koordinat User Real-time
  LatLng _currentLocation = const LatLng(-6.2088, 106.8456);
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    _determinePosition(); // Ambil lokasi GPS saat halaman dibuka
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

  // Fungsi untuk mendapatkan lokasi GPS HP secara real-time
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Cek apakah Layanan GPS aktif
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Layanan GPS/Lokasi tidak aktif. Mohon aktifkan GPS.')),
        );
      }
      return;
    }

    // Cek izin akses lokasi
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin akses lokasi ditolak.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Ambil posisi terkini
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);

      // Hitung jarak antara posisi user dan kantor (dalam meter)
      _radiusMeters = Geolocator.distanceBetween(
        _currentLocation.latitude,
        _currentLocation.longitude,
        _officeLocation.latitude,
        _officeLocation.longitude,
      );

      // Tentukan apakah dalam radius 100 meter
      _isInRadius = _radiusMeters <= 100;
      _isLoadingLocation = false;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _handleAbsenMasuk() async {
    final resultImage = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const KameraScreen()),
    );

    if (resultImage != null && mounted) {
      final isConfirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => KonfirmasiFotoScreen(imageBase64: resultImage),
        ),
      );

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
                  Icon(Icons.signal_cellular_alt, color: Colors.black, size: 18),
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
            // Header Waktu
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

            // Card Informasi Lokasi Kantor & Shift
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
                        'Kantor Pusat (Jl. Rinjani Ruko No. 09)',
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

            // BAGIAN PETA INTERAKTIF MENGGANTIKAN GAMBAR STATIS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: AspectRatio(
                  aspectRatio: 2.2,
                  child: _isLoadingLocation
                      ? Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                      : FlutterMap(
                    options: MapOptions(
                      initialCenter: _currentLocation,
                      initialZoom: 16.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.presensiku.app',
                      ),
                      MarkerLayer(
                        markers: [
                          // Marker Posisi User (Biru)
                          Marker(
                            point: _currentLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.blue,
                              size: 35,
                            ),
                          ),
                          // Marker Posisi Kantor (Merah)
                          Marker(
                            point: _officeLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 35,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Label Status Radius Dinamis (Hijau / Merah)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _isInRadius ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  _isLoadingLocation
                      ? 'Mendeteksi lokasi GPS...'
                      : _isInRadius
                      ? 'Dalam Radius Kantor (${_radiusMeters.toStringAsFixed(0)}m < 100m)'
                      : 'Di Luar Radius Kantor (${_radiusMeters.toStringAsFixed(0)}m > 100m)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isInRadius ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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

            // Tombol Absen Masuk (Bisa dibatasi hanya bisa absen jika _isInRadius bernilai true)
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

  // PERBAIKAN WIDGET _buildTimeStatusCard
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