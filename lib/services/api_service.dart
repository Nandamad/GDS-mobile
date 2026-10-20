import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio dio;
  final storage = const FlutterSecureStorage();
  bool _redirectingToSplash = false;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;
          try {
            token = await storage.read(key: 'auth_token');
          } catch (e) {
            debugPrint('Secure storage read error in interceptor: $e');
            try { await storage.deleteAll(); } catch (_) {}
          }
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          final requestPath = e.requestOptions.path.split('?').first;
          final isLoginRequest = RegExp(r'(^|/)login/?$').hasMatch(requestPath);
          if (e.response?.statusCode == 401 &&
              !isLoginRequest &&
              !_redirectingToSplash) {
            _redirectingToSplash = true;
            await deleteToken();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/splash',
              (route) => false,
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    try {
      await storage.write(key: 'auth_token', value: token);
    } catch (e) {
      try { await storage.deleteAll(); } catch (_) {}
      await storage.write(key: 'auth_token', value: token);
    }
    _redirectingToSplash = false;
  }

  Future<void> deleteToken() async {
    try {
      await storage.delete(key: 'auth_token');
      await storage.delete(key: 'is_atasan');
    } catch (e) {
      try { await storage.deleteAll(); } catch (_) {}
    }
  }

  Future<String?> getToken() async {
    try {
      return await storage.read(key: 'auth_token');
    } catch (e) {
      try { await storage.deleteAll(); } catch (_) {}
      return null;
    }
  }

  Future<void> saveIsAtasan(bool value) async {
    try {
      await storage.write(key: 'is_atasan', value: value.toString());
    } catch (e) {
      // ignore
    }
  }

  Future<bool> getIsAtasan() async {
    try {
      final val = await storage.read(key: 'is_atasan');
      return val == 'true';
    } catch (e) {
      return false;
    }
  }
}
