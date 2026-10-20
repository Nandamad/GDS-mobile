import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_plus/ui/tentang_aplikasi_page.dart';

void main() {
  testWidgets('opens privacy policy and terms from about screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: TentangAplikasiScreen()));

    await tester.scrollUntilVisible(
      find.text('Kebijakan Privasi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kebijakan Privasi'));
    await tester.pumpAndSettle();

    expect(find.text('Kebijakan Privasi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Peran Para Pihak'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Peran Para Pihak'), findsOneWidget);
    expect(find.textContaining('Pengendali Data Pribadi'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Syarat & Ketentuan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Syarat & Ketentuan'));
    await tester.pumpAndSettle();

    expect(find.text('Syarat & Ketentuan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Penerimaan Ketentuan'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Penerimaan Ketentuan'), findsOneWidget);
    expect(find.textContaining('PT. Generasi Digital Sinergi'), findsWidgets);
  });
}
