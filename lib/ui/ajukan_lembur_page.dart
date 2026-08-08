import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_config.dart';

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

  final TextEditingController _alasanController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitLembur() async {
    if (_alasanController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alasan lembur wajib diisi!')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {'Authorization': 'Bearer $token'},
        connectTimeout: const Duration(seconds: 15),
      ));

      final response = await dio.post('/lembur', data: {
        'tanggal': _tanggalLembur.toIso8601String().split('T')[0],
        'jam_mulai_lembur': _formatTime(_jamMulai),
        'jam_selesai_lembur': _formatTime(_jamSelesai),
        'alasan': _alasanController.text,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengajuan lembur berhasil!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        String msg = 'Gagal mengirim pengajuan lembur.';
        if (e.response != null && e.response!.data['message'] != null) {
          msg = e.response!.data['message'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // Menghitung selisih durasi lembur dalam jam
  double get _totalDurasi {
    final startMinutes = _jamMulai.hour * 60 + _jamMulai.minute;
    final endMinutes = _jamSelesai.hour * 60 + _jamSelesai.minute;

    if (endMinutes <= startMinutes) return 0;
    return (endMinutes - startMinutes) / 60.0;
  }

  // Pilih Tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLembur,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
            ),
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

  // Pilih Jam (Mulai / Selesai)
  Future<void> _selectTime(BuildContext context, bool isMulai) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMulai ? _jamMulai : _jamSelesai,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
            ),
          ),
          child: child!,
        );
      },
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

  String _formatDate(DateTime date) {
    final List<String> bulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Indicator Top Bar
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

            // Title
            const Text(
              'Ajukan Lembur',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 14),

            // Tanggal Lembur
            const Text(
              'Tanggal Lembur',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            _buildInputField(
              text: _formatDate(_tanggalLembur),
              icon: Icons.calendar_today_outlined,
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 12),

            // Jam Kerja Normal (Read-only)
            const Text(
              'Jam Kerja Normal (Hari Ini)',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '08:00 - 17:00 WIB',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                  Text(
                    'Read-only',
                    style: TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Row Jam Mulai & Jam Selesai
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jam Mulai Lembur',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      _buildInputField(
                        text: _formatTime(_jamMulai),
                        icon: Icons.access_time_rounded,
                        onTap: () => _selectTime(context, true),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jam Selesai Lembur',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      _buildInputField(
                        text: _formatTime(_jamSelesai),
                        icon: Icons.access_time_rounded,
                        onTap: () => _selectTime(context, false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Total Durasi Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFCCFBF1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Text(
                    'Total Durasi: ${_totalDurasi.toStringAsFixed(_totalDurasi.truncateToDouble() == _totalDurasi ? 0 : 1)} Jam',
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Alasan Lembur Textarea
            const Text(
              'Alasan Lembur',
              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
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
            const SizedBox(height: 18),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
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
                        style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 40,
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
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text(
                              'Ajukan Lembur',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String text,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            Icon(icon, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}