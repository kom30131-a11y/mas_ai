import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

import '../../../core/docx/docx_document_service.dart';
import '../../../core/docx/docx_draft_repository.dart';
import 'word_editor_toolbar.dart';
import 'word_viewer_hand_layer.dart';
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
  bool _autoFitScheduled = false;
  bool _handMode = false;

  double? _lastAutoFitWidth;
  double? _lastAutoFitPageWidth;

  String? _error;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      final draft = widget.contentId == null
          ? null
          : await _drafts.getDraft(widget.contentId!);

      final draftPath = draft?['draft_path'] as String?;
      final source = draftPath ?? widget.path;

      final controller = await _service.openController(
        path: source,
        config: const OfficeSurfaceConfig(
          mode: OfficeInteractionMode.editing,
          showRulers: false,
          interactiveRulers: false,
          enableUndo: true,
          textDirection: TextDirection.ltr,
          strings: OfficeStrings.english,
        ),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.addListener(_onControllerChanged);

      setState(() {
        _controller = controller;
        _loading = false;
        _dirty = draftPath != null;
        _handMode = false;
      });

      _scheduleAutoFit();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _onControllerChanged() {
    _markDirty();
    _scheduleAutoFit();
  }

  void _markDirty() {
    final controller = _controller;

    if (controller == null || !controller.isDirty) return;

    _dirty = true;
    _saveTimer?.cancel();

    _saveTimer = Timer(
      const Duration(seconds: 2),
      _saveDraft,
    );
  }

  void _scheduleAutoFit() {
    if (_autoFitScheduled) return;

    _autoFitScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFitScheduled = false;

      if (!mounted) return;

      final controller = _controller;
      if (controller == null) return;

      final width = controller.viewport.extent.width;
      if (width <= 0) return;

      final pages = controller.documentLaidOut.pages;
      if (pages.isEmpty) return;

      final index = controller.visiblePageIndex
          .clamp(0, pages.length - 1)
          .toInt();

      final page = pages[index];
      if (page.width <= 0) return;

      final widthChanged =
          _lastAutoFitWidth == null ||
          (_lastAutoFitWidth! - width).abs() > 0.5;

      final pageWidthChanged =
          _lastAutoFitPageWidth == null ||
          (_lastAutoFitPageWidth! - page.width).abs() > 0.01;

      if (!widthChanged && !pageWidthChanged) return;

      final fitted = WordViewerViewport.fitWidth(
        controller,
        width: width,
        resetScroll: false,
      );

      if (!fitted) return;

      _lastAutoFitWidth = width;
      _lastAutoFitPageWidth = page.width;
    });
  }

  void _toggleHandMode() {
    setState(() {
      _handMode = !_handMode;
    });
  }

  Future<void> _saveDraft() async {
    final controller = _controller;

    if (controller == null || !_dirty || _saving) return;
    if (widget.contentId == null) return;

    _saving = true;

    try {
      final bytes = await controller.saveBytesAsync();

      final draftPath = await _service.writeDraft(
        contentId: widget.contentId!,
        originalPath: widget.path,
        bytes: bytes,
      );

      await _drafts.saveDraft(
        contentId: widget.contentId!,
        draftPath: draftPath,
        originalPath: widget.path,
      );
    } finally {
      _saving = false;
    }
  }

  Future<bool> _save() async {
    final controller = _controller;

    if (controller == null) return false;

    if (mounted) {
      setState(() {
        _saving = true;
      });
    }

    try {
      final bytes = await controller.saveBytesAsync();

      await _service.writeAtomic(
        widget.path,
        bytes,
      );

      if (widget.contentId != null) {
        await _drafts.deleteDraft(
          widget.contentId!,
        );
      }

      controller.markClean();
      _dirty = false;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved'),
          ),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
          ),
        );
      }

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      } else {
        _saving = false;
      }
    }
  }

  Future<bool> _handleBack() async {
    if (!_dirty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text(
            'Save your changes before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Discard'),
            ),
            FilledButton(
              onPressed: () async {
                final saved = await _save();

                if (dialogContext.mounted) {
                  Navigator.pop(
                    dialogContext,
                    saved,
                  );
                }
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
    final controller = _controller;

    if (controller == null) return;

    WordViewerViewport.fitWidth(
      controller,
      resetScroll: false,
    );
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _controller?.removeListener(_onControllerChanged);
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

    final controller = _controller!;

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
              onPressed: () => WordViewerSearch.show(
                context,
                controller,
                replace: false,
              ),
              icon: const Icon(Icons.search),
            ),
            IconButton(
              tooltip: _handMode ? 'Edit' : 'Hand mode',
              onPressed: _toggleHandMode,
              icon: Icon(
                _handMode
                    ? Icons.edit_outlined
                    : Icons.pan_tool_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Fit width',
              onPressed: _fitWidth,
              icon: const Icon(Icons.fit_screen),
            ),
            IconButton(
              tooltip: 'Save',
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
            ),
          ],
        ),
        body: Column(
          children: [
            if (!_handMode)
              WordEditorToolbar(
                controller: controller,
                onFitPage: _fitWidth,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _scheduleAutoFit();

                  return WordViewerHandLayer(
                    controller: controller,
                    handMode: _handMode,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
