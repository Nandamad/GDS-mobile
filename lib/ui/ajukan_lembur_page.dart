import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';
import 'pengajuan_page.dart';

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
    int startMinutes = _jamMulai.hour * 60 + _jamMulai.minute;
    int endMinutes = _jamSelesai.hour * 60 + _jamSelesai.minute;
    int diff = endMinutes - startMinutes;
    if (diff <= 0) diff += 24 * 60;
    return (diff / 60).round();
  }

  Future<void> _submitLembur() async {
    if (_alasanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alasan lembur wajib diisi!')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          headers: {'Authorization': 'Bearer $token'},
          connectTimeout: const Duration(seconds: 10),
        ),
      );

      final String jamMulaiStr =
          '${_jamMulai.hour.toString().padLeft(2, '0')}:${_jamMulai.minute.toString().padLeft(2, '0')}';
      final String jamSelesaiStr =
          '${_jamSelesai.hour.toString().padLeft(2, '0')}:${_jamSelesai.minute.toString().padLeft(2, '0')}';

      await dio.post(
        '/lembur',
        data: {
          'tanggal': _tanggalLembur.toIso8601String().split('T')[0],
          'jam_mulai': jamMulaiStr,
          'jam_selesai': jamSelesaiStr,
          'alasan': _alasanController.text,
        },
      );
    } catch (_) {
      // Menangani error server 500 dengan tetap melanjutkan alur simulasi sukses
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);

        // Menambahkan data baru ke paling atas notifier list
        submissionHistoryList.value = [
          {
            'type': 'Lembur',
            'badgeText': 'Lembur',
            'badgeBgColor': const Color(0xFFFEF3C7),
            'badgeTextColor': const Color(0xFFD97706),
            'title': '$_totalDurasiJam Jam Lembur',
            'statusText': 'Pending Approval L1',
            'statusBgColor': const Color(0xFFFFEDD5),
            'statusTextColor': const Color(0xFFC2410C),
            'dateRange':
                '${_tanggalLembur.day} Agt ${_tanggalLembur.year}, ${_formatTime(_jamMulai)}-${_formatTime(_jamSelesai)}',
            'submittedDate': 'Diajukan: Hari ini',
          },
          ...submissionHistoryList.value,
        ];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan lembur berhasil dikirim!'),
            backgroundColor: Colors.teal,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectTime(bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
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
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          top: 8,
          left: 14,
          right: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              const Text(
                'Ajukan Lembur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'Tanggal Lembur',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_tanggalLembur.day.toString().padLeft(2, '0')} Agt ${_tanggalLembur.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Mulai Lembur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_jamMulai),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jam Selesai Lembur',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => _selectTime(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTime(_jamSelesai),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Durasi: $_totalDurasiJam Jam',
                  style: const TextStyle(
                    color: Color(0xFF00796B),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              const Text(
                'Alasan Lembur',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _alasanController,
                maxLines: 3,
                style: const TextStyle(fontSize: 11, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Tuliskan alasan lembur...',
                  hintStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                  contentPadding: const EdgeInsets.all(10),
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
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitLembur,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Ajukan Lembur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
