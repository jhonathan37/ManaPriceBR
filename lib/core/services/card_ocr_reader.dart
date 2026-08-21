import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'card_name_parser.dart';

class CardOcrResult {
  const CardOcrResult({required this.rawText, this.cardName});

  final String rawText;
  final String? cardName;
}

class CardOcrReader {
  CardOcrReader({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  Future<CardOcrResult> read(String imagePath) async {
    final input = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(input);
    final name = CardNameParser.clean(recognized.text);
    return CardOcrResult(
      rawText: recognized.text,
      cardName: name.isEmpty ? null : name,
    );
  }

  Future<String?> readCardName(String imagePath) async {
    final result = await read(imagePath);
    return result.cardName;
  }

  Future<void> dispose() => _recognizer.close();
}
