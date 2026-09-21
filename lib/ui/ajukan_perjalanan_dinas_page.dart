import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AjukanPerjalananDinasScreen extends StatefulWidget {
  const AjukanPerjalananDinasScreen({super.key});

  @override
  State<AjukanPerjalananDinasScreen> createState() =>
      _AjukanPerjalananDinasScreenState();
}

class _AjukanPerjalananDinasScreenState
    extends State<AjukanPerjalananDinasScreen> {
  final Color primaryTeal = const Color(0xFF009688);

  DateTime? _tanggalMulai;
  DateTime? _tanggalSelesai;
  String? _selectedJenisPerjalanan;
  
  final List<String> _jenisPerjalananOptions = [
    'Dalam Kota',
    'Luar Kota',
    'Luar Negeri'
  ];

  final TextEditingController _tujuanController = TextEditingController();
  final TextEditingController _klienController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _tujuanController.dispose();
    _klienController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isMulai) async {
    final initialDate = isMulai 
        ? (_tanggalMulai ?? DateTime.now()) 
        : (_tanggalSelesai ?? (_tanggalMulai ?? DateTime.now()));
        
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
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
    
    if (picked != null) {
      setState(() {
        if (isMulai) {
          _tanggalMulai = picked;
          // Auto-adjust tanggal selesai if it's before tanggal mulai
          if (_tanggalSelesai != null && _tanggalSelesai!.isBefore(_tanggalMulai!)) {
            _tanggalSelesai = _tanggalMulai;
          }
        } else {
          _tanggalSelesai = picked;
        }
      });
    }
  }

  Future<void> _submitPengajuan() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedJenisPerjalanan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih jenis perjalanan dinas!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_tanggalMulai == null || _tanggalSelesai == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal mulai dan selesai!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_tanggalSelesai!.isBefore(_tanggalMulai!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tanggal selesai tidak boleh sebelum tanggal mulai!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dio = ApiService().dio;
      final formatMulai = "${_tanggalMulai!.year}-${_tanggalMulai!.month.toString().padLeft(2, '0')}-${_tanggalMulai!.day.toString().padLeft(2, '0')}";
      final formatSelesai = "${_tanggalSelesai!.year}-${_tanggalSelesai!.month.toString().padLeft(2, '0')}-${_tanggalSelesai!.day.toString().padLeft(2, '0')}";

      final response = await dio.post(
        '/kunjungan/ajukan-perjalanan',
        data: {
          'tujuan_kunjungan': _tujuanController.text,
          'nama_klien': _klienController.text,
          'alamat_kunjungan': _alamatController.text,
          'jenis_perjalanan': _selectedJenisPerjalanan,
          'tanggal': formatMulai,
          'tanggal_selesai': formatSelesai,
          'catatan': _catatanController.text.isNotEmpty ? _catatanController.text : null,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message']?.toString() ??
                  'Pengajuan perjalanan dinas berhasil dikirim.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        NotificationService().showInfoNotification(
          title: 'Perjalanan Dinas Terkirim',
          body: 'Pengajuan perjalanan dinas Anda telah berhasil dikirim dan menunggu persetujuan.',
          preferenceKey: 'notif_pengajuan',
        );

        Navigator.pop(context, true);
      }
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? e.response?.data['message']?.toString() ??
              'Gagal mengajukan perjalanan dinas.'
          : 'Gagal mengajukan perjalanan dinas.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: required
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Wajib diisi' : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(icon, color: primaryTeal, size: 20),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryTeal),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? selectedDate,
    required VoidCallback onTap,
  }) {
    final text = selectedDate != null
        ? "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"
        : "Pilih Tanggal";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: primaryTeal, size: 20),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: selectedDate != null
                        ? const Color(0xFF0F172A)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Perjalanan Dinas',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formulir Pengajuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Isi detail perjalanan dinas atau penugasan luar Anda di bawah ini.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Jenis Perjalanan Dropdown
                    const Text(
                      'Jenis Perjalanan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedJenisPerjalanan,
                      hint: const Text('Pilih Jenis',
                          style: TextStyle(fontSize: 14)),
                      items: _jenisPerjalananOptions.map((String option) {
                        return DropdownMenuItem<String>(
                          value: option,
                          child: Text(option,
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedJenisPerjalanan = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon:
                            Icon(Icons.flight_takeoff, color: primaryTeal, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryTeal),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _tujuanController,
                      label: 'Tujuan Kunjungan',
                      hint: 'Contoh: Konferensi Tech, Pelatihan',
                      icon: Icons.flag_rounded,
                    ),
                    
                    _buildTextField(
                      controller: _klienController,
                      label: 'Nama Klien/Instansi',
                      hint: 'Contoh: PT. ABC, Universitas XYZ',
                      icon: Icons.business_rounded,
                    ),
                    
                    _buildTextField(
                      controller: _alamatController,
                      label: 'Alamat Kunjungan',
                      hint: 'Alamat lengkap lokasi...',
                      icon: Icons.location_on_rounded,
                      maxLines: 2,
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: _buildDatePickerField(
                            label: 'Tanggal Mulai',
                            selectedDate: _tanggalMulai,
                            onTap: () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDatePickerField(
                            label: 'Tanggal Selesai',
                            selectedDate: _tanggalSelesai,
                            onTap: () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),

                    _buildTextField(
                      controller: _catatanController,
                      label: 'Catatan (Opsional)',
                      hint: 'Tambahkan catatan jika diperlukan...',
                      icon: Icons.note_alt_rounded,
                      maxLines: 3,
                      required: false,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitPengajuan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Kirim Pengajuan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
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
}
