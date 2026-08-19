import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api';
  }
}