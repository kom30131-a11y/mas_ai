import 'dart:io';

import 'package:docx_dart/docx_dart.dart' as docx;
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
  State<ContentViewerPage> createState() => _ContentViewerPageState();
}

class _ContentViewerPageState extends State<ContentViewerPage> {
  PdfControllerPinch? pdfController;
  String? wordText;
  String? error;

  @override
  void initState() {
    super.initState();

    final type = widget.type.toLowerCase();

    if (type == 'pdf') {
      pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.path),
      );
    } else if (type == 'docx' || type == 'word') {
      _loadWord();
    }
  }

  Future<void> _loadWord() async {
    try {
      final document = docx.loadDocxDocument(widget.path);
      final buffer = StringBuffer();

      for (final paragraph in document.paragraphs) {
        final text = paragraph.text.trim();

        if (text.isNotEmpty) {
          buffer.writeln(text);
          buffer.writeln();
        }
      }

      if (!mounted) return;

      setState(() {
        wordText = buffer.toString().trim();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    }
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
          builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
            options: const DefaultBuilderOptions(),
            documentLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            pageLoaderBuilder: (_) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorBuilder: (_, error) => Center(
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

    if (type == 'docx' || type == 'word') {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _wordBody(),
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

  Widget _wordBody() {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to open Word file.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (wordText == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (wordText!.trim().isEmpty) {
      return const Center(
        child: Text(
          'This Word file contains no readable text.',
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        wordText!,
        style: const TextStyle(
          fontSize: 16,
          height: 1.6,
        ),
      ),
    );
  }
}
