import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio dio;
  final storage = const FlutterSecureStorage();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Accept'] = 'application/json';
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Handle global errors, e.g., 401 Unauthorized
        if (e.response?.statusCode == 401) {
          await storage.delete(key: 'auth_token');
          // Optionally, broadcast an event to redirect to login
        }
        return handler.next(e);
      },
    ));
  }

  Future<void> clearToken() async {
    await storage.delete(key: 'auth_token');
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }
}
