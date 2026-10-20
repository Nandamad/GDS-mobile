import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_plus/ui/app_version_text.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.fluttercommunity.plus/package_info');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('shows version from package metadata', (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'getAll');
          return <String, dynamic>{
            'appName': 'PresensiPlus+',
            'packageName': 'com.example.mobile',
            'version': '2.3.4',
            'buildNumber': '9',
            'buildSignature': '',
            'installerStore': null,
          };
        });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppVersionText(
            prefix: 'v',
            style: TextStyle(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('v2.3.4'), findsOneWidget);
  });
}
