import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../ui/ajukan_cuti_page.dart';
import '../ui/ajukan_lembur_page.dart';
import '../ui/ajukan_koreksi_presensi_page.dart';
import '../ui/perlu_persetujuan_page.dart';

class PengajuanScreen extends StatefulWidget {
  final bool showBackButton;
  const PengajuanScreen({super.key, this.showBackButton = false});

  @override
  State<PengajuanScreen> createState() => _PengajuanScreenState();
}

class _PengajuanScreenState extends State<PengajuanScreen> {
  bool _isAtasan = false;

  @override
  void initState() {
    super.initState();
    _checkAtasan();
  }

  Future<void> _checkAtasan() async {
    final isAtasan = await ApiService().getIsAtasan();
    if (mounted) {
      setState(() {
        _isAtasan = isAtasan;
      });
    }
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Pengajuan',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isAtasan) ...[
              // Card Ajukan Lembur
              _buildMenuCard(
                title: 'Ajukan Lembur',
                subtitle: 'Pengajuan lembur kerja',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanLemburScreen()),
                  );
                },
              ),
              // Card Ajukan Cuti
              _buildMenuCard(
                title: 'Ajukan Cuti',
                subtitle: 'Sakit, cuti tahunan, atau izin pribadi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanCutiScreen()),
                  );
                },
              ),
              // Card Ajukan Koreksi Presensi
              _buildMenuCard(
                title: 'Ajukan Koreksi Presensi',
                subtitle: 'Koreksi data presensi, jam masuk, atau jam pulang',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanKoreksiPresensiScreen()),
                  );
                },
              ),
              _buildMenuCard(
                title: 'Pengajuan',
                subtitle: 'Pengajuan',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PerluPersetujuanScreen()),
                ),
              ),
            ] else ...[
              // Card Ajukan Lembur
              _buildMenuCard(
                title: 'Ajukan Lembur',
                subtitle: 'Pengajuan lembur kerja',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanLemburScreen()),
                  );
                },
              ),
              // Card Ajukan Cuti
              _buildMenuCard(
                title: 'Ajukan Cuti',
                subtitle: 'Sakit, cuti tahunan, atau izin pribadi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanCutiScreen()),
                  );
                },
              ),
              // Card Ajukan Koreksi Presensi
              _buildMenuCard(
                title: 'Ajukan Koreksi Presensi',
                subtitle: 'Koreksi data presensi, jam masuk, atau jam pulang',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AjukanKoreksiPresensiScreen()),
                  );
                },
              ),
            ]
          ],
        ),
      ),
    );
  }
}
