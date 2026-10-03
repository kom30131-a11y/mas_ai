import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';
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

  Uint8List? officeBytes;
  String? error;

  bool get isWord {
    final type = widget.type.toLowerCase();

    return type == 'docx' ||
        type == 'word' ||
        widget.path.toLowerCase().endsWith('.docx');
  }

  bool get isPowerPoint {
    final type = widget.type.toLowerCase();

    return type == 'pptx' ||
        type == 'powerpoint' ||
        type == 'ppt' ||
        widget.path.toLowerCase().endsWith('.pptx');
  }

  bool get isPdf {
    final type = widget.type.toLowerCase();

    return type == 'pdf' ||
        widget.path.toLowerCase().endsWith('.pdf');
  }

  @override
  void initState() {
    super.initState();

    if (isPdf) {
      pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.path),
      );
    } else if (isWord || isPowerPoint) {
      _loadOfficeFile();
    }
  }

  Future<void> _loadOfficeFile() async {
    try {
      final file = File(widget.path);

      if (!await file.exists()) {
        throw Exception('File is no longer available.');
      }

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        officeBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isPdf && pdfController != null) {
      return _buildPdfViewer();
    }

    if (isWord || isPowerPoint) {
      return _buildOfficeViewer();
    }

    if (_isImage()) {
      return _buildImageViewer();
    }

    return _buildTextViewer();
  }

  Widget _buildPdfViewer() {
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

  Widget _buildOfficeViewer() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _officeBody(),
    );
  }

  Widget _officeBody() {
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to open file.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (officeBytes == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return MicrosoftViewer(
      officeBytes!,
      false,
    );
  }

  Widget _buildImageViewer() {
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

  Widget _buildTextViewer() {
    final text = widget.extractedText?.trim() ?? '';

    if (text.isEmpty) {
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

    final direction = _detectTextDirection(text);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Directionality(
        textDirection: direction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            text,
            textAlign: direction == TextDirection.rtl
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

  bool _isImage() {
    final type = widget.type.toLowerCase();
    final path = widget.path.toLowerCase();

    return [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'image',
    ].contains(type) ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic');
  }

  TextDirection _detectTextDirection(String text) {
    for (final rune in text.runes) {
      if (_isArabicRune(rune)) {
        return TextDirection.rtl;
      }

      if (_isLatinRune(rune)) {
        return TextDirection.ltr;
      }
    }

    return TextDirection.ltr;
  }

  bool _isArabicRune(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  bool _isLatinRune(int rune) {
    return (rune >= 0x0041 && rune <= 0x005A) ||
        (rune >= 0x0061 && rune <= 0x007A);
  }
}
