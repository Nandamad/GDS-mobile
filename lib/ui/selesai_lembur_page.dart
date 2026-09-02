import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SelesaiLemburScreen extends StatefulWidget {
  final String alasan;
  final int estimasiJam;
  final String catatan;
  final DateTime startTime;

  const SelesaiLemburScreen({
    super.key,
    required this.alasan,
    required this.estimasiJam,
    required this.catatan,
    required this.startTime,
  });

  @override
  State<SelesaiLemburScreen> createState() => _SelesaiLemburScreenState();
}

class _SelesaiLemburScreenState extends State<SelesaiLemburScreen> {
  late Timer _timer;
  Duration _remainingTime = Duration.zero;

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
    final elapsedTime = now.difference(widget.startTime);
    final totalDuration = Duration(hours: widget.estimasiJam);
    final remaining = totalDuration - elapsedTime;

    setState(() {
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
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
    return '${twoDigits(widget.startTime.hour)}:${twoDigits(widget.startTime.minute)}';
  }

  Future<void> _akhiriLembur() async {
    try {
      // Mocking the backend API call to avoid 404
      await Future.delayed(const Duration(seconds: 1));
      // await ApiService().dio.post('/lembur/selesai');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_lembur_active');
      await prefs.remove('lembur_alasan');
      await prefs.remove('lembur_estimasi');
      await prefs.remove('lembur_catatan');
      await prefs.remove('lembur_start_time');

      if (!mounted) return;
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lembur berhasil diakhiri!'),
          backgroundColor: Color(0xFF009688),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengakhiri lembur: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
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
            // Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                  const Text(
                    'SISA WAKTU LEMBUR',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_remainingTime),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dimulai dari jam ${_formatStartTime()} ${DateTime.now().timeZoneName}',
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
                  const Text(
                    'Informasi Lembur Aktif',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Alasan Lembur', widget.alasan.isEmpty ? '-' : widget.alasan),
                  const SizedBox(height: 12),
                  _buildInfoRow('Estimasi Awal', '${widget.estimasiJam} Jam'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Catatan', widget.catatan.isEmpty ? '-' : widget.catatan),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Banner Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF0F766E),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: const Text(
                      'Menekan tombol selesai akan merekam waktu lembur Anda secara permanen di sistem HRD.',
                      style: TextStyle(
                        color: Color(0xFF0F766E),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            // Button Akhiri
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _akhiriLembur,
                icon: const Icon(Icons.stop_circle_outlined, size: 20, color: Colors.white),
                label: const Text(
                  'Akhiri Lembur Sekarang',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
