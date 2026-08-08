import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation_page.dart'; // Ganti import 'dashboard_page.dart'

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
    FocusScope.of(context).unfocus(); // Sembunyikan keyboard

    final nip = _nipController.text.trim();
    final password = _passwordController.text.trim();

    // Validasi Input Kosong
    if (nip.isEmpty || password.isEmpty) {
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
      final dio = Dio(BaseOptions(
        baseUrl: 'http://10.0.2.2:8000/api', // Ubah IP sesuai server jika di physical device
        connectTimeout: const Duration(seconds: 10),
      ));

      final response = await dio.post('/login', data: {
        'email': nip,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['access_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
          );
        }
      }
    } on DioException catch (e) {
      String errorMsg = 'Gagal terhubung ke server.';
      if (e.response != null) {
        if (e.response!.statusCode == 422) {
          errorMsg = e.response!.data['message'] ?? 'Kredensial salah';
        } else {
          errorMsg = 'Error server: ${e.response!.statusCode}';
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.redAccent,
          ),
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

                      // Logo & App Header
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

                      // Section Title Masuk
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
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Input Email / NIP
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
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Contoh: 199403101...',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            borderSide: const BorderSide(color: Color(0xFF009688)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Input Password
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
                        style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: '••••••••••••',
                          hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey.shade400),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
                            borderSide: const BorderSide(color: Color(0xFF009688)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Lupa Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Silakan hubungi admin HRD untuk reset password.'),
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

                      // Tombol Masuk
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

              // Version Bottom Text
              const Padding(
                padding: EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}