import 'shift.dart';

class JamKerja {
  final int? id;
  final int? tenantId;
  final int? shiftId;
  final String? namaJamKerja;
  final String? jamMasuk;
  final String? jamPulang;
  final String? jamMulaiIstirahat;
  final String? jamSelesaiIstirahat;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Relasi
  final Shift? shift;

  JamKerja({
    this.id,
    this.tenantId,
    this.shiftId,
    this.namaJamKerja,
    this.jamMasuk,
    this.jamPulang,
    this.jamMulaiIstirahat,
    this.jamSelesaiIstirahat,
    this.createdAt,
    this.updatedAt,
    this.shift,
  });

  factory JamKerja.fromJson(Map<String, dynamic> json) {
    return JamKerja(
      id: json['id'] as int?,
      tenantId: json['tenant_id'] as int?,
      shiftId: json['shift_id'] as int?,
      namaJamKerja: json['nama_jam_kerja'] as String?,
      jamMasuk: json['jam_masuk'] as String?,
      jamPulang: json['jam_pulang'] as String?,
      jamMulaiIstirahat: json['jam_mulai_istirahat'] as String?,
      jamSelesaiIstirahat: json['jam_selesai_istirahat'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
      shift: json['shift'] != null ? Shift.fromJson(json['shift']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'shift_id': shiftId,
      'nama_jam_kerja': namaJamKerja,
      'jam_masuk': jamMasuk,
      'jam_pulang': jamPulang,
      'jam_mulai_istirahat': jamMulaiIstirahat,
      'jam_selesai_istirahat': jamSelesaiIstirahat,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'shift': shift?.toJson(),
    };
  }

  String get formattedSchedule {
    if (jamMasuk == null || jamPulang == null) {
      return 'Belum diatur';
    }

    // Ambil jam:menit (potong detik jika dari DB berformat 08:00:00)
    final start = jamMasuk!.length >= 5 ? jamMasuk!.substring(0, 5) : jamMasuk!;
    final end = jamPulang!.length >= 5
        ? jamPulang!.substring(0, 5)
        : jamPulang!;

    // Hitung total jam kerja
    int durasiJam = 0;
    try {
      final startParts = start.split(':').map(int.parse).toList();
      final endParts = end.split(':').map(int.parse).toList();

      final startTime = DateTime(2026, 1, 1, startParts[0], startParts[1]);
      var endTime = DateTime(2026, 1, 1, endParts[0], endParts[1]);

      // Handle jika shift melewati tengah malam (misal 22:00 - 06:00)
      if (endTime.isBefore(startTime)) {
        endTime = endTime.add(const Duration(days: 1));
      }

      durasiJam = endTime.difference(startTime).inHours;
    } catch (_) {}

    return '$start - $end WIB ($durasiJam Jam)';
  }
}