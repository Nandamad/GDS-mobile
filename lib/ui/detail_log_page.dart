import 'package:flutter/material.dart';
import '../model/absensi.dart';
import '../api_config.dart';

class DetailLogScreen extends StatefulWidget {
  final Absensi? absensi;

  const DetailLogScreen({super.key, this.absensi});

  @override
  State<DetailLogScreen> createState() => _DetailLogScreenState();
}

class _DetailLogScreenState extends State<DetailLogScreen> {
  int _selectedNavIndex = 3;

  String? _getPhotoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final base = ApiConfig.baseUrl.replaceAll('/api', '');
    String cleanPath = path.startsWith('/') ? path : '/$path';
    if (!cleanPath.startsWith('/storage') && !cleanPath.startsWith('storage')) {
      cleanPath = '/storage$cleanPath';
    }
    return '$base$cleanPath';
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '--:-- WIB';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Rabu, 19 Agustus 2026';
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

  String _calculateDuration(DateTime? inTime, DateTime? outTime) {
    if (inTime == null || outTime == null) return 'Belum Selesai';
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
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0.8),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey.shade800,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 40,
                    ),
                  ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Log Presensi',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 14),
            _buildSectionTitle('REKAP WAKTU'),
            const SizedBox(height: 6),
            _buildRekapWaktuRow(),
            const SizedBox(height: 14),
            _buildSectionTitle('TOTAL DURASI KERJA'),
            const SizedBox(height: 6),
            _buildDurasiBanner(),
            const SizedBox(height: 14),
            _buildSectionTitle('DETAIL LOKASI GPS'),
            const SizedBox(height: 6),
            _buildGpsCard(),
            const SizedBox(height: 14),
            _buildSectionTitle('FOTO VERIFIKASI'),
            const SizedBox(height: 6),
            _buildFotoVerifikasiRow(),
            const SizedBox(height: 14),
            _buildSectionTitle('CATATAN'),
            const SizedBox(height: 6),
            _buildCatatanCard(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildHeaderCard() {
    final status = widget.absensi?.status ?? 'hadir';
    final isLate = status.toLowerCase().contains('terlambat');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(widget.absensi?.tanggal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isLate
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isLate ? 'Terlambat' : 'Hadir Tepat Waktu',
                  style: TextStyle(
                    color: isLate
                        ? const Color(0xFFC2410C)
                        : const Color(0xFF15803D),
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: const [
              Icon(Icons.access_time_outlined, size: 14, color: Colors.grey),
              SizedBox(width: 6),
              Text(
                'Shift: ',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                'Shift Pagi / Reguler',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              const Text(
                'GPS Masuk: ',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Expanded(
                child: Text(
                  widget.absensi?.lokasiMasuk ?? 'Lokasi tidak terekam',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRekapWaktuRow() {
    final isLate = (widget.absensi?.status ?? '').toLowerCase().contains('terlambat');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JAM MASUK',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(widget.absensi?.jamMasuk),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLate ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isLate ? 'Terlambat' : 'Tepat Waktu',
                    style: TextStyle(
                      fontSize: 8,
                      color: isLate ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JAM PULANG',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(widget.absensi?.jamPulang),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Normal',
                    style: TextStyle(
                      fontSize: 8,
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFCCFBF1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: const [
              Icon(Icons.badge_outlined, size: 16, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Text(
                'Durasi Kerja',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F766E),
                ),
              ),
            ],
          ),
          Text(
            _calculateDuration(widget.absensi?.jamMasuk, widget.absensi?.jamPulang),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F766E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGpsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildGpsItem(
            title: 'Lokasi Masuk',
            address: widget.absensi?.lokasiMasuk ?? 'Lokasi GPS Tidak Ada',
            distance: 'Jarak: Dalam Radius Safe-Zone',
          ),
          const Divider(height: 20),
          _buildGpsItem(
            title: 'Lokasi Pulang',
            address: widget.absensi?.lokasiPulang ?? 'Lokasi GPS Tidak Ada',
            distance: 'Jarak: Dalam Radius Safe-Zone',
          ),
        ],
      ),
    );
  }

  Widget _buildGpsItem({
    required String title,
    required String address,
    required String distance,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.near_me_outlined, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.check, size: 10, color: Color(0xFF16A34A)),
                  const SizedBox(width: 2),
                  Text(
                    distance,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFotoVerifikasiRow() {
    final fotoMasukUrl = _getPhotoUrl(widget.absensi?.fotoMasuk);
    final fotoPulangUrl = _getPhotoUrl(widget.absensi?.fotoPulang);

    return Row(
      children: [
        _buildFotoCard(
          'Foto Masuk',
          _formatTime(widget.absensi?.jamMasuk),
          fotoMasukUrl,
        ),
        const SizedBox(width: 8),
        _buildFotoCard(
          'Foto Pulang',
          _formatTime(widget.absensi?.jamPulang),
          fotoPulangUrl,
        ),
      ],
    );
  }

  Widget _buildFotoCard(String label, String time, String? imageUrl) {
    return Expanded(
      child: InkWell(
        onTap: () => _showPhotoPreview(label, imageUrl),
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl != null
                  ? Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.no_photography, color: Colors.grey),
                ),
              )
                  : Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_outline, color: Colors.grey, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Belum ada foto',
                        style: TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            Text(time, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        widget.absensi?.catatanMasuk ?? 'Tidak ada catatan untuk hari ini.',
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) => setState(() => _selectedNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF009688),
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      iconSize: 20,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_outlined),
          label: 'Pengajuan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.format_list_bulleted),
          activeIcon: Icon(Icons.format_list_bulleted_sharp),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Notifikasi',
        ),
      ],
    );
  }
}