import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ajukan_kunjungan_page.dart';
import 'kamera_page.dart';
import 'selesai_kunjungan_page.dart';
import '../services/api_service.dart';

class MulaiKunjunganScreen extends StatefulWidget {
  final Map<String, dynamic>? kunjunganData;

  const MulaiKunjunganScreen({
    super.key,
    required this.kunjunganData,
  });

  @override
  State<MulaiKunjunganScreen> createState() => _MulaiKunjunganScreenState();
}

class _MulaiKunjunganScreenState extends State<MulaiKunjunganScreen> {
  String? _fotoSelfieBase64;
  bool _isStarting = false;

  Future<void> _ambilFoto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KameraScreen(namaKantor: 'Verifikasi Kunjungan')),
    );

    if (result != null && result is String) {
      setState(() {
        _fotoSelfieBase64 = result;
      });
    }
  }

  Future<void> _mulaiKunjungan() async {
    if (widget.kunjunganData == null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.red, size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pengajuan Kunjungan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajukan kunjungan terlebih dahulu untuk memulai kunjungan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Kembali', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AjukanKunjunganScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Ajukan', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (_fotoSelfieBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto verifikasi wajib diambil!')),
      );
      return;
    }

    setState(() {
      _isStarting = true;
    });

    try {
      final response = await ApiService().dio.post('/kunjungan/mulai', data: {
        'kunjungan_id': widget.kunjunganData!['id'], // Kirim ID Kunjungan
        'foto_selfie_mulai': _fotoSelfieBase64,
      });

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal di server');
      }

      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunjungan berhasil dimulai!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true); // Return true to refresh parent
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });
      String errorMessage = 'Terjadi kesalahan jaringan';
      if (e.response != null && e.response?.data != null) {
         if (e.response?.data is Map && e.response?.data['message'] != null) {
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memulai kunjungan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.kunjunganData;
    final bool hasKunjungan = data != null;

    // --- Helper functions ---
    String formatTanggal(String isoString) {
      try {
        final date = DateTime.parse(isoString).toLocal();
        const months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
        final dayStr = date.day.toString().padLeft(2, '0');
        return '$dayStr ${months[date.month - 1]} ${date.year}';
      } catch (_) {
        return '-';
      }
    }

    // --- Computed values ---
    String tanggal = '-';
    String namaKlien = '-';
    String tujuanKunjungan = '-';
    String alamat = '-';
    String approvedByName = 'Manager HRD';

    if (hasKunjungan) {
      tanggal = data['tanggal'] != null ? formatTanggal(data['tanggal']) : '-';
      namaKlien = data['nama_klien'] ?? '-';
      tujuanKunjungan = data['tujuan_kunjungan'] ?? '-';
      alamat = data['alamat_kunjungan'] ?? '-';
      approvedByName = data['approvedByL1']?['name'] ?? data['approvedByL2']?['name'] ?? 'Manager HRD';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: const Text(
          'Mulai Kunjungan',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===== Detail Kunjungan Card =====
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasKunjungan ? const Color(0xFF009688) : Colors.grey.shade300,
                          width: hasKunjungan ? 1.5 : 1,
                        ),
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
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: hasKunjungan ? const Color(0xFFE0F2F1) : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: hasKunjungan ? const Color(0xFF009688) : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Status Pengajuan', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Text(
                                      hasKunjungan ? 'Disetujui' : 'Belum Ada',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: hasKunjungan ? const Color(0xFF009688) : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hasKunjungan) ...[
                            const SizedBox(height: 20),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            const SizedBox(height: 16),
                            
                            const Text('Tanggal', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(tanggal, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 12),
                            
                            const Text('Nama Klien', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(namaKlien, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 12),
                            
                            const Text('Tujuan', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(tujuanKunjungan, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 12),

                            const Text('Alamat', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(alamat, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                            const SizedBox(height: 12),
                            
                            const Text('Disetujui oleh', style: TextStyle(color: Colors.grey, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text(approvedByName, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          ] else ...[
                            const SizedBox(height: 24),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Belum ada pengajuan kunjungan',
                                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
        
                    // ===== Kirim Foto =====
                    const Text(
                      'Kirim Foto Kunjungan',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _ambilFoto,
                      child: CustomPaint(
                        painter: DashedRectPainter(color: Colors.grey.shade400, strokeWidth: 1, gap: 5),
                        child: Container(
                          width: double.infinity,
                          height: 180,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _fotoSelfieBase64 != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.memory(
                                    base64Decode(_fotoSelfieBase64!.split(',').last),
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
                                      'Ambil Foto Kunjungan',
                                      style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Foto diperlukan sebagai bukti kehadiran',
                                      style: TextStyle(color: Colors.grey, fontSize: 11),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== Bottom Button =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ]
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _mulaiKunjungan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Mulai Kunjungan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

// Painter for Dashed Border
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

    final Path path = Path();
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(12)));

    final Path dashedPath = _createDashedPath(path, gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _createDashedPath(Path source, double gap) {
    Path dashedPath = Path();
    for (PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        double len = gap; // length of dash
        if (distance + len > metric.length) len = metric.length - distance;
        dashedPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
        distance += len + gap; // length of gap
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
