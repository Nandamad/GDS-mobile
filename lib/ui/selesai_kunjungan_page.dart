import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

class SelesaiKunjunganScreen extends StatefulWidget {
  const SelesaiKunjunganScreen({super.key});

  @override
  State<SelesaiKunjunganScreen> createState() => _SelesaiKunjunganScreenState();
}

class _SelesaiKunjunganScreenState extends State<SelesaiKunjunganScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _hasilKunjungan;
  final List<String> _hasilOptions = ['Perlu Follow Up', 'Selesai', 'Batal', 'Lainnya'];

  final TextEditingController _catatanController = TextEditingController();
  
  File? _fotoSelfie;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;
  
  bool _isLoading = true;
  bool _hasActiveKunjungan = false;
  
  String? _namaKlien;
  DateTime? _jamMulai;
  String? _jamMulaiString;
  String _elapsedTime = '00:00:00';
  Timer? _timer;

  String _lokasiGps = 'Mendapatkan lokasi...';
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadActiveKunjungan();
    _getLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveKunjungan() async {
    try {
      final response = await ApiService().dio.get('/kunjungan/active');
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        if (data != null) {
          setState(() {
            _hasActiveKunjungan = true;
            _namaKlien = data['nama_klien'];
            _jamMulaiString = data['jam_mulai_kunjungan'];
            
            if (data['tanggal'] != null && data['jam_mulai_kunjungan'] != null) {
              try {
                _jamMulai = DateTime.parse('${data['tanggal']} ${data['jam_mulai_kunjungan']}');
                _startTimer();
              } catch (e) {
                debugPrint('Parse date error: $e');
              }
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading active kunjungan: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_jamMulai != null) {
        final duration = DateTime.now().difference(_jamMulai!);
        if (duration.isNegative) {
          setState(() {
            _elapsedTime = '00:00:00';
          });
          return;
        }
        
        final hours = duration.inHours.toString().padLeft(2, '0');
        final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
        
        if (mounted) {
          setState(() {
            _elapsedTime = '$hours:$minutes:$seconds';
          });
        }
      }
    });
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _lokasiGps = 'Layanan lokasi tidak aktif';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _lokasiGps = 'Izin lokasi ditolak';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _lokasiGps = 'Izin lokasi ditolak permanen';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _lokasiGps = '${position.latitude},${position.longitude}';
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lokasiGps = 'Gagal mendapatkan lokasi';
        });
      }
    }
  }

  Future<void> _ambilFoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _fotoSelfie = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoSelfie == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto selfie verifikasi wajib diambil!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_lokasiGps == 'Mendapatkan lokasi...' || 
        _lokasiGps == 'Layanan lokasi tidak aktif' ||
        _lokasiGps == 'Izin lokasi ditolak' ||
        _lokasiGps == 'Izin lokasi ditolak permanen' ||
        _lokasiGps == 'Gagal mendapatkan lokasi') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS belum valid!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      FormData formData = FormData.fromMap({
        'lokasi_gps_selesai': _lokasiGps,
        'hasil_kunjungan': _hasilKunjungan,
        'catatan_hasil': _catatanController.text,
        'foto_selfie_selesai': await MultipartFile.fromFile(
          _fotoSelfie!.path,
          filename: _fotoSelfie!.path.split('/').last,
        ),
      });

      final response = await ApiService().dio.post(
        '/kunjungan/selesai',
        data: formData,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunjungan berhasil diselesaikan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Gagal menyelesaikan kunjungan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan jaringan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slightly gray background matching design
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Selesai Kunjungan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : !_hasActiveKunjungan 
          ? const Center(child: Text('Tidak ada kunjungan aktif', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '● KUNJUNGAN BERJALAN',
                              style: TextStyle(
                                color: Color(0xFFEA580C),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _elapsedTime,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _namaKlien ?? '-',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dimulai sejak pukul ${_jamMulaiString != null ? _jamMulaiString!.substring(0, 5) : '-'} WIB',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    _buildLabel('Hasil Kunjungan *'),
                    DropdownButtonFormField<String>(
                      value: _hasilKunjungan,
                      decoration: _inputDecoration('Pilih hasil kunjungan'),
                      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                      items: _hasilOptions
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => _hasilKunjungan = val),
                      validator: (val) => val == null ? 'Hasil wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Catatan Hasil Kunjungan *'),
                    TextFormField(
                      controller: _catatanController,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13),
                      decoration: _inputDecoration('Meeting berjalan dengan baik. Pihak klien...'),
                      validator: (val) => val == null || val.isEmpty ? 'Catatan wajib diisi' : null,
                    ),
                    const SizedBox(height: 24),

                    _buildLokasiGPSCard(),
                    const SizedBox(height: 24),

                    _buildLabel('Foto Selfie Verifikasi'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _ambilFoto,
                      child: CustomPaint(
                        painter: DashedRectPainter(color: Colors.grey.shade400, strokeWidth: 1, gap: 5),
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _fotoSelfie != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _fotoSelfie!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF009688), size: 28),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Ambil Foto Selfie',
                                      style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Foto wajah diperlukan untuk verifikasi kunjungan',
                                      style: TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444), // Merah
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        onPressed: (_isSubmitting || !_hasActiveKunjungan) ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Selesai Kunjungan Sekarang',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: const Color(0xFF009688)),
      ),
    );
  }

  Widget _buildLokasiGPSCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF009688), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Lokasi GPS Terdeteksi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _lokasiGps,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFE2E8F0),
              ),
              child: _latitude != null && _longitude != null
                  ? FlutterMap(
                      key: ValueKey('$_latitude-$_longitude'),
                      options: MapOptions(
                        initialCenter: LatLng(_latitude!, _longitude!),
                        initialZoom: 15.0,
                        interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.gds.presensi_plus',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_latitude!, _longitude!),
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: MapPlaceholderPainter(),
                          ),
                        ),
                        const Icon(Icons.location_off, color: Colors.grey, size: 40),
                      ],
                    ),
            ),
          )
        ],
      ),
    );
  }
}

class MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.5, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.8, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({required this.color, required this.strokeWidth, required this.gap});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));

    final PathMetrics pathMetrics = path.computeMetrics();
    for (PathMetric pathMetric in pathMetrics) {
      double distance = 0.0;
      while (distance < pathMetric.length) {
        canvas.drawPath(pathMetric.extractPath(distance, distance + gap), paint);
        distance += gap * 2;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
