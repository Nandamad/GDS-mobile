import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState extends State<PengaturanNotifikasiScreen> {
  bool _pengingatMasuk = true;
  bool _pengingatKeluar = true;
  bool _updatePengajuan = true;
  bool _infoLembur = false;
  bool _pengumumanPerusahaan = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pengingatMasuk = prefs.getBool('notif_masuk') ?? true;
      _pengingatKeluar = prefs.getBool('notif_keluar') ?? true;
      _updatePengajuan = prefs.getBool('notif_pengajuan') ?? true;
      _infoLembur = prefs.getBool('notif_lembur') ?? false;
      _pengumumanPerusahaan = prefs.getBool('notif_pengumuman') ?? true;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
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
          'Pengaturan Notifikasi',
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
            const Text(
              'Preferensi Notifikasi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kelola bagaimana dan kapan Anda menerima pemberitahuan dari PresensiKu.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            
            // List of Notification Toggles
            _buildNotificationTile(
              icon: Icons.access_time_rounded,
              title: 'Pengingat Absen Masuk',
              subtitle: 'Notifikasi sebelum jam masuk',
              value: _pengingatMasuk,
              onChanged: (val) {
                setState(() => _pengingatMasuk = val);
                _savePreference('notif_masuk', val);
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.logout_rounded,
              title: 'Pengingat Absen Keluar',
              subtitle: 'Pemberitahuan harian waktu pulang kerja',
              value: _pengingatKeluar,
              onChanged: (val) {
                setState(() => _pengingatKeluar = val);
                _savePreference('notif_keluar', val);
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.fact_check_outlined,
              title: 'Update Pengajuan',
              subtitle: 'Notifikasi saat pengajuan disetujui/ditolak',
              value: _updatePengajuan,
              onChanged: (val) {
                setState(() => _updatePengajuan = val);
                _savePreference('notif_pengajuan', val);
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.business_center_outlined,
              title: 'Info Lembur',
              subtitle: 'Tingkat waktu lembur baru yang diajukan',
              value: _infoLembur,
              onChanged: (val) {
                setState(() => _infoLembur = val);
                _savePreference('notif_lembur', val);
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.campaign_outlined,
              title: 'Pengumuman Perusahaan',
              subtitle: 'Info umum departemen dan kantor pusat',
              value: _pengumumanPerusahaan,
              onChanged: (val) {
                setState(() => _pengumumanPerusahaan = val);
                _savePreference('notif_pengumuman', val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1), // Light green background for icon
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF009688), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Transform.scale(
            scale: 0.8,
            child: CupertinoSwitch(
              value: value,
              activeColor: const Color(0xFF009688),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
