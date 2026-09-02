import 'package:flutter/material.dart';
import '../model/absensi.dart';
import '../services/image_url_service.dart';
import '../services/api_service.dart';

class DetailLogScreen extends StatefulWidget {
  final Absensi? absensi;

  const DetailLogScreen({super.key, this.absensi});

  @override
  State<DetailLogScreen> createState() => _DetailLogScreenState();
}

class _DetailLogScreenState extends State<DetailLogScreen> {
  String? _token;

  @override
  void initState() {
    super.initState();
    ApiService().getToken().then((value) {
      if (mounted) {
        setState(() {
          _token = value;
        });
      }
    });
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:-- WIB';
    final localDate = date.toLocal(); 
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final localDate = date.toLocal(); 
    final List<String> hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> bulan = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return '${hari[localDate.weekday - 1]}, ${localDate.day.toString().padLeft(2, '0')} ${bulan[localDate.month - 1]} ${localDate.year}';
  }

  String _calculateDuration(DateTime? inTime, DateTime? outTime) {
    if (inTime == null || outTime == null) return '0 Jam 0 Menit';
    final diff = outTime.difference(inTime);
    if (diff.isNegative) return '0 Jam 0 Menit';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);
    return '$hours Jam $minutes Menit';
  }

  void _showPhotoPreview(String title, String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade800,
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 40)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, size: 18, color: Color(0xFF0F172A)),
            ),
          ),
        ),
        title: const Text(
          'Detail Presensi',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 20),
            _buildRekapWaktuRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('TOTAL DURASI KERJA'),
            const SizedBox(height: 12),
            _buildDurasiBanner(),
            const SizedBox(height: 24),
            _buildSectionTitle('DETAIL LOKASI GPS'),
            const SizedBox(height: 12),
            _buildGpsCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('FOTO VERIFIKASI'),
            const SizedBox(height: 12),
            _buildFotoVerifikasiRow(),
            const SizedBox(height: 24),
            _buildSectionTitle('CATATAN'),
            const SizedBox(height: 12),
            _buildCatatanCard(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
    );
  }

  Widget _buildHeaderCard() {
    final status = (widget.absensi?.status ?? 'hadir').toLowerCase();
    final isLate = status.contains('terlambat') || status.contains('pulang');

    String statusText = 'Tepat Waktu';
    Color bgColor = const Color(0xFFDCFCE7);
    Color txtColor = const Color(0xFF15803D);

    if (isLate) {
      statusText = 'Terlambat';
      bgColor = const Color(0xFFFFEDD5);
      txtColor = const Color(0xFFC2410C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _formatDate(widget.absensi?.tanggal),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
            child: Text(
              statusText,
              style: TextStyle(color: txtColor, fontWeight: FontWeight.bold, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapWaktuRow() {
    final status = (widget.absensi?.status ?? 'hadir').toLowerCase();
    final isLate = status.contains('terlambat') || status.contains('pulang');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JAM MASUK', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_formatTime(widget.absensi?.jamMasuk), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLate ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isLate ? 'Terlambat' : 'Tepat Waktu',
                    style: TextStyle(
                      fontSize: 9,
                      color: isLate ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('JAM PULANG', style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(_formatTime(widget.absensi?.jamPulang), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurasiBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.work_outline_rounded, size: 20, color: Color(0xFF0F766E)),
              SizedBox(width: 8),
              Text(
                'Durasi Aktual',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
              ),
            ],
          ),
          Text(
            _calculateDuration(widget.absensi?.jamMasuk, widget.absensi?.jamPulang),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildGpsItem(
            title: 'Lokasi Masuk',
            address: widget.absensi?.lokasiMasuk ?? 'Lokasi GPS Tidak Ada',
            distance: widget.absensi?.lokasiMasuk != null ? 'Jarak telah tercatat di sistem' : 'GPS tidak terekam',
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
          ),
          _buildGpsItem(
            title: 'Lokasi Pulang',
            address: widget.absensi?.lokasiPulang ?? 'Lokasi GPS Tidak Ada',
            distance: widget.absensi?.lokasiPulang != null ? 'Jarak telah tercatat di sistem' : 'GPS tidak terekam',
          ),
        ],
      ),
    );
  }

  Widget _buildGpsItem({required String title, required String address, required String distance}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(distance, style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoVerifikasiRow() {
    final fotoMasukUrl = ImageUrlService.resolve(widget.absensi?.fotoMasuk);
    final fotoPulangUrl = ImageUrlService.resolve(widget.absensi?.fotoPulang);

    return Row(
      children: [
        Expanded(child: _buildFotoCard('Foto Masuk', _formatTime(widget.absensi?.jamMasuk), fotoMasukUrl)),
        const SizedBox(width: 12),
        Expanded(child: _buildFotoCard('Foto Pulang', _formatTime(widget.absensi?.jamPulang), fotoPulangUrl)),
      ],
    );
  }

  Widget _buildFotoCard(String label, String time, String? imageUrl) {
    return InkWell(
      onTap: () => _showPhotoPreview(label, imageUrl),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 160,
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 32),
                    ),
                  )
                : Container(
                    height: 160,
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_outline, color: Colors.grey, size: 32),
                          SizedBox(height: 8),
                          Text('Belum ada foto', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        (widget.absensi?.catatanMasuk != null && widget.absensi!.catatanMasuk!.isNotEmpty) 
          ? widget.absensi!.catatanMasuk! 
          : 'Tidak ada catatan untuk hari ini.',
        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
    );
  }
}
