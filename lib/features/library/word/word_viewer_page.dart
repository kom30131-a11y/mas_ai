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
          mode: OfficeInteractionMode.editing,
          textDirection: rtl
              ? TextDirection.rtl
              : TextDirection.ltr,
          strings: rtl
              ? OfficeStrings.arabic
              : OfficeStrings.english,
          theme: dark
              ? OfficeTheme.dark
              : OfficeTheme.light,
          enableUndo: true,
        ),
      );

      controller.addListener(_onChanged);

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _loading = false;
      });
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
        const SnackBar(
          content: Text('Recovered local Word draft.'),
        ),
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

  void _onChanged() {
    final controller = _controller;

    if (controller == null ||
        !controller.isDirty ||
        _saving) {
      return;
    }

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
          const SnackBar(
            content: Text('Word document saved.'),
          ),
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

      final safeName = widget.title.replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );

      final file = File(
        '${Directory.systemTemp.path}/$safeName.docx',
      );

      await file.writeAsBytes(bytes, flush: true);

      await Share.shareXFiles([
        XFile(file.path),
      ]);
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
      if (await _save() && mounted) {
        Navigator.pop(context);
      }
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

  Widget _toolbar(WordEditorController controller) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      elevation: 2,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Undo',
              onPressed:
                  controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed:
                  controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            const VerticalDivider(width: 12),

            IconButton(
              tooltip: 'Bold',
              onPressed: () => controller.applyRunFormat(
                (props) => props.bold = !props.bold,
              ),
              icon: Icon(
                Icons.format_bold,
                color: controller.activeRunProps.bold
                    ? primary
                    : null,
              ),
            ),

            IconButton(
              tooltip: 'Italic',
              onPressed: () => controller.applyRunFormat(
                (props) => props.italic = !props.italic,
              ),
              icon: Icon(
                Icons.format_italic,
                color: controller.activeRunProps.italic
                    ? primary
                    : null,
              ),
            ),

            IconButton(
              tooltip: 'Underline',
              onPressed: () => controller.applyRunFormat(
                (props) {
                  props.underline =
                      props.underline == WmlUnderline.none
                          ? WmlUnderline.single
                          : WmlUnderline.none;
                },
              ),
              icon: Icon(
                Icons.format_underlined,
                color:
                    controller.activeRunProps.underline !=
                            WmlUnderline.none
                        ? primary
                        : null,
              ),
            ),

            const VerticalDivider(width: 12),

            IconButton(
              tooltip: 'Align left',
              onPressed: () => controller.applyParagraphFormat(
                (props) =>
                    props.justification = WmlJustification.left,
              ),
              icon: const Icon(Icons.format_align_left),
            ),

            IconButton(
              tooltip: 'Center',
              onPressed: () => controller.applyParagraphFormat(
                (props) =>
                    props.justification = WmlJustification.center,
              ),
              icon: const Icon(Icons.format_align_center),
            ),

            IconButton(
              tooltip: 'Align right',
              onPressed: () => controller.applyParagraphFormat(
                (props) =>
                    props.justification = WmlJustification.right,
              ),
              icon: const Icon(Icons.format_align_right),
            ),

            IconButton(
              tooltip: 'Justify',
              onPressed: () => controller.applyParagraphFormat(
                (props) =>
                    props.justification = WmlJustification.justify,
              ),
              icon: const Icon(Icons.format_align_justify),
            ),

            const VerticalDivider(width: 12),

            IconButton(
              tooltip: 'Bulleted list',
              onPressed: () => controller.toggleList(
                numbered: false,
              ),
              icon: const Icon(Icons.format_list_bulleted),
            ),

            IconButton(
              tooltip: 'Numbered list',
              onPressed: () => controller.toggleList(
                numbered: true,
              ),
              icon: const Icon(Icons.format_list_numbered),
            ),

            PopupMenuButton<int>(
              tooltip: 'Heading',
              icon: const Icon(Icons.title),
              onSelected: controller.applyHeading,
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 1,
                  child: Text('Heading 1'),
                ),
                PopupMenuItem(
                  value: 2,
                  child: Text('Heading 2'),
                ),
                PopupMenuItem(
                  value: 3,
                  child: Text('Heading 3'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null || _controller == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
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
                  tooltip: 'Export',
                  onPressed: () => unawaited(_export()),
                  icon: const Icon(Icons.file_download),
                ),
                IconButton(
                  tooltip: 'Share',
                  onPressed: () => unawaited(_share()),
                  icon: const Icon(Icons.share),
                ),
              ],
            ),
            body: QudsWordEditor(
              controller: controller,
              toolbarBuilder: (_, value) => _toolbar(value),
            ),
          ),
        );
      },
    );
  }
}
