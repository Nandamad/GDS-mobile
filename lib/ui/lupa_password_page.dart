import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class LupaPasswordScreen extends StatefulWidget {
  const LupaPasswordScreen({super.key});

  @override
  State<LupaPasswordScreen> createState() => _LupaPasswordScreenState();
}

class _LupaPasswordScreenState extends State<LupaPasswordScreen> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  int _step = 1; // 1: Masukkan Email, 2: Masukkan Token & Password Baru

  // State untuk toggle visibilitas password
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 1. Fungsi Kirim Email (Request Token)
  Future<void> _requestToken() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email tidak boleh kosong')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ApiService().dio;
      final response = await dio.post('/forgot-password', data: {
        'email': _emailController.text.trim(),
      });

      if (response.statusCode == 200) {
        final serverToken = response.data['token'];
        if (serverToken != null) {
          _tokenController.text = serverToken;
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Token berhasil dikirim',
            ),
          ),
        );
        setState(() => _step = 2);
      }
    } on DioException catch (e) {
      final msg =
          e.response?.data['message'] ??
          'Gagal mengirim permintaan reset password.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Fungsi Reset Password Baru
  Future<void> _resetPassword() async {
    if (_tokenController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua kolom wajib diisi')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi password tidak cocok'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ApiService().dio;
      final response = await dio.post('/reset-password', data: {
        'email': _emailController.text.trim(),
        'token': _tokenController.text.trim(),
        'password': _passwordController.text,
        'password_confirmation': _confirmPasswordController.text,
      });

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.data['message'] ?? 'Password berhasil direset',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Gagal mereset password.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _step == 1 ? 'Masukkan Email' : 'Buat Password Baru',
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            Text(
              _step == 1
                  ? 'Masukkan email yang terdaftar untuk reset\npassword'
                  : 'Masukkan token yang diterima beserta\npassword baru Anda.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 32),

            if (_step == 1) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Masukkan alamat email',
                  hintStyle: TextStyle(
                    fontSize: 13,
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _requestToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          'Kirim',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ] else ...[
              TextField(
                controller: _tokenController,
                decoration: InputDecoration(
                  labelText: 'Token Verifikasi',
                  prefixIcon: const Icon(Icons.vpn_key_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // INPUT PASSWORD BARU WITH EYE ICON
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // INPUT KONFIRMASI PASSWORD BARU WITH EYE ICON
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password Baru',
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009688),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
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
                          'Ganti Password',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}