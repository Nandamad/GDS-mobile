import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl {
    // Abaikan dotenv dulu, langsung tembak IP laptopmu secara hardcode
    return 'http://192.168.18.79:8000/api'; 
  }
}