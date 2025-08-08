// Web stubs for ML Kit dependencies that don't work on web
import 'dart:typed_data';

// Stub classes for web compatibility
class TextRecognizer {
  void close() {}
  
  Future<RecognizedText> processImage(InputImage inputImage) async {
    // Return empty recognized text for web compatibility
    return const RecognizedText(text: '', blocks: []);
  }
}

class InputImage {
  static InputImage fromFile(dynamic file) {
    return InputImage._();
  }
  
  static InputImage fromBytes({
    required Uint8List bytes,
    required InputImageMetadata metadata,
  }) {
    return InputImage._();
  }
  
  InputImage._();
}

class InputImageMetadata {
  const InputImageMetadata({
    required this.size,
    required this.rotation,
    required this.format,
    required this.bytesPerRow,
  });
  
  final Size size;
  final InputImageRotation rotation;
  final InputImageFormat format;
  final int bytesPerRow;
}

class Size {
  const Size(this.width, this.height);
  final double width;
  final double height;
}

enum InputImageRotation { rotation0deg, rotation90deg, rotation180deg, rotation270deg }
enum InputImageFormat { nv21, yv12, yuv420, yuv_420_888, bgra8888 }

class RecognizedText {
  const RecognizedText({required this.text, required this.blocks});
  final String text;
  final List<TextBlock> blocks;
}

class TextBlock {
  const TextBlock({required this.text, required this.lines});
  final String text;
  final List<TextLine> lines;
}

class TextLine {
  const TextLine({required this.text});
  final String text;
}
