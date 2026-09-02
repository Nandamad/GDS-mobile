import 'package:flutter/material.dart';
import '../services/image_url_service.dart';
import 'edit_profil_page.dart';

class DataPribadiScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const DataPribadiScreen({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    final rawKaryawan = userProfile['karyawan'];
    final Map<String, dynamic> karyawan = rawKaryawan is Map
        ? Map<String, dynamic>.from(rawKaryawan)
        : (userProfile);

    final nama = (karyawan['nama_lengkap'] ??
            userProfile['name'] ??
            userProfile['nama'] ??
            'Karyawan')
        .toString();

    final rawJabatan = karyawan['jabatan'];
    final jabatan =
        (rawJabatan is Map ? rawJabatan['nama_jabatan'] : rawJabatan ?? 'Staff')
            .toString();

    final rawDivisi = karyawan['divisi'];
    final divisi =
        (rawDivisi is Map ? rawDivisi['nama_divisi'] : rawDivisi ?? 'Umum')
            .toString();

    final email = (userProfile['email'] ?? karyawan['email'] ?? '-').toString();
    final noHp = (karyawan['no_hp'] ?? '-').toString();
    final int? kId = karyawan['id'];
    final String generatedNip = kId != null ? 'EMP-${kId.toString().padLeft(3, '0')}' : '-';
    final nip = (karyawan['nip'] ?? generatedNip).toString();
    final tanggalMulai = (karyawan['tanggal_mulai_kerja'] ?? '-').toString();

    final rawFoto = karyawan['foto_url'] ??
        karyawan['foto'] ??
        karyawan['foto_karyawan'] ??
        userProfile['foto'] ??
        userProfile['avatar'];
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
          'Data Pribadi',
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
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
                      backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                      child: fotoUrl == null
                          ? const Icon(Icons.person, size: 40, color: Color(0xFF009688))
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'NIP: $nip',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Forms Read Only
            _buildReadOnlyField('NAMA LENGKAP', nama),
            const SizedBox(height: 16),
            _buildReadOnlyField('EMAIL', email),
            const SizedBox(height: 16),
            _buildReadOnlyField('NO. TELEPON', noHp),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: _buildReadOnlyField('JABATAN', jabatan)),
                const SizedBox(width: 12),
                Expanded(child: _buildReadOnlyField('DEPARTEMEN', divisi)),
              ],
            ),
            const SizedBox(height: 16),
            _buildReadOnlyField('TANGGAL BERGABUNG', tanggalMulai),
            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilScreen(
                        userProfile: userProfile,
                      ),
                    ),
                  );
                  if (result == true) {
                    if (context.mounted) Navigator.pop(context, true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009688),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Edit Profil',
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

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
