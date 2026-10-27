import 'package:flutter_test/flutter_test.dart';
import 'package:presensi_plus/ui/login_page.dart';

void main() {
  group('isValidLoginIdentifier', () {
    test('accepts valid email addresses', () {
      expect(isValidLoginIdentifier('employee@example.com'), isTrue);
      expect(isValidLoginIdentifier(' employee@example.co.id '), isTrue);
    });

    test('accepts phone numbers with supported formatting', () {
      expect(isValidLoginIdentifier('081234567890'), isTrue);
      expect(isValidLoginIdentifier('+62 812-3456-7890'), isTrue);
      expect(isValidLoginIdentifier('(021) 555-1234'), isTrue);
    });

    test('rejects usernames and malformed identifiers', () {
      expect(isValidLoginIdentifier('employee01'), isFalse);
      expect(isValidLoginIdentifier('employee@example'), isFalse);
      expect(isValidLoginIdentifier('12345'), isFalse);
      expect(isValidLoginIdentifier('+--12345678'), isFalse);
    });
  });
}
