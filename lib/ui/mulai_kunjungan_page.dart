import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class MulaiKunjunganScreen extends StatefulWidget {
  const MulaiKunjunganScreen({super.key});

  @override
  State<MulaiKunjunganScreen> createState() => _MulaiKunjunganScreenState();
}

class _MulaiKunjunganScreenState extends State<MulaiKunjunganScreen> {
  final Color primaryTeal = const Color(0xFF009688);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _namaKlienController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String? _tujuanKunjungan;
  final List<String> _tujuanOptions = ['Meeting', 'Maintenance', 'Sales', 'Lainnya'];

  bool _isSubmitting = false;

  double? _latitude;
  double? _longitude;
  String _locationName = 'Mendapatkan lokasi...';
  String _locationAddress = 'Mohon tunggu sebentar';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationName = 'Layanan lokasi tidak aktif';
            _locationAddress = 'Mohon aktifkan GPS Anda';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _locationName = 'Izin lokasi ditolak';
              _locationAddress = 'Aplikasi membutuhkan izin lokasi';
              _isLoadingLocation = false;
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationName = 'Izin lokasi ditolak permanen';
            _locationAddress = 'Silakan ubah pengaturan izin lokasi di sistem';
            _isLoadingLocation = false;
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
        });
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (mounted) {
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _locationName = place.name ?? 'Lokasi Terdeteksi';
            List<String> addressParts = [];
            if (place.street != null && place.street!.isNotEmpty) addressParts.add(place.street!);
            if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
            if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
            if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
            
            _locationAddress = addressParts.join(', ');
            if (_locationAddress.isEmpty) {
              _locationAddress = '$_latitude, $_longitude';
            }
            _isLoadingLocation = false;
          });
        } else {
          setState(() {
            _locationName = 'Lokasi Terdeteksi';
            _locationAddress = '$_latitude, $_longitude';
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationName = 'Gagal mendapatkan lokasi';
          _locationAddress = 'Terjadi kesalahan saat memuat lokasi';
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaKlienController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // We can block submission if location is not loaded, but for now we just send what we have
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum didapatkan. Mohon tunggu atau periksa izin lokasi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await ApiService().dio.post('/kunjungan/mulai', data: {
        'nama_klien': _namaKlienController.text,
        'alamat_kunjungan': _alamatController.text,
        'tujuan_kunjungan': _tujuanKunjungan,
        'catatan': _catatanController.text,
        'lokasi_gps_mulai': '$_latitude,$_longitude',
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        if (response.statusCode == 201 || response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kunjungan berhasil dimulai!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.data['message'] ?? 'Gagal memulai kunjungan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        String errorMessage = 'Terjadi kesalahan jaringan';
        if (e.response != null && e.response?.data != null) {
           if (e.response?.data['message'] != null) {
              errorMessage = e.response?.data['message'];
           } else {
              errorMessage = e.response?.data.toString() ?? 'Error dari server';
           }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mulai Kunjungan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nama Klien *'),
              _buildTextField(
                controller: _namaKlienController,
                hint: 'Masukkan nama klien',
                validator: (val) => val == null || val.isEmpty ? 'Nama klien wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Alamat Kunjungan *'),
              _buildTextField(
                controller: _alamatController,
                hint: 'Masukkan alamat kunjungan',
                validator: (val) => val == null || val.isEmpty ? 'Alamat wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Tujuan Kunjungan *'),
              DropdownButtonFormField<String>(
                value: _tujuanKunjungan,
                decoration: _inputDecoration('Pilih tujuan kunjungan'),
                icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
                items: _tujuanOptions
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _tujuanKunjungan = val),
                validator: (val) => val == null ? 'Tujuan wajib dipilih' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Catatan Kunjungan'),
              _buildTextField(
                controller: _catatanController,
                hint: 'Tuliskan agenda atau poin penting meeting di sini...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              _buildLokasiGPSCard(),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Mulai Kunjungan Sekarang',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: _inputDecoration(hint),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
        borderSide: BorderSide(color: primaryTeal),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, color: primaryTeal, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Lokasi GPS Terdeteksi',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
              ),
              if (_isLoadingLocation) ...[
                const Spacer(),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: primaryTeal),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _locationName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            _locationAddress,
            style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4),
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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Placeholder background representing a map
                  Positioned.fill(
                    child: CustomPaint(
                      painter: MapPlaceholderPainter(),
                    ),
                  ),
                  const Icon(Icons.location_on, color: Colors.red, size: 40),
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
      
    // Draw some random lines to look like streets
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.4), paint);
    canvas.drawLine(Offset(size.width * 0.4, 0), Offset(size.width * 0.5, size.height), paint);
    canvas.drawLine(Offset(0, size.height * 0.7), Offset(size.width, size.height * 0.8), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.8, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
