import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

class KameraScreen extends StatefulWidget {
  const KameraScreen({super.key});

  @override
  State<KameraScreen> createState() => _KameraScreenState();
}

class _KameraScreenState extends State<KameraScreen> {
  final String _viewId = 'webcam-video-element';
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  bool _isCameraReady = false;
  String? _errorMessage;

  // Realtime Clock State
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => _updateTime());
    _setupVideoElement();
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

  void _setupVideoElement() {
    final videoElement = html.VideoElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover'
      ..autoplay = true;
    videoElement.setAttribute('playsinline', 'true');
    _videoElement = videoElement;

    ui_web.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _videoElement!,
    );

    _startCamera();
  }

  Future<void> _startCamera() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'user',
          'width': {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _mediaStream = stream;
      _videoElement!.srcObject = stream;

      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraReady = false;
          _errorMessage =
              'Sistem menolak akses kamera.\nKlik tombol "AKTIFKAN KAMERA" di bawah jika kamera belum muncul.';
        });
      }
    }
  }

  void _takePicture() {
    if (_videoElement != null && _isCameraReady) {
      final canvas = html.CanvasElement(
        width: _videoElement!.videoWidth,
        height: _videoElement!.videoHeight,
      );
      canvas.context2D.drawImage(_videoElement!, 0, 0);
      
      // Ambil Base64 Image
      final String imageDataUrl = canvas.toDataUrl('image/png');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto verifikasi berhasil ditangkap!'),
          backgroundColor: Color(0xFF009688),
          duration: Duration(seconds: 1),
        ),
      );

      // Kembalikan data foto ke layar sebelumnya setelah 1 detik
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context, imageDataUrl);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    if (_mediaStream != null) {
      for (final track in _mediaStream!.getTracks()) {
        track.stop();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. LIVE HTML WEBCAM STREAM
          if (_isCameraReady)
            HtmlElementView(viewType: _viewId)
          else
            Center(
              child: _errorMessage != null
                  ? Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off_outlined,
                              color: Colors.white54, size: 48),
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
                            child: const Text('Coba Lagi',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF009688)),
                        SizedBox(height: 12),
                        Text(
                          'Menghubungkan ke Webcam...',
                          style: TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ],
                    ),

            ),

          // 2. OVERLAY UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
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

                // Bingkai Oval Proporsional Wajah
                Container(
                  width: 260,
                  height: 360,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(130, 180),
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.95),
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
                      padding: EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Posisikan wajah Anda\ndi dalam bingkai',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(blurRadius: 6, color: Colors.black87),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Button Ambil Foto
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isCameraReady ? _takePicture : _startCamera,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF009688),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isCameraReady ? 'AMBIL FOTO' : 'AKTIFKAN KAMERA',
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
                        style: TextStyle(color: Colors.white70, fontSize: 9),
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