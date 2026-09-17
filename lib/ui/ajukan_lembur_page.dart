import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'kamera_page.dart';

class AjukanLemburScreen extends StatefulWidget {
  const AjukanLemburScreen({super.key});

  @override
  State<AjukanLemburScreen> createState() => _AjukanLemburScreenState();
}

class _AjukanLemburScreenState extends State<AjukanLemburScreen> {
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;
  
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 2; // Default 2 jam

  String? _fotoSelfieBase64;

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  Future<void> _ajukanLembur() async {
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan lembur wajib diisi!')),
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
      _isSubmitting = true;
    });

    try {
      final String tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      // Default waktu mulai jam 17:00 jika tidak ada input jam (asumsi jam kerja selesai 17:00)
      final String jamMulaiStr = '17:00';
      int endHour = 17 + _selectedDuration;
      final String jamSelesaiStr = '${endHour.toString().padLeft(2, '0')}:00';

      final payload = {
        'tanggal': tanggal,
        'jam_mulai_lembur': jamMulaiStr,
        'jam_selesai_lembur': jamSelesaiStr,
        'foto': _fotoSelfieBase64,
      };

      final response = await ApiService().dio.post('/lembur', data: payload);
      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan lembur berhasil dikirim'), backgroundColor: Colors.green),
        );

        NotificationService().showInfoNotification(
          title: 'Pengajuan Lembur Terkirim',
          body: 'Pengajuan lembur Anda telah berhasil dikirim dan menunggu persetujuan.',
          preferenceKey: 'notif_pengajuan',
        );

        Navigator.pop(context, true); 
      } else {
        throw Exception('Gagal mengirim ke server');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan lembur: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSubmitting = false);
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
          'Mulai Lembur',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: 8),
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
            const SizedBox(height: 24),

            // Pilih Tanggal
            _buildLabel('Tanggal Lembur *'),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate), style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                    const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Alasan Lembur
            _buildLabel('Alasan Lembur *'),
            TextField(
              controller: _alasanController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
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
              ),
            ),
            const SizedBox(height: 20),

            // Estimasi Durasi Lembur
            _buildLabel('Estimasi Durasi Lembur *'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDurationChip(1),
                _buildDurationChip(2),
                _buildDurationChip(3),
                _buildDurationChip(4),
              ],
            ),
            const SizedBox(height: 20),

            // Catatan Tambahan
            _buildLabel('Catatan Tambahan'),
            TextField(
              controller: _catatanController,
              maxLines: 4,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Perlu lembur tambahan untuk menyelesaikan testing security setelah deployment server selesai malam ini.',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(16),
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
              ),
            ),
            const SizedBox(height: 24),

            // Foto Selfie
            _buildLabel('Foto Selfie Verifikasi'),
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
                              'Ambil Foto Selfie',
                              style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Foto wajah diperlukan untuk verifikasi lembur',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Center(
              child: Text(
                'Maksimal lembur dalam sebulan adalah 72 jam',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                onPressed: _isSubmitting ? null : _ajukanLembur,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Ajukan Lembur',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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

  Widget _buildDurationChip(int hours) {
    final bool isSelected = _selectedDuration == hours;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = hours;
        });
      },
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE6F7F5) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF009688) : Colors.grey.shade300,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$hours Jam',
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF009688) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
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