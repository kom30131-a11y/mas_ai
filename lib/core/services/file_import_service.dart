import 'dart:io';

import 'package:docx_dart/docx_dart.dart' as docx;
import 'package:file_picker/file_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../database/database_repository.dart';

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

    switch (extension) {
      case 'txt':
        extractedText = await _extractTextFromTxt(path);
        break;

      case 'pdf':
        extractedText = await _extractTextFromPdf(path);
        break;

      case 'docx':
        extractedText = await _extractTextFromDocx(path);
        break;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
      case 'heic':
        extractedText = await _extractTextFromImage(path);
        break;
    }

    final importedFile = ImportedFile(
      fileName: file.name,
      path: path,
      extension: extension,
      extractedText: extractedText,
    );

    await _saveImportedFile(importedFile);

    return importedFile;
  }

  Future<void> _saveImportedFile(
    ImportedFile file,
  ) async {
    final now = DateTime.now().toIso8601String();

    final contentId = await DatabaseRepository.instance.insertContent({
      'title': file.fileName,
      'type': file.extension ?? 'unknown',
      'content': file.extractedText ?? '',
      'file_path': file.path,
      'original_file_name': file.fileName,
      'created_at': now,
    });

    await DatabaseRepository.instance.insertFile({
      'content_id': contentId,
      'file_name': file.fileName,
      'file_path': file.path,
      'mime_type': _mimeType(file.extension),
      'file_size': await File(file.path).length(),
      'extracted_text': file.extractedText,
      'created_at': now,
    });
  }

  String? _mimeType(String? extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return null;
    }
  }

  Future<String> _extractTextFromTxt(String path) async {
    return File(path).readAsString();
  }

  Future<String> _extractTextFromPdf(String path) async {
    final bytes = await File(path).readAsBytes();
    final document = PdfDocument(inputBytes: bytes);

    try {
      return PdfTextExtractor(document).extractText();
    } finally {
      document.dispose();
    }
  }

  Future<String> _extractTextFromDocx(String path) async {
    final document = docx.loadDocxDocument(path);

    final buffer = StringBuffer();

    for (final paragraph in document.paragraphs) {
      final text = paragraph.text.trim();

      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }

    return buffer.toString().trim();
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
}
