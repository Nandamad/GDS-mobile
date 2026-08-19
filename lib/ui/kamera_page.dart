import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class KameraScreen extends StatefulWidget {
  const KameraScreen({super.key});

  @override
  State<KameraScreen> createState() => _KameraScreenState();
}

class _KameraScreenState extends State<KameraScreen> {
  CameraController? _cameraController;

  bool _isCameraReady = false;
  bool _isTakingPicture = false;
  String? _errorMessage;

  // Realtime Clock
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();

    _updateTime();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) => _updateTime(),
    );

    _startCamera();
  }

  void _updateTime() {
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute:$second WIB';
      });
    }
  }

  Future<void> _startCamera() async {
    try {
      if (mounted) {
        setState(() {
          _errorMessage = null;
          _isCameraReady = false;
        });
      }

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('Kamera tidak ditemukan pada perangkat.');
      }

      CameraDescription selectedCamera;

      if (kIsWeb) {
        // DI WEB: Ambil kamera pertama secara langsung untuk menghindari mismatch ID/LensDirection
        selectedCamera = cameras.first;
      } else {
        // DI MOBILE (Android/iOS): Cari kamera depan
        selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => cameras.first,
        );
      }

      final controller = CameraController(
        selectedCamera,
        // Web lebih stabil pakai low/medium agar browser tidak memblokir stream
        kIsWeb ? ResolutionPreset.medium : ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      // Flash Mode hanya diset di Mobile (Web akan crash kalau dipanggil)
      if (!kIsWeb) {
        try {
          await controller.setFlashMode(FlashMode.off);
        } catch (_) {}
      }

      _cameraController = controller;

      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _errorMessage = null;
        });
      }
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _errorMessage = _cameraErrorMessage(e);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _errorMessage = 'Gagal mengakses kamera.\n$e';
        });
      }
    }
  }

  String _cameraErrorMessage(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
        return 'Akses kamera ditolak.\nSilakan izinkan aplikasi menggunakan kamera.';
      case 'CameraAccessDeniedWithoutPrompt':
        return 'Akses kamera ditolak.\nSilakan aktifkan izin kamera dari Pengaturan Browser/HP.';
      case 'CameraAccessRestricted':
        return 'Akses kamera dibatasi oleh perangkat.';
      default:
        return 'Kamera tidak dapat digunakan.\n${e.description ?? e.code}';
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isTakingPicture) {
      return;
    }

    try {
      setState(() {
        _isTakingPicture = true;
      });

      final XFile image = await _cameraController!.takePicture();

      // Baca foto sebagai bytes
      final bytes = await image.readAsBytes();

      // Convert ke Base64
      final base64Image = base64Encode(bytes);

      // Format data URL
      final imageDataUrl = 'data:image/jpeg;base64,$base64Image';

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto verifikasi berhasil ditangkap!'),
          backgroundColor: Color(0xFF009688),
          duration: Duration(seconds: 1),
        ),
      );

      // Kembalikan foto ke halaman sebelumnya
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(context, imageDataUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraController;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // =========================================================
          // LIVE CAMERA PREVIEW
          // =========================================================
          if (_isCameraReady &&
              controller != null &&
              controller.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(controller),
            )
          else
            Positioned.fill(
              child: Center(
                child: _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_off_outlined,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _startCamera,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF009688),
                              ),
                              child: const Text(
                                'COBA LAGI',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF009688),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Menghubungkan ke Kamera...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

          // =========================================================
          // OVERLAY UI (BINGKAI KANVAS LINGKARAN & OVERLAY)
          // =========================================================
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TOP BAR
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const Text(
                            'Kantor Pusat (Jl. Sudirman)',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // FACE FRAME
                Container(
                  width: 260,
                  height: 360,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(130, 180),
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'Posisikan wajah Anda\ndi dalam bingkai',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              blurRadius: 6,
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // BUTTON
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isCameraReady && !_isTakingPicture
                              ? _takePicture
                              : _startCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isTakingPicture
                                ? 'MEMPROSES...'
                                : _isCameraReady
                                    ? 'AMBIL FOTO'
                                    : 'AKTIFKAN KAMERA',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pencahayaan yang cukup membantu verifikasi deteksi wajah AI',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}