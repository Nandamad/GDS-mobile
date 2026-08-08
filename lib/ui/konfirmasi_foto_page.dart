import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';

class KonfirmasiFotoScreen extends StatefulWidget {
  final String? imageBase64;

  const KonfirmasiFotoScreen({super.key, this.imageBase64});

  @override
  State<KonfirmasiFotoScreen> createState() => _KonfirmasiFotoScreenState();
}

class _KonfirmasiFotoScreenState extends State<KonfirmasiFotoScreen> {
  bool _isSubmitting = false;

  Future<void> _onConfirm() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 15),
      ));

      FormData formData = FormData.fromMap({
        'latitude': '-6.2088',
        'longitude': '106.8456',
        'tipe': 'masuk', // Hardcode masuk for simulation
      });

      if (widget.imageBase64 != null) {
        final bytes = base64Decode(widget.imageBase64!.split(',').last);
        formData.files.add(MapEntry(
          'foto',
          MultipartFile.fromBytes(bytes, filename: 'selfie.jpg'),
        ));
      }

      final response = await dio.post('/absensi', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presensi Berhasil Dikonfirmasi!'),
              backgroundColor: Color(0xFF009688),
            ),
          );
          Navigator.pop(context, true); // Kembalikan nilai sukses
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Gagal menyimpan absensi.';
        if (e.response != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Verifikasi Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // Top Info Card (Waktu & Lokasi)
            _buildTopInfoCard(),
            const SizedBox(height: 16),

            // Preview Foto Selfie dengan Frame Deteksi Wajah
            _buildCameraPreviewCard(),
            const SizedBox(height: 16),

            // Card Data Verifikasi
            _buildDataVerifikasiCard(),
            const SizedBox(height: 20),

            // Tombol Aksi Bottom
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF009688)),
              SizedBox(width: 8),
              Text(
                '08:45:12 WIB',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF009688)),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kantor Pusat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Jl. Sudirman No. 123, Jakarta',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreviewCard() {
    final hasBase64 = widget.imageBase64 != null && widget.imageBase64!.startsWith('data:image');

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF009688), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Image Preview Selfie
            hasBase64
                ? Image.memory(
                    base64Decode(widget.imageBase64!.split(',').last),
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  )
                : Image.network(
                    'https://i.pravatar.cc/400?img=11',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),

            // Face Detection Bounding Box Frame
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Badge Wajah Terdeteksi
            Positioned(
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF009688).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.qr_code_scanner, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'WAJAH TERDETEKSI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataVerifikasiCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Verifikasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildVerifikasiRow(
            label: 'Waktu Server',
            value: '08:45:12 WIB',
            isVerified: true,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Tanggal',
            value: 'Rabu, 05 Agustus 2026',
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Koordinat GPS',
            value: '-6.2088, 106.8456',
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Jarak dari Kantor',
            value: '45 meter',
            isVerified: true,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Deteksi Wajah',
            value: 'Terverifikasi',
            isVerified: true,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Status',
            value: 'Dalam Radius Kantor',
            valueColor: const Color(0xFF009688),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiRow({
    required String label,
    required String value,
    bool isVerified = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 13,
                color: Color(0xFF009688),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF009688)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'AMBIL ULANG',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'KONFIRMASI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}