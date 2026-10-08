import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final value = type.toLowerCase();

    if (value == 'pdf') {
      return PdfViewerPage(
        title: title,
        path: path,
      );
    }

    if (_isWord(value)) {
      return WordViewerPage(
        title: title,
        path: path,
      );
    }

    if (_isPowerPoint(value)) {
      return PowerPointViewerPage(
        title: title,
        path: path,
      );
    }

    if (_isImage(value)) {
      return ImageViewerPage(
        title: title,
        path: path,
      );
    }

    if (extractedText != null &&
        extractedText!.trim().isNotEmpty) {
      return _textViewer(
        context,
        extractedText!,
      );
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

  bool _isWord(String value) {
    return value == 'word' ||
        value == 'doc' ||
        value == 'docx';
  }

  bool _isPowerPoint(String value) {
    return value == 'ppt' ||
        value == 'pptx' ||
        value == 'powerpoint';
  }

  bool _isImage(String value) {
    return value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp' ||
        value == 'heic' ||
        value == 'image';
  }

  Widget _textViewer(
    BuildContext context,
    String text,
  ) {
    final isArabic = RegExp(
      r'[\u0600-\u06FF]',
    ).hasMatch(text);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Directionality(
        textDirection:
            isArabic
                ? TextDirection.rtl
                : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            textAlign:
                isArabic
                    ? TextAlign.right
                    : TextAlign.left,
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
