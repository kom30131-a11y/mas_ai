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

      // تهيئة المتحكم بخصائص تطابق تجربة مايكروسوفت وورد الاحترافية
      final controller = await _docx.openController(
        path: sourcePath,
        config: OfficeSurfaceConfig(
          mode: OfficeInteractionMode.viewing,
          textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
          strings: _rtl ? OfficeStrings.arabic : OfficeStrings.english,
          theme: _dark ? OfficeTheme.dark : OfficeTheme.light,
          showRulers: true, // إظهار المساطر تماماً مثل مايكروسوفت وورد
          showFormulaBar: false,
          showGridHeaders: false,
          showGridlines: true,
          showSlideHandles: false,
          enableUndo: true,
          autofocus: false,
          adaptiveChrome: true,
          showFindChrome: false,
          interactiveRulers: true,
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
      return draftPath;
    }

    final sourceDate = await original.lastModified();
    final draftDate = await draftFile.lastModified();

    if (!draftDate.isAfter(sourceDate)) {
      await _drafts.deleteDraft(id);
      await _docx.deleteFile(draftPath);
      return widget.path;
    }

    return draftPath;
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
        await _drafts.deleteDraft(id);
      }

      controller.markClean();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ التعديلات بنجاح.')),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل الحفظ: $e')),
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
        SnackBar(content: Text('تم التصدير إلى: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل التصدير: $e')),
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
        SnackBar(content: Text('فشل المشاركة: $e')),
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
              tooltip: 'ملائمة العرض',
              onPressed: _fitWidth,
              child: const Icon(Icons.fit_screen),
            ),
          ),
      ],
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
            child: Text(_error ?? 'تعذر فتح المستند.', textAlign: TextAlign.center),
          ),
        ),
      );
    }

    final controller = _controller!;

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text(controller.isDirty ? '${widget.title} *' : widget.title),
            actions: [
              IconButton(
                tooltip: 'بحث',
                onPressed: () => unawaited(WordViewerSearch.show(context, controller, replace: false)),
                icon: const Icon(Icons.search),
              ),
              IconButton(
                tooltip: 'ملائمة العرض',
                onPressed: _fitWidth,
                icon: const Icon(Icons.fit_screen),
              ),
              if (_editing) ...[
                IconButton(
                  tooltip: 'حفظ',
                  onPressed: controller.isDirty ? () => unawaited(_save()) : null,
                  icon: const Icon(Icons.save),
                ),
                IconButton(
                  tooltip: 'إنهاء التعديل',
                  onPressed: _saving ? null : () => unawaited(_finishEditing()),
                  icon: const Icon(Icons.check),
                ),
              ] else ...[
                IconButton(
                  tooltip: 'تعديل',
                  onPressed: _enterEditing,
                  icon: const Icon(Icons.edit),
                ),
              ],
              IconButton(
                tooltip: 'تصدير',
                onPressed: () => unawaited(_export()),
                icon: const Icon(Icons.file_download),
              ),
              IconButton(
                tooltip: 'مشاركة',
                onPressed: () => unawaited(_share()),
                icon: const Icon(Icons.share),
              ),
            ],
          ),
          body: _surface(controller),
        );
      },
    );
  }
}
