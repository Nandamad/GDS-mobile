import 'karyawan.dart';
import 'user.dart';

class Lembur {
  final int? id;
  final int? tenantId;
  final int? karyawanId;
  final DateTime? tanggal;
  final DateTime? jamMulaiLembur;
  final DateTime? jamSelesaiLembur;
  final String? alasan;
  final String? status; // e.g., 'pending', 'approved', 'rejected'
  final int? approvedByL1;
  final DateTime? approvedAtL1;
  final int? approvedByL2;
  final DateTime? approvedAtL2;
  final String? catatanPersetujuan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Karyawan? karyawan;
  final User? approverL1;
  final User? approverL2;

  Lembur({
    this.id,
    this.tenantId,
    this.karyawanId,
    this.tanggal,
    this.jamMulaiLembur,
    this.jamSelesaiLembur,
    this.alasan,
    this.status,
    this.approvedByL1,
    this.approvedAtL1,
    this.approvedByL2,
    this.approvedAtL2,
    this.catatanPersetujuan,
    this.createdAt,
    this.updatedAt,
    this.karyawan,
    this.approverL1,
    this.approverL2,
  });

  factory Lembur.fromJson(Map<String, dynamic> json) {
    return Lembur(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'])
          : null,
      jamMulaiLembur: json['jam_mulai_lembur'] != null
          ? DateTime.tryParse(json['jam_mulai_lembur'])
          : null,
      jamSelesaiLembur: json['jam_selesai_lembur'] != null
          ? DateTime.tryParse(json['jam_selesai_lembur'])
          : null,
      alasan: json['alasan'] as String?,
      status: json['status'] as String?,
      approvedByL1: json['approved_by_l1'] as int?,
      approvedAtL1: json['approved_at_l1'] != null
          ? DateTime.tryParse(json['approved_at_l1'])
          : null,
      approvedByL2: json['approved_by_l2'] as int?,
      approvedAtL2: json['approved_at_l2'] != null
          ? DateTime.tryParse(json['approved_at_l2'])
          : null,
      catatanPersetujuan: json['catatan_persetujuan'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
      approverL1: json['approved_by_l1_user'] != null
          ? User.fromJson(json['approved_by_l1_user'])
          : (json['approved_by_l1'] is Map<String, dynamic>
              ? User.fromJson(json['approved_by_l1'])
              : null),
      approverL2: json['approved_by_l2_user'] != null
          ? User.fromJson(json['approved_by_l2_user'])
          : (json['approved_by_l2'] is Map<String, dynamic>
              ? User.fromJson(json['approved_by_l2'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'karyawan_id': karyawanId,
      'tanggal': tanggal?.toIso8601String().split('T').first,
      'jam_mulai_lembur': jamMulaiLembur?.toIso8601String(),
      'jam_selesai_lembur': jamSelesaiLembur?.toIso8601String(),
      'alasan': alasan,
      'status': status,
      'approved_by_l1': approvedByL1,
      'approved_at_l1': approvedAtL1?.toIso8601String(),
      'approved_by_l2': approvedByL2,
      'approved_at_l2': approvedAtL2?.toIso8601String(),
      'catatan_persetujuan': catatanPersetujuan,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'karyawan': karyawan?.toJson(),
      'approved_by_l1_user': approverL1?.toJson(),
      'approved_by_l2_user': approverL2?.toJson(),
    };
  }
}