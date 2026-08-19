import 'log_keterlambatan.dart';
import 'karyawan.dart';

class Absensi {
  final int? id;
  final int? tenantId;
  final int? karyawanId;
  final DateTime? tanggal;
  final DateTime? jamMasuk;
  final DateTime? jamPulang;
  final String? status;
  final String? lokasiMasuk;
  final String? lokasiPulang;
  final String? fotoMasuk;
  final String? fotoPulang;
  final String? catatanMasuk;
  final Karyawan? karyawan;
  final List<LogKeterlambatan>? logKeterlambatans;

  Absensi({
    this.id,
    this.tenantId,
    this.karyawanId,
    this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    this.status,
    this.lokasiMasuk,
    this.lokasiPulang,
    this.fotoMasuk,
    this.fotoPulang,
    this.catatanMasuk,
    this.karyawan,
    this.logKeterlambatans,
  });

  // Helper untuk memparse tanggal/jam dari ISO string atau SQL format ("YYYY-MM-DD HH:mm:ss")
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    String str = value.toString().trim();
    if (str.isEmpty) return null;
    if (str.contains(' ') && !str.contains('T')) {
      str = str.replaceFirst(' ', 'T');
    }
    return DateTime.tryParse(str);
  }

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      tanggal: _parseDateTime(json['tanggal']),
      jamMasuk: _parseDateTime(json['jam_masuk']),
      // Cek jam_pulang atau jam_keluar
      jamPulang: _parseDateTime(json['jam_pulang'] ?? json['jam_keluar']),
      status: json['status'] as String?,
      // Cek gps_masuk / lokasi_masuk
      lokasiMasuk: (json['gps_masuk'] ?? json['lokasi_masuk']) as String?,
      lokasiPulang: (json['gps_pulang'] ?? json['lokasi_pulang']) as String?,
      // Cek foto_selfie_masuk / foto_masuk
      fotoMasuk: (json['foto_selfie_masuk'] ?? json['foto_masuk']) as String?,
      fotoPulang: (json['foto_selfie_pulang'] ?? json['foto_pulang']) as String?,
      // Cek catatan / catatan_masuk
      catatanMasuk: (json['catatan'] ?? json['catatan_masuk']) as String?,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
      logKeterlambatans: json['log_keterlambatans'] != null
          ? (json['log_keterlambatans'] as List)
              .map((e) => LogKeterlambatan.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'karyawan_id': karyawanId,
      'tanggal': tanggal?.toIso8601String().split('T').first,
      'jam_masuk': jamMasuk?.toIso8601String(),
      'jam_pulang': jamPulang?.toIso8601String(),
      'status': status,
      'karyawan': karyawan?.toJson(),
      'gps_masuk': lokasiMasuk,
      'gps_pulang': lokasiPulang,
      'foto_selfie_masuk': fotoMasuk,
      'foto_selfie_pulang': fotoPulang,
      'catatan': catatanMasuk,
      'log_keterlambatans': logKeterlambatans?.map((e) => e.toJson()).toList(),
    };
  }
}