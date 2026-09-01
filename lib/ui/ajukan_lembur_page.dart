import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kamera_page.dart';
import 'selesai_lembur_page.dart';

class AjukanLemburScreen extends StatefulWidget {
  const AjukanLemburScreen({super.key});

  @override
  State<AjukanLemburScreen> createState() => _AjukanLemburScreenState();
}

class _AjukanLemburScreenState extends State<AjukanLemburScreen> {
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  int _estimasiJam = 2; // Default 2 hours based on image
  String? _fotoSelfieBase64;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkActiveLembur();
  }

  Future<void> _checkActiveLembur() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool('is_lembur_active') ?? false;
    if (isActive) {
      final alasan = prefs.getString('lembur_alasan') ?? '';
      final estimasiJam = prefs.getInt('lembur_estimasi') ?? 2;
      final catatan = prefs.getString('lembur_catatan') ?? '';
      final startTimeStr = prefs.getString('lembur_start_time');
      if (startTimeStr != null) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SelesaiLemburScreen(
              alasan: alasan,
              estimasiJam: estimasiJam,
              catatan: catatan,
              startTime: DateTime.parse(startTimeStr),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _ambilFoto() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KameraScreen(namaKantor: 'Verifikasi Lembur')),
    );

    if (result != null && result is String) {
      setState(() {
        _fotoSelfieBase64 = result;
      });
    }
  }

  void _mulaiLembur() {
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan lembur wajib diisi!')),
      );
      return;
    }
    
    // In a real app we'd validate foto selfie as well.
    // For now we allow without it or mock it.
    /*
    if (_fotoSelfieBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto verifikasi wajib diambil!')),
      );
      return;
    }
    */

    setState(() {
      _isSubmitting = true;
    });

    // Mocking an API call by storing to SharedPreferences
    Future.delayed(const Duration(seconds: 1), () async {
      if (!mounted) return;

      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_lembur_active', true);
      await prefs.setString('lembur_alasan', _alasanController.text.trim());
      await prefs.setInt('lembur_estimasi', _estimasiJam);
      await prefs.setString('lembur_catatan', _catatanController.text.trim());
      await prefs.setString('lembur_start_time', now.toIso8601String());

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SelesaiLemburScreen(
            alasan: _alasanController.text.trim(),
            estimasiJam: _estimasiJam,
            catatan: _catatanController.text.trim(),
            startTime: now,
          ),
        ),
      );
    });
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
          'Mulai Lembur',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5), // Light orange background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      const Text(
                        'Pemberitahuan Lembur',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kegiatan lembur hanya akan dihitung setelah waktu kerja normal Anda hari ini selesai.',
                    style: TextStyle(
                      color: Color(0xFFEA580C),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alasan Lembur
            const Text(
              'Alasan Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: '',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estimasi Durasi
            const Text(
              'Estimasi Durasi Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDurationChip(1),
                const SizedBox(width: 8),
                _buildDurationChip(2),
                const SizedBox(width: 8),
                _buildDurationChip(3),
                const SizedBox(width: 8),
                _buildDurationChip(4),
              ],
            ),
            const SizedBox(height: 20),

            // Catatan Tambahan
            const Text(
              'Catatan Tambahan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Perlu lembur tambahan untuk menyelesaikan testing security setelah deployment server selesai malam ini.',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Foto Selfie
            const Text(
              'Foto Selfie Verifikasi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _ambilFoto,
              child: CustomPaint(
                painter: DashedRectPainter(color: Colors.grey.shade400, strokeWidth: 1, gap: 5),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _fotoSelfieBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(_fotoSelfieBase64!.split(',').last),
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0F766E), size: 24),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ambil Foto Selfie',
                              style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Foto wajah diperlukan untuk verifikasi lembur',
                              style: TextStyle(color: Colors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _mulaiLembur,
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 20),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Mulai Lembur Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

  Widget _buildDurationChip(int hours) {
    bool isSelected = _estimasiJam == hours;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _estimasiJam = hours;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCCFBF1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$hours Jam',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
            ),
          ),
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
    path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(8)));

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
