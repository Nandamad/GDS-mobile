# Audit Kesiapan Rilis PresensiPlus+

**Tanggal pemeriksaan:** 20 Oktober 2026

**Versi proyek:** 1.1.14+1

**Cakupan:** pemeriksaan kode dan konfigurasi repository pada Windows untuk kesiapan rilis APK Android; catatan iOS dan dokumentasi turut disertakan.

> **Status: BELUM SIAP DIRILIS.** Temuan P0 di bawah perlu diselesaikan atau dikonfirmasi sebelum APK dibagikan ke pengguna/Play Store. Ini adalah audit statis repository, bukan audit backend, penetration test, pemeriksaan akun Play Console, atau tinjauan hukum.

## 1. Ringkasan

| Prioritas | Jumlah | Arti |
|---|---:|---|
| P0 — Penghambat rilis | 6 | Selesaikan sebelum distribusi publik. |
| P1 — Penting | 9 | Selesaikan atau dokumentasikan keputusan/mitigasinya sebelum rilis produksi. |
| P2 — Penyempurnaan | 3 | Jadwalkan sebelum atau segera setelah rilis sesuai risiko. |

## 2. Penghambat rilis — P0

### P0-1. Header autentikasi tampaknya mengirim nilai literal, bukan token

- **Bukti:** `lib/services/api_service.dart`, bagian interceptor `onRequest`.
- Kode mengambil token dari secure storage, tetapi memasang `Authorization: ******`. Jika ini kode yang benar-benar dibangun, request yang memerlukan autentikasi tidak mengirim token pengguna dan kemungkinan ditolak backend.
- **Tindakan:** pastikan header memakai token tersimpan pada request yang memerlukannya. Jangan mencatat atau menampilkan token dalam log. Tambahkan tes untuk memastikan request terautentikasi membawa header yang benar dan endpoint login tidak menerima header yang salah.
- **Verifikasi rilis:** uji login dan alur API utama pada build release terhadap backend yang memang akan dipakai produksi.

### P0-2. Pemeriksaan sertifikat TLS menerima sertifikat yang tidak valid

- **Bukti:** `lib/services/api_service.dart`, callback `badCertificateCallback` berisi `return true` untuk host produksi; nilai fingerprint masih placeholder dan tidak digunakan.
- Ini mematikan validasi sertifikat saat sertifikat dianggap tidak valid. Catatan `SSL Pinning` di kode tidak berarti pinning telah diterapkan.
- **Tindakan:** hapus bypass sertifikat dari konfigurasi produksi. Gunakan validasi sertifikat standar; bila pinning memang dibutuhkan, implementasikan dan siapkan prosedur rotasi pin secara teruji. Bypass localhost, jika tetap diperlukan untuk development, harus dipisahkan dan tidak aktif pada release.
- **Verifikasi rilis:** uji bahwa koneksi dengan sertifikat tidak valid ditolak.

### P0-3. APK release ditandatangani dengan debug signing

- **Bukti:** `android/app/build.gradle.kts`, `buildTypes.release.signingConfig` menunjuk ke `signingConfigs.debug`.
- APK tersebut bukan paket rilis yang ditandatangani dengan kunci upload/release organisasi.
- **Tindakan:** siapkan keystore rilis yang dijaga aman, konfigurasi signing release melalui secret/environment lokal/CI, dan jangan memasukkan keystore atau password ke Git. Verifikasi sertifikat APK sebelum distribusi.

### P0-4. Application ID Android masih `com.example.mobile`

- **Bukti:** `android/app/build.gradle.kts`, `namespace` dan `applicationId`.
- Ini adalah identitas contoh Flutter, bukan identitas produksi yang telah dikonfirmasi. Application ID harus dipilih sebelum publikasi dan umumnya tidak dapat diganti setelah aplikasi terbit tanpa membuat aplikasi berbeda.
- **Tindakan:** tentukan ID reverse-domain unik yang dimiliki perusahaan, lalu selaraskan konfigurasi Android dan store listing. Pastikan tidak berbenturan dengan aplikasi yang sudah ada.

### P0-5. Base URL aplikasi masih menunjuk host `devabs`

- **Bukti:** `lib/api_config.dart` dan `assets/.env` mendefinisikan URL API dengan host `devabs.yukliat.com`.
- URL tersebut terlihat seperti environment development; belum ada bukti dari repository bahwa ini adalah endpoint produksi yang disetujui. Ada dua sumber konfigurasi yang sama-sama mendefinisikan URL, sementara `ApiConfig` mengembalikan nilai statis.
- **Tindakan:** konfirmasi endpoint produksi dengan pemilik backend; pilih satu mekanisme environment yang konsisten. Pastikan build release tidak diam-diam memakai endpoint development atau staging.
- **Catatan:** file `.env` terdaftar sebagai aset aplikasi. Aset yang dibundel dapat diekstrak; jangan simpan password, private key, atau secret di dalamnya. URL API biasanya bukan secret.

### P0-6. Dokumen legal yang ditampilkan aplikasi masih memiliki placeholder

- **Bukti:** `kebijakan-privasi-presensiplus.md` menandai bagian wajib dilengkapi, antara lain retensi, pemrosesan biometrik, penyedia/server, keamanan, dan kontak Perusahaan. `syarat-ketentuan-presensiplus.md` masih memiliki catatan placeholder untuk peninjauan sengketa.
- Dokumen ini didaftarkan sebagai aset dan dapat terlihat langsung di aplikasi.
- **Tindakan:** isi atau hapus semua placeholder, verifikasi pernyataan sesuai perilaku nyata aplikasi dan perjanjian Perusahaan, lalu minta peninjauan ahli hukum sebelum dipublikasikan.

## 3. Penting sebelum rilis — P1

### P1-1. HTTP cleartext diizinkan Android

- **Bukti:** `android/app/src/main/AndroidManifest.xml` menetapkan `android:usesCleartextTraffic="true"`.
- Ini mengizinkan koneksi HTTP tanpa TLS dari aplikasi. Walaupun URL API saat ini HTTPS, izin global ini memperbesar risiko jika ada endpoint HTTP yang dipanggil.
- **Tindakan:** hapus izin cleartext untuk produksi atau batasi hanya pada konfigurasi development yang terpisah. Audit seluruh endpoint dan gambar agar memakai HTTPS.

### P1-2. Website di halaman Tentang masih URL placeholder/tidak valid

- **Bukti:** `lib/ui/tentang_aplikasi_page.dart` menampilkan `https:example.com`.
- **Tindakan:** ganti dengan URL HTTPS resmi yang sudah dikonfirmasi, atau hilangkan baris website. Periksa juga nilai perusahaan default `PT Generasi Digital Solusi`; nama ini berbeda dari nama Penyedia yang diberikan, yaitu PT. Generasi Digital Sinergi.

### P1-3. Versi aplikasi ditulis manual di beberapa layar

- **Bukti:** `pubspec.yaml` menetapkan 1.1.14+1; versi tampilan juga ditulis manual di `lib/ui/login_page.dart`, `lib/ui/splash_screen.dart`, dan `lib/ui/tentang_aplikasi_page.dart`.
- Nilai manual mudah tertinggal setelah nomor versi dinaikkan.
- **Tindakan:** gunakan satu sumber versi dari metadata paket/build dan uji bahwa versi di layar sama dengan APK.

### P1-4. Android version code saat ini `1`

- **Bukti:** `pubspec.yaml` menggunakan `1.1.14+1`; metadata artefak lokal juga mencatat versionCode 1.
- **Tindakan:** cek Play Console dan riwayat distribusi. Jika versionCode 1 sudah pernah diunggah, build baru harus memakai code yang lebih tinggi; setiap unggahan baru perlu code unik yang meningkat.

### P1-5. Izin exact alarm dan full-screen intent perlu ditinjau terhadap kebijakan Google Play

- **Bukti:** `AndroidManifest.xml` meminta `SCHEDULE_EXACT_ALARM` dan `USE_FULL_SCREEN_INTENT`. `lib/services/notification_service.dart` menjadwalkan exact alarm dan mengaktifkan `fullScreenIntent`.
- **Tindakan:** pastikan fitur alarm lembur memang memenuhi persyaratan dan deklarasi Google Play untuk izin tersebut. Uji alur permintaan izin, penolakan, Android 13+, Android 14+, reboot, zona waktu, dan mode hemat baterai. Hapus izin/behavior jika tidak benar-benar diperlukan.

### P1-6. Konfigurasi iOS belum lengkap/terverifikasi

- **Bukti:** pada checkout ini `ios/Podfile` tidak ditemukan; `ios/Runner/Info.plist` belum mencantumkan deskripsi penggunaan kamera/lokasi; bundle ID masih `com.example.mobile`. Kode notifikasi menetapkan bunyi `alarm_lembur.aiff`, tetapi file dengan nama tersebut tidak ditemukan di `ios/`.
- **Tindakan:** jika iOS termasuk target rilis, lengkapi proyek CocoaPods, usage description yang sesuai dengan fitur, bundle ID, serta file/konfigurasi notifikasi iOS. Build dan uji di Mac dengan Xcode; pemeriksaan ini tidak dapat menggantikan build/signing iOS.

### P1-7. Upgrade dependency tertinggal dan perlu diuji, bukan dinaikkan massal

Pemeriksaan `flutter pub outdated` pada lingkungan audit melaporkan **28 dependency terkunci pada versi lebih lama**, **30 dependency dibatasi oleh constraint lebih lama daripada versi yang dapat diselesaikan**, serta dua package yang dihentikan. Contoh dependency langsung:

| Package | Terkunci saat audit | Versi terbaru yang dilaporkan | Catatan |
|---|---:|---:|---|
| `audioplayers` | 6.7.1 | 6.8.1 | Update minor |
| `camera` | 0.12.0+2 | 0.12.1 | Patch/minor |
| `file_picker` | 11.0.3 | 13.1.0 | Major; uji perubahan API |
| `flutter_bloc` | 8.1.6 | 9.1.1 | Major |
| `flutter_dotenv` | 5.2.1 | 6.0.1 | Major |
| `flutter_local_notifications` | 19.5.0 | 22.3.2 | Major; cek perubahan izin dan scheduler |
| `flutter_map` | 7.0.2 | 8.3.2 | Major |
| `flutter_secure_storage` | 9.2.4 | 11.2.0 | Major; uji migrasi/platform |
| `geocoding` | 2.2.2 | 5.0.0 | Major |
| `geolocator` | 13.0.4 | 14.1.2 | Major |
| `intl` | 0.19.0 | 0.20.3 | Periksa kompatibilitas |
| `package_info_plus` | 9.0.1 | 10.2.2 | Major |
| `flutter_launcher_icons` | 0.13.1 | 0.14.4 | Dev dependency |

`flutter_secure_storage_macos` dan `js` dilaporkan discontinued. Tidak semua package yang lebih baru otomatis aman/kompatibel untuk proyek ini. Buat cabang upgrade bertahap, baca changelog, jalankan analyze/test, lalu uji di perangkat Android yang didukung. Catatan versi bersifat snapshot tanggal audit dan harus diperiksa ulang sebelum rilis.

### P1-8. Analisis statis menemukan peringatan dan lint

- `flutter analyze` selesai dengan **94 temuan: 20 warning dan 74 info**, tanpa error analyzer yang dilaporkan.
- Warning mencakup nilai fingerprint yang tidak digunakan, variabel/import tidak terpakai, serta bagian kode yang tidak direferensikan di beberapa halaman. Info mencakup API deprecated seperti `withOpacity` dan lint gaya.
- **Tindakan:** tinjau warning sebelum rilis, terutama yang menyentuh jalur bisnis, lalu tetapkan baseline lint. Temuan lint bukan bukti otomatis adanya bug, tetapi jumlahnya menyulitkan melihat regresi baru.

### P1-9. Cakupan tes otomatis belum meliputi alur bisnis utama

- **Bukti:** suite saat ini berisi tes onboarding, bantuan/dokumen legal, dan resolusi URL gambar.
- Belum terlihat tes untuk login/token, presensi GPS/kamera, pengajuan dan persetujuan cuti/lembur, notifikasi, izin ditolak, atau mode offline.
- **Tindakan:** tambahkan tes untuk alur kritis dan jalankan smoke test manual pada perangkat nyata dengan backend staging sebelum distribusi. Kelulusan tes yang ada tidak membuktikan alur yang belum diuji aman.

## 4. Data statis, nilai fallback, dan konfigurasi yang perlu dikonfirmasi

### Placeholder yang jelas

- `lib/ui/tentang_aplikasi_page.dart`: URL `https:example.com`.
- `lib/services/api_service.dart`: string fingerprint `HASH_DARI_SERTIFIKAT_SERVER_PRODUCTION_ANDA` belum dipakai.
- Dokumen legal: placeholder wajib lengkapi (lihat P0-6).
- `com.example.mobile`: package ID contoh pada Android dan iOS.

### Nilai tetap/fallback yang belum tentu salah

- `lib/api_config.dart` dan `assets/.env`: base URL tetap pada host `devabs`; tentukan pemisahan development/staging/production.
- `lib/ui/tentang_aplikasi_page.dart`: nama Penyedia default berbeda dari PT. Generasi Digital Sinergi; parameter `namaPerusahaan` perlu dipastikan benar-benar dipakai.
- `lib/ui/data_pribadi_page.dart` dan `lib/ui/profil_page.dart`: fallback jabatan `Staff`, divisi `Umum`, dan kantor `Kantor Pusat`. Pastikan hanya muncul saat data API kosong, bukan menutupi kegagalan pemuatan.
- `lib/services/lembur_helper.dart`: durasi lembur default 60 menit saat semua field durasi tidak tersedia/tidak valid. Pastikan perilaku ini sesuai kebijakan; nilai fallback dapat memicu durasi/notifikasi yang menyesatkan.
- `lib/ui/login_page.dart`, `lib/ui/splash_screen.dart`, dan `lib/ui/tentang_aplikasi_page.dart`: versi ditulis manual, berisiko tidak konsisten.
- `lib/ui/dashboard_page.dart` dan `lib/ui/presensi_harian_page.dart`: aplikasi mengirim flag `is_mocked`. Validasi dan keputusan akhir harus tetap dilakukan backend; audit backend belum termasuk cakupan ini.

### Pemeriksaan secret

- `assets/.env` tercatat di Git dan didaftarkan sebagai asset Flutter. Nama key yang terlihat adalah `API_BASE_URL`; nilai konfigurasi tidak disalin ke laporan sebagai secret.
- Tidak dilakukan pemindaian secret penuh terhadap seluruh riwayat Git atau audit backend. Sebelum rilis, jalankan secret scanner pada repository dan pastikan tidak ada password, token, private key, atau credential vendor di aset, kode, log, maupun riwayat commit. Jika pernah terunggah, rotasi credential tersebut.

## 5. Penyempurnaan — P2

1. **Optimasi ukuran paket:** APK lokal sekitar 70 MB dan AAB sekitar 58 MB. Periksa aset/media dan native library terbesar; gunakan build per-ABI bila sesuai jalur distribusi, lalu ukur dampaknya pada ukuran unduhan pengguna.
2. **README proyek:** `README.md` masih berisi teks starter “A new Flutter project.” Ganti dengan langkah setup, konfigurasi environment tanpa secret, build, signing, dan prosedur rilis yang benar.
3. **Audit tampilan fallback dan aksesibilitas:** verifikasi label statis seperti `Staff`, `Umum`, `Kantor Pusat`, serta fallback durasi 60 menit agar tidak disangka data resmi. Uji pembaca layar, ukuran teks besar, kontras, dan area sentuh pada halaman inti.

## 6. Pengujian dan artefak yang tersedia

- `flutter test`: **9 tes lulus** pada tanggal audit.
- Tes yang ada hanya mencakup onboarding, beberapa navigasi bantuan/dokumen legal, dan resolusi URL gambar. Belum ada tes otomatis yang terlihat untuk login/API, presensi GPS/kamera, penolakan izin, approval, cuti/lembur, notifikasi, migrasi storage, atau penanganan offline.
- `flutter analyze`: 94 temuan (lihat P1-8).
- Di folder `build/` terdapat APK release `PresensiPlus_v1.1.14.apk` sekitar 70 MB dan AAB sekitar 58 MB. Metadata build lokal mencatat application ID `com.example.mobile` dan versionCode `1`. Artefak ini berada di folder build dan **jangan dianggap siap distribusi**: konfigurasi signing release saat ini masih memakai debug key, serta timestamp artefak mendahului perubahan halaman dokumen legal yang masuk ke workspace.
- Ukuran paket relatif besar; ukur APK/AAB final yang ditandatangani dan periksa komponen/asset terbesar sebelum publikasi.

## 7. Catatan konfigurasi Android

- `compileSdk` dan `targetSdk` saat ini 36; verifikasi kembali persyaratan target API Google Play pada tanggal submit.
- Java/Kotlin memakai target 17; Gradle wrapper 8.14 dan Android Gradle Plugin 8.11.1 tercatat di konfigurasi proyek.
- Manifest meminta lokasi, kamera, notifikasi, getaran, exact alarm, dan full-screen intent. Pastikan permission runtime hanya diminta saat relevan, alasan ditampilkan dengan jelas, dan kebijakan toko mengizinkan penggunaan yang dimaksud.
- Lakukan uji manual setidaknya di versi Android minimum yang didukung dan versi terbaru, pada jaringan lambat/offline, GPS mati, izin ditolak, notifikasi dimatikan, serta perangkat dengan layar/ukuran berbeda.

## 8. Extension, plugin, dan tooling

- Dependency Flutter/Dart adalah plugin/library aplikasi; pembaruan dan temuan utamanya ada di bagian P1-7.
- Folder `.vscode` di repository hanya menampilkan `settings.json`; tidak ditemukan manifest rekomendasi extension project seperti `.vscode/extensions.json`. Extension VS Code yang terpasang pada komputer pengguna tidak dapat dinilai dari repository ini.
- Flutter/Dart yang dipakai saat pemeriksaan: Flutter 3.41.9, Dart 3.11.5. Pastikan toolchain CI/build konsisten dengan constraint SDK dan uji ulang setelah update.

## 9. Urutan tindakan yang disarankan

1. **Blokir distribusi publik** sampai P0-1 sampai P0-6 ditangani.
2. Konfirmasi URL produksi, Application ID final, versionCode berikutnya, akun signing, dan lingkungan backend.
3. Perbaiki HTTPS/certificate handling dan hapus debug signing serta nilai contoh.
4. Lengkapi dokumen legal; selaraskan isinya dengan praktik pemrosesan, konfigurasi tenant, retensi, dan kontrak.
5. Tinjau permission notifikasi Android/Play dan lengkapi atau putuskan target iOS.
6. Upgrade dependency secara bertahap; mulai dari patch yang kompatibel, lalu evaluasi major update dengan regression test.
7. Tambahkan tes untuk autentikasi dan alur inti presensi; jalankan pengujian perangkat nyata dan backend staging.
8. Buat APK/AAB release baru dengan signing produksi, cek identitas/version/signature, uji instalasi dan upgrade dari versi sebelumnya, lalu arsipkan checksum dan simbol mapping dengan akses terbatas.

## 10. Batas pemeriksaan

Audit ini membaca kode/config repository dan menjalankan `flutter pub outdated`, `flutter analyze`, serta `flutter test`. Audit ini **tidak** memverifikasi backend/konfigurasi server, kontrak dan kebijakan Perusahaan, Play Console, sertifikat domain, keamanan perangkat, seluruh riwayat Git, penetration test, atau build/signing iOS. Temuan yang bergantung pada backend atau keputusan bisnis ditandai untuk konfirmasi, bukan dianggap fakta yang telah terbukti.
