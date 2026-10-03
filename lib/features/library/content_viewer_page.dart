import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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

  bool get isWord {
    final type = widget.type.toLowerCase();
    return type == 'word' ||
        type == 'doc' ||
        type == 'docx';
  }

  bool get isPowerPoint {
    final type = widget.type.toLowerCase();
    return type == 'ppt' ||
        type == 'pptx' ||
        type == 'powerpoint';
  }

  bool get isImage {
    final type = widget.type.toLowerCase();
    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'image',
    ].contains(type);
  }

  Future<void> _openOfficeFile() async {
    final result = await OpenFilex.open(widget.path);

    if (!mounted) return;

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
    final type = widget.type.toLowerCase();

    if (type == 'pdf' && pdfController != null) {
      return _pdfViewer();
    }

    if (isImage) {
      return _imageViewer();
    }

    if (isWord || isPowerPoint) {
      return _officeViewer();
    }

    if (widget.extractedText != null &&
        widget.extractedText!.trim().isNotEmpty) {
      return _textViewer(
        widget.extractedText!,
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

  Widget _pdfViewer() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: PdfViewPinch(
        controller: pdfController!,
        minScale: 1,
        maxScale: 5,
        builders:
            PdfViewPinchBuilders<DefaultBuilderOptions>(
          options: const DefaultBuilderOptions(),
          documentLoaderBuilder: (_) =>
              const Center(
            child: CircularProgressIndicator(),
          ),
          pageLoaderBuilder: (_) =>
              const Center(
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

  Widget _imageViewer() {
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

  Widget _officeViewer() {
    final format =
        isWord ? 'Word' : 'PowerPoint';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                isWord
                    ? Icons.description_outlined
                    : Icons.slideshow_outlined,
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                format,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Open the original file with the '
                'compatible Android application.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _openOfficeFile,
                icon: const Icon(
                  Icons.open_in_new,
                ),
                label: const Text(
                  'Open file',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textViewer(String text) {
    final isArabic = RegExp(
      r'[\u0600-\u06FF]',
    ).hasMatch(text);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Directionality(
        textDirection: isArabic
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            textAlign: isArabic
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
