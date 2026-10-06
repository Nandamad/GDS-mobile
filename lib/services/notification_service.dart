import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Service untuk mengelola notifikasi lokal dan alarm lembur.
///
/// ## Cara Custom Alarm Sound:
///
/// ### Android:
/// 1. Letakkan file audio (`.mp3`, `.wav`, `.ogg`) di folder:
///    `android/app/src/main/res/raw/`
///    Contoh: `android/app/src/main/res/raw/alarm_lembur.mp3`
///
/// 2. Ubah nilai `_alarmSoundAndroid` di bawah menjadi nama file (tanpa ekstensi):
///    ```dart
///    static const String _alarmSoundAndroid = 'alarm_lembur';
///    ```
///
/// ### iOS:
/// 1. Tambahkan file audio (`.aiff`, `.caf`, `.wav`) ke Xcode project
///    di folder `Runner/`
///
/// 2. Ubah nilai `_alarmSoundIOS` di bawah menjadi nama file (dengan ekstensi):
///    ```dart
///    static const String _alarmSoundIOS = 'alarm_lembur.aiff';
///    ```
///
/// ### Menggunakan Custom Audio via AudioPlayer (fallback):
/// Letakkan file audio di folder `assets/sounds/alarm_lembur.mp3`
/// lalu pastikan sudah didaftarkan di `pubspec.yaml` under `assets:`.
///
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isInitialized = false;

  // ========================================
  // CUSTOM ALARM SOUND CONFIGURATION
  // ========================================
  // Ganti nama file di bawah ini untuk mengubah suara alarm.
  // Untuk Android: letakkan file di android/app/src/main/res/raw/
  // Untuk iOS: tambahkan file ke Xcode project Runner/
  // Untuk fallback AudioPlayer: letakkan di assets/sounds/

  /// Nama file alarm Android (tanpa ekstensi), di folder res/raw/
  static const String _alarmSoundAndroid = 'alarm_lembur';

  /// Nama file alarm iOS (dengan ekstensi), di folder Runner/
  static const String _alarmSoundIOS = 'alarm_lembur.aiff';

  /// Path asset untuk fallback AudioPlayer
  static const String _alarmAssetPath = 'sounds/alarm_lembur.mp3';

  /// Apakah menggunakan custom sound file (true) atau default system (false)
  /// Set ke false jika belum menyiapkan file custom alarm.
  static const bool _useCustomSound = true;

  // ========================================

  /// Inisialisasi notification service. Panggil sekali di `main.dart`.
  Future<void> initialize() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
    
    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {}

    // Request permission di Android 13+ tanpa await agar tidak nge-block UI
    _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Tampilkan notifikasi lokal saat lembur selesai.
  Future<void> showLemburSelesaiNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final infoLemburEnabled = prefs.getBool('notif_lembur') ?? false;
    
    // Jika user menonaktifkan fitur info lembur di profil, jangan tampilkan notifikasi
    if (!infoLemburEnabled) return;

    if (!_isInitialized) await initialize();

    late AndroidNotificationDetails androidDetails;
    late DarwinNotificationDetails iosDetails;

    if (_useCustomSound) {
      androidDetails = AndroidNotificationDetails(
        'lembur_alarm_channel',
        'Alarm Lembur',
        channelDescription: 'Notifikasi saat waktu lembur telah selesai',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_alarmSoundAndroid),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );
      iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: _alarmSoundIOS,
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        'lembur_alarm_channel',
        'Alarm Lembur',
        channelDescription: 'Notifikasi saat waktu lembur telah selesai',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
      );
      iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1001, // ID unik untuk notifikasi lembur
      '⏰ Waktu Lembur Telah Selesai!',
      'Waktu lembur Anda telah habis. Silakan selesaikan dan laporkan lembur Anda.',
      details,
    );
  }

  /// Tampilkan notifikasi saat pengajuan berhasil dikirim (Izin/Cuti/Lembur/Koreksi).
  Future<void> showPengajuanDikirimNotification(String tipePengajuan) async {
    final prefs = await SharedPreferences.getInstance();
    final updatePengajuanEnabled = prefs.getBool('notif_pengajuan') ?? false;
    
    if (!updatePengajuanEnabled) return;

    if (!_isInitialized) await initialize();

    await _notifications.show(
      2001, 
      '✅ Pengajuan Terkirim',
      'Pengajuan $tipePengajuan Anda telah berhasil dikirim dan sedang menunggu persetujuan.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pengajuan_channel',
          'Status Pengajuan',
          channelDescription: 'Notifikasi update status pengajuan',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true),
      ),
    );
  }

  /// Jadwalkan alarm lembur di jam tertentu
  Future<void> scheduleLemburSelesaiNotification(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    final infoLemburEnabled = prefs.getBool('notif_lembur') ?? false;
    if (!infoLemburEnabled) return;

    if (!_isInitialized) await initialize();

    // Batalkan jadwal lembur sebelumnya jika ada
    await _notifications.cancel(1001);

    // Jika waktu selesai sudah lewat, jangan jadwalkan
    if (endTime.isBefore(DateTime.now())) return;

    await _notifications.zonedSchedule(
      1001,
      '⏰ Waktu Lembur Selesai!',
      'Waktu lembur Anda telah habis. Segera selesaikan pekerjaan Anda.',
      tz.TZDateTime.from(endTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'lembur_alarm_channel',
          'Alarm Lembur',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Mainkan alarm sound menggunakan AudioPlayer.
  /// Ini memberikan suara alarm yang lebih kuat dan bisa diulang.
  Future<void> playAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    final infoLemburEnabled = prefs.getBool('notif_lembur') ?? false;
    
    // Jika user menonaktifkan fitur info lembur di profil, jangan mainkan alarm
    if (!infoLemburEnabled) return;

    try {
      // Set volume ke maksimum
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop); // Loop alarm

      if (_useCustomSound) {
        // Gunakan custom sound dari assets
        await _audioPlayer.play(AssetSource(_alarmAssetPath));
      } else {
        // Fallback: gunakan system sound berulang + haptic
        await _playSystemAlarm();
      }
    } catch (e) {
      // Fallback ke system sound jika AudioPlayer gagal
      await _playSystemAlarm();
    }
  }

  /// Berhentikan alarm sound.
  Future<void> stopAlarmSound() async {
    try {
      await _audioPlayer.stop();
    } catch (_) {}
  }

  /// Mainkan system alarm sebagai fallback.
  Future<void> _playSystemAlarm() async {
    for (int i = 0; i < 5; i++) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  /// Dispose resources.
  void dispose() {
    _audioPlayer.dispose();
  }

  /// Tampilkan notifikasi info general (misal: pengajuan berhasil, dll)
  Future<void> showInfoNotification({
    required String title,
    required String body,
    String? payload,
    String preferenceKey = 'notif_pengajuan',
    bool defaultPreference = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(preferenceKey) ?? defaultPreference;
    
    // Jika preference diset false oleh user, batalkan
    if (!isEnabled) return;

    if (!_isInitialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'info_channel',
      'Informasi Umum',
      channelDescription: 'Notifikasi untuk info pengajuan, absensi, dll',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Gunakan random ID untuk notifikasi info agar tidak tertimpa
    final id = Random().nextInt(100000);

    await _notifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Jadwalkan notifikasi pengingat harian sesuai jam masuk dan keluar admin.
  Future<void> scheduleDailyReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final notifMasuk = prefs.getBool('notif_masuk') ?? true;
    final notifKeluar = prefs.getBool('notif_keluar') ?? true;

    // Default time
    int masukHour = 7;
    int masukMinute = 30;
    int keluarHour = 17;
    int keluarMinute = 0;

    final jamMasukStr = prefs.getString('jam_masuk_notif');
    final jamKeluarStr = prefs.getString('jam_keluar_notif');

    if (jamMasukStr != null && jamMasukStr.contains(':')) {
      final parts = jamMasukStr.split(':');
      if (parts.length >= 2) {
        masukHour = int.tryParse(parts[0]) ?? 7;
        masukMinute = int.tryParse(parts[1]) ?? 30;
        // Ingatkan 30 menit sebelum jam masuk?
        // Tapi kita jadwalkan pas jam masuk aja atau 15 menit sebelumnya
        // Biar sesuai dengan default sebelumnya (07:30 jika jam_masuk 08:00? Oh tunggu.)
      }
    }

    if (jamKeluarStr != null && jamKeluarStr.contains(':')) {
      final parts = jamKeluarStr.split(':');
      if (parts.length >= 2) {
        keluarHour = int.tryParse(parts[0]) ?? 17;
        keluarMinute = int.tryParse(parts[1]) ?? 0;
      }
    }

    // Selalu batalkan jadwal lama agar bersih
    await _notifications.cancel(101);
    await _notifications.cancel(102);

    if (notifMasuk) {
      // Menit peringatan (misal 15 menit sebelum masuk). Tapi untuk amannya kita pasang sesuai string.
      // Kecuali user minta khusus. Kita jadwalkan tepat di jam yang didapat dari admin dikurangi 15 menit.
      var mHour = masukHour;
      var mMin = masukMinute - 15;
      if (mMin < 0) {
        mMin += 60;
        mHour -= 1;
      }

      await _scheduleDailyNotification(
        id: 101,
        title: 'Pengingat Absen Masuk',
        body: 'Jangan lupa untuk melakukan absen masuk sekarang!',
        hour: mHour,
        minute: mMin,
      );
    }

    if (notifKeluar) {
      await _scheduleDailyNotification(
        id: 102,
        title: 'Pengingat Absen Keluar',
        body: 'Waktunya pulang! Jangan lupa untuk melakukan absen keluar.',
        hour: keluarHour,
        minute: keluarMinute,
      );
    }
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Pengingat Harian',
          channelDescription: 'Notifikasi pengingat absen masuk dan keluar harian',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
