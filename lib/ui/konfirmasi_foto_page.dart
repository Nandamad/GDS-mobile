import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class KonfirmasiFotoScreen extends StatefulWidget {
  final String? imageBase64;
  final LatLng currentLocation;
  final String namaKantor;
  final String alamatKantor;
  final double jarakMeter;
  final bool isInRadius;

  const KonfirmasiFotoScreen({
    super.key,
    this.imageBase64,
    required this.currentLocation,
    required this.namaKantor,
    required this.alamatKantor,
    required this.jarakMeter,
    required this.isInRadius,
  });

  @override
  State<KonfirmasiFotoScreen> createState() => _KonfirmasiFotoScreenState();
}

class _KonfirmasiFotoScreenState extends State<KonfirmasiFotoScreen> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second WIB';
  }

  String _formatDate(DateTime date) {
    final List<String> hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    final List<String> bulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${hari[date.weekday - 1]}, ${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
  }

  void _onConfirm() {
    if (!widget.isInRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda berada di luar radius kantor!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF0F172A)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Verifikasi Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            _buildTopInfoCard(),
            const SizedBox(height: 16),
            _buildCameraPreviewCard(),
            const SizedBox(height: 16),
            _buildDataVerifikasiCard(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF009688)),
              const SizedBox(width: 8),
              Text(
                _formatTime(_now),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Color(0xFF009688),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.namaKantor,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      widget.alamatKantor,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCameraPreviewCard() {
    String cleanBase64 = '';
    if (widget.imageBase64 != null) {
      if (widget.imageBase64!.contains(',')) {
        cleanBase64 = widget.imageBase64!.split(',').last;
      } else {
        cleanBase64 = widget.imageBase64!;
      }
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s+'), '');
    }
    
    final hasBase64 = cleanBase64.isNotEmpty;

    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF009688), width: 3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          alignment: Alignment.center,
          children: [
            hasBase64
                ? Image.memory(
              base64Decode(cleanBase64),
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              color: Colors.grey.shade300,
              child: const Center(
                child: Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            ),
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataVerifikasiCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Verifikasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _buildVerifikasiRow(
            label: 'Waktu Server',
            value: _formatTime(_now),
            isVerified: true,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Tanggal',
            value: _formatDate(_now),
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Koordinat GPS',
            value:
            '${widget.currentLocation.latitude.toStringAsFixed(6)}, '
                '${widget.currentLocation.longitude.toStringAsFixed(6)}',
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Jarak dari Kantor',
            value: '${widget.jarakMeter.toStringAsFixed(0)} meter',
            isVerified: widget.isInRadius,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Deteksi Wajah',
            value: 'Terverifikasi',
            isVerified: true,
          ),
          const Divider(height: 14),
          _buildVerifikasiRow(
            label: 'Status',
            value: widget.isInRadius
                ? 'Dalam Radius Kantor'
                : 'Di Luar Radius Kantor',
            valueColor: widget.isInRadius
                ? const Color(0xFF009688)
                : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiRow({
    required String label,
    required String value,
    bool isVerified = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
            if (isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_circle,
                size: 13,
                color: Color(0xFF009688),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 40,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF009688)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'AMBIL ULANG',
                style: TextStyle(
                  color: Color(0xFF009688),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: _onConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'KONFIRMASI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}