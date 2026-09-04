import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ajukan_lembur_page.dart';
import 'kamera_page.dart';
import 'selesai_lembur_page.dart';

class MulaiLemburScreen extends StatefulWidget {
  final Map<String, dynamic>? lemburData;
  final String lemburStatus;

  const MulaiLemburScreen({
    super.key, 
    required this.lemburData,
    required this.lemburStatus,
  });

  @override
  State<MulaiLemburScreen> createState() => _MulaiLemburScreenState();
}

class _MulaiLemburScreenState extends State<MulaiLemburScreen> {
  String? _fotoSelfieBase64;
  bool _isStarting = false;

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
    if (widget.lemburData == null) {
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
                  'Pengajuan Lembur',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ajukan lembur terlebih dahulu untuk memulai lembur',
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
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AjukanLemburScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Ajukan Lembur', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
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

    if (widget.lemburStatus == 'Menunggu') {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengajuan lembur Anda sedang diproses HRD')));
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

    // Simulasi proses kamera/mulai (api start tidak ada di backend, lembur otomatis terhitung dari jam_mulai)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SelesaiLemburScreen(lemburData: widget.lemburData!),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.lemburData;
    final tanggal = data?['tanggal'] != null 
        ? DateFormat('dd MMMM yyyy').format(DateTime.parse(data!['tanggal'])) 
        : '-';
    final alasan = data?['alasan'] ?? '-';
    final durasiMenit = data?['durasi_lembur_menit'] != null ? (data!['durasi_lembur_menit'] as int) : 0;
    final estimasiJam = durasiMenit > 0 ? (durasiMenit / 60).toStringAsFixed(0) : '-';
    final approvedByName = data?['approved_by_l1']?['name'] ?? data?['approved_by_l2']?['name'] ?? '-';

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Detail Lembur Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF009688), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
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
                                'Detail Lembur',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (widget.lemburData != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: widget.lemburStatus == 'Disetujui' ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: widget.lemburStatus == 'Disetujui' ? const Color(0xFF009688) : const Color(0xFFD97706)),
                                  ),
                                  child: Text(
                                    widget.lemburStatus == 'Disetujui' ? 'Disetujui' : 'Menunggu',
                                    style: TextStyle(
                                      color: widget.lemburStatus == 'Disetujui' ? const Color(0xFF009688) : const Color(0xFFD97706),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Tanggal', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(tanggal, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          const SizedBox(height: 12),
                          const Text('Alasan Lembur', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(alasan, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                          const SizedBox(height: 12),
                          const Text('Estimasi Durasi', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('$estimasiJam Jam', style: const TextStyle(fontSize: 13, color: Color(0xFF009688))),
                          const SizedBox(height: 12),
                          const Text('Disetujui oleh', style: TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(approvedByName, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
        
                    // Foto Selfie
                    const Text(
                      'Kirim Foto Lembur',
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
                                      'Ambil Foto Lembur',
                                      style: TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Foto diperlukan sebagai bukti lembur',
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
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _mulaiLembur,
                  icon: _isStarting
                      ? const SizedBox.shrink()
                      : const Icon(Icons.play_arrow_outlined, color: Colors.white, size: 20),
                  label: _isStarting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Mulai Lembur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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
