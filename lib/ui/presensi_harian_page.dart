import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'kamera_page.dart';
import 'konfirmasi_foto_page.dart';
import 'koreksi_presensi_page.dart';

class PresensiScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const PresensiScreen({super.key, this.onNotificationTap});

  @override
  State<PresensiScreen> createState() => _PresensiScreenState();
}

class _PresensiScreenState extends State<PresensiScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  late Timer _timer;
  String _currentTime = '00:00';

  bool _isSudahAbsenMasuk = false;
  bool _isSudahAbsenKeluar = false;

  Map<String, dynamic>? _lemburData;
  DateTime? _serverTime;
  String _lemburStatus = '';
  String _lemburCountdown = '';

  LatLng? _officeLocation;
  double _radiusMeters = 0.0;
  double _maxRadiusMeters = 0.0;
  bool _isInRadius = false;

  String _namaKantor = 'Kantor';
  String _alamatKantor = '';

  LatLng _currentLocation = const LatLng(-7.7279, 109.0089);

  @override
  void initState() {
    super.initState();

    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );

    _determinePosition();
    _fetchPresensiData();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute';

        if (_serverTime != null) {
          _serverTime = _serverTime!.add(const Duration(seconds: 1));
          
          if (_lemburData != null) {
            final mulai = DateTime.parse(_lemburData!['jam_mulai']);
            final selesai = DateTime.parse(_lemburData!['jam_selesai']);
            
            if (_serverTime!.isAfter(mulai) && _serverTime!.isBefore(selesai)) {
              _lemburStatus = 'Sedang Lembur';
              final diff = selesai.difference(_serverTime!);
              final h = diff.inHours.toString().padLeft(2, '0');
              final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
              final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
              _lemburCountdown = '$h:$m:$s';
            } else if (_serverTime!.isAfter(selesai)) {
              _lemburStatus = 'Selesai';
              _lemburCountdown = 'Lembur Selesai';
            } else {
              _lemburStatus = 'Menunggu';
              _lemburCountdown = '';
            }
          }
        }
      });
    }
  }

  Future<void> _fetchPresensiData() async {
    try {
      final dio = ApiService().dio;

      // 1. Fetch Today Status
      final todayRes = await dio.get('/absensi/today');
      if (todayRes.statusCode == 200) {
        final resData = todayRes.data;
        final data = resData['data'];
        final kantor = resData['kantor'];

        if (kantor != null) {
          final lat = double.tryParse(kantor['latitude'].toString());
          final lng = double.tryParse(kantor['longitude'].toString());
          final rad = double.tryParse(
            kantor['radius_toleransi_meter'].toString(),
          );

          if (lat != null && lng != null) _officeLocation = LatLng(lat, lng);
          if (rad != null) _maxRadiusMeters = rad;

          _namaKantor = kantor['nama_kantor']?.toString() ?? 'Kantor';
          _alamatKantor = kantor['alamat']?.toString() ?? '';
        }

        if (resData['server_time'] != null) {
          _serverTime = DateTime.parse(resData['server_time']);
        }
        _lemburData = resData['lembur'];

        if (data != null && data is Map) {
          _isSudahAbsenMasuk =
              data['jam_masuk'] != null &&
              data['jam_masuk'].toString().isNotEmpty;
          _isSudahAbsenKeluar =
              data['jam_keluar'] != null &&
              data['jam_keluar'].toString().isNotEmpty;
        } else {
          // Reset jika data absensi dihapus/null oleh admin (hasil koreksi disetujui)
          _isSudahAbsenMasuk = false;
          _isSudahAbsenKeluar = false;
        }
      }

      // 2. Fetch Dashboard Summary
      final dashRes = await dio.get('/dashboard');
      if (dashRes.statusCode == 200) {
        final payload = dashRes.data;
        _dashboardData = payload is Map && payload['data'] is Map
            ? payload['data']
            : payload;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _calculateOfficeDistance();
    } catch (e) {
      debugPrint('ERROR FETCHING PRESENSI: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _calculateOfficeDistance();
    } catch (_) {}
  }

  void _calculateOfficeDistance() {
    if (_officeLocation == null || _maxRadiusMeters <= 0) return;

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
  }

  Future<bool> _submitAbsensi({
    required String tipe,
    required String fotoBase64,
  }) async {
    try {
      final dio = ApiService().dio;

      String base64String = fotoBase64;
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');

      Uint8List imageBytes = base64Decode(base64String);

      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(
          imageBytes,
          filename: 'selfie_\.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'tipe': tipe,
      });

      final response = await dio.post('/absensi', data: formData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleAbsenProcess() async {
    final String tipe = !_isSudahAbsenMasuk ? 'masuk' : 'pulang';

    final resultImage = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => KameraScreen(namaKantor: _namaKantor)),
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

    final berhasil = await _submitAbsensi(tipe: tipe, fotoBase64: resultImage);

    if (!berhasil || !mounted) return;

    await _fetchPresensiData();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Absen $tipe berhasil disimpan.')));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              )
            : RefreshIndicator(
                onRefresh: _fetchPresensiData,
                color: const Color(0xFF009688),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildSkorKehadiranCard(),
                      const SizedBox(height: 20),
                      _buildDigitalClock(),
                      const SizedBox(height: 16),
                      _buildAbsenButton(),
                      const SizedBox(height: 16),
                      _buildRadiusBadge(),
                      const SizedBox(height: 16),
                      _buildStatusHariIniCard(),
                      const SizedBox(height: 20),
                      _buildLogKeterlambatanSection(),
                      const SizedBox(height: 20),
                      _buildTombolKoreksiPresensi(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSkorKehadiranCard() {
    final attn = _dashboardData?['attendance_month'] ?? {};
    final total = attn['total_hari_kerja'] ?? 25;
    final hadir = attn['hadir'] ?? 18;
    final pct = total > 0 ? ((hadir / total) * 100).round() : 72;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Skor Kehadiran',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Color(0xFF009688),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 65,
                height: 65,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct / 100,
                      strokeWidth: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: const Color(0xFF009688),
                    ),
                    Text(
                      '$pct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kehadiran bulan ini',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$hadir hari dari $total hari kerja',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDigitalClock() {
    return Column(
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'WIB • Hari ini',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAbsenButton() {
    if (_lemburStatus == 'Sedang Lembur') {
      return Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SISA WAKTU LEMBUR',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _lemburCountdown,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 26,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sedang Lembur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    Color btnColor;
    String btnText;

    if (!_isSudahAbsenMasuk) {
      btnColor = const Color(0xFF009688); // Hijau / Tosca
      btnText = 'Absen Masuk';
    } else if (!_isSudahAbsenKeluar) {
      btnColor = const Color(0xFFC62828); // Merah
      btnText = 'Absen Keluar';
    } else {
      btnColor = Colors.grey;
      btnText = 'Sudah Absen';
    }

    if (!_isInRadius && !(_isSudahAbsenMasuk && _isSudahAbsenKeluar)) {
      btnColor = Colors.grey;
      btnText = 'Luar Radius';
    }

    return GestureDetector(
      onTap: ((_isSudahAbsenMasuk && _isSudahAbsenKeluar) || !_isInRadius)
          ? null
          : _handleAbsenProcess,
      child: Container(
        width: 170,
        height: 170,
        decoration: BoxDecoration(
          color: btnColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: btnColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 4,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 6),
            Text(
              btnText,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadiusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isInRadius ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: _isInRadius ? const Color(0xFF009688) : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            _isInRadius ? 'Dalam radius kantor' : 'Di luar radius kantor',
            style: TextStyle(
              color: _isInRadius ? const Color(0xFF009688) : Colors.red,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHariIniCard() {
    String statusText = 'Belum Absen Masuk';
    String descText =
        'Silakan tekan tombol Absen Masuk untuk memulai shift hari ini.';
    Color badgeBg = const Color(0xFFFFF3E0);
    Color badgeTxt = const Color(0xFFE65100);

    if (_isSudahAbsenMasuk && !_isSudahAbsenKeluar) {
      statusText = 'Sudah Absen Masuk';
      descText =
          'Jangan lupa tekan tombol Absen Keluar saat selesai jam kerja.';
      badgeBg = const Color(0xFFE8F5E9);
      badgeTxt = const Color(0xFF2E7D32);
    } else if (_isSudahAbsenMasuk && _isSudahAbsenKeluar) {
      statusText = 'Presensi Selesai';
      descText = 'Terima kasih atas kerja keras Anda hari ini!';
      badgeBg = const Color(0xFFE0F2F1);
      badgeTxt = const Color(0xFF00695C);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status hari ini',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: badgeTxt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: badgeTxt,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descText,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLogKeterlambatanSection() {
    final List<dynamic> logs =
        _dashboardData?['late_logs'] ??
        [
          {
            'date': '04 Agt',
            'type': 'Terlambat',
            'diff': '+15m',
            'atasan': 'Pending',
            'hrd': 'Waiting',
          },
          {
            'date': '01 Agt',
            'type': 'Pulang Awal',
            'diff': '-30m',
            'atasan': 'OK',
            'hrd': 'Pending',
          },
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Log Keterlambatan & Pulang Awal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Column(
          children: logs.map((log) {
            final isLate = (log['type'] ?? '').toString().contains('Terlambat');

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
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
                      Row(
                        children: [
                          Text(
                            log['date'] ?? '-',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isLate
                                  ? const Color(0xFFFFEDD5)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              log['type'] ?? '-',
                              style: TextStyle(
                                color: isLate
                                    ? const Color(0xFFC2410C)
                                    : const Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        log['diff'] ?? '-',
                        style: TextStyle(
                          color: isLate
                              ? const Color(0xFFC2410C)
                              : const Color(0xFFDC2626),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Persetujuan:   Atasan: ${log['atasan'] ?? '-'}   HRD: ${log['hrd'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // WIDGET TOMBOL KOREKSI PRESENSI (SUDAH DIPERBAIKI PARAMETER CONTEXT-NYA)
  Widget _buildTombolKoreksiPresensi() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton.icon(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KoreksiPresensiScreen(),
            ),
          );
          // Refresh otomatis data presensi setelah kembali dari halaman koreksi
          _fetchPresensiData();
        },
        icon: const Icon(
          Icons.edit_calendar_rounded,
          size: 16,
          color: Color(0xFF009688),
        ),
        label: const Text(
          'Ajukan Koreksi Presensi',
          style: TextStyle(
            color: Color(0xFF009688),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          side: const BorderSide(color: Color(0xFF009688)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

