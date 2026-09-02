import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'main_navigation_page.dart';
import 'lupa_password_page.dart'; // <-- Pastikan file ini sudah di-import

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final input = _nipController.text.trim();
    final password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email/NIP dan Password wajib diisi!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ApiService().dio;

      final response = await dio.post(
        '/login',
        data: {'login': input, 'password': password},
      );

      if (response.statusCode == 200) {
        final dynamic payload = response.data;

        String? extractToken(dynamic data) {
          if (data is! Map) return null;

          final map = Map<String, dynamic>.from(data);

          for (final key in ['access_token', 'token', 'authorization']) {
            final value = map[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }

          for (final key in ['data', 'user', 'auth']) {
            final nested = map[key];
            if (nested is Map) {
              final nestedToken = extractToken(nested);
              if (nestedToken != null) return nestedToken;
            }
          }

          return null;
        }

        final token = extractToken(payload);

        if (token != null && token.isNotEmpty) {
          await ApiService().saveToken(token);

          bool asBool(dynamic value) {
            if (value is bool) return value;
            return [
              'true',
              '1',
              'yes',
            ].contains(value?.toString().trim().toLowerCase());
          }

          Map<String, dynamic>? findUser(dynamic data) {
            if (data is! Map) return null;
            final map = Map<String, dynamic>.from(data);
            if (map.containsKey('is_atasan') ||
                map.containsKey('isAtasan') ||
                map.containsKey('karyawan_id')) {
              return map;
            }
            final directUser = map['user'];
            if (directUser is Map) {
              return Map<String, dynamic>.from(directUser);
            }

            for (final key in ['data', 'auth']) {
              final nestedUser = findUser(map[key]);
              if (nestedUser != null) return nestedUser;
            }
            return null;
          }

          var isAtasan = asBool(findUser(payload)?['is_atasan']);

          try {
            final userResponse = await dio.get('/user');
            final currentUser = findUser(userResponse.data);
            isAtasan = asBool(
              currentUser?['is_atasan'] ?? currentUser?['isAtasan'],
            );
          } on DioException catch (e) {
            debugPrint(
              'GET /user ERROR: ${e.response?.statusCode} ${e.response?.data}',
            );
          }

          if (!isAtasan) {
            try {
              final approvalResponse = await dio.get('/approval/pending');
              final approvalPayload = approvalResponse.data;
              dynamic approvalData = approvalPayload;
              if (approvalPayload is Map) {
                approvalData =
                    approvalPayload['data'] ??
                    approvalPayload['items'] ??
                    approvalPayload['result'] ??
                    [];
              }
              isAtasan =
                  approvalResponse.statusCode == 200 &&
                  approvalData is List &&
                  approvalData.isNotEmpty;
            } on DioException catch (e) {
              debugPrint(
                'CHECK ATASAN ERROR: ${e.response?.statusCode} ${e.response?.data}',
              );
            }
          }

          await ApiService().saveIsAtasan(isAtasan);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const MainNavigationScreen(),
              ),
            );
          }
        } else {
          debugPrint('LOGIN TOKEN TIDAK DITEMUKAN: $payload');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Token login tidak valid dari server.'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        }
      }
    } on DioException catch (e) {
      String errorMsg = 'Gagal terhubung ke server.';
      if (e.response != null) {
        if (e.response!.statusCode == 422) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            errorMsg = data['message'];
          } else {
            errorMsg = 'NIP/Email atau Password salah atau format tidak valid.';
          }
        } else if (e.response!.statusCode == 401) {
          final data = e.response!.data;
          if (data is Map && data.containsKey('message')) {
            errorMsg = data['message'];
          } else {
            errorMsg = 'Kredensial tidak valid atau akun dinonaktifkan.';
          }
        } else {
          errorMsg = 'Error server: ${e.response!.statusCode}';
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: const BoxDecoration(
                                color: Color(0xFF009688),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Selamat Datang',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Masuk ke akun PresensiKu Anda',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),

                      const Text(
                        'NIP / Email',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nipController,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan NIP Anda',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: Colors.grey.shade400,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // DIRECT KE HALAMAN LUPA PASSWORD
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LupaPasswordScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Lupa Password?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF009688),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}