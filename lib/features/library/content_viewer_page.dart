import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class ContentViewerPage extends StatefulWidget {
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
  State<ContentViewerPage> createState() =>
      _ContentViewerPageState();
}

class _ContentViewerPageState
    extends State<ContentViewerPage> {
  PdfControllerPinch? pdfController;

  @override
  void initState() {
    super.initState();

    if (widget.type.toLowerCase() == 'pdf') {
      pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.path),
      );
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type.toLowerCase();

    if (type == 'pdf' && pdfController != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: PdfViewPinch(
          controller: pdfController!,
          minScale: 1,
          maxScale: 5,
          builders: PdfViewPinchBuilders(
            documentLoaderBuilder: (_) =>
                const Center(
              child: CircularProgressIndicator(),
            ),
            pageLoaderBuilder: (_) =>
                const Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (_, error) =>
                Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to open PDF.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if ([
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'image',
    ].contains(type)) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.file(
              File(widget.path),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    if (widget.extractedText != null &&
        widget.extractedText!.trim().isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            widget.extractedText!,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: const Center(
        child: Text(
          'Preview is not available for this file.',
        ),
      ),
    );
  }
}
