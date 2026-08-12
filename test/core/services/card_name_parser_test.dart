import 'package:flutter_test/flutter_test.dart';
import 'package:manaprice_br/core/services/card_name_parser.dart';

void main() {
  group('CardNameParser', () {
    test('returns a useful card name from OCR text', () {
      final result = CardNameParser.clean('Magic\nThe Gathering\nThe One Ring');
      expect(result, 'The One Ring');
    });

    test('normalizes repeated whitespace and punctuation', () {
      final result = CardNameParser.clean('  Lightning   Bolt!  ');
      expect(result, 'Lightning Bolt');
    });
  });
}
