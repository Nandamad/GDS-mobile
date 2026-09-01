import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';

import '../services/api_service.dart';
import '../model/absensi.dart';
import '../cubit/location_cubit.dart';
import '../cubit/location_state.dart';
import 'kamera_page.dart';
import 'konfirmasi_foto_page.dart';
import 'riwayat_presensi_page.dart';

class PresensiHarianScreen extends StatefulWidget {
  const PresensiHarianScreen({super.key});

  @override
  State<PresensiHarianScreen> createState() => _PresensiHarianScreenState();
}

class _PresensiHarianScreenState extends State<PresensiHarianScreen> {
  bool _isLoading = true;

  // Data
  Map<String, dynamic> _attendanceSummary = {};
  List<Map<String, dynamic>> _recentHistory = [];

  // GPS & Location States
  String _namaKantor = 'Kantor';
  String _alamatKantor = '';

  // Absensi Status
  bool _isSudahAbsenMasuk = false;
  bool _isSudahAbsenKeluar = false;

  // Time
  late Timer _timer;
  String _currentTime = '00:00';
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );
    _fetchAllData();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');

    final dayNames = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final dayName = dayNames[now.weekday - 1];
    final monthName = monthNames[now.month - 1];

    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute';
        _currentDate =
            '${now.timeZoneName} - $dayName, ${now.day} $monthName ${now.year}';
      });
    }
  }

  Future<void> _fetchAllData() async {
    setState(() {
      _isLoading = true;
    });
    await Future.wait([_fetchDashboardAndToday(), _fetchRecentHistory()]);
  }

  Future<void> _fetchDashboardAndToday() async {
    try {
      final dio = ApiService().dio;

      // Fetch Today (Location config & status)
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
          LatLng? officeLoc;
          double maxRad = 0.0;
          if (lat != null && lng != null) officeLoc = LatLng(lat, lng);
          if (rad != null) maxRad = rad;

          if (mounted) {
            context.read<LocationCubit>().setOfficeConfig(officeLoc, maxRad);
          }

          _namaKantor = kantor['nama_kantor']?.toString() ?? 'Kantor';
          _alamatKantor = kantor['alamat']?.toString() ?? '';
        }

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

      // Fetch Dashboard Data (For Ringkasan Kehadiran)
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
          if (data['attendance_month'] != null) {
            _attendanceSummary = Map<String, dynamic>.from(
              data['attendance_month'],
            );
          }
        }
      }
    } catch (e) {
      debugPrint('PRESENSI DATA FETCH ERROR: $e');
    }

    if (mounted) setState(() => _isLoading = false);
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
        final parsedData = data.map((item) {
          final absensiObj = Absensi.fromJson(item);
          final isCuti = item['tipe'] != null && item['tipe'] != 'Kehadiran';
          final rawStatus = (absensiObj.status ?? item['status'] ?? 'hadir')
              .toString()
              .toLowerCase();

          Color bgColor = const Color(0xFFE8F5E9);
          Color txtColor = const Color(0xFF2E7D32);
          String statusTxt = 'Hadir';

          if (isCuti) {
            statusTxt = 'Izin/Cuti';
            bgColor = const Color(0xFFE0F2F1);
            txtColor = const Color(0xFF00695C);
          } else if (rawStatus.contains('terlambat') ||
              rawStatus.contains('late')) {
            statusTxt = 'Terlambat';
            bgColor = const Color(0xFFFFF3E0);
            txtColor = const Color(0xFFE65100);
          } else if (rawStatus.contains('pulang_awal') ||
              rawStatus.contains('pulang awal')) {
            statusTxt = 'Pulang Awal';
            bgColor = const Color(0xFFFEE2E2);
            txtColor = const Color(0xFFDC2626);
          } else if (rawStatus.contains('alpha') ||
              rawStatus.contains('tidak hadir') ||
              rawStatus.contains('tidak_absen')) {
            statusTxt = 'Alpha';
            bgColor = const Color(0xFFF1F5F9);
            txtColor = const Color(0xFF64748B);
          }

          final monthNames = [
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
          final dayNames = [
            'Senin',
            'Selasa',
            'Rabu',
            'Kamis',
            'Jumat',
            'Sabtu',
            'Minggu',
          ];

          String dateStr = '-';
          if (absensiObj.tanggal != null) {
            final d = absensiObj.tanggal!;
            final dayName = dayNames[d.weekday - 1];
            final monthName = monthNames[d.month - 1];
            dateStr = '$dayName, ${d.day} $monthName ${d.year}';
          }

          String formatTime(DateTime? t) {
            if (t == null) return '-';
            final local = t.toLocal();
            return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
          }

          return {
            'date': dateStr,
            'statusText': statusTxt,
            'statusBgColor': bgColor,
            'statusTextColor': txtColor,
            'checkIn': formatTime(absensiObj.jamMasuk),
            'checkOut': formatTime(absensiObj.jamPulang),
          };
        }).toList();

        // Limit to 5 entries
        if (mounted) {
          setState(() {
            _recentHistory = parsedData.take(5).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('FETCH RECENT HISTORY ERROR: $e');
    }
  }

  // GPS & Location Methods
  Future<String?> _submitAbsensi({
    required String tipe,
    required String fotoBase64,
    required LocationState locState,
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
        'latitude': locState.currentLocation!.latitude.toString(),
        'longitude': locState.currentLocation!.longitude.toString(),
        'tipe': tipe,
        'accuracy': locState.gpsAccuracy.toString(),
        'is_mocked': locState.isMocked.toString(),
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

  Future<void> _handleAbsenProcess(String tipe, LocationState locState) async {
    // Check if location is available
    if (locState.currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi tidak tersedia. Silakan aktifkan GPS.'),
        ),
      );
      return;
    }

    // Basic validation
    if (tipe == 'masuk' && _isSudahAbsenMasuk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah melakukan absen masuk hari ini.'),
        ),
      );
      return;
    }
    if (tipe == 'pulang' && !_isSudahAbsenMasuk) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anda belum absen masuk.')));
      return;
    }
    if (tipe == 'pulang' && _isSudahAbsenKeluar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah melakukan absen keluar hari ini.'),
        ),
      );
      return;
    }

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
            currentLocation: locState.currentLocation!,
            namaKantor: _namaKantor,
            alamatKantor: _alamatKantor,
            jarakMeter: locState.radiusMeters,
            isInRadius: locState.isInRadius,
            gpsAccuracy: locState.gpsAccuracy,
          ),
        ),
      );

      if (isConfirmed == true) {
        finalImage = resultImage;
        break;
      }
    }

    if (!mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF009688)),
      ),
    );

    final errorMessage = await _submitAbsensi(
      tipe: tipe,
      fotoBase64: finalImage,
      locState: locState,
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    if (!mounted) return;
    if (errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }

    await _fetchAllData();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Absen $tipe berhasil disimpan.')));
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final locState = context.watch<LocationCubit>().state;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // We will build our own back button if needed, or leave it empty if inside bottom nav
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF0F172A),
                    size: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF009688)),
            )
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
                    const SizedBox(height: 16),
                    _buildDigitalClock(),
                    const SizedBox(height: 32),
                    _buildActionButtons(locState),
                    const SizedBox(height: 32),
                    _buildRingkasanKehadiran(),
                    const SizedBox(height: 24),
                    _buildRiwayatAbsensi(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDigitalClock() {
    return Column(
      children: [
        Text(
          _currentTime,
          style: const TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF009688),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _currentDate,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(LocationState locState) {
    bool canAbsenMasuk = !_isSudahAbsenMasuk && locState.isInRadius;
    bool canAbsenKeluar =
        _isSudahAbsenMasuk && !_isSudahAbsenKeluar && locState.isInRadius;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: canAbsenMasuk
                ? () => _handleAbsenProcess('masuk', locState)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canAbsenMasuk
                    ? const Color(0xFF009688)
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(16),
                boxShadow: canAbsenMasuk
                    ? [
                        BoxShadow(
                          color: const Color(0xFF009688).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.login_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Absen Masuk',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: canAbsenKeluar
                ? () => _handleAbsenProcess('pulang', locState)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: canAbsenKeluar
                    ? const Color(0xFFFEF2F2)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: canAbsenKeluar
                      ? const Color(0xFFFECACA)
                      : Colors.grey.shade300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: canAbsenKeluar
                          ? Colors.white
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.logout_rounded,
                      color: canAbsenKeluar
                          ? const Color(0xFFDC2626)
                          : Colors.grey,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Absen Keluar',
                    style: TextStyle(
                      color: canAbsenKeluar
                          ? const Color(0xFFDC2626)
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRingkasanKehadiran() {
    final Map<String, dynamic> items = {
      'Hadir': {
        'val': _attendanceSummary['hadir'] ?? 0,
        'color': const Color(0xFF009688),
      },
      'Terlambat': {
        'val': _attendanceSummary['terlambat'] ?? 0,
        'color': const Color(0xFFF59E0B),
      },
      'Izin': {
        'val': _attendanceSummary['izin'] ?? 0,
        'color': const Color(0xFF3B82F6),
      },
      'Cuti': {
        'val': _attendanceSummary['cuti'] ?? 0,
        'color': const Color(0xFF009688),
      },
      'Sakit': {
        'val': _attendanceSummary['sakit'] ?? 0,
        'color': const Color(0xFF8B5CF6),
      },
      'Alpha': {
        'val': _attendanceSummary['alpha'] ?? 0,
        'color': const Color(0xFFEF4444),
      },
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Kehadiran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: items.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: entry.value['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 9,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${entry.value['val']} Hari',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatAbsensi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Riwayat Absensi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF0F172A),
              ),
            ),
            if (_recentHistory.isNotEmpty)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RiwayatPresensiScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    color: Color(0xFF009688),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_recentHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Color(0xFFC9CCCD),
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Belum ada riwayat absensi',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                  Text(
                    'untuk bulan ini',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ..._recentHistory.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['date'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Jam Masuk ${item['checkIn']} • Jam Pulang ${item['checkOut']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item['statusBgColor'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item['statusText'],
                      style: TextStyle(
                        color: item['statusTextColor'],
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }
}
