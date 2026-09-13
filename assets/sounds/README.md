# Custom Alarm Sounds

Letakkan file alarm custom Anda di folder ini.

## Format yang didukung:
- `.mp3` (recommended)
- `.wav`
- `.ogg` (Android only)

## Cara penggunaan:
1. Letakkan file alarm di sini, contoh: `alarm_lembur.mp3`
2. Buka `lib/services/notification_service.dart`
3. Ubah `_useCustomSound` menjadi `true`
4. Ubah `_alarmAssetPath` menjadi `sounds/nama_file.mp3`

## Untuk notifikasi Android:
1. Copy file alarm ke `android/app/src/main/res/raw/`
2. Ubah `_alarmSoundAndroid` menjadi nama file (tanpa ekstensi)

## Untuk notifikasi iOS:
1. Tambahkan file alarm ke Xcode project di folder Runner/
2. Ubah `_alarmSoundIOS` menjadi nama file (dengan ekstensi)
