import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:quds_office_editor/quds_office_editor.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/docx/docx_document_service.dart';
import '../../../core/docx/docx_draft_repository.dart';
import '../../../core/storage/library_storage_service.dart';
import 'word_editor_toolbar.dart';
import 'word_viewer_search.dart';
import 'word_viewer_viewport.dart';

enum _ExitChoice { save, discard, cancel }

class WordViewerPage extends StatefulWidget {
  final String title;
  final String path;
  final int? contentId;

  const WordViewerPage({
    super.key,
    required this.title,
    required this.path,
    this.contentId,
  });

  @override
  State<WordViewerPage> createState() => _WordViewerPageState();
}

class _WordViewerPageState extends State<WordViewerPage>
    with WidgetsBindingObserver {
  final _docx = DocxDocumentService.instance;
  final _drafts = DocxDraftRepository.instance;
  final _repo = DatabaseRepository.instance;
  final _storage = LibraryStorageService.instance;

  WordEditorController? _controller;
  Timer? _draftTimer;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;
  bool _selecting = false;
  bool _singlePageView = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _controller?.removeListener(_onChanged);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_saveDraft());
    }
  }

  Future<void> _load() async {
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final dark = Theme.of(context).brightness == Brightness.dark;

    try {
      await OfficeHostFonts.ensureRegistered();
      await _drafts.ensureReady();

      final sourcePath = await _resolveSourcePath();
      final controller = await _docx.openController(
        path: sourcePath,
        config: OfficeSurfaceConfig(
          mode: OfficeInteractionMode.viewing,
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          strings: rtl ? OfficeStrings.arabic : OfficeStrings.english,
          theme: dark ? OfficeTheme.dark : OfficeTheme.light,
          showRulers: false,
          showFindChrome: false,
          enableUndo: true,
        ),
      );

      controller.addListener(_onChanged);

      controller.onFindRequested = () {
        if (!_editing) _setSelecting(true);
        unawaited(
          WordViewerSearch.show(
            context,
            controller,
            replace: false,
          ),
        );
      };

      controller.onReplaceRequested = () {
        if (!_editing) _setSelecting(true);
        unawaited(
          WordViewerSearch.show(
            context,
            controller,
            replace: true,
          ),
        );
      };

      controller.onFindResult = (hit) {
        if (hit == null) return;
        if (!_editing) _setSelecting(true);
        controller.revealFindHit(hit);
        controller.refresh();
      };

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });

      _schedulePageFit(controller, resetScroll: true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<String> _resolveSourcePath() async {
    final original = File(widget.path);
    final id = widget.contentId;

    if (id == null) return widget.path;

    final draft = await _drafts.getDraft(id);
    if (draft == null) return widget.path;

    final draftPath = draft['draft_path']?.toString();

    if (draftPath == null || draftPath.isEmpty) {
      await _drafts.deleteDraft(id);
      return widget.path;
    }

    final draftFile = File(draftPath);

    if (!await draftFile.exists()) {
      await _drafts.deleteDraft(id);
      return widget.path;
    }

    if (!await original.exists()) {
      _showRecoveredMessage();
      return draftPath;
    }

    final sourceDate = await original.lastModified();
    final draftDate = await draftFile.lastModified();

    if (!draftDate.isAfter(sourceDate)) {
      await _drafts.deleteDraft(id);
      await _docx.deleteFile(draftPath);
      return widget.path;
    }

    final recover = await _showDraftDialog();

    if (recover) return draftPath;

    await _drafts.deleteDraft(id);
    await _docx.deleteFile(draftPath);
    return widget.path;
  }

  void _enterEditing() {
    final controller = _controller;
    if (controller == null || _editing) return;

    controller.setMode(OfficeInteractionMode.editing);
    controller.attachInput();

    if (mounted) {
      setState(() {
        _editing = true;
        _selecting = false;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_controller, controller)) return;
      controller.attachInput();
      controller.refresh();
    });

    _schedulePageFit(controller);
  }

  Future<void> _finishEditing() async {
    final controller = _controller;
    if (controller == null || !_editing) return;

    if (controller.isDirty) {
      final saved = await _save();
      if (!saved || !mounted) return;
    }

    controller.detachInput();
    controller.setMode(OfficeInteractionMode.viewing);

    if (mounted) {
      setState(() {
        _editing = false;
        _selecting = false;
      });
    }

    _schedulePageFit(controller);
  }

  void _setSelecting(bool value) {
    final controller = _controller;
    if (controller == null || _editing) return;

    if (value) {
      controller.setMode(OfficeInteractionMode.selecting);
    } else {
      controller.setMode(OfficeInteractionMode.viewing);
    }

    if (mounted) {
      setState(() => _selecting = value);
    }

    controller.refresh();
  }

  void _toggleSelecting() {
    _setSelecting(!_selecting);
  }

  void _schedulePageFit(
    WordEditorController controller, {
    bool resetScroll = false,
  }) {
    var attempts = 0;

    void attempt(Duration _) {
      if (!mounted || !identical(_controller, controller)) return;

      final fitted = WordViewerViewport.fitCurrentPage(
        controller,
        resetScroll: resetScroll && attempts == 0,
      );

      attempts++;

      if (!fitted && attempts < 8) {
        WidgetsBinding.instance.addPostFrameCallback(attempt);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback(attempt);
  }

  void _showRecoveredMessage() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recovered local Word draft.')),
      );
    });
  }

  Future<bool> _showDraftDialog() async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recover unsaved Word draft?'),
        content: const Text(
          'A newer local draft was found for this document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Open original'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Recover draft'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  void _openSearch({required bool replace}) {
    final controller = _controller;
    if (controller == null || !controller.canFind) return;

    if (!_editing) _setSelecting(true);

    unawaited(
      WordViewerSearch.show(
        context,
        controller,
        replace: replace,
      ),
    );
  }

  void _onChanged() {
    final controller = _controller;

    if (controller == null || !controller.isDirty || _saving) return;

    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(seconds: 2),
      () => unawaited(_saveDraft()),
    );
  }

  Future<void> _saveDraft() async {
    final id = widget.contentId;
    final controller = _controller;

    if (id == null ||
        controller == null ||
        !controller.isDirty ||
        _saving) {
      return;
    }

    try {
      final bytes = await controller.saveBytesAsync();
      final draftPath = await _docx.writeDraft(
        contentId: id,
        originalPath: widget.path,
        bytes: bytes,
      );

      await _drafts.saveDraft(
        contentId: id,
        draftPath: draftPath,
        originalPath: widget.path,
      );
    } catch (_) {}
  }

  Future<bool> _save() async {
    final controller = _controller;

    if (controller == null || _saving) return false;

    if (!mounted) return false;
    setState(() => _saving = true);

    try {
      final bytes = await controller.saveBytesAsync();
      await _docx.writeAtomic(widget.path, bytes);

      final id = widget.contentId;
      if (id != null) {
        await _repo.updateContent(
          contentId: id,
          filePath: widget.path,
        );
        await _repo.updateFilePath(
          contentId: id,
          filePath: widget.path,
        );

        final hash = await _storage.hashFile(widget.path);
        final files = await _repo.getFiles(contentId: id);

        for (final file in files) {
          final fileId = file['id'];
          if (fileId is int) {
            await _repo.updateFileHash(
              fileId: fileId,
              hash: hash,
            );
          }
        }

        final draft = await _drafts.getDraft(id);
        final draftPath = draft?['draft_path']?.toString();

        await _drafts.deleteDraft(id);

        if (draftPath != null && draftPath.isNotEmpty) {
          await _docx.deleteFile(draftPath);
        }
      }

      controller.markClean();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Word document saved.')),
        );
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final bytes = await controller.saveBytesAsync();
      final path = await _docx.exportCopy(
        fileName: p.basename(widget.path),
        bytes: bytes,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported to:\n$path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _share() async {
    final controller = _controller;
    if (controller == null) return;

    try {
      final bytes = await controller.saveBytesAsync();
      final safeName = widget.title.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final file = File(
        '${Directory.systemTemp.path}/$safeName.docx',
      );

      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  Future<void> _handleBack() async {
    final controller = _controller;

    if (controller == null || !controller.isDirty) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final choice = await showDialog<_ExitChoice>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'Save your Word changes before leaving?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ExitChoice.cancel,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ExitChoice.discard,
            ),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _ExitChoice.save,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted ||
        choice == null ||
        choice == _ExitChoice.cancel) {
      return;
    }

    if (choice == _ExitChoice.save) {
      if (await _save() && mounted) Navigator.pop(context);
      return;
    }

    final id = widget.contentId;
    if (id != null) {
      final draft = await _drafts.getDraft(id);
      final draftPath = draft?['draft_path']?.toString();

      await _drafts.deleteDraft(id);

      if (draftPath != null && draftPath.isNotEmpty) {
        await _docx.deleteFile(draftPath);
      }
    }

    controller.markClean();
    if (mounted) Navigator.pop(context);
  }

  Widget _surface(WordEditorController controller) {
    final editor = QudsWordEditor(
      controller: controller,
      toolbarBuilder: _editing
          ? (_, value) => WordEditorToolbar(
                controller: value,
                onFitPage: () =>
                    WordViewerViewport.fitCurrentPage(value),
              )
          : (_, value) => const SizedBox.shrink(),
    );

    if (_editing) return editor;

    return Stack(
      fit: StackFit.expand,
      children: [
        editor,
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _pageStatus(controller),
        ),
      ],
    );
  }

  Widget _pageStatus(WordEditorController controller) {
    final count = controller.pageCount;
    final page = count == 0 ? 0 : controller.visiblePageIndex + 1;

    return SafeArea(
      top: false,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Material(
            elevation: 3,
            borderRadius: BorderRadius.circular(20),
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Previous page',
                    visualDensity: VisualDensity.compact,
                    onPressed: page <= 1
                        ? null
                        : () => WordViewerViewport.jumpToPage(
                              controller,
                              -1,
                            ),
                    icon: const Icon(
                      Icons.keyboard_arrow_up,
                    ),
                  ),
                  Text(
                    'Page $page / $count',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    visualDensity: VisualDensity.compact,
                    onPressed: count == 0 || page >= count
                        ? null
                        : () => WordViewerViewport.jumpToPage(
                              controller,
                              1,
                            ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _error ?? 'Could not open DOCX.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final controller = _controller!;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return PopScope(
          canPop: !controller.isDirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && controller.isDirty) {
              unawaited(_handleBack());
            }
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                controller.isDirty
                    ? '${widget.title} *'
                    : widget.title,
              ),
              actions: [
                if (_editing)
                  if (_saving)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: 'Save',
                      onPressed: controller.isDirty
                          ? () => unawaited(_save())
                          : null,
                      icon: const Icon(Icons.save),
                    ),
                IconButton(
                  tooltip: 'Find',
                  onPressed: controller.canFind
                      ? () => _openSearch(replace: false)
                      : null,
                  icon: const Icon(Icons.search),
                ),
                if (!_editing)
                  IconButton(
                    tooltip: 'Fit page to screen',
                    onPressed: () =>
                        _schedulePageFit(controller),
                    icon: const Icon(Icons.fit_screen),
                  ),
                if (!_editing)
                  IconButton(
                    tooltip: _selecting
                        ? 'Finish text selection'
                        : 'Select text',
                    onPressed: _toggleSelecting,
                    icon: Icon(
                      _selecting
                          ? Icons.highlight_off
                          : Icons.select_all,
                    ),
                  ),
                if (_editing)
                  IconButton(
                    tooltip: 'Find and replace',
                    onPressed: controller.canFind
                        ? () => _openSearch(replace: true)
                        : null,
                    icon: const Icon(Icons.find_replace),
                  ),
                IconButton(
                  tooltip: 'Export',
                  onPressed: () => unawaited(_export()),
                  icon: const Icon(Icons.file_download),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: () => unawaited(_share()),
                  icon: const Icon(Icons.share),
                ),
                const SizedBox(width: 4),
                _editing
                    ? TextButton.icon(
                        onPressed: _saving
                            ? null
                            : () => unawaited(_finishEditing()),
                        icon: const Icon(Icons.check),
                        label: const Text('Done'),
                      )
                    : TextButton.icon(
                        onPressed: _enterEditing,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                      ),
                const SizedBox(width: 4),
              ],
            ),
            body: _surface(controller),
          ),
        );
      },
    );
  }
}
