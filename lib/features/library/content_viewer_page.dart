import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import 'image/image_viewer_page.dart';
import 'pdf/pdf_viewer_page.dart';
import 'powerpoint/powerpoint_viewer_page.dart';
import 'word/word_viewer_page.dart';

class ContentViewerPage extends StatelessWidget {
  final String title;
  final String path;
  final String type;
  final String? extractedText;

  const ContentViewerPage({
    super.key,
    required this.title,
    required this.path,
    required this.type,
    this.extractedText,
  });

  bool get isWord {
    final value = type.toLowerCase();

    return value == 'word' ||
        value == 'doc' ||
        value == 'docx';
  }

  bool get isPowerPoint {
    final value = type.toLowerCase();

    return value == 'ppt' ||
        value == 'pptx' ||
        value == 'powerpoint';
  }

  bool get isImage {
    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'image',
    ].contains(type.toLowerCase());
  }

  Future<void> _openOfficeFile(BuildContext context) async {
    final result = await OpenFilex.open(path);

    if (!context.mounted) return;

    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No compatible app was found to open this file.\n'
            '${result.message}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = type.toLowerCase();

    if (value == 'pdf') {
      return PdfViewerPage(
        title: title,
        path: path,
      );
    }

    if (isImage) {
      return ImageViewerPage(
        title: title,
        path: path,
      );
    }

    if (isWord) {
      return WordViewerPage(
        title: title,
        path: path,
        onOpen: () => _openOfficeFile(context),
      );
    }

    if (isPowerPoint) {
      return PowerPointViewerPage(
        title: title,
        path: path,
        onOpen: () => _openOfficeFile(context),
      );
    }

    if (extractedText != null &&
        extractedText!.trim().isNotEmpty) {
      return _textViewer(context, extractedText!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: const Center(
        child: Text(
          'Preview is not available for this file.',
        ),
      ),
    );
  }

  Widget _textViewer(BuildContext context, String text) {
    final isArabic = RegExp(
      r'[\u0600-\u06FF]',
    ).hasMatch(text);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Directionality(
        textDirection:
            isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            textAlign:
                isArabic ? TextAlign.right : TextAlign.left,
            style: const TextStyle(
              fontSize: 16,
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}
