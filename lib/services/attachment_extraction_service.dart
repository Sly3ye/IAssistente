import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AttachmentExtractionResult {
  const AttachmentExtractionResult({
    required this.text,
    required this.kind,
    required this.note,
  });

  final String text;
  final String kind;
  final String note;
}

class AttachmentExtractionService {
  Future<AttachmentExtractionResult> extractTextFromFile({
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    final extension = _extension(fileName);

    if (_isTextExtension(extension)) {
      final text = await _readText(filePath: filePath, bytes: bytes);
      return AttachmentExtractionResult(
        text: text,
        kind: 'text',
        note: 'Testo estratto da $fileName',
      );
    }

    if (extension == 'pdf') {
      final pdfBytes = await _readBytes(filePath: filePath, bytes: bytes);
      final text = _extractPdfText(pdfBytes);
      return AttachmentExtractionResult(
        text: text,
        kind: 'pdf',
        note: 'Testo estratto da PDF $fileName',
      );
    }

    if (_isImageExtension(extension)) {
      final text = await _extractImageText(
        fileName: fileName,
        filePath: filePath,
        bytes: bytes,
      );
      return AttachmentExtractionResult(
        text: text,
        kind: 'image',
        note: 'OCR estratto da immagine $fileName',
      );
    }

    return AttachmentExtractionResult(
      text: '',
      kind: 'unknown',
      note: 'Tipo file non supportato: .$extension',
    );
  }

  Future<String> _readText({String? filePath, Uint8List? bytes}) async {
    if (bytes != null) {
      return String.fromCharCodes(bytes);
    }
    if (filePath != null && await File(filePath).exists()) {
      return File(filePath).readAsString();
    }
    return '';
  }

  Future<Uint8List> _readBytes({String? filePath, Uint8List? bytes}) async {
    if (bytes != null) return bytes;
    if (filePath != null && await File(filePath).exists()) {
      return File(filePath).readAsBytes();
    }
    return Uint8List(0);
  }

  String _extractPdfText(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final text = extractor.extractText();
      document.dispose();
      return text.trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _extractImageText({
    required String fileName,
    String? filePath,
    Uint8List? bytes,
  }) async {
    String? usablePath = filePath;

    if ((usablePath == null || usablePath.isEmpty) && bytes != null) {
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$fileName';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes);
      usablePath = tempPath;
    }

    if (usablePath == null || usablePath.isEmpty) {
      return '';
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(usablePath);
      final recognized = await recognizer.processImage(inputImage);
      return recognized.text.trim();
    } catch (_) {
      return '';
    } finally {
      recognizer.close();
    }
  }

  String _extension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index <= 0 || index == fileName.length - 1) return '';
    return fileName.substring(index + 1).toLowerCase();
  }

  bool _isTextExtension(String ext) {
    return ext == 'txt' ||
        ext == 'md' ||
        ext == 'json' ||
        ext == 'csv' ||
        ext == 'yaml' ||
        ext == 'yml';
  }

  bool _isImageExtension(String ext) {
    return ext == 'png' ||
        ext == 'jpg' ||
        ext == 'jpeg' ||
        ext == 'webp' ||
        ext == 'bmp';
  }
}
