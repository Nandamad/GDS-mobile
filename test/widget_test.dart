// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:presensi_plus/services/image_url_service.dart';

void main() {
  test('resolves private attendance photo paths to the API route', () {
    final resolved = ImageUrlService.resolve('/absensi/foto masuk.jpg');

    expect(resolved, isNotNull);
    final uri = Uri.parse(resolved!);
    expect(uri.path, '/api/absensi/foto');
    expect(uri.queryParameters['path'], 'absensi/foto masuk.jpg');
  });

  test('resolves private leave documents to the API route', () {
    final resolved = ImageUrlService.resolve('dokumen_cuti/surat dokter.pdf');

    expect(resolved, isNotNull);
    final uri = Uri.parse(resolved!);
    expect(uri.path, '/api/dokumen/cuti');
    expect(uri.queryParameters['path'], 'dokumen_cuti/surat dokter.pdf');
  });

  test('preserves already routed protected document URLs', () {
    expect(
      ImageUrlService.resolve('/api/dokumen/cuti?path=dokumen_cuti%2Fsurat.pdf'),
      'https://devabs.yukliat.com/api/dokumen/cuti?path=dokumen_cuti%2Fsurat.pdf',
    );
  });

  test('resolves ordinary files to public storage', () {
    expect(
      ImageUrlService.resolve('avatars/karyawan.png'),
      'https://devabs.yukliat.com/storage/avatars/karyawan.png',
    );
  });
}
