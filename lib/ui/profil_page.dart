import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/image_url_service.dart';
import 'login_page.dart';
import 'data_pribadi_page.dart';
import 'pengaturan_notifikasi_page.dart';
import 'ubah_password_page.dart';
import 'riwayat_kontrak_page.dart';
import 'bantuan_faq_page.dart';
import 'tentang_aplikasi_page.dart';
import 'riwayat_presensi_page.dart';

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
  bool _profileImageFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Ambil data profil karyawan yang login dari API (Penanganan Tipe Data Sangat Aman)
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
        final dynamic payload = response.data;

        Map<String, dynamic>? extractProfile(dynamic data) {
          if (data is! Map) return null;
          final map = Map<String, dynamic>.from(data);

          for (final key in ['data', 'user', 'profile']) {
            final value = map[key];
            if (value is Map) {
              return Map<String, dynamic>.from(value);
            }
          }
          return map;
        }

        final profile = extractProfile(payload);

        if (profile != null) {
          if (!mounted) return;
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
          return;
        }

        if (!mounted) return;
        setState(() {
          _errorMessage = 'Format data profil tidak valid.';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      debugPrint(
        'PROFILE ERROR: ${e.response?.statusCode} ${e.response?.data}',
      );

      if (!mounted) return;
      setState(() {
        _errorMessage = e.response?.data is Map
            ? e.response?.data['message']?.toString() ??
                  'Gagal memuat data profil.'
            : e.response?.data?.toString() ?? 'Gagal memuat data profil.';
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PROFILE PARSE ERROR: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Terjadi kesalahan sistem saat memuat profil.';
        _isLoading = false;
      });
    }
  }

  // Aksi Logout
  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await ApiService().deleteToken();

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
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryTeal))
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _fetchUserProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                      ),
                      child: const Text(
                        'Coba Lagi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  _buildProfileHeaderCard(),
                  const SizedBox(height: 24),
                  
                  // Menu List Group
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Data Pribadi',
                          onTap: () async {
                            if (_userProfile != null) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DataPribadiScreen(
                                    userProfile: _userProfile!,
                                  ),
                                ),
                              );
                              if (result == true) {
                                setState(() { _isLoading = true; });
                                _fetchUserProfile();
                              }
                            }
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Pengaturan Notifikasi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PengaturanNotifikasiScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Password',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const UbahPasswordScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.article_outlined,
                          title: 'Riwayat Kontrak',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RiwayatKontrakScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.format_list_bulleted_rounded,
                          title: 'Riwayat Presensi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RiwayatPresensiScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Bantuan & FAQ',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BantuanFaqScreen(),
                              ),
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang Aplikasi',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TentangAplikasiScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  _buildTombolKeluar(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // Header Profil
  Widget _buildProfileHeaderCard() {
    final rawKaryawan = _userProfile?['karyawan'];
    final Map<String, dynamic> karyawan = rawKaryawan is Map
        ? Map<String, dynamic>.from(rawKaryawan)
        : (_userProfile ?? {});

    final nama =
        (karyawan['nama_lengkap'] ??
                _userProfile?['name'] ??
                _userProfile?['nama'] ??
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
            
    final nip = (karyawan['nip'] ?? '-').toString();

    // Cek semua kemungkinan key nama foto dari API Laravel
    final rawFoto =
        karyawan['foto_url'] ??
        karyawan['foto'] ??
        karyawan['foto_karyawan'] ??
        _userProfile?['foto'] ??
        _userProfile?['avatar'];

    final fotoUrl = ImageUrlService.resolve(rawFoto?.toString());
    
    // Parse year joined for badge
    String yearJoined = '2020';
    if (karyawan['tanggal_mulai_kerja'] != null) {
       try {
          // just take first 4 chars assuming YYYY-MM-DD
          yearJoined = karyawan['tanggal_mulai_kerja'].toString().substring(0, 4);
       } catch (_) {}
    }

    return Container(
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
              border: Border.all(color: primaryTeal, width: 2.5),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: lightTealBadge,
              backgroundImage: fotoUrl != null && !_profileImageFailed
                  ? NetworkImage(fotoUrl)
                  : null,
              onBackgroundImageError: fotoUrl == null
                  ? null
                  : (error, stackTrace) {
                      if (mounted && !_profileImageFailed) {
                        setState(() => _profileImageFailed = true);
                      }
                    },
              child: fotoUrl == null || _profileImageFailed
                  ? Icon(Icons.person, size: 38, color: primaryTeal)
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
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$jabatan - $divisi',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'NIP: $nip',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Badges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.business_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      karyawan['kantor'] != null && karyawan['kantor'] is Map 
                          ? (karyawan['kantor']['nama_kantor']?.toString() ?? 'Kantor Pusat')
                          : 'Kantor Pusat',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      'Bergabung: $yearJoined',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1), // light teal
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF009688)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  Widget _buildTombolKeluar() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _logout,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
        ),
        child: const Text(
          'Keluar',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
