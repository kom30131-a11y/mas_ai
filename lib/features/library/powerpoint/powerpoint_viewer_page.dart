import 'dart:io';

import 'package:flutter/material.dart';
import 'package:microsoft_viewer/microsoft_viewer.dart';

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
  MicrosoftViewer? _viewer;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFile();
  }

  Future<void> _loadFile() async {
    try {
      final bytes = await File(widget.path).readAsBytes();

      if (!mounted) return;

      setState(() {
        _viewer = MicrosoftViewer(
          bytes,
          true,
          key: ValueKey(widget.path),
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to open PowerPoint file.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: _viewer ?? const SizedBox.shrink(),
    );
  }
}
