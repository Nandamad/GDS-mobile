class PaketLayanan {
  final int? id;
  final String? namaPaket;
  final String? deskripsi;
  final double? harga;
  final int? durasiBulan;
  final int? maksimalKaryawan;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaketLayanan({
    this.id,
    this.namaPaket,
    this.deskripsi,
    this.harga,
    this.durasiBulan,
    this.maksimalKaryawan,
    this.statusAktif = true,
    this.createdAt,
    this.updatedAt,
  });

  factory PaketLayanan.fromJson(Map<String, dynamic> json) {
    return PaketLayanan(
      id: json['id'] as int?,
      namaPaket: json['nama_paket'] as String?,
      deskripsi: json['deskripsi'] as String?,
      harga: json['harga'] != null
          ? double.tryParse(json['harga'].toString())
          : null,
      durasiBulan: json['durasi_bulan'] as int?,
      maksimalKaryawan: json['maksimal_karyawan'] as int?,
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
      'nama_paket': namaPaket,
      'deskripsi': deskripsi,
      'harga': harga,
      'durasi_bulan': durasiBulan,
      'maksimal_karyawan': maksimalKaryawan,
      'status_aktif': statusAktif,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}