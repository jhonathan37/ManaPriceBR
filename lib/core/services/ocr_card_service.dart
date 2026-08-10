import 'card_name_parser.dart';

class OcrCardService {
  const OcrCardService._();

  /// Converts raw OCR output into the best candidate card name.
  /// The camera/ML Kit adapter can feed its recognized text here.
  static String recognizeName(String recognizedText) {
    return CardNameParser.clean(recognizedText);
  }
}
