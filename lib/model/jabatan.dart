int? _safeInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _safeBool(dynamic value) {
  if (value is bool) return value;
  if (value == null) return true;
  final text = value.toString().toLowerCase();
  return text == '1' || text == 'true' || text == 'yes';
}

String? _safeString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

class Jabatan {
  final int? id;
  final int? tenantId;
  final String? namaJabatan;
  final int? levelTingkat;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Jabatan({
    this.id,
    this.tenantId,
    this.namaJabatan,
    this.levelTingkat,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Jabatan.fromJson(Map<String, dynamic> json) {
    return Jabatan(
      id: _safeInt(json['id']),
      tenantId: _safeInt(json['tenant_id']),
      namaJabatan: _safeString(json['nama_jabatan']),
      levelTingkat: _safeInt(json['level_tingkat']),
      statusAktif: _safeBool(json['status_aktif']),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Method untuk mengubah Object Jabatan kembali menjadi Map (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'nama_jabatan': namaJabatan,
      'level_tingkat': levelTingkat,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
