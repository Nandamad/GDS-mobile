import 'jam_kerja.dart';

class Shift {
  final int? id;
  final int? tenantId;
  final String? namaShift;
  final String? kodeShift;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi (hasMany jamKerjas)
  final List<JamKerja>? jamKerjas;

  Shift({
    this.id,
    this.tenantId,
    this.namaShift,
    this.kodeShift,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
    this.jamKerjas,
  });

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      namaShift: json['nama_shift'] as String?,
      kodeShift: json['kode_shift'] as String?,
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      jamKerjas: json['jam_kerjas'] != null
          ? (json['jam_kerjas'] as List)
              .map((e) => JamKerja.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'nama_shift': namaShift,
      'kode_shift': kodeShift,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'jam_kerjas': jamKerjas?.map((e) => e.toJson()).toList(),
    };
  }
}