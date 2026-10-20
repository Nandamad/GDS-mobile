import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_plus/ui/bantuan_faq_page.dart';

void main() {
  testWidgets('shows distinct HRD and app support paths', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BantuanFaqScreen(
          userProfile: {
            'name': 'Ayu',
            'karyawan': {'id': 12, 'nip': 'KRY-012'},
            'tenant': {
              'email': 'hrd@perusahaan.co.id',
              'nomor_telepon': '081234567890',
            },
          },
        ),
      ),
    );

    expect(find.text('Hubungi HRD'), findsOneWidget);
    expect(
      find.text(
        'Untuk urusan cuti, lembur, koreksi presensi, dan data kepegawaian.',
      ),
      findsOneWidget,
    );
    expect(find.text('hrd@perusahaan.co.id'), findsOneWidget);
    expect(find.text('081234567890'), findsOneWidget);
    expect(find.text('Dukungan Aplikasi'), findsOneWidget);
    expect(
      find.text(
        'Untuk kendala teknis seperti error, GPS/kamera, login, atau bug aplikasi.',
      ),
      findsOneWidget,
    );
    expect(find.text('presensiplus.id@gmail.com'), findsOneWidget);
    expect(
      tester
          .widget<ElevatedButton>(
            find.ancestor(
              of: find.text('Chat HRD via WhatsApp'),
              matching: find.byType(ElevatedButton),
            ),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('does not offer HRD WhatsApp when tenant phone is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BantuanFaqScreen(
          userProfile: {
            'tenant': {'email': 'hrd@perusahaan.co.id'},
          },
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text('Kontak WhatsApp HRD belum tersedia'),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Dukungan Aplikasi'), findsOneWidget);
  });
}
