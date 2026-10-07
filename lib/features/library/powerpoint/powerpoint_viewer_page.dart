import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

class PowerPointViewerPage extends StatefulWidget {
  final String title;
  final String path;

  const PowerPointViewerPage({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  State<PowerPointViewerPage> createState() =>
      _PowerPointViewerPageState();
}

class _PowerPointViewerPageState
    extends State<PowerPointViewerPage> {
  bool _opening = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _openFile();
  }

  Future<void> _openFile() async {
    try {
      final file = File(widget.path);

      if (!await file.exists()) {
        throw Exception('PowerPoint file not found.');
      }

      final result = await OpenFilex.open(file.path);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _error =
              'Unable to open PowerPoint file.\n${result.message}';
          _opening = false;
        });
        return;
      }

      setState(() => _opening = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to open PowerPoint file.\n$e';
        _opening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _opening
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : const Center(
                  child: Text(
                    'PowerPoint opened in the installed Office application.',
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }
}
