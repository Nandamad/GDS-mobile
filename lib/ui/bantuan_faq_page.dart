import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanFaqScreen extends StatelessWidget {
  const BantuanFaqScreen({super.key});

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
          'Pusat Bantuan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  )
                ]
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 48, color: Color(0xFF009688)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Halo, ada yang bisa kami bantu?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari topik masalah...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hubungi Kami',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.mark_email_unread_rounded,
                          title: 'Email',
                          subtitle: 'presensiplus.id\n@gmail.com',
                          color: const Color(0xFF3B82F6),
                          onTap: () => _launchURL('mailto:presensiplus.id@gmail.com'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildContactCard(
                          icon: Icons.chat_rounded,
                          title: 'WhatsApp',
                          subtitle: '+62 857-0766-9915',
                          color: const Color(0xFF10B981),
                          onTap: () => _launchURL('https://wa.me/6285707669915'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Pertanyaan Populer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String title, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          )
        ]
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
        iconColor: const Color(0xFF009688),
        collapsedIconColor: const Color(0xFF94A3B8),
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.5),
          )
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }
}
