import '../api_config.dart';

class ImageUrlService {
  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          return '$base${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
        }
      } on FormatException {
        return null;
      }
      return trimmed;
    }

    var normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    
    // Jika URL adalah endpoint foto terproteksi, kembalikan langsung
    if (trimmed.contains('api/absensi/foto') || trimmed.contains('api/dokumen/cuti') || trimmed.contains('api/kunjungan/foto') || trimmed.contains('admin/logkehadiran/foto')) {
      return '$base$normalizedPath';
    }

    if (trimmed.startsWith('kunjungan/selfie/') || trimmed.startsWith('/kunjungan/selfie/')) {
      final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return Uri.parse('$base/api/kunjungan/foto')
          .replace(queryParameters: {'path': cleanPath})
          .toString();
    }

    if (trimmed.startsWith('absensi/') || trimmed.startsWith('/absensi/')) {
      final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return Uri.parse('$base/api/absensi/foto')
          .replace(queryParameters: {'path': cleanPath})
          .toString();
    }

    if (trimmed.startsWith('dokumen_cuti/') ||
        trimmed.startsWith('/dokumen_cuti/')) {
      final cleanPath = trimmed.startsWith('/') ? trimmed.substring(1) : trimmed;
      return Uri.parse('$base/api/dokumen/cuti')
          .replace(queryParameters: {'path': cleanPath})
          .toString();
    }

    if (!normalizedPath.startsWith('/storage/')) {
      normalizedPath = '/storage$normalizedPath';
    }
    return '$base$normalizedPath';
  }
}