import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

import '../../../core/docx/docx_document_service.dart';
import '../../../core/docx/docx_draft_repository.dart';
import 'toolbar/word_editor_toolbar.dart';
import 'word_viewer_search.dart';
import 'word_viewer_viewport.dart';

class WordViewerPage extends StatefulWidget {
  final String path;
  final int? contentId;

  const WordViewerPage({
    super.key,
    required this.path,
    this.contentId,
  });

  @override
  State<WordViewerPage> createState() => _WordViewerPageState();
}

class _WordViewerPageState extends State<WordViewerPage> {
  final _service = DocxDocumentService.instance;
  final _drafts = DocxDraftRepository.instance;

  WordEditorController? _controller;
  Timer? _saveTimer;
  bool _dirty = false;
  bool _saving = false;
  bool _loading = true;
  String? _error;

  WordEditorController? get controller => _controller;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final draft = widget.contentId == null
          ? null
          : await _drafts.findByContentId(widget.contentId!);

      final source = draft?.draftPath ?? widget.path;

      final controller = await _service.openController(source);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });

      if (draft != null) {
        _dirty = true;
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _markDirty() {
    _dirty = true;
    _saveTimer?.cancel();

    _saveTimer = Timer(
      const Duration(seconds: 2),
      _saveDraft,
    );
  }

  Future<void> _saveDraft() async {
    final c = _controller;
    if (c == null || !_dirty || _saving) return;

    _saving = true;

    try {
      final bytes = await c.writeBytes();

      if (widget.contentId != null) {
        await _drafts.saveDraft(
          contentId: widget.contentId!,
          originalPath: widget.path,
          bytes: bytes,
        );
      }
    } finally {
      _saving = false;
    }
  }

  Future<void> _save() async {
    final c = _controller;
    if (c == null) return;

    setState(() {
      _saving = true;
    });

    try {
      final bytes = await c.writeBytes();

      await _service.writeAtomic(
        widget.path,
        bytes,
      );

      if (widget.contentId != null) {
        await _drafts.deleteDraft(
          widget.contentId!,
        );
      }

      _dirty = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<bool> _handleBack() async {
    if (!_dirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'Save your changes before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(
                  context,
                  false,
                );
                await _save();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _fitWidth() {
    final c = _controller;
    if (c == null) return;

    WordViewerViewport.fitWidth(
      c,
      resetScroll: false,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Word'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Unable to open document',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final c = _controller!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (await _handleBack() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.path.split('/').last,
          ),
          actions: [
            IconButton(
              tooltip: 'Find',
              onPressed: () => showSearch(
                context: context,
                delegate: WordViewerSearch(c),
              ),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: 'Fit width',
              onPressed: _fitWidth,
              icon: const Icon(Icons.fit_width),
            ),
            IconButton(
              tooltip: 'Save',
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
            ),
          ],
        ),
        body: Column(
          children: [
            WordEditorToolbar(
              controller: c,
              onFitPage: _fitWidth,
            ),
            Expanded(
              child: QudsWordEditor(
                controller: c,
                onChanged: _markDirty,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
