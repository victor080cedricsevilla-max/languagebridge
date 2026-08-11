import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Camera OCR wrapper.
///
/// Captures (or picks) an image and extracts its text with Google ML Kit's
/// on-device text recognizer. Works for any Latin-script text, which covers
/// English, Filipino, Cebuano, Ilocano, and the other supported languages.
class OcrService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  /// Picks an image from [source], runs OCR, and returns the recognized text.
  /// Returns `null` if the user cancelled, or an empty string if no text was
  /// found. Throws if the image can't be read.
  Future<String?> scanText(ImageSource source) async {
    final file = await _picker.pickImage(source: source, imageQuality: 90);
    if (file == null) return null; // user cancelled

    final input = InputImage.fromFilePath(file.path);
    final recognized = await _recognizer.processImage(input);
    // Collapse the recognizer's line breaks into spaces for a cleaner phrase.
    return recognized.text.replaceAll('\n', ' ').trim();
  }

  void dispose() => _recognizer.close();
}
