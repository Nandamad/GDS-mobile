import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AjukanLemburScreen extends StatefulWidget {
  const AjukanLemburScreen({super.key});

  @override
  State<AjukanLemburScreen> createState() => _AjukanLemburScreenState();
}

class _AjukanLemburScreenState extends State<AjukanLemburScreen> {
  final TextEditingController _alasanController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  int _estimasiJam = 2;
  bool _isSubmitting = false;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _alasanController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _mulaiLembur() async {
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
      final String tanggal = DateFormat('yyyy-MM-dd').format(_selectedDate);
      
      final String jamMulaiStr = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      // Hitung jam selesai berdasarkan durasi
      int endHour = _selectedTime.hour + _estimasiJam;
      int endMinute = _selectedTime.minute;
      if (endHour >= 24) endHour = endHour % 24; // Handle lewat tengah malam
      
      final String jamSelesaiStr = '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

      final payload = {
        'tanggal': tanggal,
        'jam_mulai_lembur': jamMulaiStr,
        'jam_selesai_lembur': jamSelesaiStr,
        'alasan': _alasanController.text.trim() + (_catatanController.text.isNotEmpty ? ' - ' + _catatanController.text : ''),
      };

      final response = await ApiService().dio.post('/lembur', data: payload);
      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengajuan lembur berhasil dikirim'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); // Return true to refresh history
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengajukan lembur: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isSubmitting = false);
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
          'Ajukan Lembur',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      const Text(
                        'Pemberitahuan Lembur',
                        style: TextStyle(
                          color: Color(0xFFEA580C),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kegiatan lembur hanya akan dihitung setelah waktu kerja normal Anda hari ini selesai dan membutuhkan persetujuan HRD.',
                    style: TextStyle(
                      color: Color(0xFFEA580C),
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pilih Tanggal
            const Text(
              'Tanggal Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 12)),
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Pilih Waktu Mulai
            const Text(
              'Waktu Mulai Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectTime(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_selectedTime.format(context), style: const TextStyle(fontSize: 12)),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Alasan Lembur
            const Text(
              'Alasan Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alasanController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Contoh: Pekerjaan tambahan',
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            const SizedBox(height: 20),

            // Estimasi Durasi
            const Text(
              'Estimasi Durasi Lembur *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDurationChip(1),
                const SizedBox(width: 8),
                _buildDurationChip(2),
                const SizedBox(width: 8),
                _buildDurationChip(3),
                const SizedBox(width: 8),
                _buildDurationChip(4),
              ],
            ),
            const SizedBox(height: 20),

            // Catatan Tambahan
            const Text(
              'Catatan Tambahan',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _catatanController,
              maxLines: 4,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Perlu lembur tambahan...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.4),
                fillColor: Colors.white,
                filled: true,
                contentPadding: const EdgeInsets.all(12),
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
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _mulaiLembur,
                icon: _isSubmitting
                    ? const SizedBox.shrink()
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Ajukan Lembur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  disabledBackgroundColor: Colors.grey.shade300,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int hours) {
    bool isSelected = _estimasiJam == hours;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _estimasiJam = hours;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFCCFBF1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF0F766E) : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$hours Jam',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}
