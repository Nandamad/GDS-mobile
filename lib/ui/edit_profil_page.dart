import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/image_url_service.dart';
import '../services/api_service.dart';
import 'kamera_page.dart';
class EditProfilScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfilScreen({super.key, required this.userProfile});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  late TextEditingController _namaController;
  late TextEditingController _emailController;
  late TextEditingController _noHpController;
  late TextEditingController _alamatController;
  
  bool _isSubmitting = false;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final rawKaryawan = widget.userProfile['karyawan'];
    final Map<String, dynamic> karyawan = rawKaryawan is Map
        ? Map<String, dynamic>.from(rawKaryawan)
        : (widget.userProfile);

    final nama = (karyawan['nama_lengkap'] ??
            widget.userProfile['name'] ??
            widget.userProfile['nama'] ??
            '')
        .toString();
    final email = (widget.userProfile['email'] ?? karyawan['email'] ?? '').toString();
    final noHp = (karyawan['no_hp'] ?? '').toString();
    final alamat = (karyawan['alamat'] ?? '').toString(); 

    _namaController = TextEditingController(text: nama);
    _emailController = TextEditingController(text: email);
    _noHpController = TextEditingController(text: noHp);
    _alamatController = TextEditingController(text: alamat);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _simpanPerubahan() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = FormData.fromMap({
        'nama_lengkap': _namaController.text,
        'email': _emailController.text,
        'no_hp': _noHpController.text,
        'alamat': _alamatController.text,
      });

      if (_base64Image != null) {
        final bytes = base64Decode(_base64Image!.split(',').last);
        formData.files.add(MapEntry(
          'foto',
          MultipartFile.fromBytes(bytes, filename: 'profile.jpg'),
        ));
      }

      final response = await ApiService().dio.post(
        '/profile/update',
        data: formData,
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil berhasil diperbarui'),
              backgroundColor: Color(0xFF009688),
            ),
          );
          Navigator.pop(context, true); // kembalikan true agar halaman sblmnya tau ada update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal memperbarui profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan koneksi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _tampilkanPilihanFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const KameraScreen(namaKantor: 'Foto Profil'),
                    ),
                  );
                  if (result != null && result is String) {
                    setState(() {
                      _base64Image = result;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                  if (image != null) {
                    final bytes = await image.readAsBytes();
                    final base64String = base64Encode(bytes);
                    setState(() {
                      _base64Image = 'data:image/jpeg;base64,$base64String';
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rawKaryawan = widget.userProfile['karyawan'];
    final Map<String, dynamic> karyawan = rawKaryawan is Map
        ? Map<String, dynamic>.from(rawKaryawan)
        : (widget.userProfile);

    final rawFoto = karyawan['foto_url'] ??
        karyawan['foto'] ??
        karyawan['foto_karyawan'] ??
        widget.userProfile['foto'] ??
        widget.userProfile['avatar'];
    final fotoUrl = ImageUrlService.resolve(rawFoto?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // Foto Profil with Camera Badge
            Center(
              child: GestureDetector(
                onTap: _tampilkanPilihanFoto,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF009688), width: 2.5),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFFE0F2F1),
                            backgroundImage: _base64Image != null
                                ? MemoryImage(base64Decode(_base64Image!.split(',').last)) as ImageProvider
                                : (fotoUrl != null ? NetworkImage(fotoUrl) : null),
                            child: (_base64Image == null && fotoUrl == null)
                                ? const Icon(Icons.person, size: 40, color: Color(0xFF009688))
                                : null,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(bottom: 2, right: 2),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF009688),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ubah Foto Profil',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF009688),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Editable Forms
            _buildEditField(
              label: 'Nama Lengkap',
              controller: _namaController,
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              label: 'Email',
              controller: _emailController,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              label: 'No. Telepon',
              controller: _noHpController,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            _buildEditField(
              label: 'Alamat',
              controller: _alamatController,
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),
            const SizedBox(height: 40),
            
            // Button Simpan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _simpanPerubahan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: readOnly ? Colors.grey.shade600 : const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            fillColor: readOnly ? const Color(0xFFF1F5F9) : Colors.white,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: readOnly ? Colors.grey.shade300 : const Color(0xFF009688), 
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
