import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../api_config.dart'; // Pastikan path ApiConfig sudah benar
import '../services/api_service.dart';
import 'login_page.dart'; // Import layar login untuk aksi logout

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final Color primaryTeal = const Color(0xFF009688);
  final Color lightTealBadge = const Color(0xFFE0F2F1);

  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Ambil data profil karyawan yang login dari API
  Future<void> _fetchUserProfile() async {
    try {
      final token = await ApiService().getToken();

      if (token == null) {
        _logout();
        return;
      }

      final dio = ApiService().dio;

      final response = await dio.get('/profile');

      if (response.statusCode == 200) {
        setState(() {
          _userProfile = response.data['data'] ?? response.data;
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage =
        e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
            'Gagal memuat data profil.'
            : e.response?.data?.toString() ??
            'Gagal memuat data profil.';
        _isLoading = false;
      });
    }
  }
  // Aksi Logout
  Future<void> _logout() async {
    await ApiService().clearToken();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileHeaderCard(),
            const SizedBox(height: 16),
            _buildInformasiPekerjaanCard(),
            const SizedBox(height: 16),
            _buildPengaturanAkunCard(),
            const SizedBox(height: 20),
            _buildTombolKeluar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Card Header Profil (Dinamis)
  Widget _buildProfileHeaderCard() {
    final karyawan = _userProfile?['karyawan'] ?? _userProfile;
    final nama = karyawan?['nama_lengkap'] ?? _userProfile?['name'] ?? 'Karyawan';
    final jabatan = karyawan?['jabatan']?['nama_jabatan'] ?? 'Staff';
    final divisi = karyawan?['divisi']?['nama_divisi'] ?? 'Umum';
    final foto = karyawan?['foto_url'] ?? 'https://i.pravatar.cc/300?img=11';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
              border: Border.all(color: primaryTeal, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundImage: NetworkImage(foto),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nama,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            jabatan,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: lightTealBadge,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              divisi,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: primaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card Informasi Pekerjaan (Dinamis)
  Widget _buildInformasiPekerjaanCard() {
    final karyawan = _userProfile?['karyawan'] ?? _userProfile;

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
            'Informasi Pekerjaan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('NIP', karyawan?['nip'] ?? '-'),
          const Divider(height: 20),
          _buildInfoRow('Email', _userProfile?['email'] ?? karyawan?['email'] ?? '-'),
          const Divider(height: 20),
          _buildInfoRow('No. HP', karyawan?['no_hp'] ?? '-'),
          const Divider(height: 20),
          _buildInfoRow('Tanggal Bergabung', karyawan?['tanggal_mulai_kerja'] ?? '-'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildPengaturanAkunCard() {
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
            'Pengaturan Akun',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingMenu(
            icon: Icons.lock_outline_rounded,
            title: 'Ubah Password',
            onTap: () {},
          ),
          const Divider(height: 16),
          _buildSettingMenu(
            icon: Icons.info_outline_rounded,
            title: 'Tentang Aplikasi',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingMenu({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTombolKeluar() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(
          Icons.logout_rounded,
          color: Colors.redAccent,
          size: 16,
        ),
        label: const Text(
          'Keluar Aplikasi',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}