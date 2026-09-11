import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Duration _remainingTime = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  bool _isSubmitting = false;
  bool _alarmPlayed = false;

  DateTime get startTime => DateTime.parse(widget.lemburData['jam_mulai_lembur']).toLocal();
  String get alasan => widget.lemburData['alasan'] ?? '';
  String get catatan => widget.lemburData['catatan'] ?? '';
  int get estimasiMenit => widget.lemburData['durasi_lembur_menit'] as int? ?? 120;

  /// Waktu selesai yang dijadwalkan (startTime + estimasi)
  DateTime get scheduledEndTime => startTime.add(Duration(minutes: estimasiMenit));

  /// Apakah waktu lembur sudah habis
  bool get isTimeUp => DateTime.now().isAfter(scheduledEndTime);

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
    final elapsed = now.difference(startTime);
    final remaining = scheduledEndTime.difference(now);

    setState(() {
      _elapsedTime = elapsed;
      _remainingTime = remaining.isNegative ? Duration.zero : remaining;
    });

    // Bunyikan alarm saat waktu habis
    if (isTimeUp && !_alarmPlayed) {
      _alarmPlayed = true;
      _playAlarm();
    }
  }

  /// Memainkan alarm menggunakan system haptic & sound
  Future<void> _playAlarm() async {
    // Haptic feedback kuat
    HapticFeedback.heavyImpact();

    // Gunakan system alert sound via platform channel
    try {
      SystemSound.play(SystemSoundType.alert);
      // Ulangi beberapa kali untuk efek alarm
      for (int i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
        }
      }
    } catch (_) {
      // Fallback: cukup haptic saja
    }
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

  /// Dialog peringatan jika mencoba selesai sebelum waktunya
  void _showCannotFinishDialog() {
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
                'Selesai Lembur',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maaf lembur tidak dapat diselesaikan sampai jam yang telah ditentukan',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _akhiriLembur() async {
    // Cek apakah waktu sudah habis
    if (!isTimeUp) {
      _showCannotFinishDialog();
      return;
    }

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
    final bool timeUp = isTimeUp;
    
    // Format Estimasi Awal
    final int estHours = estimasiMenit ~/ 60;
    final int estMins = estimasiMenit % 60;
    final String estimasiText = estMins > 0 ? '$estHours Jam $estMins Menit' : '$estHours Jam';
    
    // Format Waktu Berjalan (elapsed)
    final int elapHours = _elapsedTime.inHours;
    final int elapMins = _elapsedTime.inMinutes.remainder(60);
    final String elapsedText = elapMins > 0 ? '$elapHours Jam $elapMins Menit' : '$elapHours Jam';

    // Timer display: countdown jika masih berjalan, elapsed jika sudah habis
    final String timerDisplay = timeUp 
        ? _formatDuration(_elapsedTime) 
        : _formatDuration(_remainingTime);

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ===== Banner Info (jika waktu sudah habis) =====
                    if (timeUp) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Waktu lembur telah melebihi estimasi, silahkan selesaikan lembur Anda',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
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

                    // ===== Timer Card =====
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
                            timeUp ? 'WAKTU LEMBUR TELAH HABIS' : 'LEMBUR BERJALAN',
                            style: TextStyle(
                              color: timeUp ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            timerDisplay,
                            style: TextStyle(
                              color: timeUp ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
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
                                  color: timeUp ? const Color(0xFFEF4444) : const Color(0xFF009688),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                timeUp 
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
                    
                    // ===== Informasi Lembur Aktif Card =====
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
                          if (catatan.isNotEmpty) ...[
                            _buildInfoRow('Catatan', catatan),
                            const SizedBox(height: 12),
                          ],
                          if (timeUp) ...[
                            // Tampilkan status berakhir dan durasi aktual
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Status',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Berakhir',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: Colors.red.shade400,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Waktu Berjalan', elapsedText),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // ===== Button Selesai Lembur =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _akhiriLembur,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: timeUp ? const Color(0xFFEF4444) : const Color(0xFF009688),
                    disabledBackgroundColor: Colors.grey.shade300,
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
            ),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}