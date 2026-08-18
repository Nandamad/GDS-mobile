import 'dart:io';
import '../ui/detail_workflow_page.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../api_config.dart';
import '../ui/pengajuan_page.dart';

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

  DateTime _tanggalSelesai =
  DateTime.now().add(const Duration(days: 1));

  File? _selectedFile;
  String? _fileName;

  bool _isSubmitting = false;

  final TextEditingController _alasanController =
  TextEditingController();

  int get _durasiHari {
    return _tanggalSelesai
        .difference(_tanggalMulai)
        .inDays +
        1;
  }

  // ============================================================
  // SUBMIT CUTI / IZIN
  // ============================================================

  Future<void> _submitCuti() async {
    if (_alasanController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alasan wajib diisi!'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Ambil token login
      final token = await ApiService().getToken();

      if (token == null) {
        throw Exception('Token login tidak ditemukan');
      }

      // Dio
      final dio = ApiService().dio;

      // ========================================================
      // FORMAT TANGGAL
      // ========================================================

      final startFormatted =
          "${_tanggalMulai.year}-"
          "${_tanggalMulai.month.toString().padLeft(2, '0')}-"
          "${_tanggalMulai.day.toString().padLeft(2, '0')}";

      final endFormatted =
          "${_tanggalSelesai.year}-"
          "${_tanggalSelesai.month.toString().padLeft(2, '0')}-"
          "${_tanggalSelesai.day.toString().padLeft(2, '0')}";

      // ========================================================
      // JENIS PENGAJUAN
      // ========================================================

      String jenisIzinVal =
      _tipePengajuan.toLowerCase();

      // Backend menerima:
      // cuti
      // izin
      //
      // Kalau user memilih Sakit,
      // sementara dikirim sebagai izin.

      if (jenisIzinVal != 'cuti') {
        jenisIzinVal = 'izin';
      }

      // ========================================================
      // FORM DATA
      // ========================================================

      final formData = FormData.fromMap({
        'jenis': jenisIzinVal,
        'tanggal_mulai': startFormatted,
        'tanggal_selesai': endFormatted,
        'alasan': _alasanController.text.trim(),
      });

      // ========================================================
      // UPLOAD FILE JIKA ADA
      // ========================================================

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

      // ========================================================
      // REQUEST KE LARAVEL
      // ========================================================

      final response = await dio.post(
        '/cuti',
        data: formData,
      );

      debugPrint(
        'Submit cuti berhasil: '
            '${response.statusCode} ${response.data}',
      );

      // ========================================================
      // BERHASIL
      // ========================================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pengajuan berhasil dikirim!',
          ),
          backgroundColor: Colors.teal,
        ),
      );

      Navigator.pop(context);

    } on DioException catch (e) {
      // ========================================================
      // ERROR DARI DIO / LARAVEL
      // ========================================================

      debugPrint(
        'Submit cuti error: '
            '${e.response?.statusCode} '
            '${e.response?.data}',
      );

      String message =
          'Gagal mengirim pengajuan';

      if (e.response?.data is Map) {
        final data = e.response!.data;

        message =
            data['message']?.toString() ??
                message;
      } else if (e.message != null) {
        message = e.message!;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal: $message',
          ),
          backgroundColor: Colors.red,
        ),
      );

    } catch (e) {
      // ========================================================
      // ERROR LAIN
      // ========================================================

      debugPrint(
        'Submit cuti error: $e',
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

  // ============================================================
  // PILIH TANGGAL
  // ============================================================

  Future<void> _selectDate(
      BuildContext context,
      bool isMulai,
      ) async {
    final DateTime? picked =
    await showDatePicker(
      context: context,
      initialDate:
      isMulai
          ? _tanggalMulai
          : _tanggalSelesai,
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
        if (isMulai) {
          _tanggalMulai = picked;

          if (_tanggalSelesai
              .isBefore(_tanggalMulai)) {
            _tanggalSelesai =
                _tanggalMulai;
          }
        } else {
          if (picked.isBefore(
              _tanggalMulai)) {
            _tanggalSelesai =
                _tanggalMulai;
          } else {
            _tanggalSelesai = picked;
          }
        }
      });
    }
  }

  // ============================================================
  // PILIH FILE
  // ============================================================

  Future<void> _pickFile() async {
    final result =
    await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
    );

    if (result != null &&
        result.files.single.path != null) {
      setState(() {
        _selectedFile =
            File(result.files.single.path!);

        _fileName =
            result.files.single.name;
      });
    }
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String _formatDate(DateTime date) {
    final List<String> bulan = [
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration:
        const BoxDecoration(
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
            mainAxisSize:
            MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin:
                  const EdgeInsets
                      .symmetric(
                    vertical: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    Colors.grey.shade300,
                    borderRadius:
                    BorderRadius.circular(
                        2),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                'Ajukan Izin / Cuti Baru',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                  FontWeight.bold,
                  color:
                  Color(0xFF0F172A),
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // TIPE PENGAJUAN
              // ==================================================

              const Text(
                'Tipe Pengajuan',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              Row(
                children: [
                  _buildTypeRadio('Izin'),
                  const SizedBox(width: 6),
                  _buildTypeRadio('Cuti'),
                  const SizedBox(width: 6),
                  _buildTypeRadio('Sakit'),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // TANGGAL
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Tanggal Mulai',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                            Colors.grey,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                            height: 4),

                        _buildDatePickerField(
                          _formatDate(
                              _tanggalMulai),
                              () =>
                              _selectDate(
                                context,
                                true,
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        const Text(
                          'Tanggal Selesai',
                          style: TextStyle(
                            fontSize: 10,
                            color:
                            Colors.grey,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),

                        const SizedBox(
                            height: 4),

                        _buildDatePickerField(
                          _formatDate(
                              _tanggalSelesai),
                              () =>
                              _selectDate(
                                context,
                                false,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ==================================================
              // DURASI
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                      0xFFE0F2F1),
                  borderRadius:
                  BorderRadius.circular(
                      8),
                ),
                child: Text(
                  'Durasi: $_durasiHari Hari Kerja',
                  style:
                  const TextStyle(
                    color:
                    Color(0xFF00796B),
                    fontWeight:
                    FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // ALASAN
              // ==================================================

              const Text(
                'Alasan Pengajuan',
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
                style:
                const TextStyle(
                  fontSize: 11,
                  color:
                  Color(0xFF0F172A),
                ),
                decoration:
                InputDecoration(
                  hintText:
                  'Tuliskan alasan pengajuan...',
                  hintStyle:
                  const TextStyle(
                    fontSize: 11,
                    color:
                    Colors.grey,
                  ),
                  contentPadding:
                  const EdgeInsets
                      .all(10),
                  border:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(
                        8),
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
                        8),
                    borderSide:
                    BorderSide(
                      color:
                      Colors.grey.shade300,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==================================================
              // FILE
              // ==================================================

              const Text(
                'Surat Keterangan / Bukti Pendukung (Opsional)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight:
                  FontWeight.w500,
                ),
              ),

              const SizedBox(height: 6),

              InkWell(
                onTap: _pickFile,
                borderRadius:
                BorderRadius.circular(
                    8),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets
                      .symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                        0xFFF8FAFC),
                    borderRadius:
                    BorderRadius.circular(
                        8),
                    border:
                    Border.all(
                      color:
                      const Color(
                          0xFF009688)
                          .withOpacity(
                          0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _selectedFile != null
                            ? Icons
                            .check_circle_rounded
                            : Icons
                            .arrow_upward_rounded,
                        size: 18,
                        color:
                        const Color(
                            0xFF009688),
                      ),

                      const SizedBox(
                          height: 4),

                      Text(
                        _fileName ??
                            'Unggah Surat Dokter / Bukti',
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 11,
                          fontWeight:
                          FontWeight.bold,
                          color:
                          Color(
                              0xFF009688),
                        ),
                      ),

                      const SizedBox(
                          height: 2),

                      Text(
                        _selectedFile !=
                            null
                            ? 'Klik untuk mengubah berkas'
                            : 'Format PDF, JPG, PNG up to 5MB',
                        style:
                        const TextStyle(
                          fontSize: 8,
                          color:
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // BUTTON
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child:
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(
                                context),
                        style:
                        OutlinedButton
                            .styleFrom(
                          side:
                          BorderSide(
                            color: Colors
                                .grey
                                .shade300,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                8),
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
                            : _submitCuti,
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                              0xFF009688),
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                8),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                          CircularProgressIndicator(
                            color:
                            Colors.white,
                            strokeWidth:
                            2,
                          ),
                        )
                            : const Text(
                          'Kirim Pengajuan',
                          style:
                          TextStyle(
                            color:
                            Colors.white,
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

  // ============================================================
  // RADIO TIPE
  // ============================================================

  Widget _buildTypeRadio(
      String type) {
    final isSelected =
        _tipePengajuan == type;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _tipePengajuan = type;
          });
        },
        borderRadius:
        BorderRadius.circular(8),
        child: Container(
          padding:
          const EdgeInsets
              .symmetric(
            vertical: 6,
          ),
          decoration:
          BoxDecoration(
            color: isSelected
                ? const Color(
                0xFFE0F2F1)
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
                8),
            border:
            Border.all(
              color: isSelected
                  ? const Color(
                  0xFF009688)
                  : Colors
                  .grey
                  .shade300,
              width:
              isSelected
                  ? 1.2
                  : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .center,
            children: [
              Icon(
                isSelected
                    ? Icons
                    .radio_button_checked
                    : Icons
                    .radio_button_off,
                size: 12,
                color: isSelected
                    ? const Color(
                    0xFF009688)
                    : Colors.grey,
              ),

              const SizedBox(
                  width: 3),

              Text(
                type,
                style:
                TextStyle(
                  fontSize: 10,
                  fontWeight:
                  isSelected
                      ? FontWeight
                      .bold
                      : FontWeight
                      .normal,
                  color: isSelected
                      ? const Color(
                      0xFF009688)
                      : Colors
                      .grey
                      .shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE PICKER FIELD
  // ============================================================

  Widget _buildDatePickerField(
      String dateText,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(8),
      child: Container(
        padding:
        const EdgeInsets
            .symmetric(
          horizontal: 6,
          vertical: 8,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(8),
          border:
          Border.all(
            color:
            Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
          children: [
            Expanded(
              child: Text(
                dateText,
                style:
                const TextStyle(
                  fontSize: 10,
                  fontWeight:
                  FontWeight.w600,
                  color:
                  Color(0xFF0F172A),
                ),
                overflow:
                TextOverflow.ellipsis,
              ),
            ),

            const Icon(
              Icons.arrow_drop_down,
              size: 16,
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