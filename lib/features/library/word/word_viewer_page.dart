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
  bool _editing = false;
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
          textDirection:
              rtl ? TextDirection.rtl : TextDirection.ltr,
          strings:
              rtl ? OfficeStrings.arabic : OfficeStrings.english,
          theme: dark ? OfficeTheme.dark : OfficeTheme.light,
          showRulers: false,
          showFindChrome: true,
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !identical(_controller, controller)) return;
        _fitPageToViewport(controller, resetScroll: true);
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

  void _enterEditing() {
    final controller = _controller;
    if (controller == null || _editing) return;

    controller.setMode(OfficeInteractionMode.editing);
    if (mounted) setState(() => _editing = true);
  }

  Future<void> _finishEditing() async {
    final controller = _controller;
    if (controller == null || !_editing) return;

    if (controller.isDirty) {
      final saved = await _save();
      if (!saved || !mounted) return;
    }

    controller.setMode(OfficeInteractionMode.viewing);
    if (mounted) setState(() => _editing = false);
  }

  void _fitPageToViewport(
    WordEditorController controller, {
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final viewWidth = viewport.extent.width;

    if (viewWidth <= 0) return;

    var maxPageWidth = 0.0;

    for (final page in controller.documentLaidOut.pages) {
      if (page.width > maxPageWidth) {
        maxPageWidth = page.width;
      }
    }

    if (maxPageWidth <= 0) return;

    const pointsToPixels = 96 / 72;
    const sideGutter = 64.0 * 2;
    const scrollBar = 14.0;

    final usableWidth = viewWidth - sideGutter - scrollBar;

    if (usableWidth <= 0) return;

    final scale = (usableWidth / (maxPageWidth * pointsToPixels))
        .clamp(viewport.clampMin, viewport.clampMax)
        .toDouble();

    viewport.setScale(scale);

    if (resetScroll) {
      viewport.origin = Offset.zero;
    } else {
      viewport.origin = Offset(0, viewport.origin.dy);
    }
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

    if (controller == null || !controller.isDirty || _saving) {
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

  void _showFontSizeMenu(
    BuildContext context,
    WordEditorController controller,
  ) {
    const sizes = <double>[
      8,
      9,
      10,
      11,
      12,
      14,
      16,
      18,
      20,
      24,
      28,
      32,
      36,
      48,
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: sizes.length,
          itemBuilder: (_, index) {
            final size = sizes[index];

            return ListTile(
              title: Text(
                size.toStringAsFixed(0),
                style: TextStyle(fontSize: size.clamp(12, 28)),
              ),
              onTap: () {
                Navigator.pop(context);
                controller.applyRunFormat(
                  (props) => props.fontSizeHalfPoints =
                      (size * 2).round(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showColorMenu(
    BuildContext context,
    WordEditorController controller, {
    required bool highlight,
  }) {
    const colors = <String>[
      '000000',
      '444444',
      'D32F2F',
      '1976D2',
      '388E3C',
      'F57C00',
      '7B1FA2',
      '00838F',
    ];

    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            for (final hex in colors)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse('FF$hex', radix: 16),
                  ),
                ),
                title: Text(hex),
                onTap: () {
                  Navigator.pop(context);
                  controller.applyRunFormat(
                    (props) {
                      if (highlight) {
                        props.highlight = hex;
                      } else {
                        props.color = hex;
                      }
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTableMenu(
    BuildContext context,
    WordEditorController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Insert 3 × 3 table'),
              onTap: () {
                Navigator.pop(context);
                controller.insertTable(rows: 3, columns: 3);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Insert row'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                controller.insertTableRow(
                  after: true,
                  table: controller.selectedTable,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_column),
              title: const Text('Insert column'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                controller.insertTableColumn(
                  after: true,
                  table: controller.selectedTable,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: const Text('Merge selected cells'),
              enabled: controller.canMergeTableCells,
              onTap: () {
                Navigator.pop(context);
                controller.mergeTableCells();
              },
            ),
            ListTile(
              leading: const Icon(Icons.call_split),
              title: const Text('Unmerge cells'),
              enabled: controller.canUnmergeTableCells,
              onTap: () {
                Navigator.pop(context);
                controller.unmergeTableCells();
              },
            ),
            ListTile(
              leading: const Icon(Icons.fit_screen),
              title: const Text('Auto fit table'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                controller.autoFitTable(WordTableAutoFit.window);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle_outline),
              title: const Text('Delete selected row'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                final cell = controller.tableAtCaret;
                final table = cell?.table ?? controller.selectedTable;
                final row = cell?.row;
                if (table != null && row != null) {
                  controller.deleteTableRow(
                    table: table,
                    row: row,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle),
              title: const Text('Delete selected column'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                final cell = controller.tableAtCaret;
                final table = cell?.table ?? controller.selectedTable;
                final col = cell?.col;
                if (table != null && col != null) {
                  controller.deleteTableColumn(
                    table: table,
                    col: col,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete table'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                controller.deleteTable(
                  table: controller.selectedTable,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbar(WordEditorController controller) {
    final primary = Theme.of(context).colorScheme.primary;
    final run = controller.activeRunProps;

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
              tooltip: 'Copy',
              onPressed: controller.canCopy
                  ? () => unawaited(controller.copyToClipboard())
                  : null,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: 'Cut',
              onPressed: controller.canCut
                  ? () => unawaited(controller.cutToClipboard())
                  : null,
              icon: const Icon(Icons.content_cut),
            ),
            IconButton(
              tooltip: 'Paste',
              onPressed: controller.canPaste
                  ? () => unawaited(controller.pasteFromClipboard())
                  : null,
              icon: const Icon(Icons.content_paste),
            ),

            const VerticalDivider(width: 12),

            IconButton(
              tooltip: 'Bold',
              onPressed: () => controller.applyRunFormat(
                (props) => props.bold = !props.bold,
              ),
              icon: Icon(
                Icons.format_bold,
                color: run.bold ? primary : null,
              ),
            ),
            IconButton(
              tooltip: 'Italic',
              onPressed: () => controller.applyRunFormat(
                (props) => props.italic = !props.italic,
              ),
              icon: Icon(
                Icons.format_italic,
                color: run.italic ? primary : null,
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
                color: run.underline != WmlUnderline.none
                    ? primary
                    : null,
              ),
            ),
            IconButton(
              tooltip: 'Strikethrough',
              onPressed: () => controller.applyRunFormat(
                (props) => props.strike = !props.strike,
              ),
              icon: Icon(
                Icons.strikethrough_s,
                color: run.strike ? primary : null,
              ),
            ),

            IconButton(
              tooltip: 'Font size',
              onPressed: () =>
                  _showFontSizeMenu(context, controller),
              icon: const Icon(Icons.format_size),
            ),
            IconButton(
              tooltip: 'Text color',
              onPressed: () => _showColorMenu(
                context,
                controller,
                highlight: false,
              ),
              icon: const Icon(Icons.format_color_text),
            ),
            IconButton(
              tooltip: 'Highlight',
              onPressed: () => _showColorMenu(
                context,
                controller,
                highlight: true,
              ),
              icon: const Icon(Icons.highlight),
            ),

            PopupMenuButton<WmlVertAlign>(
              tooltip: 'Text position',
              icon: const Icon(Icons.vertical_align_center),
              onSelected: (value) {
                controller.applyRunFormat(
                  (props) => props.vertAlign = value,
                );
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: WmlVertAlign.baseline,
                  child: Text('Normal'),
                ),
                PopupMenuItem(
                  value: WmlVertAlign.superscript,
                  child: Text('Superscript'),
                ),
                PopupMenuItem(
                  value: WmlVertAlign.subscript,
                  child: Text('Subscript'),
                ),
              ],
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
                PopupMenuItem(
                  value: 4,
                  child: Text('Heading 4'),
                ),
                PopupMenuItem(
                  value: 5,
                  child: Text('Heading 5'),
                ),
                PopupMenuItem(
                  value: 6,
                  child: Text('Heading 6'),
                ),
              ],
            ),

            PopupMenuButton<String>(
              tooltip: 'More',
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                switch (value) {
                  case 'indent+':
                    controller.setParagraphIndent(left: 24);
                    break;
                  case 'indent-':
                    controller.setParagraphIndent(left: 0);
                    break;
                  case 'rtl':
                    controller.setParagraphDirection(rtl: true);
                    break;
                  case 'ltr':
                    controller.setParagraphDirection(rtl: false);
                    break;
                  case 'page':
                    controller.insertPageBreak();
                    break;
                  case 'section':
                    controller.insertSectionBreak();
                    break;
                  case 'fit':
                    _fitPageToViewport(controller);
                    break;
                  case 'portrait':
                    controller.setPageLandscape(false);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitPageToViewport(controller);
                    });
                    break;
                  case 'landscape':
                    controller.setPageLandscape(
                      !controller.isPageLandscape,
                    );
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _fitPageToViewport(controller);
                    });
                    break;
                  case 'table':
                    unawaited(
                      _showTableMenu(context, controller),
                    );
                    break;
                  case 'select':
                    controller.selectAll();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'indent+',
                  child: Text('Increase indent'),
                ),
                PopupMenuItem(
                  value: 'indent-',
                  child: Text('Reset indent'),
                ),
                PopupMenuItem(
                  value: 'rtl',
                  child: Text('RTL paragraph'),
                ),
                PopupMenuItem(
                  value: 'ltr',
                  child: Text('LTR paragraph'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'page',
                  child: Text('Page break'),
                ),
                PopupMenuItem(
                  value: 'section',
                  child: Text('Section break'),
                ),
                PopupMenuItem(
                  value: 'fit',
                  child: Text('Fit page'),
                ),
                PopupMenuItem(
                  value: 'portrait',
                  child: Text('Portrait page'),
                ),
                PopupMenuItem(
                  value: 'landscape',
                  child: Text('Toggle landscape'),
                ),
                PopupMenuItem(
                  value: 'table',
                  child: Text('Table tools'),
                ),
                PopupMenuItem(
                  value: 'select',
                  child: Text('Select all'),
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
                      ? controller.requestFind
                      : null,
                  icon: const Icon(Icons.search),
                ),
                if (_editing)
                  IconButton(
                    tooltip: 'Find and replace',
                    onPressed: controller.canFind
                        ? controller.requestReplace
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
            body: QudsWordEditor(
              controller: controller,
              toolbarBuilder: (_, value) =>
                  _editing ? _toolbar(value) : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}
