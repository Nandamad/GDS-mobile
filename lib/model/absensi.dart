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
    this.karyawan,
    this.logKeterlambatans,
  });

  factory Absensi.fromJson(Map<String, dynamic> json) {
    return Absensi(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      tanggal: json['tanggal'] != null ? DateTime.tryParse(json['tanggal']) : null,
      jamMasuk: json['jam_masuk'] != null ? DateTime.tryParse(json['jam_masuk']) : null,
      jamPulang: json['jam_pulang'] != null ? DateTime.tryParse(json['jam_pulang']) : null,
      status: json['status'] as String?,
      karyawan: json['karyawan'] != null ? Karyawan.fromJson(json['karyawan']) : null,
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
      'log_keterlambatans': logKeterlambatans?.map((e) => e.toJson()).toList(),
    };
  }
}