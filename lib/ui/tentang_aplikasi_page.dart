import 'package:flutter/material.dart';

class TentangAplikasiScreen extends StatelessWidget {
  const TentangAplikasiScreen({super.key});

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
          'Tentang Aplikasi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          children: [
            // Logo / Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1), // Light green
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.access_time_rounded, color: Color(0xFF009688), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'PresensiKu',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versi 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 24),
            
            // Description
            const Text(
              'PresensiKu adalah solusi Employee Self-Service (ESS) terintegrasi untuk memudahkan kehadiran, pengajuan cuti, serta pengelolaan data kepegawaian Anda dalam satu genggaman tangan secara real-time dan transparan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Dibuat oleh', 'PT Global Digital Solusi'),
                  const Divider(height: 24),
                  _buildInfoRow('Email', 'admin@gds.com'),
                  const Divider(height: 24),
                  _buildInfoRow('Website', 'www.gds.com'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Policies
            _buildActionCard('Kebijakan Privasi', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halaman Kebijakan Privasi sedang dalam pengembangan.')));
            }),
            const SizedBox(height: 12),
            _buildActionCard('Syarat & Ketentuan', () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Halaman Syarat & Ketentuan sedang dalam pengembangan.')));
            }),
            
            const SizedBox(height: 40),
            // Copyright
            const Text(
              '© 2026 PresensiKu. All rights reserved.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
