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
    if (trimmed.contains('api/absensi/foto')) {
        return trimmed.startsWith('http') ? trimmed : '$base$normalizedPath';
    }

    if (!normalizedPath.startsWith('/storage/')) {
      normalizedPath = '/storage$normalizedPath';
    }
    return '$base$normalizedPath';
  }
}