import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../services/image_url_service.dart';
import 'kamera_page.dart';
import 'konfirmasi_foto_page.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNotificationTap;

  const DashboardScreen({super.key, this.onNotificationTap});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _userFotoUrl;
  String _errorMessage = '';
  int _unreadNotificationCount = 0;

  // Absensi states
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
  StreamSubscription<Position>? _positionStream;
  double _gpsAccuracy = 0.0;
  bool _isMocked = false;

  List<dynamic> _logKeterlambatan = [];

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
    _determinePosition();
    _fetchAllData();
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
            final mulaiStr = _lemburData!['jam_mulai'];
            final selesaiStr = _lemburData!['jam_selesai'];
            if (mulaiStr != null && selesaiStr != null) {
              final mulai = DateTime.parse(mulaiStr);
              final selesai = DateTime.parse(selesaiStr);

              if (_serverTime!.isAfter(mulai) &&
                  _serverTime!.isBefore(selesai)) {
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
        }
      });
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.wait([
      _fetchDashboardAndToday(),
      _fetchRecentHistory(),
      _fetchUserProfileFoto(),
      _fetchUnreadNotificationCount(),
    ]);
  }

  Future<void> _fetchDashboardAndToday() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Sesi login tidak ditemukan.';
          _isLoading = false;
        });
        return;
      }

      final dio = ApiService().dio;

      // 1. Fetch Today (Absensi Status)
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
          _isSudahAbsenMasuk = false;
          _isSudahAbsenKeluar = false;
        }
      }

      // 2. Fetch Dashboard Data
      final dashRes = await dio.get('/dashboard');
      if (dashRes.statusCode == 200) {
        final payload = dashRes.data;
        Map<String, dynamic>? data;
        if (payload is Map) {
          data = payload['data'] is Map
              ? Map<String, dynamic>.from(payload['data'])
              : Map<String, dynamic>.from(payload);
        }
        if (data != null) {
          _dashboardData = data;
          // keterlambatan akan di-fetch dari history endpoint
        }
      }

      _calculateOfficeDistance();
    } on DioException catch (e) {
      debugPrint(
        'DASHBOARD ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );
      _errorMessage = 'Gagal memuat dashboard: ${e.message}';
    } catch (e) {
      debugPrint('DASHBOARD PARSE ERROR: $e');
      _errorMessage = 'Terjadi kesalahan sistem.';
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRecentHistory() async {
    try {
      final dio = ApiService().dio;
      final now = DateTime.now();
      final response = await dio.get(
        '/history',
        queryParameters: {'month': now.month, 'year': now.year},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? [];
        final keterlambatanData = <Map<String, dynamic>>[];

        for (var item in data) {
          final rawStatus = (item['status'] ?? 'hadir')
              .toString()
              .toLowerCase();

          // Filter hanya keterlambatan dan pulang awal
          if (rawStatus.contains('terlambat') ||
              rawStatus.contains('late') ||
              rawStatus.contains('pulang_awal') ||
              rawStatus.contains('pulang awal')) {
            final isTerlambat =
                rawStatus.contains('terlambat') || rawStatus.contains('late');

            keterlambatanData.add({
              'tanggal': item['tanggal'] ?? item['jam_masuk'],
              'tipe': isTerlambat ? 'Terlambat' : 'Pulang Awal',
              'menit': item['menit_keterlambatan'] ?? 0,
              'status_atasan': item['approval_atasan'] ?? 'Pending',
              'status_hrd': item['approval_hrd'] ?? 'Pending',
            });
          }
        }

        if (mounted) {
          setState(() {
            _logKeterlambatan = keterlambatanData;
          });
        }
      }
    } catch (e) {
      debugPrint('FETCH RECENT HISTORY ERROR: $e');
      // Jika error, biarkan kosong (tidak ada mock data)
      if (mounted) {
        setState(() {
          _logKeterlambatan = [];
        });
      }
    }
  }

  Future<void> _fetchUserProfileFoto() async {
    try {
      final response = await ApiService().dio.get('/profile');
      if (response.statusCode == 200) {
        final payload = response.data;
        if (payload is Map) {
          final profile = payload['data'] is Map ? payload['data'] : payload;
          final karyawan = profile['karyawan'] is Map
              ? profile['karyawan']
              : profile;
          final rawFoto =
              karyawan['foto_url'] ?? karyawan['foto'] ?? profile['foto'];
          final resolved = ImageUrlService.resolve(rawFoto?.toString());
          if (mounted && resolved != null) {
            setState(() => _userFotoUrl = resolved);
          }
        }
      }
    } catch (e) {
      debugPrint('FETCH PROFILE FOTO IN DASHBOARD ERROR: $e');
    }
  }

  Future<void> _fetchUnreadNotificationCount() async {
    var unreadCount = 0;
    try {
      final response = await ApiService().dio.get('/notifikasi');
      dynamic list = response.data is Map
          ? (response.data['data'] ?? response.data['items'] ?? [])
          : response.data;
      if (list is List) {
        unreadCount += list
            .where((item) => item is Map && item['read_at'] == null)
            .length;
      }
    } catch (e) {
      debugPrint('GET /notifikasi COUNT ERROR: $e');
    }

    try {
      final response = await ApiService().dio.get('/approval/pending');
      dynamic list = response.data is Map
          ? (response.data['data'] ?? response.data['items'] ?? [])
          : response.data;
      if (list is List) unreadCount += list.length;
    } catch (e) {
      debugPrint('GET /approval/pending COUNT ERROR: $e');
    }

    if (mounted) {
      setState(() => _unreadNotificationCount = unreadCount);
    }
  }

  // GPS & Location Methods
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _startLocationStream();
  }

  void _startLocationStream() {
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) {
          if (!mounted) return;
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _gpsAccuracy = position.accuracy;
            _isMocked = position.isMocked;
          });
          _calculateOfficeDistance();
        });
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

  Future<String?> _submitAbsensi({
    required String tipe,
    required String fotoBase64,
  }) async {
    try {
      final dio = ApiService().dio;
      String base64String = fotoBase64;
      if (base64String.contains(','))
        base64String = base64String.split(',').last;
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');
      Uint8List imageBytes = base64Decode(base64String);

      final formData = FormData.fromMap({
        'foto': MultipartFile.fromBytes(
          imageBytes,
          filename: 'selfie.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'latitude': _currentLocation.latitude.toString(),
        'longitude': _currentLocation.longitude.toString(),
        'tipe': tipe,
        'accuracy': _gpsAccuracy.toString(),
        'is_mocked': _isMocked.toString(),
      });

      final response = await dio.post('/absensi', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) return null;
      return 'Server menolak penyimpanan presensi.';
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null)
        return data['message'].toString();
      return 'Presensi gagal dikirim. Periksa koneksi dan lokasi Anda.';
    } catch (e) {
      return 'Presensi gagal diproses.';
    }
  }

  Future<void> _handleAbsenProcess() async {
    final String tipe = !_isSudahAbsenMasuk ? 'masuk' : 'pulang';

    String? finalImage;
    while (true) {
      final resultImage = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => KameraScreen(namaKantor: _namaKantor),
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
            gpsAccuracy: _gpsAccuracy,
          ),
        ),
      );

      if (isConfirmed == true) {
        finalImage = resultImage;
        break;
      }
    }

    if (!mounted) return;

    final errorMessage = await _submitAbsensi(
      tipe: tipe,
      fotoBase64: finalImage,
    );

    if (!mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    await _fetchDashboardAndToday();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Absen $tipe berhasil disimpan.')));
  }

  @override
  void dispose() {
    _timer.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  String _formatDateString(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}';
    } catch (_) {
      return dateStr;
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              )
            : _errorMessage.isNotEmpty
            ? _buildErrorState()
            : RefreshIndicator(
                onRefresh: _fetchAllData,
                color: const Color(0xFF009688),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildSkorKehadiranCard(),
                      const SizedBox(height: 32),
                      _buildDigitalClock(),
                      const SizedBox(height: 24),
                      _buildAbsenButton(),
                      const SizedBox(height: 16),
                      _buildRadiusBadge(),
                      const SizedBox(height: 24),
                      _buildStatusHariIniCard(),
                      const SizedBox(height: 24),
                      _buildLogKeterlambatanList(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final rawUser =
        _dashboardData?['user'] ??
        _dashboardData?['data']?['user'] ??
        _dashboardData;
    final Map<String, dynamic> user = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : {};
    final rawKaryawan = user['karyawan'] ?? _dashboardData?['karyawan'];
    final Map<String, dynamic> karyawan = rawKaryawan is Map
        ? Map<String, dynamic>.from(rawKaryawan)
        : user;
    final nama =
        (karyawan['nama_lengkap'] ?? user['nama'] ?? user['name'] ?? 'Pengguna')
            .toString()
            .split(' ')
            .first;

    final rawFotoDashboard =
        karyawan['foto_url'] ?? karyawan['foto'] ?? user['foto'];
    final fotoUrl =
        _userFotoUrl ?? ImageUrlService.resolve(rawFotoDashboard?.toString());

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFCCFBF1),
          backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
          child: fotoUrl == null
              ? const Icon(Icons.person, color: Color(0xFF009688))
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Selamat pagi, $nama! ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Text('👋', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'Siap untuk mulai kerja hari ini?',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: widget.onNotificationTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.notifications_none,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      _unreadNotificationCount > 9
                          ? '9+'
                          : '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkorKehadiranCard() {
    final attn = _dashboardData?['attendance_month'] ?? {};
    final total =
        int.tryParse(attn['total_hari_kerja']?.toString() ?? '25') ?? 25;
    final hadir = int.tryParse(attn['hadir']?.toString() ?? '18') ?? 18;
    final pct = total > 0 ? ((hadir / total) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$pct%',
                  style: const TextStyle(
                    color: Color(0xFF009688),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 70,
                height: 70,
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
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kehadiran bulan ini',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$hadir hari dari $total hari kerja',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'WIB • Hari ini',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAbsenButton() {
    if (_lemburStatus == 'Sedang Lembur') {
      return _buildLemburButton();
    }

    Color btnColor;
    String btnText;

    if (!_isSudahAbsenMasuk) {
      btnColor = const Color(0xFF009688);
      btnText = 'Absen Masuk';
    } else if (!_isSudahAbsenKeluar) {
      btnColor = const Color(0xFFC62828); // Red
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
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          color: btnColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: btnColor.withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 6,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isSudahAbsenMasuk && !_isSudahAbsenKeluar
                      ? Icons.logout_rounded
                      : Icons.login_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  btnText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLemburButton() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 6,
            offset: const Offset(0, 10),
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
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sedang Lembur',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isInRadius ? const Color(0xFFE0F2F1) : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: _isInRadius ? const Color(0xFF009688) : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            _isInRadius ? 'Dalam radius kantor' : 'Di luar radius kantor',
            style: TextStyle(
              color: _isInRadius ? const Color(0xFF009688) : Colors.red,
              fontSize: 12,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeBg.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: badgeTxt,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: badgeTxt,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            descText,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLogKeterlambatanList() {
    if (_logKeterlambatan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'Log Keterlambatan & Pulang Awal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        ..._logKeterlambatan.map((log) {
          final isTerlambat =
              (log['tipe'] ?? '').toString().toLowerCase() == 'terlambat';
          final tgl = log['tanggal'] != null
              ? _formatDateString(log['tanggal'].toString())
              : '-';
          final title = isTerlambat ? 'Terlambat' : 'Pulang Awal';
          final menit = log['menit'] ?? '0';
          final valText = isTerlambat ? '+$menit\m' : '-$menit\m';
          final colorVal = Colors.red;
          final colorBg = const Color(0xFFFFEBEE);
          final colorTxt = const Color(0xFFC62828);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          tgl,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: colorTxt,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      valText,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: colorVal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Persetujuan: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const Text(
                      'Atasan: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${log['status_atasan'] ?? 'Pending'}  ',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'HRD: ',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    Text(
                      '${log['status_hrd'] ?? 'Pending'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
