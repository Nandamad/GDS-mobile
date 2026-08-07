import 'karyawan.dart';
import 'user.dart';

class IzinCuti {
  final int? id;
  final int? tenantId;
  final int? karyawanId;
  final String? jenis; // e.g., 'izin', 'cuti', 'sakit'
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String? alasan;
  final String? status; // e.g., 'pending', 'approved', 'rejected'
  final int? approvedBy;
  final DateTime? approvedAt;
  final String? catatanPersetujuan;
  final String? fileLampiran;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Karyawan? karyawan;
  final User? approver;

  IzinCuti({
    this.id,
    this.tenantId,
    this.karyawanId,
    this.jenis,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.alasan,
    this.status,
    this.approvedBy,
    this.approvedAt,
    this.catatanPersetujuan,
    this.fileLampiran,
    this.createdAt,
    this.updatedAt,
    this.karyawan,
    this.approver,
  });

  factory IzinCuti.fromJson(Map<String, dynamic> json) {
    return IzinCuti(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      jenis: json['jenis'] as String?,
      tanggalMulai: json['tanggal_mulai'] != null
          ? DateTime.tryParse(json['tanggal_mulai'])
          : null,
      tanggalSelesai: json['tanggal_selesai'] != null
          ? DateTime.tryParse(json['tanggal_selesai'])
          : null,
      alasan: json['alasan'] as String?,
      status: json['status'] as String?,
      approvedBy: json['approved_by'] as int?,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : null,
      catatanPersetujuan: json['catatan_persetujuan'] as String?,
      fileLampiran: json['file_lampiran'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
      approver: json['approved_by_user'] != null
          ? User.fromJson(json['approved_by_user'])
          : (json['approved_by'] is Map<String, dynamic>
              ? User.fromJson(json['approved_by'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'karyawan_id': karyawanId,
      'jenis': jenis,
      'tanggal_mulai': tanggalMulai?.toIso8601String().split('T').first,
      'tanggal_selesai': tanggalSelesai?.toIso8601String().split('T').first,
      'alasan': alasan,
      'status': status,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'catatan_persetujuan': catatanPersetujuan,
      'file_lampiran': fileLampiran,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'karyawan': karyawan?.toJson(),
      'approved_by_user': approver?.toJson(),
    };
  }
}