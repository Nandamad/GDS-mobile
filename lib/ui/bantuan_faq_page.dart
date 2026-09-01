import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanFaqScreen extends StatelessWidget {
  const BantuanFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Bantuan & FAQ',
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
            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Cari pertanyaan...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Pertanyaan Populer
            const Text(
              'PERTANYAAN POPULER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildFaqItem('Bagaimana cara absen masuk?', 'Anda dapat menekan tombol "Absen Masuk" di halaman utama (Dashboard) ketika Anda sudah berada di dalam radius lokasi kantor yang ditentukan.'),
            const SizedBox(height: 12),
            _buildFaqItem('Bagaimana cara mengajukan cuti?', 'Buka menu Pengajuan, pilih opsi "Cuti", isi formulir pengajuan cuti beserta alasan, lalu tekan tombol "Ajukan".'),
            const SizedBox(height: 12),
            _buildFaqItem('Apa yang harus dilakukan jika lupa absen?', 'Anda dapat mengajukan koreksi presensi melalui menu Pengajuan -> "Koreksi Presensi", dan memberikan alasan lupa absen untuk disetujui atasan.'),
            const SizedBox(height: 12),
            _buildFaqItem('Bagaimana cara melihat sisa cuti?', 'Informasi sisa cuti dapat Anda lihat di bagian profil Anda, atau di halaman Ringkasan Kehadiran.'),
            const SizedBox(height: 12),
            _buildFaqItem('Bagaimana cara mengajukan lembur?', 'Buka menu Pengajuan, lalu pilih opsi "Lembur". Isi durasi dan alasan lembur untuk dikonfirmasi oleh atasan Anda.'),
            const SizedBox(height: 32),
            
            // Bantuan Lain Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1), // Light green
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Butuh bantuan lain?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF009688),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tim HRD kami siap membantu Anda dengan kendala teknis atau administratif.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF009688),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, size: 16, color: Color(0xFF009688)),
                      const SizedBox(width: 8),
                      const Text(
                        'hrd@gds.com',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF009688),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF009688)),
                      const SizedBox(width: 8),
                      const Text(
                        '+62 812-3456-7890',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF009688),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () => _launchEmail(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hubungi HRD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String title, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        iconColor: const Color(0xFF94A3B8),
        collapsedIconColor: const Color(0xFF94A3B8),
        shape: const Border(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
            ),
          )
        ],
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri url = Uri.parse('mailto:hrd@gds.com');
    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }
}
