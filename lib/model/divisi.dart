class Divisi {
  final int? id;
  final int? tenantId;
  final String? namaDivisi;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Divisi({
    this.id,
    this.tenantId,
    this.namaDivisi,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory Divisi.fromJson(Map<String, dynamic> json) {
    return Divisi(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      namaDivisi: json['nama_divisi'] as String?,
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'nama_divisi': namaDivisi,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}