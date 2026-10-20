import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class BantuanFaqScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;

  const BantuanFaqScreen({super.key, required this.userProfile});

  static const _appSupportEmail = 'presensiplus.id@gmail.com';

  @override
  Widget build(BuildContext context) {
    final employee = _asMap(userProfile['karyawan']) ?? userProfile;
    final tenant = _asMap(userProfile['tenant']);
    final employeeName = _nonEmptyValue(
      employee['nama_lengkap'] ?? userProfile['name'] ?? userProfile['nama'],
    );
    final employeeId =
        _nonEmptyValue(
          employee['nip'] ?? employee['id'] ?? userProfile['karyawan_id'],
        ) ??
        '-';
    final hrdEmail = _nonEmptyValue(tenant?['email']);
    final tenantPhone = _nonEmptyValue(tenant?['nomor_telepon']);
    final hrdPhone = _whatsAppPhone(tenant?['nomor_telepon']?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
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
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 48,
                      color: Color(0xFF009688),
                    ),
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
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
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
                  _buildSupportCard(
                    icon: Icons.people_alt_outlined,
                    title: 'Hubungi HRD',
                    description:
                        'Untuk urusan cuti, lembur, koreksi presensi, dan data kepegawaian.',
                    contact:
                        hrdEmail ?? 'Kontak email perusahaan belum tersedia.',
                    secondaryContact:
                        tenantPhone ?? 'Nomor perusahaan belum tersedia.',
                    color: const Color(0xFF009688),
                    buttonLabel: hrdPhone == null
                        ? 'Kontak WhatsApp HRD belum tersedia'
                        : 'Chat HRD via WhatsApp',
                    buttonIcon: Icons.chat_rounded,
                    onPressed: hrdPhone == null
                        ? null
                        : () async {
                            final packageInfo =
                                await PackageInfo.fromPlatform();
                            if (!context.mounted) return;
                            final message = [
                              'Halo HRD, saya membutuhkan bantuan.',
                              'Nama: ${employeeName ?? '-'}',
                              'ID Karyawan: $employeeId',
                              'Versi aplikasi: ${packageInfo.version}',
                            ].join('\n');
                            final uri = Uri.https('wa.me', '/$hrdPhone', {
                              'text': message,
                            });
                            await _launchURL(context, uri);
                          },
                  ),
                  const SizedBox(height: 12),
                  _buildSupportCard(
                    icon: Icons.phone_android_rounded,
                    title: 'Dukungan Aplikasi',
                    description:
                        'Untuk kendala teknis seperti error, GPS/kamera, login, atau bug aplikasi.',
                    contact: _appSupportEmail,
                    color: const Color(0xFF3B82F6),
                    buttonLabel: 'Email Dukungan Aplikasi',
                    buttonIcon: Icons.email_outlined,
                    onPressed: () async {
                      final packageInfo = await PackageInfo.fromPlatform();
                      if (!context.mounted) return;
                      final message = [
                        'Halo Tim Dukungan PresensiPlus+, saya mengalami kendala aplikasi.',
                        'Nama: ${employeeName ?? '-'}',
                        'ID Karyawan: $employeeId',
                        'Versi aplikasi: ${packageInfo.version}',
                      ].join('\n');
                      final uri = Uri(
                        scheme: 'mailto',
                        path: _appSupportEmail,
                        queryParameters: {
                          'subject': 'Bantuan teknis PresensiPlus+',
                          'body': message,
                        },
                      );
                      await _launchURL(context, uri);
                    },
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
                  _buildFaqItem(
                    'Bagaimana cara absen masuk?',
                    'Anda dapat menekan tombol "Absen Masuk" di halaman utama (Dashboard) ketika Anda sudah berada di dalam radius lokasi kantor yang ditentukan.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Bagaimana cara mengajukan cuti?',
                    'Buka menu Pengajuan, pilih opsi "Cuti", isi formulir pengajuan cuti beserta alasan, lalu tekan tombol "Ajukan".',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Apa yang harus dilakukan jika lupa absen?',
                    'Anda dapat mengajukan koreksi presensi melalui menu Pengajuan -> "Koreksi Presensi", dan memberikan alasan lupa absen untuk disetujui atasan.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Bagaimana cara melihat sisa cuti?',
                    'Informasi sisa cuti dapat Anda lihat di bagian profil Anda, atau di halaman Ringkasan Kehadiran.',
                  ),
                  const SizedBox(height: 12),
                  _buildFaqItem(
                    'Bagaimana cara mengajukan lembur?',
                    'Buka menu Pengajuan, lalu pilih opsi "Lembur". Isi durasi dan alasan lembur untuk dikonfirmasi oleh atasan Anda.',
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required String contact,
    String? secondaryContact,
    required Color color,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            contact,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (secondaryContact != null) ...[
            const SizedBox(height: 4),
            Text(
              secondaryContact,
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon, size: 18),
              label: Text(buttonLabel, textAlign: TextAlign.center),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF64748B),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
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
          ),
        ],
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _whatsAppPhone(String? phone) {
    if (phone == null) return null;
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) {
      digits = '62${digits.substring(1)}';
    }
    if (!digits.startsWith('62') || digits.length < 10 || digits.length > 15) {
      return null;
    }
    return digits;
  }

  static String? _nonEmptyValue(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  Future<void> _launchURL(BuildContext context, Uri uri) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat membuka aplikasi tujuan. Pastikan aplikasi email atau WhatsApp tersedia.',
          ),
        ),
      );
    }
  }
}
