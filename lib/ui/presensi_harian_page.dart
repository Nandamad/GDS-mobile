import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../api_config.dart';
import '../services/api_service.dart';
import '../model/jam_kerja.dart'; 
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

  late Timer _timer;
  String _currentTime = '';

  // Variable State untuk menampung Model JamKerja
  JamKerja? _jamKerja;

  String _jamMasuk = 'Belum Absen';
  String _jamKeluar = 'Belum Absen';
  bool _isSudahAbsenMasuk = false;
  bool _isSudahAbsenKeluar = false;

  LatLng? _officeLocation;

  double _radiusMeters = 0.0;
  double _maxRadiusMeters = 0.0;
  bool _isInRadius = false;

  String _namaKantor = 'Memuat lokasi kantor...';
  String _alamatKantor = '';

  LatLng _currentLocation = const LatLng(-7.7279, 109.0089);
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();

    _updateTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );

    _loadOfficeLocation();
    _determinePosition();
    _checkTodayAttendance();
  }

  void _calculateOfficeDistance() {
    if (_officeLocation == null || _maxRadiusMeters <= 0) {
      return;
    }

    final distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      _officeLocation!.latitude,
      _officeLocation!.longitude,
    );

    if (!mounted) return;

    setState(() {
      _radiusMeters = distance;
      _isInRadius = distance <= _maxRadiusMeters;
    });

    debugPrint(
      'GPS USER: ${_currentLocation.latitude}, ${_currentLocation.longitude}',
    );
    debugPrint(
      'GPS KANTOR: ${_officeLocation!.latitude}, ${_officeLocation!.longitude}',
    );
    debugPrint(
      'JARAK: ${distance.toStringAsFixed(2)} meter',
    );
    debugPrint(
      'RADIUS: ${_maxRadiusMeters.toStringAsFixed(2)} meter',
    );
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

  Future<void> _loadOfficeLocation() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;

      final response = await dio.get('/profile');

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final karyawan = data['karyawan'];
        final kantor = karyawan?['kantor'];

        if (kantor == null) {
          throw Exception('Data kantor karyawan belum tersedia.');
        }

        final latitude = double.tryParse(
          kantor['latitude'].toString(),
        );

        final longitude = double.tryParse(
          kantor['longitude'].toString(),
        );

        final radius = double.tryParse(
          kantor['radius_toleransi_meter'].toString(),
        );

        if (latitude == null || longitude == null || radius == null) {
          throw Exception('Koordinat atau radius kantor tidak valid.');
        }

        if (!mounted) return;

        setState(() {
          _officeLocation = LatLng(
            latitude,
            longitude,
          );

          _maxRadiusMeters = radius;

          _namaKantor =
              kantor['nama_kantor']?.toString() ?? 'Kantor';

          _alamatKantor =
              kantor['alamat_lengkap']?.toString() ?? '';
        });

        if (!_isLoadingLocation) {
          _calculateOfficeDistance();
        }
      }
    } on DioException catch (e) {
      debugPrint(
        'Gagal mengambil lokasi kantor: '
            '${e.response?.data ?? e.message}',
      );
    } catch (e) {
      debugPrint('Error lokasi kantor: $e');
    }
  }

  Future<bool> _submitAbsensi({
    required String tipe,
    required String fotoBase64,
  }) async {
    try {
      final token = await ApiService().getToken();
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi login tidak ditemukan. Silakan login ulang.'),
            ),
          );
        }
        return false;
      }

      String base64String = fotoBase64;

      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      Uint8List imageBytes = base64Decode(base64String);

      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(
          imageBytes,
          filename: 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'tipe': tipe,
      });

      final dio = ApiService().dio;

      final response = await dio.post(
        '/absensi',
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      return false;

    } on DioException catch (e) {

      final message =
          e.response?.data?['message']?.toString() ??
              'Gagal mengirim presensi ke server.';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      return false;

    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
          ),
        );
      }

      return false;
    }
  }

  Future<void> _checkTodayAttendance() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = ApiService().dio;

      final response = await dio.get('/absensi/today');

      debugPrint('RESPON API ABSENSI: ${jsonEncode(response.data)}');

      if (response.statusCode != 200) return;

      final responseData = response.data;

      final data = responseData['data'];
      final kantor = responseData['kantor'];
      final jamKerjaJson = responseData['jam_kerja']; // Ambil root jam_kerja

      if (!mounted) return;

      setState(() {
        // =========================
        // 1. DATA JAM KERJA
        // =========================
        if (jamKerjaJson != null) {
          _jamKerja = JamKerja.fromJson(jamKerjaJson);
        }

        // =========================
        // 2. DATA KANTOR DARI SERVER
        // =========================
        if (kantor != null) {
          final latitude = double.tryParse(
            kantor['latitude'].toString(),
          );

          final longitude = double.tryParse(
            kantor['longitude'].toString(),
          );

          final radius = double.tryParse(
            kantor['radius_toleransi_meter'].toString(),
          );

          if (latitude != null && longitude != null) {
            _officeLocation = LatLng(
              latitude,
              longitude,
            );
          }

          if (radius != null) {
            _maxRadiusMeters = radius;
          }

          _namaKantor =
              kantor['nama_kantor']?.toString() ?? 'Kantor';

          _alamatKantor =
              kantor['alamat']?.toString() ?? '';
        }

        // =========================
        // 3. DATA ABSENSI
        // =========================
        if (data != null && data is Map) {
          final jamMasuk = data['jam_masuk'];

          if (jamMasuk != null &&
              jamMasuk.toString().isNotEmpty) {
            _jamMasuk = jamMasuk.toString();
            _isSudahAbsenMasuk = true;
          }

          final jamKeluar = data['jam_keluar'];

          if (jamKeluar != null &&
              jamKeluar.toString().isNotEmpty) {
            _jamKeluar = jamKeluar.toString();
            _isSudahAbsenKeluar = true;
          }
        }
      });

      _calculateOfficeDistance();

    } on DioException catch (e) {
      debugPrint(
        'ERROR TODAY: ${e.response?.data}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.response?.data?['message']?.toString() ??
                  'Gagal mengambil data presensi.',
            ),
          ),
        );
      }

    } catch (e) {
      debugPrint('ERROR TODAY: $e');
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Layanan GPS/Lokasi tidak aktif.'),
          ),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        _isLoadingLocation = false;
      });

      if (_officeLocation != null) {
        _calculateOfficeDistance();
      }
    } catch (e) {
      debugPrint('Gagal mendapatkan GPS: $e');

      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _handleAbsenMasuk() async {
    final resultImage = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const KameraScreen(),
      ),
    );

    if (resultImage == null || !mounted) return;

    final isConfirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => KonfirmasiFotoScreen(
          imageBase64: resultImage,
          currentLocation: _currentLocation,
          namaKantor: _namaKantor,
          alamatKantor: _alamatKantor,
          jarakMeter: _radiusMeters,
          isInRadius: _isInRadius,
        ),
      ),
    );

    if (isConfirmed != true || !mounted) return;

    final berhasil = await _submitAbsensi(
      tipe: 'masuk',
      fotoBase64: resultImage,
    );

    if (!berhasil || !mounted) return;

    await _checkTodayAttendance();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Absen masuk berhasil disimpan.'),
      ),
    );
  }

  Future<void> _handleAbsenKeluar() async {
    final resultImage = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const KameraScreen(),
      ),
    );

    if (resultImage == null || !mounted) return;

    final isConfirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => KonfirmasiFotoScreen(
          imageBase64: resultImage,
          currentLocation: _currentLocation,
          namaKantor: _namaKantor,
          alamatKantor: _alamatKantor,
          jarakMeter: _radiusMeters,
          isInRadius: _isInRadius,
        ),
      ),
    );

    if (isConfirmed != true || !mounted) return;

    final berhasil = await _submitAbsensi(
      tipe: 'pulang',
      fotoBase64: resultImage,
    );

    if (!berhasil || !mounted) return;

    await _checkTodayAttendance();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Absen pulang berhasil disimpan.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _alamatKantor.isNotEmpty
                            ? '$_namaKantor ($_alamatKantor)'
                            : _namaKantor,
                      ),
                      const Divider(height: 24),
                      // Memanggil getter formattedSchedule dari _jamKerja
                      _buildInfoRow(
                        Icons.access_time_outlined,
                        'Jadwal Shift',
                        _jamKerja?.formattedSchedule ?? 'Belum ada jadwal',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.not_listed_location_outlined,
                        'Radius Toleransi: ${_maxRadiusMeters.toStringAsFixed(0)} Meter',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                                if (_officeLocation != null)
                                  Marker(
                                    point: _officeLocation!,
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
                          ? 'Dalam Radius Kantor (${_radiusMeters.toStringAsFixed(0)}m ≤ ${_maxRadiusMeters.toStringAsFixed(0)}m)'
                          : 'Di Luar Radius Kantor (${_radiusMeters.toStringAsFixed(0)}m > ${_maxRadiusMeters.toStringAsFixed(0)}m)',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  _buildTimeStatusCard('Jam Masuk', _jamMasuk, isDone: _isSudahAbsenMasuk),
                  const SizedBox(width: 16),
                  _buildTimeStatusCard('Jam Pulang', _jamKeluar, isDone: _isSudahAbsenKeluar),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: (_isSudahAbsenMasuk && !_isSudahAbsenKeluar)
                      ? _handleAbsenKeluar
                      : null,
                  icon: Icon(
                    Icons.camera_alt_outlined,
                    color: (_isSudahAbsenMasuk && !_isSudahAbsenKeluar)
                        ? primaryTeal
                        : Colors.grey[400],
                  ),
                  label: Text(
                    _isSudahAbsenKeluar ? 'SUDAH ABSEN KELUAR' : 'ABSEN KELUAR',
                    style: TextStyle(
                      color: (_isSudahAbsenMasuk && !_isSudahAbsenKeluar)
                          ? primaryTeal
                          : Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: (_isSudahAbsenMasuk && !_isSudahAbsenKeluar)
                        ? lightTealAccent
                        : Colors.grey[100],
                    side: BorderSide(
                        color: (_isSudahAbsenMasuk && !_isSudahAbsenKeluar)
                            ? primaryTeal
                            : Colors.grey[200]!),
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