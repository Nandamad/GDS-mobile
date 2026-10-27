import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class PengaturanNotifikasiScreen extends StatefulWidget {
  const PengaturanNotifikasiScreen({super.key});

  @override
  State<PengaturanNotifikasiScreen> createState() =>
      _PengaturanNotifikasiScreenState();
}

class _PengaturanNotifikasiScreenState
    extends State<PengaturanNotifikasiScreen> {
  bool _pengingatMasuk = true;
  bool _pengingatKeluar = true;
  bool _updatePengajuan = true;
  bool _infoLembur = false;
  bool _pengumumanPerusahaan = true;
  bool _canScheduleExactAlarms = true;
  bool _isRequestingAlarmPermission = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    var canScheduleExactAlarms = false;
    try {
      canScheduleExactAlarms = await NotificationService()
          .canScheduleExactReminders();
    } catch (e) {
      debugPrint('Checking exact alarm permission failed: $e');
    }

    if (!mounted) return;
    setState(() {
      _pengingatMasuk = prefs.getBool('notif_masuk') ?? true;
      _pengingatKeluar = prefs.getBool('notif_keluar') ?? true;
      _updatePengajuan = prefs.getBool('notif_pengajuan') ?? true;
      _infoLembur = prefs.getBool('notif_lembur') ?? false;
      _pengumumanPerusahaan = prefs.getBool('notif_pengumuman') ?? true;
      _canScheduleExactAlarms = canScheduleExactAlarms;
    });
  }

  Future<void> _requestExactAlarmPermission() async {
    setState(() => _isRequestingAlarmPermission = true);
    try {
      final granted = await NotificationService().requestReminderPermissions();
      if (!mounted) return;

      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Aktifkan izin notifikasi dan "Alarm & reminders" untuk PresensiPlus di Pengaturan Android.',
            ),
          ),
        );
        return;
      }

      setState(() => _canScheduleExactAlarms = true);
      await NotificationService().scheduleDailyReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin diberikan. Pengingat absen sudah dijadwalkan.'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Requesting exact alarm permission failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Izin alarm belum aktif. Periksa Pengaturan Android lalu coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRequestingAlarmPermission = false);
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    final isReminder = key == 'notif_masuk' || key == 'notif_keluar';
    final isOvertime = key == 'notif_lembur';
    final requiresExactAlarm = isReminder || isOvertime;
    final requestsNotificationPermission =
        requiresExactAlarm ||
        key == 'notif_pengajuan' ||
        key == 'notif_pengumuman';
    try {
      final notificationService = NotificationService();
      if (requestsNotificationPermission && value) {
        final permissionGranted = requiresExactAlarm
            ? await notificationService.requestReminderPermissions()
            : await notificationService.requestNotificationPermissions();
        if (!permissionGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Izin notifikasi atau "Alarm & reminders" belum diberikan. Aktifkan di Pengaturan perangkat lalu coba lagi.',
                ),
              ),
            );
          }
          return;
        }
        if (mounted && requiresExactAlarm) {
          setState(() => _canScheduleExactAlarms = true);
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
      await _loadPreferences();

      if (isReminder) {
        await notificationService.scheduleDailyReminders();
        if (mounted && value) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pengingat dijadwalkan. Jika waktunya hari ini sudah lewat, pengingat berikutnya akan muncul pada jadwal berikutnya.',
              ),
            ),
          );
        }
      }
      if (isOvertime && !value) {
        await notificationService.cancelLemburSelesaiNotification();
      }
    } catch (e) {
      debugPrint('Saving notification preference failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan notifikasi gagal diterapkan. Coba lagi.'),
          ),
        );
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
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
              'Kelola bagaimana dan kapan Anda menerima pemberitahuan dari PresensiPlus.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            if (!_canScheduleExactAlarms) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Izin alarm tepat belum aktif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9A3412),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Tanpa izin "Alarm & reminders", Android dapat menunda pengingat beberapa menit.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9A3412),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isRequestingAlarmPermission
                          ? null
                          : _requestExactAlarmPermission,
                      child: Text(
                        _isRequestingAlarmPermission
                            ? 'Membuka Pengaturan...'
                            : 'Aktifkan izin alarm tepat',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // List of Notification Toggles
            _buildNotificationTile(
              icon: Icons.access_time_rounded,
              title: 'Pengingat Absen Masuk',
              subtitle: 'Notifikasi sebelum jam masuk',
              value: _pengingatMasuk,
              onChanged: (val) {
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
                _savePreference('notif_keluar', val);
              },
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.fact_check_outlined,
              title: 'Update Pengajuan',
              subtitle:
                  'Disinkronkan saat aplikasi aktif; push saat ditutup perlu backend',
              value: _updatePengajuan,
              onChanged: (val) => _savePreference('notif_pengajuan', val),
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.business_center_outlined,
              title: 'Info Lembur',
              subtitle: 'Alarm saat waktu lembur selesai',
              value: _infoLembur,
              onChanged: (val) => _savePreference('notif_lembur', val),
            ),
            const SizedBox(height: 12),
            _buildNotificationTile(
              icon: Icons.campaign_outlined,
              title: 'Pengumuman Perusahaan',
              subtitle:
                  'Disinkronkan saat aplikasi aktif; push saat ditutup perlu backend',
              value: _pengumumanPerusahaan,
              onChanged: (val) => _savePreference('notif_pengumuman', val),
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
