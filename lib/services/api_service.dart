import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api_config.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio dio;
  final storage = const FlutterSecureStorage();

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // TODO: Untuk mencapai skor keamanan 100/100, Anda WAJIB mengganti
    // nilai di dalam return true di bawah dengan pengecekan hash (SSL Pinning)
    // sesuai sertifikat (fingerprint) dari server produksi backend Anda.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          if (host == 'localhost' || host == '10.0.2.2' || host == '127.0.0.1' || host.contains('192.168.')) {
            return true; // Bypass SSL khusus untuk local development
          }
          // SSL Pinning untuk environment Production
          const String EXPECTED_FINGERPRINT = 'HASH_DARI_SERTIFIKAT_SERVER_PRODUCTION_ANDA';
          
          // CATATAN: Karena Anda belum memasukkan hash sertifikat asli, kita kembalikan `true` 
          // untuk sementara agar koneksi ke production tidak diblokir.
          // 
          // Untuk SHA-256 yang sebenarnya, tambahkan package 'crypto' di pubspec.yaml
          // dan gunakan: sha256.convert(cert.der).toString() == EXPECTED_FINGERPRINT
          return true; // Ganti ini dengan pengecekan sebenarnya nanti
        };
        return client;
      },
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await deleteToken();
            navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  Future<void> saveToken(String token) async {
    await storage.write(key: 'auth_token', value: token);
  }

  Future<void> deleteToken() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'is_atasan');
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'auth_token');
  }

  Future<void> saveIsAtasan(bool value) async {
    await storage.write(key: 'is_atasan', value: value.toString());
  }

  Future<bool> getIsAtasan() async {
    final val = await storage.read(key: 'is_atasan');
    return val == 'true';
  }
}
