import 'package:flutter/material.dart';

import 'image/image_viewer_page.dart';
import 'pdf/pdf_viewer_page.dart';
import 'powerpoint/powerpoint_viewer_page.dart';
import 'word/word_viewer_page.dart';

class ContentViewerPage extends StatelessWidget {
  final String path;
  final String type;
  final String? extractedText;

  const ContentViewerPage({
    super.key,
    required this.path,
    required this.type,
    this.extractedText,
  });

  @override
  Widget build(BuildContext context) {
    final value = type.toLowerCase();

    if (value == 'pdf') {
      return PdfViewerPage(path: path);
    }

    if (value == 'word' ||
        value == 'doc' ||
        value == 'docx') {
      return WordViewerPage(path: path);
    }

    if (value == 'ppt' ||
        value == 'pptx' ||
        value == 'powerpoint') {
      return PowerPointViewerPage(path: path);
    }

    if (value == 'jpg' ||
        value == 'jpeg' ||
        value == 'png' ||
        value == 'webp' ||
        value == 'heic' ||
        value == 'image') {
      return ImageViewerPage(path: path);
    }

    if (extractedText != null &&
        extractedText!.trim().isNotEmpty) {
      final isArabic = RegExp(
        r'[\u0600-\u06FF]',
      ).hasMatch(extractedText!);

      return Scaffold(
        appBar: AppBar(
          title: Text(path.split('/').last),
        ),
        body: Directionality(
          textDirection:
              isArabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              extractedText!,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(path.split('/').last),
      ),
      body: const Center(
        child: Text(
          'Preview is not available for this file.',
        ),
      ),
    );
  }
}
