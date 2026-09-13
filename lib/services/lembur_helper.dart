/// Helper untuk menghitung durasi lembur dalam menit dari data API.
///
/// Prioritas:
/// 1. `estimasi_jam` (jika ada) → estimasi_jam * 60
/// 2. `durasi_lembur_menit` (jika ada) → langsung pakai
/// 3. Hitung dari selisih `jam_mulai`/`jam_selesai` atau `jam_mulai_lembur`/`jam_selesai_lembur`
/// 4. Default 60 menit jika semua data tidak tersedia
int hitungDurasiLemburMenit(Map<String, dynamic>? data) {
  if (data == null) return 60;

  // 1. Dari estimasi_jam
  if (data['estimasi_jam'] != null) {
    final jam = int.tryParse(data['estimasi_jam'].toString()) ?? 0;
    if (jam > 0) return jam * 60;
  }

  // 2. Dari durasi_lembur_menit
  if (data['durasi_lembur_menit'] != null) {
    final menit = int.tryParse(data['durasi_lembur_menit'].toString()) ?? 0;
    if (menit > 0) return menit;
  }

  // 3. Hitung dari selisih jam_mulai & jam_selesai
  final mulaiStr = data['jam_mulai'] ?? data['jam_mulai_lembur'];
  final selesaiStr = data['jam_selesai'] ?? data['jam_selesai_lembur'];

  if (mulaiStr != null && selesaiStr != null) {
    try {
      DateTime? mulai;
      DateTime? selesai;

      // Coba parse sebagai ISO 8601 (datetime penuh)
      mulai = DateTime.tryParse(mulaiStr.toString());
      selesai = DateTime.tryParse(selesaiStr.toString());

      // Jika parse gagal, coba sebagai format HH:mm
      if (mulai == null && mulaiStr.toString().contains(':')) {
        final parts = mulaiStr.toString().split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          mulai = DateTime(now.year, now.month, now.day,
              int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
        }
      }
      if (selesai == null && selesaiStr.toString().contains(':')) {
        final parts = selesaiStr.toString().split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          selesai = DateTime(now.year, now.month, now.day,
              int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
        }
      }

      if (mulai != null && selesai != null) {
        final diff = selesai.difference(mulai).inMinutes;
        if (diff > 0) return diff;
      }
    } catch (_) {
      // Jika parsing gagal, lanjut ke default
    }
  }

  // 4. Default 60 menit
  return 60;
}
