import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AjukanKoreksiPresensiScreen extends StatefulWidget {
  const AjukanKoreksiPresensiScreen({super.key});

  @override
  State<AjukanKoreksiPresensiScreen> createState() =>
      _AjukanKoreksiPresensiScreenState();
}

class _AjukanKoreksiPresensiScreenState
    extends State<AjukanKoreksiPresensiScreen> {
  final Color primaryTeal = const Color(0xFF009688);

  DateTime? _selectedDate;
  TimeOfDay? _jamMasukBaru;
  TimeOfDay? _jamPulangBaru;

  String? _selectedJenisKoreksi;
  final List<String> _jenisKoreksiOptions = [
    'Lupa Absen Masuk',
    'Lupa Absen Pulang',
    'Lupa Absen Masuk & Pulang',
    'Kendala Sistem',
    'Lainnya'
  ];

  final TextEditingController _alasanController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  File? _buktiImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _alasanController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Kompresi gambar
      );
      if (image != null) {
        setState(() {
          _buktiImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isMasuk) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMasuk
          ? (_jamMasukBaru ?? const TimeOfDay(hour: 8, minute: 0))
          : (_jamPulangBaru ?? const TimeOfDay(hour: 17, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryTeal,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isMasuk) {
          _jamMasukBaru = picked;
        } else {
          _jamPulangBaru = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-- : --';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitKoreksi() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal presensi yang ingin dikoreksi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_selectedJenisKoreksi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis koreksi!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiService().dio;
      final tanggalFormatted =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      // Gabungkan jenis koreksi ke alasan karena backend mungkin belum support field jenis_koreksi
      final finalAlasan =
          "[$_selectedJenisKoreksi] ${_alasanController.text.trim()}";

      // Meskipun backend mungkin belum support multipart file upload untuk bukti,
      // kita kirimkan sebagai request biasa terlebih dahulu.
      final response = await dio.post(
        '/koreksi-presensi',
        data: {
          'tanggal': tanggalFormatted,
          'jam_masuk_baru':
              _jamMasukBaru != null ? _formatTime(_jamMasukBaru) : null,
          'jam_pulang_baru':
              _jamPulangBaru != null ? _formatTime(_jamPulangBaru) : null,
          'alasan': finalAlasan,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message']?.toString() ??
                  'Pengajuan koreksi presensi berhasil dikirim.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        NotificationService().showInfoNotification(
          title: 'Koreksi Presensi Terkirim',
          body:
              'Pengajuan koreksi presensi Anda telah berhasil dikirim dan menunggu persetujuan.',
          preferenceKey: 'notif_pengajuan',
        );

        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString() ??
              'Gagal mengajukan koreksi.'
          : 'Gagal mengajukan koreksi.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ajukan Koreksi Presensi',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF64748B)),
            onPressed: () {
              // Bantuan action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pengajuan koreksi akan diteruskan ke atasan untuk disetujui.',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF166534),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tanggal Presensi
              _buildSectionTitle('Tanggal Presensi'),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Color(0xFF64748B)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Pilih Tanggal'
                            : '${_selectedDate!.day.toString().padLeft(2, '0')} ${_getMonthName(_selectedDate!.month)} ${_selectedDate!.year}',
                        style: TextStyle(
                          color: _selectedDate == null
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Jenis Koreksi
              _buildSectionTitle('Jenis Koreksi'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedJenisKoreksi,
                decoration: InputDecoration(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryTeal),
                  ),
                ),
                hint: const Text(
                  'Lupa Absen Masuk, Lupa Absen Pulang, Kend...',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF64748B)),
                items: _jenisKoreksiOptions
                    .map((jenis) => DropdownMenuItem(
                          value: jenis,
                          child: Text(jenis,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF1E293B))),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedJenisKoreksi = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Waktu Sebenarnya
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Jam Masuk Sebenarnya'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  _jamMasukBaru != null
                                      ? _formatTime(_jamMasukBaru)
                                      : '-- : --',
                                  style: TextStyle(
                                    color: _jamMasukBaru != null
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Jam Pulang Sebenarnya'),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time,
                                    size: 18, color: Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  _jamPulangBaru != null
                                      ? _formatTime(_jamPulangBaru)
                                      : '-- : --',
                                  style: TextStyle(
                                    color: _jamPulangBaru != null
                                        ? const Color(0xFF1E293B)
                                        : const Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
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
              const SizedBox(height: 16),

              // Alasan
              _buildSectionTitle('Alasan Koreksi'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _alasanController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Jelaskan alasan pengajuan koreksi...',
                  hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8), fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primaryTeal),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Alasan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 16),

              // Bukti Pendukung
              _buildSectionTitle('Bukti Pendukung'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid, // Simulasi dashed border
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _buktiImage != null ? Icons.image : Icons.cloud_upload_outlined,
                        color: primaryTeal,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _buktiImage != null
                            ? 'Gambar dipilih'
                            : 'Upload foto/screenshot (Opsional)',
                        style: TextStyle(
                          color: primaryTeal,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buktiImage != null
                            ? _buktiImage!.path.split('/').last
                            : 'Maks. ukuran file 5MB. Format: JPG, PNG',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Button Kirim
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isSubmitting ? null : _submitKoreksi,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Kirim Pengajuan Koreksi',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Ags',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }
}
