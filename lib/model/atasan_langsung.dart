import 'karyawan.dart'; // Pastikan file karyawan.dart sudah ada

class AtasanLangsung {
  final int? id;
  final int? karyawanId;
  final int? atasanId;
  final DateTime? tanggalMulaiBerlaku;
  final DateTime? tanggalSelesaiBerlaku;
  final bool statusAktif;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Relasi (Optional, dimuat jika ada 'include' dari API)
  final Karyawan? bawahan;
  final Karyawan? atasan;

  AtasanLangsung({
    this.id,
    this.karyawanId,
    this.atasanId,
    this.tanggalMulaiBerlaku,
    this.tanggalSelesaiBerlaku,
    this.statusAktif = false, // Default false jika null dari JSON
    this.createdAt,
    this.updatedAt,
    this.bawahan,
    this.atasan,
  });

  // Method untuk mengubah data JSON (Map) menjadi Object AtasanLangsung
  factory AtasanLangsung.fromJson(Map<String, dynamic> json) {
    return AtasanLangsung(
      id: json['id'] as int?,
      karyawanId: json['karyawan_id'] as int?,
      atasanId: json['atasan_id'] as int?,
      
      // Parsing String Date (YYYY-MM-DD) dari Laravel menjadi DateTime Dart
      tanggalMulaiBerlaku: json['tanggal_mulai_berlaku'] != null
          ? DateTime.tryParse(json['tanggal_mulai_berlaku'])
          : null,
      tanggalSelesaiBerlaku: json['tanggal_selesai_berlaku'] != null
          ? DateTime.tryParse(json['tanggal_selesai_berlaku'])
          : null,
          
      // Parsing Boolean
      statusAktif: json['status_aktif'] is bool
          ? json['status_aktif']
          : (json['status_aktif'] == 1 || json['status_aktif'] == '1'),
          
      // Parsing Timestamps (ISO8601)
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
          
      // Parsing Relasi jika data nested tersedia di JSON
      bawahan: json['bawahan'] != null
          ? Karyawan.fromJson(json['bawahan'])
          : null,
      atasan: json['atasan'] != null
          ? Karyawan.fromJson(json['atasan'])
          : null,
    );
  }

  // Method untuk mengubah Object AtasanLangsung kembali menjadi Map (snake_case)
  // Sering digunakan saat mengirim data (POST/PUT) ke API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'karyawan_id': karyawanId,
      'atasan_id': atasanId,
      // Mengirim kembali format date YYYY-MM-DD saja
      'tanggal_mulai_berlaku': tanggalMulaiBerlaku?.toIso8601String().split('T').first,
      'tanggal_selesai_berlaku': tanggalSelesaiBerlaku?.toIso8601String().split('T').first,
      'status_aktif': statusAktif,
      // Timestamps biasanya tidak dikirim manual saat Create/Update, tapi ditambahkan untuk kelengkapan
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      // toJson relasi (jika perlu dikirim balik)
      'bawahan': bawahan?.toJson(),
      'atasan': atasan?.toJson(),
    };
  }
}