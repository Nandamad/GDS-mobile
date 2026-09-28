import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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

    return SingleChildScrollView(
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
    );
  }

  Widget _buildKontrakCard(Map<String, dynamic> kontrak) {
    final title = kontrak['judul']?.toString() ?? 'Kontrak Kerja';
    final jenis = kontrak['jenis_kontrak']?.toString() ?? '-';
    final periodeMulai = kontrak['periode_mulai']?.toString() ?? '-';
    final periodeSelesai = kontrak['periode_selesai']?.toString() ?? '-';
    final periode = '$periodeMulai - $periodeSelesai';
    final departemen = kontrak['departemen']?.toString() ?? '-';
    
    String statusText = kontrak['status_teks']?.toString() ?? '';
    if (statusText.toLowerCase() == 'berakhir') {
      statusText = 'Selesai';
    }
    
    final bool isActive = (kontrak['is_aktif'] == true) || (statusText.toLowerCase() == 'aktif');

    Color badgeBgColor;
    Color badgeTextColor;

    if (statusText.toLowerCase() == 'aktif') {
      badgeBgColor = const Color(0xFFE0F2F1);
      badgeTextColor = const Color(0xFF009688);
    } else if (statusText.toLowerCase() == 'perpanjangan') {
      badgeBgColor = const Color(0xFFFEF3C7); // Kuning/Abu bg
      badgeTextColor = const Color(0xFFD97706);
    } else {
      badgeBgColor = const Color(0xFFF1F5F9);
      badgeTextColor = const Color(0xFF4B5563);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? const Color(0xFF009688) : Colors.grey.shade200,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive
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
