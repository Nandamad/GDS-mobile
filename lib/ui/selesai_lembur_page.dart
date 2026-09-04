import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SelesaiLemburScreen extends StatefulWidget {
  final Map<String, dynamic> lemburData;

  const SelesaiLemburScreen({
    super.key,
    required this.lemburData,
  });

  @override
  State<SelesaiLemburScreen> createState() => _SelesaiLemburScreenState();
}

class _SelesaiLemburScreenState extends State<SelesaiLemburScreen> {
  late Timer _timer;
  Duration _elapsedTime = Duration.zero;
  bool _isSubmitting = false;

  DateTime get startTime => DateTime.parse(widget.lemburData['jam_mulai_lembur']).toLocal();
  String get alasan => widget.lemburData['alasan'] ?? '';
  int get estimasiMenit => widget.lemburData['durasi_lembur_menit'] as int? ?? 120; // Default 2 jam

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTime();
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _elapsedTime = now.difference(startTime);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatStartTime() {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${twoDigits(startTime.hour)}:${twoDigits(startTime.minute)}';
  }

  Future<void> _akhiriLembur() async {
    setState(() => _isSubmitting = true);
    try {
      final response = await ApiService().dio.post('/lembur/selesai');
      
      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.popUntil(context, (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lembur berhasil diakhiri!'),
            backgroundColor: Color(0xFF009688),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengakhiri lembur: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) {
         setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExceeded = _elapsedTime.inMinutes >= estimasiMenit;
    
    // Format Estimasi Awal
    final int estHours = estimasiMenit ~/ 60;
    final int estMins = estimasiMenit % 60;
    final String estimasiText = estMins > 0 ? '$estHours Jam $estMins Menit' : '$estHours Jam';
    
    // Format Waktu Berjalan
    final int elapHours = _elapsedTime.inHours;
    final int elapMins = _elapsedTime.inMinutes.remainder(60);
    final String elapsedText = elapMins > 0 ? '$elapHours Jam $elapMins Menit' : '$elapHours Jam';

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
          'Selesai Lembur',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Banner Info (Hanya tampil jika exceeded)
            if (isExceeded) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // Orange light
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF97316),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Waktu lembur telah melebihi estimasi, silahkan selesaikan lembur Anda',
                        style: TextStyle(
                          color: Color(0xFFC2410C),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    isExceeded ? 'WAKTU LEMBUR TELAH HABIS' : 'WAKTU BERJALAN',
                    style: TextStyle(
                      color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_elapsedTime),
                    style: TextStyle(
                      color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF009688),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isExceeded 
                            ? 'Estimasi lembur Anda telah berakhir'
                            : 'Dimulai dari jam ${_formatStartTime()} WIB',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Informasi Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
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
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Informasi Lembur Aktif',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  _buildInfoRow('Alasan Lembur', alasan.isEmpty ? '-' : alasan),
                  const SizedBox(height: 12),
                  _buildInfoRow('Estimasi Awal', estimasiText),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Waktu Berjalan',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          elapsedText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            const Spacer(),
            
            // Button Akhiri
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _akhiriLembur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF009688),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Selesai Lembur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
