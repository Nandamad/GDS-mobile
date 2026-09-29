import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class RiwayatKontrakScreen extends StatefulWidget {
  const RiwayatKontrakScreen({super.key});

  @override
  State<RiwayatKontrakScreen> createState() => _RiwayatKontrakScreenState();
}

class _RiwayatKontrakScreenState extends State<RiwayatKontrakScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _kontrakAktif;
  List<dynamic> _kontrakSebelumnya = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService().dio.get('/kontrak');
      
      if (response.statusCode == 200 && response.data['status'] == 'success') {
        final data = response.data['data'];
        if (mounted) {
          setState(() {
            _kontrakAktif = data['kontrak_aktif'];
            _kontrakSebelumnya = data['kontrak_sebelumnya'] ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Gagal memuat data kontrak.';
            _isLoading = false;
          });
        }
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.response?.data['message'] ?? 'Terjadi kesalahan koneksi.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan sistem.';
          _isLoading = false;
        });
      }
    }
  }

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
          'Riwayat Kontrak',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF009688)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688)),
              child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: const Color(0xFF009688),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'KONTRAK AKTIF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          if (_kontrakAktif != null)
            _buildKontrakCard(_kontrakAktif!)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Text(
                'Belum ada data kontrak aktif',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          
          if (_kontrakSebelumnya.isNotEmpty) ...[
            const Text(
              'KONTRAK SEBELUMNYA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ..._kontrakSebelumnya.map((kontrak) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildKontrakCard(kontrak as Map<String, dynamic>),
              );
            }),
            const SizedBox(height: 24),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildKontrakCard(Map<String, dynamic> kontrak) {
    final title = kontrak['judul']?.toString() ?? 'Kontrak Kerja';
    final jenis = kontrak['jenis_kontrak']?.toString() ?? '-';
    final periodeMulai = kontrak['periode_mulai']?.toString() ?? '-';
    final periodeSelesai = kontrak['periode_selesai']?.toString() ?? '-';
    final periode = '$periodeMulai - $periodeSelesai';
    final departemen = kontrak['departemen']?.toString() ?? '-';
    final dokumenUrl = kontrak['dokumen_url']?.toString();
    
    final statusText = kontrak['status_teks']?.toString() ?? '';
    
    final bool isAktifBoolean = kontrak['is_aktif'] == true;

    Color badgeBgColor;
    Color badgeTextColor;
    Border? badgeBorder;

    if (statusText.toLowerCase() == 'aktif') {
      badgeBgColor = const Color(0xFFEFF6FF); // bg-blue-50
      badgeTextColor = const Color(0xFF2563EB); // text-blue-600
    } else if (statusText.toLowerCase() == 'perpanjangan') {
      badgeBgColor = const Color(0xFFF1F5F9); // bg-slate-100
      badgeTextColor = const Color(0xFF475569); // text-slate-600
    } else if (statusText.toLowerCase() == 'berakhir') {
      badgeBgColor = const Color(0xFFFFF7ED); // bg-orange-50
      badgeTextColor = const Color(0xFFEA580C); // text-orange-600
    } else if (statusText.toLowerCase() == 'non-aktif') {
      badgeBgColor = const Color(0xFFF1F5F9); // bg-slate-100
      badgeTextColor = const Color(0xFF64748B); // text-slate-500
      badgeBorder = Border.all(color: const Color(0xFFCBD5E1)); // border-slate-300
    } else {
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAktifBoolean ? const Color(0xFF009688) : Colors.grey.shade200,
          width: isAktifBoolean ? 1.5 : 1.0,
        ),
        boxShadow: isAktifBoolean
            ? [
                BoxShadow(
                  color: const Color(0xFF009688).withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: badgeBorder,
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Jenis Kontrak', jenis),
          const SizedBox(height: 8),
          _buildInfoRow('Periode', periode),
          const SizedBox(height: 8),
          _buildInfoRow('Departemen', departemen),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (dokumenUrl != null && dokumenUrl.isNotEmpty) {
                  final uri = Uri.parse(dokumenUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka dokumen')),
                      );
                    }
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tidak ada dokumen')),
                    );
                  }
                }
              },
              icon: Icon(
                Icons.description_outlined,
                size: 16,
                color: (dokumenUrl != null && dokumenUrl.isNotEmpty) ? const Color(0xFF009688) : Colors.grey,
              ),
              label: Text(
                'Lihat Dokumen',
                style: TextStyle(
                  color: (dokumenUrl != null && dokumenUrl.isNotEmpty) ? const Color(0xFF009688) : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: BorderSide(color: (dokumenUrl != null && dokumenUrl.isNotEmpty) ? const Color(0xFF009688) : Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
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
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
