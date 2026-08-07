import 'shift.dart';

class JamKerja {
  final int? id;
  final int? tenantId;
  final int? shiftId;
  final String? namaJamKerja;
  final String? jamMasuk;
  final String? jamPulang;
  final String? jamMulaiIstirahat;
  final String? jamSelesaiIstirahat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Shift? shift;

  JamKerja({
    this.id,
    this.tenantId,
    this.shiftId,
    this.namaJamKerja,
    this.jamMasuk,
    this.jamPulang,
    this.jamMulaiIstirahat,
    this.jamSelesaiIstirahat,
    this.createdAt,
    this.updatedAt,
    this.shift,
  });

  factory JamKerja.fromJson(Map<String, dynamic> json) {
    return JamKerja(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      shiftId: json['shift_id'] as int?,
      namaJamKerja: json['nama_jam_kerja'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      jamMulaiIstirahat: json['jam_mulai_istirahat'] as String?,
      jamSelesaiIstirahat: json['jam_selesai_istirahat'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      shift: json['shift'] != null ? Shift.fromJson(json['shift']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'shift_id': shiftId,
      'nama_jam_kerja': namaJamKerja,
      'jam_masuk': jamMasuk,
      'jam_pulang': jamPulang,
      'jam_mulai_istirahat': jamMulaiIstirahat,
      'jam_selesai_istirahat': jamSelesaiIstirahat,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shift': shift?.toJson(),
    };
  }
}