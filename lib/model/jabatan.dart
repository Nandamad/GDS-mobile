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
    this.statusAktif = true, // Default true jika null dari JSON
    this.createdAt,
    this.updatedAt,
  });

  // Method untuk mengubah data JSON (Map) menjadi Object Jabatan
  factory Jabatan.fromJson(Map<String, dynamic> json) {
    return Jabatan(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      namaJabatan: json['nama_jabatan'] as String?,
      levelTingkat: json['level_tingkat'] as int?,
      
      // Handling tinyint(1) atau boolean dari MySQL/Laravel
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
          
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
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