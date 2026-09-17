import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
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
  String _locationName = 'Lokasi Kunjungan';
  String _locationAddress = 'Ketik alamat di atas untuk melihat peta';
  bool _isLoadingLocation = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _alamatController.addListener(_onAlamatChanged);
  }

  void _onAlamatChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), () {
      final address = _alamatController.text.trim();
      if (address.isNotEmpty) {
        _geocodeAddress(address);
      }
    });
  }

  Future<void> _geocodeAddress(String address) async {
    setState(() {
      _isLoadingLocation = true;
      _locationAddress = 'Mencari lokasi...';
    });

    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        if (mounted) {
          setState(() {
            _latitude = loc.latitude;
            _longitude = loc.longitude;
            _locationName = 'Lokasi Ditemukan';
            _locationAddress = address;
            _isLoadingLocation = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationName = 'Lokasi tidak ditemukan';
          _locationAddress = 'Alamat belum terbaca di peta';
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _namaKlienController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi peta belum ditemukan. Mohon ketikkan alamat kunjungan yang lebih jelas.'),
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
                'Lokasi Peta (Berdasarkan Alamat)',
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
                        const Icon(Icons.location_off, color: Colors.grey, size: 30),
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

    final path = Path();
    double step = 20;
    for (double i = 0; i < size.width; i += step) {
      path.moveTo(i, 0);
      path.lineTo(i, size.height);
    }
    for (double i = 0; i < size.height; i += step) {
      path.moveTo(0, i);
      path.lineTo(size.width, i);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
