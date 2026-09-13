import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

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
  static const bool _useCustomSound = false;

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

    // Request permission di Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _isInitialized = true;
  }

  /// Tampilkan notifikasi lokal saat lembur selesai.
  Future<void> showLemburSelesaiNotification() async {
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

  /// Mainkan alarm sound menggunakan AudioPlayer.
  /// Ini memberikan suara alarm yang lebih kuat dan bisa diulang.
  Future<void> playAlarmSound() async {
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
}
