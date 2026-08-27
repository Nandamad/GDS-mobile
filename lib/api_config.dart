import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
  final url = dotenv.env['API_BASE_URL'] ??
      'http://192.168.18.79:8000/api';

  print('API BASE URL = $url');

  return url;
}
}
