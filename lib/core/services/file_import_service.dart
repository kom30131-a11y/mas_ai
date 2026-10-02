import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ImportedFile {
  final String fileName;
  final String path;
  final String? extension;
  final String? extractedText;

  const ImportedFile({
    required this.fileName,
    required this.path,
    this.extension,
    this.extractedText,
  });

  bool get hasExtractedText =>
      extractedText != null && extractedText!.trim().isNotEmpty;
}

class FileImportService {
  FileImportService._();

  static final FileImportService instance = FileImportService._();

  Future<ImportedFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final file = result.files.single;
    final path = file.path!;
    final extension = file.extension?.toLowerCase();

    String? extractedText;

    if (extension == 'txt') {
      extractedText = await File(path).readAsString();
    } else if (_isImage(extension)) {
      extractedText = await _extractTextFromImage(path);
    }

    return ImportedFile(
      fileName: file.name,
      path: path,
      extension: extension,
      extractedText: extractedText,
    );
  }

  Future<String> _extractTextFromImage(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizer = TextRecognizer();

    try {
      final result = await recognizer.processImage(inputImage);
      return result.text;
    } finally {
      await recognizer.close();
    }
  }

  bool _isImage(String? extension) {
    return extension == 'jpg' ||
        extension == 'jpeg' ||
        extension == 'png' ||
        extension == 'webp' ||
        extension == 'heic';
  }
}
