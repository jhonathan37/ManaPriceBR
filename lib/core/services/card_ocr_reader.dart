import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'card_name_parser.dart';

class CardOcrReader {
  CardOcrReader({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<String?> readCardName(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final name = CardNameParser.clean(recognized.text);
    return name.isEmpty ? null : name;
  }

  Future<void> dispose() => _recognizer.close();
}
