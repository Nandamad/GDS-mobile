import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class KoreksiPresensiScreen extends StatefulWidget {
  const KoreksiPresensiScreen({super.key});

  @override
  State<KoreksiPresensiScreen> createState() => _KoreksiPresensiScreenState();
}

class _KoreksiPresensiScreenState extends State<KoreksiPresensiScreen> {
  final Color primaryTeal = const Color(0xFF009688);

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  TimeOfDay? _jamMasukBaru;
  TimeOfDay? _jamPulangBaru;

  // Waktu bawaan dari shift
  TimeOfDay _defaultShiftMasuk = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _defaultShiftPulang = const TimeOfDay(hour: 17, minute: 0);

  final TextEditingController _alasanController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchShiftData();
  }

  // Fetch jam shift karyawan dari API Profil
  Future<void> _fetchShiftData() async {
    try {
      final dio = ApiService().dio;
      final response = await dio.get('/profile');

      if (response.statusCode == 200) {
        final payload = response.data;
        final karyawan = payload['data']?['karyawan'] ?? payload['karyawan'] ?? payload['data'];
        final shift = karyawan?['shift'];

        if (shift != null && shift is Map) {
          final jamMasukStr = shift['jam_masuk']?.toString();
          final jamKeluarStr = shift['jam_keluar']?.toString();

          if (jamMasukStr != null && jamMasukStr.contains(':')) {
            final parts = jamMasukStr.split(':');
            _defaultShiftMasuk = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          if (jamKeluarStr != null && jamKeluarStr.contains(':')) {
            final parts = jamKeluarStr.split(':');
            _defaultShiftPulang = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
        }
      }
    } catch (e) {
      debugPrint('FETCH SHIFT ERROR: $e');
    }
  }

  // KETIKA TANGGAL DIKLIK -> OTOMATIS ISI JAM SESUAI SHIFT
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
      _jamMasukBaru = _defaultShiftMasuk;
      _jamPulangBaru = _defaultShiftPulang;
    });
  }

  Future<void> _selectTime(BuildContext context, bool isMasuk) async {
    final initial = isMasuk ? (_jamMasukBaru ?? _defaultShiftMasuk) : (_jamPulangBaru ?? _defaultShiftPulang);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
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
  if (time == null) return '00:00';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute'; // Mengembalikan murni HH:mm (contoh: "08:00")
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

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiService().dio;
      final tanggalFormatted =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      final response = await dio.post(
        '/koreksi-presensi',
        data: {
          'tanggal': tanggalFormatted,
          'jam_masuk_baru': _jamMasukBaru != null ? _formatTime(_jamMasukBaru) : null,
          'jam_pulang_baru': _jamPulangBaru != null ? _formatTime(_jamPulangBaru) : null,
          'alasan': _alasanController.text,
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
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString() ?? 'Gagal mengajukan koreksi.'
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Koreksi Presensi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKalenderCard(),
              const SizedBox(height: 16),
              if (_selectedDate != null) _buildSelectedInfoBox(),
              const SizedBox(height: 16),
              _buildFormWaktuCard(),
              const SizedBox(height: 16),
              _buildFormAlasanCard(),
              const SizedBox(height: 24),
              _buildTombolSubmit(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKalenderCard() {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday;
    final totalGridItems = daysInMonth + (firstWeekday - 1);

    const namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
                  });
                },
              ),
              Text(
                '${namaBulan[_focusedMonth.month - 1]} ${_focusedMonth.year}',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                onPressed: () {
                  setState(() {
                    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min']
                .map((d) => SizedBox(
                      width: 36,
                      child: Text(d, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalGridItems,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                final prevMonthLastDay = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month - 1);
                final dayNum = prevMonthLastDay - (firstWeekday - 2 - index);
                return _buildCellDay(dayNum.toString(), isOutside: true);
              }

              final dayNum = index - (firstWeekday - 2);
              final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNum);
              final isSelected = _selectedDate != null &&
                  _selectedDate!.year == currentDate.year &&
                  _selectedDate!.month == currentDate.month &&
                  _selectedDate!.day == currentDate.day;

              return InkWell(
                onTap: () => _onDateSelected(currentDate),
                borderRadius: BorderRadius.circular(12),
                child: _buildCellDay(
                  dayNum.toString(),
                  isSelected: isSelected,
                  hasIndicator: true,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCellDay(String day, {bool isOutside = false, bool isSelected = false, bool hasIndicator = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? primaryTeal : (isOutside ? Colors.grey.shade50 : Colors.white),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? primaryTeal : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : (isOutside ? Colors.grey.shade400 : const Color(0xFF0F172A)),
            ),
          ),
          if (hasIndicator && !isOutside && !isSelected) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSelectedInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryTeal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_available_rounded, color: primaryTeal, size: 20),
          const SizedBox(width: 8),
          Text(
            'Tanggal Dipilih: ${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryTeal),
          ),
        ],
      ),
    );
  }

  Widget _buildFormWaktuCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Koreksi Jam',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Masuk: ${_formatTime(_jamMasukBaru)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pulang: ${_formatTime(_jamPulangBaru)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormAlasanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alasan Koreksi Presensi',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _alasanController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Tuliskan alasan perbaikan (contoh: Lupa absen keluar / Salah tekan tombol absen)...',
              hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
            validator: (val) => val == null || val.trim().isEmpty ? 'Alasan wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildTombolSubmit() {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isSubmitting ? null : _submitKoreksi,
        child: _isSubmitting
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Kirim Pengajuan Koreksi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}