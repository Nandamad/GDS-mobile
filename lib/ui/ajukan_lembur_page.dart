import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AjukanLemburSheet extends StatefulWidget {
  const AjukanLemburSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AjukanLemburSheet(),
    );
  }

  @override
  State<AjukanLemburSheet> createState() => _AjukanLemburSheetState();
}

class _AjukanLemburSheetState extends State<AjukanLemburSheet> {
  DateTime _tanggalLembur = DateTime.now();

  TimeOfDay _jamMulai = const TimeOfDay(hour: 17, minute: 0);
  TimeOfDay _jamSelesai = const TimeOfDay(hour: 19, minute: 0);

  bool _isSubmitting = false;
  final TextEditingController _alasanController = TextEditingController();

  int get _totalDurasiJam {
    final startMinutes = _jamMulai.hour * 60 + _jamMulai.minute;
    final endMinutes = _jamSelesai.hour * 60 + _jamSelesai.minute;

    int diff = endMinutes - startMinutes;
    if (diff <= 0) {
      diff += 24 * 60;
    }

    return (diff / 60).round();
  }

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _submitLembur() async {
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan lembur wajib diisi!')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await ApiService().getToken();
      if (token == null) {
        throw Exception('Token login tidak ditemukan');
      }

      final dio = ApiService().dio;

      final tanggal =
          '${_tanggalLembur.year}-${_tanggalLembur.month.toString().padLeft(2, '0')}-${_tanggalLembur.day.toString().padLeft(2, '0')}';
      final jamMulai =
          '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}';
      final jamSelesai =
          '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}';

      await dio.post(
        '/lembur',
        data: {
          'tanggal': tanggal,
          'jam_mulai_lembur': jamMulai,
          'jam_selesai_lembur': jamSelesai,
          'alasan': _alasanController.text.trim(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengajuan lembur berhasil dikirim!'),
          backgroundColor: Color(0xFF009688),
        ),
      );

      Navigator.pop(context);
    } on DioException catch (e) {
      String message = 'Gagal mengirim pengajuan';
      final data = e.response?.data;

      if (data is Map) {
        message = data['message']?.toString() ?? data['error']?.toString() ?? message;
      } else if (e.message != null) {
        message = e.message!;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: $message'),
          backgroundColor: Colors.red,
        ),
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLembur,
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
        _tanggalLembur = picked;
      });
    }
  }

  Future<void> _selectTime(bool isMulai) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
    );

    if (picked != null) {
      setState(() {
        if (isMulai) {
          _jamMulai = picked;
        } else {
          _jamSelesai = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];

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
            // HEADER BAR WITH BACK BUTTON & TITLE
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
                    child: const Icon(
                      Icons.arrow_back,
                      size: 18,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'Ajukan Lembur',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 34), // Spacer agar title berada di tengah
              ],
            ),
            const SizedBox(height: 16),

            // BANNER JAM KERJA NORMAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF0F766E).withOpacity(0.3),
                      ),
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
                        const Text(
                          'Jam Kerja Normal: 08:00 - 17:00 WIB',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pastikan lembur sudah disetujui atasan.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // FIELD TANGGAL LEMBUR
            const Text(
              'Tanggal Lembur',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _selectDate,
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
                          _formatDate(_tanggalLembur),
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
            ),
            const SizedBox(height: 14),

            // FIELD JAM MULAI LEMBUR
            const Text(
              'Jam Mulai Lembur',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildTimeField(
              time: _jamMulai,
              onTap: () => _selectTime(true),
            ),
            const SizedBox(height: 14),

            // FIELD JAM SELESAI LEMBUR
            const Text(
              'Jam Selesai Lembur',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildTimeField(
              time: _jamSelesai,
              onTap: () => _selectTime(false),
            ),
            const SizedBox(height: 14),

            // BANNER DURASI LEMBUR
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
                    '$_totalDurasiJam Jam',
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

            // FORM ALASAN LEMBUR
            const Text(
              'Alasan Lembur',
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
                hintText: 'Tuliskan alasan lembur Anda...',
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
            const SizedBox(height: 20),

            // TOMBOL SUBMIT
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitLembur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
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

  // WIDGET HELPER INPUT WAKTU
  Widget _buildTimeField({
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
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
                  Icons.access_time_rounded,
                  size: 18,
                  color: Colors.grey,
                ),
                const SizedBox(width: 10),
                Text(
                  _formatTime(time),
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
}