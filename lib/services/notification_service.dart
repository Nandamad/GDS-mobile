import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'api_service.dart';

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
  bool _isSyncingServerNotifications = false;

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

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

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
    } catch (e) {
      debugPrint('Notification timezone setup failed: $e');
    }

    final notificationPermission = await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    if (notificationPermission == false) {
      debugPrint('Notification permission was denied.');
    }

    _isInitialized = true;
  }

  /// Requests the permissions needed when the user enables attendance reminders.
  Future<bool> requestReminderPermissions() async {
    if (!_isInitialized) await initialize();

    final notificationGranted = await requestNotificationPermissions();
    if (!notificationGranted) return false;

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true;

    final canScheduleExactly = await androidPlugin
        .canScheduleExactNotifications();
    if (canScheduleExactly != true) {
      await androidPlugin.requestExactAlarmsPermission();
    }

    return await androidPlugin.canScheduleExactNotifications() == true;
  }

  Future<bool> requestNotificationPermissions() async {
    if (!_isInitialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin != null) {
      return await androidPlugin.requestNotificationsPermission() != false;
    }

    final iosPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (iosPlugin != null) {
      return await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) !=
          false;
    }

    return true;
  }

  Future<bool> canScheduleExactReminders() async {
    if (!_isInitialized) await initialize();

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return true;

    return await androidPlugin.canScheduleExactNotifications() == true;
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        ),
      ),
    );
  }

  /// Jadwalkan alarm lembur di jam tertentu
  Future<void> scheduleLemburSelesaiNotification(DateTime endTime) async {
    final prefs = await SharedPreferences.getInstance();
    final infoLemburEnabled = prefs.getBool('notif_lembur') ?? false;
    if (!_isInitialized) await initialize();

    await cancelLemburSelesaiNotification();
    if (!infoLemburEnabled) return;

    // Jika waktu selesai sudah lewat, jangan jadwalkan
    if (!endTime.isAfter(DateTime.now())) return;

    final scheduleMode = await _androidScheduleMode();
    final androidDetails = AndroidNotificationDetails(
      'lembur_alarm_channel',
      'Alarm Lembur',
      channelDescription: 'Notifikasi saat waktu lembur telah selesai',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: _useCustomSound
          ? const RawResourceAndroidNotificationSound(_alarmSoundAndroid)
          : null,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500, 200, 500]),
      category: AndroidNotificationCategory.alarm,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: _useCustomSound ? _alarmSoundIOS : null,
    );

    await _notifications.zonedSchedule(
      1001,
      '⏰ Waktu Lembur Selesai!',
      'Waktu lembur Anda telah habis. Segera selesaikan pekerjaan Anda.',
      tz.TZDateTime.from(endTime, tz.local),
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: scheduleMode,
    );
  }

  Future<void> cancelLemburSelesaiNotification() async {
    if (!_isInitialized) await initialize();
    await _notifications.cancel(1001);
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

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Tampilkan notifikasi server baru saat aplikasi aktif melakukan sinkronisasi.
  Future<void> syncServerNotifications() async {
    if (_isSyncingServerNotifications) return;
    _isSyncingServerNotifications = true;

    try {
      final response = await ApiService().dio.get('/notifikasi');
      if (response.statusCode != 200) return;

      final items = _readServerNotificationList(response.data);
      final prefs = await SharedPreferences.getInstance();
      const seenKey = 'seen_server_notification_ids';
      const initializedKey = 'server_notification_sync_initialized';
      final seenIds = prefs.getStringList(seenKey) ?? <String>[];
      final currentIds = items
          .whereType<Map>()
          .map((item) => item['id']?.toString())
          .whereType<String>()
          .toList();

      if (!(prefs.getBool(initializedKey) ?? false)) {
        await prefs.setStringList(seenKey, currentIds.take(200).toList());
        await prefs.setBool(initializedKey, true);
        return;
      }

      final seen = seenIds.toSet();
      final newlySeen = <String>[];
      for (final rawItem in items.whereType<Map>()) {
        final id = rawItem['id']?.toString();
        if (id == null || seen.contains(id)) continue;
        newlySeen.add(id);

        final data = _readServerNotificationData(rawItem);
        final title = (data['title'] ?? rawItem['title'] ?? rawItem['type'])
            ?.toString()
            .trim();
        final body =
            (data['body'] ??
                    data['message'] ??
                    rawItem['message'] ??
                    rawItem['body'])
                ?.toString()
                .trim();
        if (rawItem['read_at'] != null ||
            title == null ||
            title.isEmpty ||
            body == null ||
            body.isEmpty) {
          continue;
        }

        final categoryText =
            '${rawItem['type'] ?? ''} ${data['type'] ?? ''} ${data['kategori'] ?? ''} $title'
                .toLowerCase();
        final isAnnouncement =
            categoryText.contains('pengumuman') ||
            categoryText.contains('announcement') ||
            categoryText.contains('berita');
        final isApprovalUpdate =
            categoryText.contains('pengajuan') ||
            categoryText.contains('approval') ||
            categoryText.contains('persetujuan') ||
            categoryText.contains('disetujui') ||
            categoryText.contains('ditolak') ||
            categoryText.contains('approved') ||
            categoryText.contains('rejected');
        final preferenceKey = isAnnouncement
            ? 'notif_pengumuman'
            : isApprovalUpdate
            ? 'notif_pengajuan'
            : categoryText.contains('lembur')
            ? 'notif_lembur'
            : 'notif_pengajuan';

        await showInfoNotification(
          title: title,
          body: body,
          payload: id,
          preferenceKey: preferenceKey,
        );
      }

      if (newlySeen.isNotEmpty) {
        final updatedIds = <String>[
          ...newlySeen,
          ...seenIds.where((id) => !newlySeen.contains(id)),
        ];
        await prefs.setStringList(seenKey, updatedIds.take(200).toList());
      }
    } catch (e, stackTrace) {
      debugPrint('Syncing server notifications failed: $e\n$stackTrace');
    } finally {
      _isSyncingServerNotifications = false;
    }
  }

  List<dynamic> _readServerNotificationList(dynamic payload) {
    dynamic value = payload;
    for (var index = 0; index < 3 && value is Map; index++) {
      value = value['data'] ?? value['items'] ?? value['result'] ?? value;
      if (value is Map &&
          !value.containsKey('data') &&
          !value.containsKey('items') &&
          !value.containsKey('result')) {
        break;
      }
    }
    return value is List ? value : const [];
  }

  Map<String, dynamic> _readServerNotificationData(Map item) {
    final rawData = item['data'];
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    if (rawData is String) {
      try {
        final decoded = jsonDecode(rawData);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException catch (e) {
        debugPrint('Invalid server notification data JSON: $e');
      }
    }
    return const {};
  }

  /// Jadwalkan notifikasi pengingat harian sesuai jam masuk dan keluar admin.
  Future<void> scheduleDailyReminders() async {
    if (!_isInitialized) await initialize();

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

    final parsedJamMasuk = _parseTime(jamMasukStr);
    if (parsedJamMasuk != null) {
      masukHour = parsedJamMasuk.hour;
      masukMinute = parsedJamMasuk.minute;
    }

    final parsedJamKeluar = _parseTime(jamKeluarStr);
    if (parsedJamKeluar != null) {
      keluarHour = parsedJamKeluar.hour;
      keluarMinute = parsedJamKeluar.minute;
    }

    await _notifications.cancel(101);
    await _notifications.cancel(102);

    if (notifMasuk) {
      final reminderTime = DateTime(
        2000,
        1,
        1,
        masukHour,
        masukMinute,
      ).subtract(const Duration(minutes: 15));

      await _scheduleDailyNotification(
        id: 101,
        title: 'Pengingat Absen Masuk',
        body: 'Jangan lupa untuk melakukan absen masuk sekarang!',
        hour: reminderTime.hour,
        minute: reminderTime.minute,
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

    final pending = await _notifications.pendingNotificationRequests();
    debugPrint(
      'Attendance reminder IDs scheduled: ${pending.where((item) => item.id == 101 || item.id == 102).map((item) => item.id).toList()}; check-in is 15 minutes before $masukHour:${masukMinute.toString().padLeft(2, '0')}, check-out is $keluarHour:${keluarMinute.toString().padLeft(2, '0')}.',
    );
  }

  DateTime? _parseTime(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.trim());
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      debugPrint('Ignoring invalid attendance reminder time: $value');
      return null;
    }

    return DateTime(2000, 1, 1, hour, minute);
  }

  Future<void> _scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_isInitialized) await initialize();

    final scheduleMode = await _androidScheduleMode();
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_channel',
          'Pengingat Harian',
          channelDescription:
              'Notifikasi pengingat absen masuk dan keluar harian',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: scheduleMode,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return AndroidScheduleMode.exactAllowWhileIdle;

    final canScheduleExactly = await androidPlugin
        .canScheduleExactNotifications();
    if (canScheduleExactly == true) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    throw StateError(
      'Enable "Alarms & reminders" for PresensiPlus in Android settings to receive attendance reminders on time.',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
