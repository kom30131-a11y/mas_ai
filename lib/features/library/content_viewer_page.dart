import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
    final lower = type.toLowerCase();

    if (lower == 'pdf') {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SfPdfViewer.file(File(path)),
      );
    }

    if ([
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'image',
    ].contains(lower)) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: InteractiveViewer(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (extractedText != null &&
        extractedText!.trim().isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            extractedText!,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(
        child: Text('Preview is not available for this file.'),
      ),
    );
  }
}
