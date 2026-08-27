import '../api_config.dart';

class ImageUrlService {
  static String? resolve(String? path) {
    if (path == null || path.trim().isEmpty) return null;

    final trimmed = path.trim();
    final base = ApiConfig.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    // 1. Jika path sudah berupa URL lengkap (http/https)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      try {
        final uri = Uri.parse(trimmed);
        if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
          final targetBase = Uri.parse(base);
          final newUri = uri.replace(
            scheme: targetBase.scheme,
            host: targetBase.host,
            port: targetBase.port,
          );
          return newUri.toString();
        }
      } on FormatException {
        return null;
      }
      return trimmed;
    }

    // 2. Jika path berupa URL relatif
    var normalizedPath = trimmed.startsWith('/') ? trimmed : '/$trimmed';

    // Jika sudah ada prefix /storage/ atau /api/, langsung gabung dengan base
    if (normalizedPath.startsWith('/storage/') ||
        normalizedPath.startsWith('/api/')) {
      return '$base$normalizedPath';
    }

    // Fallback: tambahkan /storage/
    return '$base/storage$normalizedPath';
  }
}
