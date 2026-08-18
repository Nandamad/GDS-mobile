import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../ui/detail_workflow_page.dart';
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

  TimeOfDay _jamMulai = const TimeOfDay(
    hour: 17,
    minute: 0,
  );

  TimeOfDay _jamSelesai = const TimeOfDay(
    hour: 19,
    minute: 0,
  );

  bool _isSubmitting = false;

  final TextEditingController _alasanController =
  TextEditingController();

  int get _totalDurasiJam {
    final startMinutes =
        _jamMulai.hour * 60 + _jamMulai.minute;

    final endMinutes =
        _jamSelesai.hour * 60 + _jamSelesai.minute;

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
        const SnackBar(
          content: Text('Alasan lembur wajib diisi!'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await ApiService().getToken();

      if (token == null) {
        throw Exception(
          'Token login tidak ditemukan',
        );
      }

      final dio = ApiService().dio;

      final tanggal =
          '${_tanggalLembur.year}-'
          '${_tanggalLembur.month.toString().padLeft(2, '0')}-'
          '${_tanggalLembur.day.toString().padLeft(2, '0')}';

      final jamMulai =
          '${_jamMulai.hour.toString().padLeft(2, '0')}:'
          '${_jamMulai.minute.toString().padLeft(2, '0')}';

      final jamSelesai =
          '${_jamSelesai.hour.toString().padLeft(2, '0')}:'
          '${_jamSelesai.minute.toString().padLeft(2, '0')}';

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
          content: Text(
            'Pengajuan lembur berhasil dikirim!',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pop(context);
    } on DioException catch (e) {
      debugPrint(
        'Submit lembur error: '
            '${e.response?.statusCode} '
            '${e.response?.data}',
      );

      String message =
          'Gagal mengirim pengajuan';

      final data = e.response?.data;

      if (data is Map) {
        message =
            data['message']?.toString() ??
                data['error']?.toString() ??
                message;
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
      debugPrint(
        'Submit lembur error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terjadi kesalahan, coba lagi',
          ),
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
            colorScheme:
            const ColorScheme.light(
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

  Future<void> _selectTime(
      bool isMulai,
      ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
      isMulai ? _jamMulai : _jamSelesai,
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
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const bulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day.toString().padLeft(2, '0')} '
        '${bulan[date.month - 1]} '
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        padding: EdgeInsets.only(
          top: 8,
          left: 14,
          right: 14,
          bottom:
          MediaQuery.of(context)
              .viewInsets
              .bottom +
              16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // HANDLE
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin:
                  const EdgeInsets.symmetric(
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                    Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(2),
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

              // TANGGAL
              const Text(
                'Tanggal Lembur',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              InkWell(
                onTap: _selectDate,
                borderRadius:
                BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color:
                    const Color(0xFFF8FAFC),
                    borderRadius:
                    BorderRadius.circular(8),
                    border: Border.all(
                      color:
                      Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                    children: [
                      Text(
                        _formatDate(
                          _tanggalLembur,
                        ),
                        style:
                        const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons
                            .calendar_today_rounded,
                        size: 14,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // JAM
              Row(
                children: [
                  Expanded(
                    child: _buildTimeField(
                      title:
                      'Jam Mulai Lembur',
                      time: _jamMulai,
                      onTap: () =>
                          _selectTime(true),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: _buildTimeField(
                      title:
                      'Jam Selesai Lembur',
                      time: _jamSelesai,
                      onTap: () =>
                          _selectTime(false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // DURASI
              Container(
                width: double.infinity,
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                  const Color(0xFFE0F2F1),
                  borderRadius:
                  BorderRadius.circular(8),
                ),
                child: Text(
                  'Total Durasi: $_totalDurasiJam Jam',
                  style: const TextStyle(
                    color:
                    Color(0xFF00796B),
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ALASAN
              const Text(
                'Alasan Lembur',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(height: 4),

              TextField(
                controller:
                _alasanController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 11,
                  color:
                  Color(0xFF0F172A),
                ),
                decoration:
                InputDecoration(
                  hintText:
                  'Tuliskan alasan lembur...',
                  hintStyle:
                  const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  contentPadding:
                  const EdgeInsets.all(
                    10,
                  ),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                    borderSide:
                    BorderSide(
                      color:
                      Colors.grey.shade300,
                    ),
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                      8,
                    ),
                    borderSide:
                    BorderSide(
                      color:
                      Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BUTTON
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child:
                      OutlinedButton(
                        onPressed:
                        _isSubmitting
                            ? null
                            : () =>
                            Navigator.pop(
                              context,
                            ),
                        style:
                        OutlinedButton
                            .styleFrom(
                          side:
                          BorderSide(
                            color:
                            Colors.grey
                                .shade300,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                          ),
                        ),
                        child:
                        const Text(
                          'Batal',
                          style:
                          TextStyle(
                            color:
                            Colors.grey,
                            fontSize: 11,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child:
                      ElevatedButton(
                        onPressed:
                        _isSubmitting
                            ? null
                            : _submitLembur,
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF009688,
                          ),
                          disabledBackgroundColor:
                          Colors.grey
                              .shade400,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              8,
                            ),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                          CircularProgressIndicator(
                            color:
                            Colors
                                .white,
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Text(
                          'Ajukan Lembur',
                          style:
                          TextStyle(
                            color:
                            Colors
                                .white,
                            fontSize:
                            11,
                            fontWeight:
                            FontWeight
                                .bold,
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

  Widget _buildTimeField({
    required String title,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight:
            FontWeight.w500,
          ),
        ),

        const SizedBox(height: 4),

        InkWell(
          onTap: onTap,
          borderRadius:
          BorderRadius.circular(8),
          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(8),
              border: Border.all(
                color:
                Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
              children: [
                Text(
                  _formatTime(time),
                  style:
                  const TextStyle(
                    fontSize: 11,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const Icon(
                  Icons
                      .access_time_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}