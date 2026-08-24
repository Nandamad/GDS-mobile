import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'main_navigation_page.dart';

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
        data: {
          'login': input,
          'password': password,
        },
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

          // Ekstrak is_atasan dari payload.user (sesuai kontrak backend)
          bool isAtasan = false;
          if (payload is Map) {
            final user = payload['user'];
            if (user is Map && user['is_atasan'] == true) {
              isAtasan = true;
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
          // Menampilkan detail pesan error dari validator Laravel
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
                      const SizedBox(height: 40),
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCFBF1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                size: 30,
                                color: Color(0xFF009688),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'PresensiKu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Sistem Presensi Karyawan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Masukkan kredensial Anda untuk melanjutkan',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Email atau NIP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nipController,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 199403101...',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF009688),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 18,
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
                            vertical: 12,
                            horizontal: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF009688),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Silakan hubungi admin HRD untuk reset password.',
                                ),
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
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF009688),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
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
