import 'dart:io';

import 'package:archive/archive.dart';
import 'package:docx_dart/docx_dart.dart' as docx;
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:xml/xml.dart';

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

String? documentText;
String? error;

@override
void initState() {
super.initState();

final type = widget.type.toLowerCase().trim();

if (type == 'pdf') {
  pdfController = PdfControllerPinch(
    document: PdfDocument.openFile(widget.path),
  );
} else if (type == 'docx' || type == 'word') {
  _loadWord();
} else if (
    type == 'pptx' ||
    type == 'ppt' ||
    type == 'powerpoint'
) {
  _loadPowerPoint();
}

}

Future<void> _loadWord() async {
try {
final file = File(widget.path);

  if (!await file.exists()) {
    throw Exception('Word file was not found.');
  }

  final document = docx.loadDocxDocument(widget.path);
  final buffer = StringBuffer();

  for (final paragraph in document.paragraphs) {
    final text = paragraph.text.trim();

    if (text.isNotEmpty) {
      buffer.writeln(text);
      buffer.writeln();
    }
  }

  var result = buffer.toString().trim();

  if (result.isEmpty &&
      widget.extractedText != null &&
      widget.extractedText!.trim().isNotEmpty) {
    result = widget.extractedText!.trim();
  }

  if (!mounted) return;

  setState(() {
    documentText = result;
  });
} catch (e) {
  if (!mounted) return;

  setState(() {
    error = e.toString();
  });
}

}

Future<void> _loadPowerPoint() async {
try {
final file = File(widget.path);

  if (!await file.exists()) {
    throw Exception('PowerPoint file was not found.');
  }

  final bytes = await file.readAsBytes();

  if (bytes.isEmpty) {
    throw Exception('PowerPoint file is empty.');
  }

  final archive = ZipDecoder().decodeBytes(bytes);

  final slides = archive.files
      .where(
        (file) =>
            file.isFile &&
            RegExp(
              r'^ppt/slides/slide\d+\.xml$',
              caseSensitive: false,
            ).hasMatch(file.name),
      )
      .toList();

  slides.sort(
    (a, b) => _slideNumber(a.name).compareTo(
      _slideNumber(b.name),
    ),
  );

  if (slides.isEmpty) {
    throw Exception(
      'No PowerPoint slides were found.',
    );
  }

  final buffer = StringBuffer();

  for (var i = 0; i < slides.length; i++) {
    final slide = slides[i];

    final xmlText = String.fromCharCodes(
      slide.content,
    );

    if (xmlText.trim().isEmpty) {
      continue;
    }

    final document = XmlDocument.parse(xmlText);

    final texts = <String>[];

    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.localName == 't') {
        final text = element.innerText.trim();

        if (text.isNotEmpty) {
          texts.add(text);
        }
      }
    }

    if (texts.isEmpty) {
      continue;
    }

    buffer.writeln('Slide ${i + 1}');
    buffer.writeln();

    for (final text in texts) {
      buffer.writeln(text);
    }

    buffer.writeln();
    buffer.writeln();
  }

  var result = buffer.toString().trim();

  if (result.isEmpty &&
      widget.extractedText != null &&
      widget.extractedText!.trim().isNotEmpty) {
    result = widget.extractedText!.trim();
  }

  if (!mounted) return;

  setState(() {
    documentText = result;
  });
} catch (e) {
  if (!mounted) return;

  setState(() {
    error = e.toString();
  });
}

}

int _slideNumber(String name) {
final match = RegExp(
r'slide(\d+).xml$',
caseSensitive: false,
).firstMatch(name);

if (match == null) {
  return 0;
}

return int.tryParse(match.group(1)!) ?? 0;

}

@override
void dispose() {
pdfController?.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
final type = widget.type.toLowerCase().trim();

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
    body: _documentBody('Word'),
  );
}

if (
    type == 'pptx' ||
    type == 'ppt' ||
    type == 'powerpoint'
) {
  return Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: _documentBody('PowerPoint'),
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

Widget _documentBody(String format) {
if (error != null) {
return Center(
child: Padding(
padding: const EdgeInsets.all(24),
child: Text(
'Unable to open $format file.\n$error',
textAlign: TextAlign.center,
),
),
);
}

if (documentText == null) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}

if (documentText!.trim().isEmpty) {
  return Center(
    child: Text(
      'This $format file contains no readable text.',
      textAlign: TextAlign.center,
    ),
  );
}

return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: SelectableText(
    documentText!,
    style: const TextStyle(
      fontSize: 16,
      height: 1.6,
    ),
  ),
);

}
}
