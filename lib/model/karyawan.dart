import 'divisi.dart';
import 'jabatan.dart';
import 'kantor.dart';
import 'shift.dart';
import 'absensi.dart';
import 'izin_cuti.dart';
import 'lembur.dart';
import 'jadwal_shift_karyawan.dart';
import 'log_keterlambatan.dart';
import 'atasan_langsung.dart';

class Karyawan {
  final int? id;
  final int? tenantId;
  final int? userId;
  final int? divisiId;
  final int? jabatanId;
  final int? kantorId;
  final int? shiftId;
  final String? nip;
  final String? namaLengkap;
  final String? email;
  final String? nomorTelepon;
  final String? alamat;
  final String? foto;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Master Data Relations (belongsTo)
  final Divisi? divisi;
  final Jabatan? jabatan;
  final Kantor? kantor;
  final Shift? shift;

  // Transaksional Relations (hasMany)
  final List<Absensi>? absensis;
  final List<IzinCuti>? izinCutis;
  final List<Lembur>? lemburs;
  final List<JadwalShiftKaryawan>? jadwalShifts;
  final List<LogKeterlambatan>? logKeterlambatans;
  final List<AtasanLangsung>? atasan;

  Karyawan({
    this.id,
    this.tenantId,
    this.userId,
    this.divisiId,
    this.jabatanId,
    this.kantorId,
    this.shiftId,
    this.nip,
    this.namaLengkap,
    this.email,
    this.nomorTelepon,
    this.alamat,
    this.foto,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
    this.divisi,
    this.jabatan,
    this.kantor,
    this.shift,
    this.absensis,
    this.izinCutis,
    this.lemburs,
    this.jadwalShifts,
    this.logKeterlambatans,
    this.atasan,
  });

  factory Karyawan.fromJson(Map<String, dynamic> json) {
    return Karyawan(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      userId: json['user_id'] as int?,
      divisiId: json['divisi_id'] as int?,
      jabatanId: json['jabatan_id'] as int?,
      kantorId: json['kantor_id'] as int?,
      shiftId: json['shift_id'] as int?,
      nip: json['nip'] as String?,
      namaLengkap: json['nama_lengkap'] as String?,
      email: json['email'] as String?,
      nomorTelepon: json['nomor_telepon'] as String?,
      alamat: json['alamat'] as String?,
      foto: json['foto'] as String?,
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,

      // Master Data Parsing
      divisi: json['divisi'] != null ? Divisi.fromJson(json['divisi']) : null,
      jabatan: json['jabatan'] != null ? Jabatan.fromJson(json['jabatan']) : null,
      kantor: json['kantor'] != null ? Kantor.fromJson(json['kantor']) : null,
      shift: json['shift'] != null ? Shift.fromJson(json['shift']) : null,

      // Transaksional Parsing
      absensis: json['absensis'] != null
          ? (json['absensis'] as List)
              .map((e) => Absensi.fromJson(e))
              .toList()
          : null,
      izinCutis: json['izin_cutis'] != null
          ? (json['izin_cutis'] as List)
              .map((e) => IzinCuti.fromJson(e))
              .toList()
          : null,
      lemburs: json['lemburs'] != null
          ? (json['lemburs'] as List)
              .map((e) => Lembur.fromJson(e))
              .toList()
          : null,
      jadwalShifts: json['jadwal_shifts'] != null
          ? (json['jadwal_shifts'] as List)
              .map((e) => JadwalShiftKaryawan.fromJson(e))
              .toList()
          : null,
      logKeterlambatans: json['log_keterlambatans'] != null
          ? (json['log_keterlambatans'] as List)
              .map((e) => LogKeterlambatan.fromJson(e))
              .toList()
          : null,
      atasan: json['atasan'] != null
          ? (json['atasan'] as List)
              .map((e) => AtasanLangsung.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'user_id': userId,
      'divisi_id': divisiId,
      'jabatan_id': jabatanId,
      'kantor_id': kantorId,
      'shift_id': shiftId,
      'nip': nip,
      'nama_lengkap': namaLengkap,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'alamat': alamat,
      'foto': foto,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'divisi': divisi?.toJson(),
      'jabatan': jabatan?.toJson(),
      'kantor': kantor?.toJson(),
      'shift': shift?.toJson(),
      'absensis': absensis?.map((e) => e.toJson()).toList(),
      'izin_cutis': izinCutis?.map((e) => e.toJson()).toList(),
      'lemburs': lemburs?.map((e) => e.toJson()).toList(),
      'jadwal_shifts': jadwalShifts?.map((e) => e.toJson()).toList(),
      'log_keterlambatans': logKeterlambatans?.map((e) => e.toJson()).toList(),
      'atasan': atasan?.map((e) => e.toJson()).toList(),
    };
  }
}