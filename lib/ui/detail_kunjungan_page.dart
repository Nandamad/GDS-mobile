import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/image_url_service.dart';
import '../services/api_service.dart';

class DetailKunjunganScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKunjunganScreen({super.key, required this.data});

  bool get isPerjalananDinas => data['tanggal_selesai'] != null || data['jenis_perjalanan'] != null;

  String _value(dynamic value) {
    if (value == null) return '-';
    final text = value.toString().trim();
    if (text.isEmpty || text == 'null') return '-';
    return text;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return '-';
    try {
      final date = DateTime.parse(value.toString()).toLocal();
      const bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'];
      return '${date.day.toString().padLeft(2, '0')} ${bulan[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';
    final text = value.toString();
    if (text.contains(':')) {
      final parts = text.split(':');
      if (parts.length >= 2) return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')} WIB';
    }
    return text;
  }
  
  String _calculateDurationText() {
    if (data['jam_mulai_kunjungan'] != null && data['jam_selesai_kunjungan'] != null) {
      try {
        final start = DateFormat("HH:mm:ss").parse(data['jam_mulai_kunjungan']);
        final end = DateFormat("HH:mm:ss").parse(data['jam_selesai_kunjungan']);
        final diff = end.difference(start);
        
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(diff.inMinutes.remainder(60).abs());
        String twoDigitSeconds = twoDigits(diff.inSeconds.remainder(60).abs());
        return "${twoDigits(diff.inHours.abs())}:$twoDigitMinutes:$twoDigitSeconds";
      } catch (_) {
        return "-";
      }
    }
    return "00:00:00";
  }

  List<Color> _getBadgeColors(String status) {
    final lower = status.toLowerCase();
    if (lower == 'selesai' || lower == 'disetujui') return [const Color(0xFFDCFCE7), const Color(0xFF15803D)];
    if (lower == 'ditolak') return [const Color(0xFFFEE2E2), const Color(0xFFDC2626)];
    if (lower == 'menunggu' || lower == 'menunggu_verifikasi' || lower == 'pending') return [const Color(0xFFFFEDD5), const Color(0xFFC2410C)];
    return [const Color(0xFFF1F5F9), const Color(0xFF475569)]; 
  }

  String _formatStatus(String status) {
    final lower = status.toLowerCase();
    if (lower == 'menunggu_verifikasi') return 'MENUNGGU';
    return lower.toUpperCase();
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
        title: Text(
          isPerjalananDinas ? 'Detail Perjalanan Dinas' : 'Detail Kunjungan',
          style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopCard(),
            const SizedBox(height: 16),
            if (isPerjalananDinas) _buildDetailLokasiCard() else ...[
              _buildTimeDurationCard(),
              const SizedBox(height: 16),
              _buildTujuanKunjunganCard(),
              const SizedBox(height: 16),
              if (data['hasil_kunjungan'] != null || data['catatan'] != null) ...[
                _buildHasilKunjunganCard(),
                const SizedBox(height: 16),
              ]
            ],
            if (data['lokasi_gps_mulai'] != null || data['lokasi_gps_selesai'] != null) ...[
              _buildMapCard(
                title: isPerjalananDinas ? 'Lokasi GPS Terverifikasi' : 'Lokasi GPS Terdeteksi',
                gpsString: data['lokasi_gps_selesai'] ?? data['lokasi_gps_mulai'],
                alamat: data['alamat_kunjungan'],
              ),
              const SizedBox(height: 16),
            ] else if (isPerjalananDinas) ...[
              _buildMapEmptyCard(),
              const SizedBox(height: 16),
            ],
            
            if (data['foto_mulai'] != null || data['foto_selesai'] != null) ...[
              _buildSelfieCard(data['foto_selesai'] ?? data['foto_mulai']),
              const SizedBox(height: 16),
            ],

            if (isPerjalananDinas) ...[
              _buildWorkflow(),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopCard() {
    final status = data['status_final'] ?? data['status'] ?? 'Menunggu';
    final badgeColors = _getBadgeColors(status);
    final badgeText = _formatStatus(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _value(data['nama_klien'] ?? data['tujuan_kunjungan']),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: badgeColors[0], borderRadius: BorderRadius.circular(20)),
                child: Text(badgeText, style: TextStyle(color: badgeColors[1], fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isPerjalananDinas) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMiniStat('Keberangkatan', _formatDate(data['tanggal_mulai'] ?? data['tanggal']))),
                Expanded(child: _buildMiniStat('Kepulangan', _formatDate(data['tanggal_selesai']))),
                Expanded(child: _buildMiniStat('Durasi', _value(data['durasi_hari']) != '-' ? '${data['durasi_hari']} Hari' : '-')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jenis Perjalanan', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                Text(_value(data['jenis_perjalanan']), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            )
          ] else ...[
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(_formatDate(data['tanggal']), style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            )
          ]
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
      ],
    );
  }

  Widget _buildTimeDurationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text('DURASI KUNJUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(
            _calculateDurationText(),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)), // Teal color
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waktu Mulai', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text(_formatTime(data['jam_mulai_kunjungan']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Waktu Selesai', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 4),
                  Text(_formatTime(data['jam_selesai_kunjungan']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTujuanKunjunganCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TUJUAN KUNJUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(_value(data['tujuan_kunjungan']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          const Text('ALAMAT KUNJUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(_value(data['alamat_kunjungan']), style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildDetailLokasiCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detail Lokasi & Tujuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          const Text('Alamat Kunjungan', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(_value(data['alamat_kunjungan']), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          const Text('Tujuan Kegiatan', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(_value(data['tujuan_kunjungan']), style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A))),
          if (data['catatan'] != null) ...[
            const SizedBox(height: 12),
            const Text('Catatan Tambahan', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
            const SizedBox(height: 4),
            Text(data['catatan'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ]
        ],
      ),
    );
  }

  Widget _buildHasilKunjunganCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('HASIL KUNJUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(_value(data['hasil_kunjungan']), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
          ),
          const SizedBox(height: 16),
          const Text('CATATAN HASIL KUNJUNGAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(_value(data['catatan_hasil'] ?? data['catatan']), style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildMapEmptyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF475569)),
              const SizedBox(width: 8),
              const Text('Lokasi GPS Terencana', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Peta GPS & verifikasi check-in akan otomatis aktif setelah pengajuan ini disetujui HRD.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          )
        ],
      ),
    );
  }

  Widget _buildMapCard({required String title, required String gpsString, String? alamat}) {
    List<String> coords = gpsString.split(',');
    double lat = -6.200000;
    double lng = 106.816666;
    if (coords.length >= 2) {
      lat = double.tryParse(coords[0]) ?? lat;
      lng = double.tryParse(coords[1]) ?? lng;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Color(0xFF0F766E)), // Teal pin
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          if (alamat != null) ...[
            const SizedBox(height: 8),
            Text(alamat, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 15.0,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.gds.presensi_plus',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(lat, lng),
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSelfieCard(String imageUrlPath) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF0F766E)), 
              const SizedBox(width: 8),
              const Text('Foto Selfie Verifikasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: FutureBuilder<String?>(
                    future: ApiService().getToken(),
                    builder: (context, snapshot) {
                      return Image.network(
                        ImageUrlService.resolve(imageUrlPath)!,
                        fit: BoxFit.cover,
                        headers: snapshot.data != null ? {'Authorization': 'Bearer ${snapshot.data}'} : null,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.grey)),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1).withOpacity(0.9), // Light teal
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF0F766E).withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified_user, size: 10, color: Color(0xFF0F766E)),
                      SizedBox(width: 4),
                      Text('GPS VERIFIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F766E))),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWorkflow() {
    final l1 = data['status_approval_level1'];
    final l2 = data['status_approval_level2'];
    final finalStatus = data['status_final'];

    final l1Approved = _approved(l1);
    final l2Approved = _approved(l2);
    final rejected = _rejected(l1) || _rejected(l2) || _rejected(finalStatus);
    final selesai = l1Approved && l2Approved && _approved(finalStatus);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Alur Persetujuan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),
          _step(
            title: 'Pengajuan Dibuat',
            subtitle: 'Diajukan oleh: ${_value(data['karyawan']?['nama'] ?? 'Karyawan')}',
            dateStr: _formatDate(data['created_at']),
            statusType: 'done',
            first: true,
            last: false,
          ),
          _step(
            title: 'Verifikasi L1 / Atasan',
            subtitle: l1Approved ? 'Disetujui oleh Atasan' : (rejected ? 'Ditolak' : 'Sedang ditinjau oleh Atasan'),
            dateStr: _formatDate(data['approved_at_l1']),
            statusType: _getStepStatusType(l1, rejected, l1Approved, false),
            first: false,
            last: false,
          ),
          _step(
            title: 'Persetujuan HRD',
            subtitle: l2Approved ? 'Persetujuan akhir diberikan oleh HRD' : (rejected ? 'Ditolak' : 'Sedang ditinjau oleh HRD'),
            dateStr: _formatDate(data['approved_at_l2']),
            statusType: _getStepStatusType(l2, rejected, l2Approved, l1Approved),
            first: false,
            last: false,
          ),
          _step(
            title: 'Perjalanan Selesai',
            subtitle: selesai ? 'Laporan pertanggungjawaban terverifikasi' : '-',
            dateStr: '',
            statusType: selesai ? 'done' : (rejected ? 'cancelled' : 'waiting'),
            first: false,
            last: true,
          ),
        ],
      ),
    );
  }

  bool _approved(dynamic value) {
    if (value == null) return false;
    final status = value.toString().toLowerCase().trim();
    return status == 'disetujui' || status == 'approved' || status == 'approve';
  }

  bool _rejected(dynamic value) {
    if (value == null) return false;
    final status = value.toString().toLowerCase().trim();
    return status == 'ditolak' || status == 'rejected' || status == 'reject';
  }

  String _getStepStatusType(dynamic val, bool overallRejected, bool isApproved, bool prevApproved) {
    if (_rejected(val)) return 'rejected';
    if (overallRejected) return 'cancelled';
    if (isApproved) return 'done';
    if (prevApproved || (!_approved(val) && !_rejected(val))) return 'pending';
    return 'waiting';
  }

  Widget _step({
    required String title,
    required String subtitle,
    required String dateStr,
    required String statusType, 
    required bool first,
    required bool last,
  }) {
    Color iconColor = Colors.grey.shade400;
    Color lineColor = Colors.grey.shade300;
    IconData? iconData;
    double iconSize = 10;
    bool isFilledCircle = false;

    if (statusType == 'done') {
      iconColor = const Color(0xFF10B981);
      lineColor = const Color(0xFF10B981);
      isFilledCircle = true;
    } else if (statusType == 'rejected') {
      iconColor = const Color(0xFFEF4444);
      iconData = Icons.close;
    } else if (statusType == 'pending') {
      iconColor = const Color(0xFF64748B);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (!first) Container(width: 2, height: 12, color: statusType == 'done' || statusType == 'pending' ? lineColor : Colors.grey.shade300),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilledCircle ? iconColor : Colors.white,
                  border: Border.all(color: iconColor, width: 2),
                ),
                child: iconData != null ? Center(child: Icon(iconData, size: iconSize, color: Colors.white)) : null,
              ),
              if (!last) Container(width: 2, height: 36, color: statusType == 'done' ? lineColor : Colors.grey.shade300),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: statusType == 'waiting' || statusType == 'cancelled' ? Colors.grey : const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                if (dateStr.isNotEmpty && dateStr != '-')
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                  )
                else if (statusType == 'pending')
                  const Text('...', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)))
              ],
            ),
          ),
        ),
      ],
    );
  }
}
