import 'karyawan.dart';

class Kantor {
  final int? id;
  final int? tenantId;
  final String? namaKantor;
  final String? alamat;
  final double? latitude;
  final double? longitude;
  final int? radiusMeter;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi (hasMany karyawans)
  final List<Karyawan>? karyawans;

  Kantor({
    this.id,
    this.tenantId,
    this.namaKantor,
    this.alamat,
    this.latitude,
    this.longitude,
    this.radiusMeter,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
    this.karyawans,
  });

  factory Kantor.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final tenantId = json['tenant_id'];
    final namaKantor = json['nama_kantor'];
    final alamat = json['alamat'];

    return Kantor(
      id: id is int ? id : int.tryParse(id.toString()),
      tenantId: tenantId is int ? tenantId : int.tryParse(tenantId.toString()),
      namaKantor: namaKantor is String ? namaKantor : namaKantor?.toString(),
      alamat: alamat is String ? alamat : alamat?.toString(),
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      radiusMeter: json['radius_toleransi_meter'] != null
          ? int.tryParse(json['radius_toleransi_meter'].toString())
          : null,
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
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
      'tenant_id': tenantId,
      'nama_kantor': namaKantor,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meter': radiusMeter,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'karyawans': karyawans?.map((e) => e.toJson()).toList(),
    };
  }
}
