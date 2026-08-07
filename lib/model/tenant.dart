import 'paket_layanan.dart';
import 'kantor.dart';
import 'karyawan.dart';

class Tenant {
  final int? id;
  final int? paketId;
  final String? namaPerusahaan;
  final String? kodeTenant;
  final String? email;
  final String? nomorTelepon;
  final String? alamat;
  final String? logo;
  final bool statusAktif;
  final DateTime? tanggalKadaluarsa;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final PaketLayanan? paketLayanan;
  final List<Kantor>? kantors;
  final List<Karyawan>? karyawans;

  Tenant({
    this.id,
    this.paketId,
    this.namaPerusahaan,
    this.kodeTenant,
    this.email,
    this.nomorTelepon,
    this.alamat,
    this.logo,
    this.statusAktif = true,
    this.tanggalKadaluarsa,
    this.createdAt,
    this.updatedAt,
    this.paketLayanan,
    this.kantors,
    this.karyawans,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'] as int?,
      paketId: json['paket_id'] as int?,
      namaPerusahaan: json['nama_perusahaan'] as String?,
      kodeTenant: json['kode_tenant'] as String?,
      email: json['email'] as String?,
      nomorTelepon: json['nomor_telepon'] as String?,
      alamat: json['alamat'] as String?,
      logo: json['logo'] as String?,
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
      tanggalKadaluarsa: json['tanggal_kadaluarsa'] != null
          ? DateTime.tryParse(json['tanggal_kadaluarsa'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      paketLayanan: json['paket_layanan'] != null
          ? PaketLayanan.fromJson(json['paket_layanan'])
          : null,
      kantors: json['kantors'] != null
          ? (json['kantors'] as List)
              .map((e) => Kantor.fromJson(e))
              .toList()
          : null,
      karyawans: json['karyawans'] != null
          ? (json['karyawans'] as List)
              .map((e) => Karyawan.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paket_id': paketId,
      'nama_perusahaan': namaPerusahaan,
      'kode_tenant': kodeTenant,
      'email': email,
      'nomor_telepon': nomorTelepon,
      'alamat': alamat,
      'logo': logo,
      'status_aktif': statusAktif,
      'tanggal_kadaluarsa':
          tanggalKadaluarsa?.toIso8601String().split('T').first,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'paket_layanan': paketLayanan?.toJson(),
      'kantors': kantors?.map((e) => e.toJson()).toList(),
      'karyawans': karyawans?.map((e) => e.toJson()).toList(),
    };
  }
}