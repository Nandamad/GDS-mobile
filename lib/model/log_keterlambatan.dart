import 'absensi.dart';
import 'karyawan.dart';

class LogKeterlambatan {
  final int? id;
  final int? tenantId;
  final int? absensiId;
  final int? karyawanId;
  final DateTime? tanggal;
  final int? menitKeterlambatan;
  final String? alasan;
  final bool dampakPayroll;
  final bool dampakKpi;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Absensi? absensi;
  final Karyawan? karyawan;

  LogKeterlambatan({
    this.id,
    this.tenantId,
    this.absensiId,
    this.karyawanId,
    this.tanggal,
    this.menitKeterlambatan,
    this.alasan,
    this.dampakPayroll = false,
    this.dampakKpi = false,
    this.createdAt,
    this.updatedAt,
    this.absensi,
    this.karyawan,
  });

  factory LogKeterlambatan.fromJson(Map<String, dynamic> json) {
    return LogKeterlambatan(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      absensiId: json['absensi_id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      tanggal: json['tanggal'] != null
          ? DateTime.tryParse(json['tanggal'])
          : null,
      menitKeterlambatan: json['menit_keterlambatan'] as int?,
      alasan: json['alasan'] as String?,
      dampakPayroll: json['dampak_payroll'] is bool
          ? json['dampak_payroll']
          : (json['dampak_payroll'] == 1 || json['dampak_payroll'] == '1'),
      dampakKpi: json['dampak_kpi'] is bool
          ? json['dampak_kpi']
          : (json['dampak_kpi'] == 1 || json['dampak_kpi'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      absensi:
          json['absensi'] != null ? Absensi.fromJson(json['absensi']) : null,
      karyawan: json['karyawan'] != null
          ? Karyawan.fromJson(json['karyawan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'absensi_id': absensiId,
      'karyawan_id': karyawanId,
      'tanggal': tanggal?.toIso8601String().split('T').first,
      'menit_keterlambatan': menitKeterlambatan,
      'alasan': alasan,
      'dampak_payroll': dampakPayroll,
      'dampak_kpi': dampakKpi,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'absensi': absensi?.toJson(),
      'karyawan': karyawan?.toJson(),
    };
  }
}