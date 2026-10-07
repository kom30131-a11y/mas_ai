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
  bool _started = false;
  bool _rtl = false;
  bool _dark = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    _dark = Theme.of(context).brightness == Brightness.dark;

    if (!_started) {
      _started = true;
      unawaited(_load());
      return;
    }

    final controller = _controller;
    if (controller == null) return;

    controller.syncConfig(
      controller.config.copyWith(
        theme: _dark ? OfficeTheme.dark : OfficeTheme.light,
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        strings: _rtl ? OfficeStrings.arabic : OfficeStrings.english,
      ),
    );
    controller.onSurfaceDirectionChanged();
    controller.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftTimer?.cancel();
    _controller?.removeListener(_onChanged);

    try {
      _controller?.detachInput();
    } catch (_) {}

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
    try {
      await OfficeHostFonts.ensureRegistered();
      await _drafts.ensureReady();

      final sourcePath = await _resolveSourcePath();

      final controller = await _docx.openController(
        path: sourcePath,
        config: OfficeSurfaceConfig(
          mode: OfficeInteractionMode.viewing,
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          strings: _rtl ? OfficeStrings.arabic : OfficeStrings.english,
          theme: _dark ? OfficeTheme.dark : OfficeTheme.light,
          showRulers: false,
          showFormulaBar: false,
          showGridHeaders: false,
          showGridlines: false,
          showSlideHandles: false,
          enableUndo: true,
          autofocus: false,
          adaptiveChrome: true,
          showFindChrome: false,
          interactiveRulers: false,
          showNavigationPane: false,
          showNotesPane: false,
        ),
      );

      controller.onFindRequested = () {
        unawaited(
          WordViewerSearch.show(
            context,
            controller,
            replace: false,
          ),
        );
      };

      controller.onReplaceRequested = () {
        if (_editing) {
          unawaited(
            WordViewerSearch.show(
              context,
              controller,
              replace: true,
            ),
          );
        }
      };

      controller.addListener(_onChanged);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });

      _scheduleFitWidth(controller, resetScroll: true);
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
        content: const Text('A newer local draft was found for this document.'),
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
    if (id == null || controller == null || !controller.isDirty || _saving) return;

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
      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<bool> _save() async {
    final controller = _controller;
    if (controller == null || _saving) return false;

    setState(() => _saving = true);

    try {
      final bytes = await controller.saveBytesAsync();
      await _docx.writeAtomic(widget.path, bytes);

      final id = widget.contentId;
      if (id != null) {
        await _repo.updateContent(contentId: id, filePath: widget.path);
        await _repo.updateFilePath(contentId: id, filePath: widget.path);

        final hash = await _storage.hashFile(widget.path);
        final files = await _repo.getFiles(contentId: id);

        for (final file in files) {
          final fileId = file['id'];
          if (fileId is int) {
            await _repo.updateFileHash(fileId: fileId, hash: hash);
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
      if (mounted) {
        setState(() => _saving = false);
      }
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
      final safeName = widget.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final file = File('${Directory.systemTemp.path}/$safeName.docx');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }

  void _scheduleFitWidth(WordEditorController controller, {bool resetScroll = false}) {
    var attempts = 0;
    void fit() {
      if (!mounted || !identical(_controller, controller)) return;
      final fitted = WordViewerViewport.fitWidth(controller, resetScroll: resetScroll);
      if (fitted || attempts >= 8) return;
      attempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => fit());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => fit());
  }

  void _fitWidth() {
    final controller = _controller;
    if (controller == null) return;
    _scheduleFitWidth(controller, resetScroll: false);
  }

  void _enterEditing() {
    final controller = _controller;
    if (controller == null || _editing) return;

    _selecting = false;
    controller.setMode(OfficeInteractionMode.editing);
    controller.attachInput();

    if (mounted) setState(() => _editing = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_controller, controller)) return;
      controller.refresh();
    });
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
    _fitWidth();
  }

  void _enterSelecting() {
    final controller = _controller;
    if (controller == null || _editing) return;
    controller.setMode(OfficeInteractionMode.selecting);
    if (mounted) setState(() => _selecting = true);
    controller.refresh();
  }

  void _finishSelecting() {
    final controller = _controller;
    if (controller == null || !_selecting) return;
    controller.setMode(OfficeInteractionMode.viewing);
    if (mounted) setState(() => _selecting = false);
    controller.refresh();
  }

  Future<void> _showSearch({required bool replace}) async {
    final controller = _controller;
    if (controller == null) return;
    await WordViewerSearch.show(context, controller, replace: replace);
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
        content: const Text('Save your Word changes before leaving?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ExitChoice.discard),
            child: const Text('Discard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _ExitChoice.save),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (!mounted || choice == null || choice == _ExitChoice.cancel) return;

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
    return Stack(
      children: [
        QudsWordEditor(
          controller: controller,
          toolbarBuilder: (_, value) {
            if (!_editing) return const SizedBox.shrink();
            return WordEditorToolbar(controller: value, onFitPage: _fitWidth);
          },
        ),
        if (!_editing)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'fit_width_fab',
              tooltip: 'Fit Width',
              onPressed: _fitWidth,
              child: const Icon(Icons.fit_screen),
            ),
          ),
      ],
    );
  }

  List<Widget> _appBarActions(WordEditorController controller) {
    final isDirty = controller.isDirty;
    final statusWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Tooltip(
          message: isDirty ? 'Unsaved modifications' : 'All changes saved',
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDirty ? Colors.orangeAccent : Colors.greenAccent,
            ),
          ),
        ),
      ),
    );

    if (_editing) {
      return [
        statusWidget,
        if (_saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else
          IconButton(
            tooltip: 'Save',
            onPressed: isDirty ? () => unawaited(_save()) : null,
            icon: const Icon(Icons.save),
          ),
        IconButton(
          tooltip: 'Find',
          onPressed: () => unawaited(_showSearch(replace: false)),
          icon: const Icon(Icons.search),
        ),
        IconButton(
          tooltip: 'Find and replace',
          onPressed: () => unawaited(_showSearch(replace: true)),
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
        IconButton(
          tooltip: 'Done',
          onPressed: _saving ? null : () => unawaited(_finishEditing()),
          icon: const Icon(Icons.check),
        ),
      ];
    }

    return [
      statusWidget,
      IconButton(
        tooltip: 'Find',
        onPressed: () => unawaited(_showSearch(replace: false)),
        icon: const Icon(Icons.search),
      ),
      IconButton(
        tooltip: 'Fit width',
        onPressed: _fitWidth,
        icon: const Icon(Icons.fit_screen),
      ),
      if (_selecting)
        IconButton(
          tooltip: 'View',
          onPressed: _finishSelecting,
          icon: const Icon(Icons.visibility),
        )
      else
        IconButton(
          tooltip: 'Select text',
          onPressed: _enterSelecting,
          icon: const Icon(Icons.select_all),
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
      IconButton(
        tooltip: 'Edit',
        onPressed: _enterEditing,
        icon: const Icon(Icons.edit),
      ),
    ];
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
            child: Text(_error ?? 'Could not open DOCX.', textAlign: TextAlign.center),
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
              title: Text(controller.isDirty ? '${widget.title} *' : widget.title),
              actions: _appBarActions(controller),
            ),
            body: _surface(controller),
          ),
        );
      },
    );
  }
}
