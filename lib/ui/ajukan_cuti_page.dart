import 'dart:io';
import 'dart:ui'; // <--- Tambahkan baris ini
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AjukanCutiSheet extends StatefulWidget {
  const AjukanCutiSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AjukanCutiSheet(),
    );
  }

  @override
  State<AjukanCutiSheet> createState() => _AjukanCutiSheetState();
}

class _AjukanCutiSheetState extends State<AjukanCutiSheet> {
  String _tipePengajuan = 'Cuti';

  DateTime _tanggalMulai = DateTime.now();
  DateTime _tanggalSelesai = DateTime.now().add(const Duration(days: 4));

  File? _selectedFile;
  String? _fileName;

  bool _isSubmitting = false;
  int _sisaCuti = 8; // Default value, bisa diambil dari API

  final TextEditingController _alasanController = TextEditingController();

  int get _durasiHari {
    return _tanggalSelesai.difference(_tanggalMulai).inDays + 1;
  }

  @override
  void initState() {
    super.initState();
    _fetchSisaCuti();
  }

  Future<void> _fetchSisaCuti() async {
    try {
      final dio = ApiService().dio;
      final response = await dio.get('/dashboard');
      if (response.statusCode == 200) {
        final payload = response.data;
        final data = payload is Map && payload['data'] is Map ? payload['data'] : payload;
        final summary = data['summary'];
        if (summary != null && summary['sisa_cuti'] != null) {
          setState(() {
            _sisaCuti = int.tryParse(summary['sisa_cuti'].toString()) ?? 8;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _submitCuti() async {
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan wajib diisi!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final token = await ApiService().getToken();
      if (token == null) throw Exception('Token login tidak ditemukan');

      final dio = ApiService().dio;

      final startFormatted =
          "${_tanggalMulai.year}-${_tanggalMulai.month.toString().padLeft(2, '0')}-${_tanggalMulai.day.toString().padLeft(2, '0')}";
      final endFormatted =
          "${_tanggalSelesai.year}-${_tanggalSelesai.month.toString().padLeft(2, '0')}-${_tanggalSelesai.day.toString().padLeft(2, '0')}";

      String jenisIzinVal = _tipePengajuan.toLowerCase();
      if (jenisIzinVal != 'cuti') {
        jenisIzinVal = 'izin';
      }

      final formData = FormData.fromMap({
        'jenis': jenisIzinVal,
        'tanggal_mulai': startFormatted,
        'tanggal_selesai': endFormatted,
        'alasan': _alasanController.text.trim(),
      });

      if (_selectedFile != null) {
        formData.files.add(
          MapEntry(
            'dokumen_pendukung',
            await MultipartFile.fromFile(
              _selectedFile!.path,
              filename: _fileName,
            ),
          ),
        );
      }

      final response = await dio.post('/cuti', data: formData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan berhasil dikirim!'),
          backgroundColor: Color(0xFF009688),
        ),
      );

      Navigator.pop(context);
    } on DioException catch (e) {
      String message = 'Gagal mengirim pengajuan';
      if (e.response?.data is Map) {
        message = e.response!.data['message']?.toString() ?? message;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $message'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan, coba lagi'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isMulai ? _tanggalMulai : _tanggalSelesai,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF009688)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
          if (_tanggalSelesai.isBefore(_tanggalMulai)) {
            _tanggalSelesai = _tanggalMulai;
          }
        } else {
          if (picked.isBefore(_tanggalMulai)) {
            _tanggalSelesai = _tanggalMulai;
          } else {
            _tanggalSelesai = picked;
          }
        }
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName = result.files.single.name;
      });
    }
  }

  String _formatDate(DateTime date) {
    final List<String> bulan = [
      'Agt', 'Agt', 'Agt', 'Agt', 'Agt', 'Agt', 'Agt', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    // Menggunakan format pad dua digit tanggal dan tahun
    return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER BAR WITH BACK/CLOSE BUTTON & TITLE
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Ajukan Cuti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 34), // Spacer agar judul tetap presisi di tengah
              ],
            ),
            const SizedBox(height: 16),

            // SISA CUTI BANNER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F766E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Sisa Cuti: $_sisaCuti Hari',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Pastikan kamu memilih tanggal yang tepat.',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // TIPE PENGAJUAN
            const Text(
              'Tipe',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildSegmentedTab('Cuti'),
                  _buildSegmentedTab('Izin'),
                  _buildSegmentedTab('Sakit'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // TANGGAL MULAI
            const Text(
              'Tanggal Mulai',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildDatePickerField(
              _formatDate(_tanggalMulai),
                  () => _selectDate(context, true),
            ),
            const SizedBox(height: 14),

            // TANGGAL SELESAI
            const Text(
              'Tanggal Selesai',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildDatePickerField(
              _formatDate(_tanggalSelesai),
                  () => _selectDate(context, false),
            ),
            const SizedBox(height: 14),

            // DURASI BANNER
            const Text(
              'Durasi',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F766E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_durasiHari Hari Kerja',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ALASAN
            const Text(
              'Alasan',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _alasanController,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Tuliskan alasan cuti Anda...',
                hintStyle: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // LAMPIRAN (DOTTED BORDER BOX)
            const Text(
              'Lampiran (Opsional)',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickFile,
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: DashedRectPainter(
                  color: const Color(0xFF009688),
                  strokeWidth: 1.2,
                  gap: 4.0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 24,
                        color: Color(0xFF009688),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fileName ?? 'Ambil foto atau unggah file',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF009688),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCuti,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Kirim Pengajuan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET SEGMENTED TAB
  Widget _buildSegmentedTab(String type) {
    final isSelected = _tipePengajuan == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _tipePengajuan = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCCFBF1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            type,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  // WIDGET DATE PICKER FIELD
  Widget _buildDatePickerField(String dateText, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }
}

// PAINTER UNTUK GARIS PUTUS-PUTUS (DASHED BORDER)
class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final Path dashPath = Path();
    double distance = 0.0;

    for (final PathMetric pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + gap),
          Offset.zero,
        );
        distance += gap * 2;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}