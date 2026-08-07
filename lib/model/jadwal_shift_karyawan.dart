import 'karyawan.dart';
import 'jam_kerja.dart';

class JadwalShiftKaryawan {
  final int? id;
  final int? karyawanId;
  final int? shiftId;
  final DateTime? tanggal;
  final String? keterangan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Karyawan? karyawan;
  final JamKerja? shift;

  JadwalShiftKaryawan({
    this.id,
    this.karyawanId,
    this.shiftId,
    this.tanggal,
    this.keterangan,
    this.createdAt,
    this.updatedAt,
    this.karyawan,
    this.shift,
  });

  factory JadwalShiftKaryawan.fromJson(Map<String, dynamic> json) {
    return JadwalShiftKaryawan(
      id: json['id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      shiftId: json['shift_id'] as int?,
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'])
          : null,
      keterangan: json['keterangan'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
      shift: json['shift'] != null
          ? JamKerja.fromJson(json['shift'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'karyawan_id': karyawanId,
      'shift_id': shiftId,
      'tanggal': tanggal?.toIso8601String().split('T').first,
      'keterangan': keterangan,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'karyawan': karyawan?.toJson(),
      'shift': shift?.toJson(),
    };
  }
}