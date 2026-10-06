import 'dart:io';

import 'package:docx_viewer_plus/docx_viewer_plus.dart';
import 'package:flutter/material.dart';

class WordViewerPage extends StatefulWidget {
  final String title;
  final String path;

  const WordViewerPage({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<WordViewerPage> createState() => _WordViewerPageState();
}

class _WordViewerPageState extends State<WordViewerPage> {
  final _key = GlobalKey<DocxViewerWidgetState>();

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      final file = File(widget.path);

      final saved = await _key.currentState?.save(
        outputPath: file.path,
      );

      if (!mounted) return;

      if (saved != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Word document saved'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Save failed: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _share() async {
    try {
      final bytes =
          await _key.currentState?.getDocxBytes();

      if (bytes == null) return;

      final temp = File(
        '${Directory.systemTemp.path}/'
        '${widget.title.replaceAll(RegExp(r'[\\\\/:*?"<>|]'), '_')}.docx',
      );

      await temp.writeAsBytes(bytes);

      if (!mounted) return;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(temp.path),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Share failed: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final arabic =
        Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save),
          ),
          IconButton(
            tooltip: 'Share',
            onPressed: _share,
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: DocxViewerWidget(
        key: _key,
        filePath: widget.path,
        config: DocxViewerConfig(
          toolbarPosition: ToolbarPosition.bottom,
          forceTextDirection:
              arabic
                  ? TextDirection.rtl
                  : TextDirection.ltr,
          strings: arabic
              ? DocxViewerStrings.arabic
              : null,
        ),
      ),
    );
  }
}
