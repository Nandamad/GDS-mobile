import 'package:flutter/foundation.dart';

class ApiConfig {
  // PENTING: Sesuaikan URL ini dengan URL Laravel Anda!
  // Jika Anda mengakses backend/admin di "http://127.0.0.1:8000", gunakan URL tersebut.
  // Jika menggunakan XAMPP (contoh: "http://localhost/gds/public"), ganti port-nya.
  
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api'; // URL untuk Web (Coba ganti ke localhost jika gagal)
    } else {
      return 'http://10.0.2.2:8000/api'; // URL untuk Android Emulator
    }
  }
}
