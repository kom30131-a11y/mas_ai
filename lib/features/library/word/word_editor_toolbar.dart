import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorToolbar extends StatelessWidget {
  final WordEditorController controller;
  final VoidCallback onFitPage;

  const WordEditorToolbar({
    super.key,
    required this.controller,
    required this.onFitPage,
  });

  void _applyRun(void Function(WmlRunProps props) update) {
    controller.applyRunFormat(update);
  }

  void _applyParagraph(void Function(WmlParagraphProps props) update) {
    controller.applyParagraphFormat(update);
  }

  Future<void> _showFontSizeMenu(BuildContext context) async {
    const sizes = <double>[8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48];
    await showModalBottomSheet<void>(
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
                _applyRun((props) => props.fontSizeHalfPoints = (size * 2).round());
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showColorMenu(BuildContext context, {required bool highlight}) async {
    const colors = <String>['000000', '444444', 'D32F2F', '1976D2', '388E3C', 'F57C00', '7B1FA2', '00838F', 'FFF59D'];
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            for (final hex in colors)
              ListTile(
                leading: CircleAvatar(backgroundColor: Color(int.parse('FF$hex', radix: 16))),
                title: Text(hex),
                onTap: () {
                  Navigator.pop(context);
                  _applyRun((props) {
                    if (highlight) {
                      props.highlight = hex;
                    } else {
                      props.color = hex;
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTableMenu(BuildContext context) async {
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
                controller.insertTableRow(after: true, table: controller.selectedTable);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_column),
              title: const Text('Insert column'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                controller.insertTableColumn(after: true, table: controller.selectedTable);
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
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete table'),
              enabled: controller.isInTable,
              onTap: () {
                Navigator.pop(context);
                final table = controller.selectedTable;
                if (table != null) controller.deleteTable(table: table);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: controller.canUndo ? controller.undo : null,
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: controller.canRedo ? controller.redo : null,
              icon: const Icon(Icons.redo),
            ),
            const VerticalDivider(width: 12),
            IconButton(
              tooltip: 'Copy',
              onPressed: controller.canCopy ? () => unawaited(controller.copyToClipboard()) : null,
              icon: const Icon(Icons.copy),
            ),
            IconButton(
              tooltip: 'Cut',
              onPressed: controller.canCut ? () => unawaited(controller.cutToClipboard()) : null,
              icon: const Icon(Icons.content_cut),
            ),
            IconButton(
              tooltip: 'Paste',
              onPressed: controller.canPaste ? () => unawaited(controller.pasteFromClipboard()) : null,
              icon: const Icon(Icons.paste),
            ),
            const VerticalDivider(width: 12),
            IconButton(
              tooltip: 'Bold',
              onPressed: () => _applyRun((props) => props.bold = !props.bold),
              icon: Icon(Icons.format_bold, color: run.bold ? primary : null),
            ),
            IconButton(
              tooltip: 'Italic',
              onPressed: () => _applyRun((props) => props.italic = !props.italic),
              icon: Icon(Icons.format_italic, color: run.italic ? primary : null),
            ),
            IconButton(
              tooltip: 'Underline',
              onPressed: () => _applyRun((props) {
                props.underline = props.underline == WmlUnderline.none
                    ? WmlUnderline.single
                    : WmlUnderline.none;
              }),
              icon: Icon(
                Icons.format_underlined,
                color: run.underline != WmlUnderline.none ? primary : null,
              ),
            ),
            IconButton(
              tooltip: 'Strikethrough',
              onPressed: () => _applyRun((props) => props.strike = !props.strike),
              icon: Icon(Icons.strikethrough_s, color: run.strike ? primary : null),
            ),
            IconButton(
              tooltip: 'Font size',
              onPressed: () => unawaited(_showFontSizeMenu(context)),
              icon: const Icon(Icons.format_size),
            ),
            IconButton(
              tooltip: 'Text color',
              onPressed: () => unawaited(_showColorMenu(context, highlight: false)),
              icon: const Icon(Icons.format_color_text),
            ),
            IconButton(
              tooltip: 'Highlight',
              onPressed: () => unawaited(_showColorMenu(context, highlight: true)),
              icon: const Icon(Icons.highlight),
            ),
            const VerticalDivider(width: 12),
            IconButton(
              tooltip: 'Align left',
              onPressed: () => _applyParagraph((props) => props.justification = WmlJustification.left),
              icon: const Icon(Icons.format_align_left),
            ),
            IconButton(
              tooltip: 'Center',
              onPressed: () => _applyParagraph((props) => props.justification = WmlJustification.center),
              icon: const Icon(Icons.format_align_center),
            ),
            IconButton(
              tooltip: 'Align right',
              onPressed: () => _applyParagraph((props) => props.justification = WmlJustification.right),
              icon: const Icon(Icons.format_align_right),
            ),
            IconButton(
              tooltip: 'Justify',
              onPressed: () => _applyParagraph((props) => props.justification = WmlJustification.justify),
              icon: const Icon(Icons.format_align_justify),
            ),
            IconButton(
              tooltip: 'Bulleted list',
              onPressed: () => controller.toggleList(numbered: false),
              icon: const Icon(Icons.format_list_bulleted),
            ),
            IconButton(
              tooltip: 'Numbered list',
              onPressed: () => controller.toggleList(numbered: true),
              icon: const Icon(Icons.format_list_numbered),
            ),
            const VerticalDivider(width: 12),
            PopupMenuButton<String>(
              tooltip: 'Advanced Tools',
              icon: const Icon(Icons.more_horiz),
              onSelected: (value) {
                switch (value) {
                  case 'h1':
                    controller.applyHeading(1);
                    break;
                  case 'h2':
                    controller.applyHeading(2);
                    break;
                  case 'h3':
                    controller.applyHeading(3);
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
                    onFitPage();
                    break;
                  case 'table':
                    unawaited(_showTableMenu(context));
                    break;
                  case 'select':
                    controller.selectAll();
                    break;
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'h1', child: Text('Heading 1')),
                PopupMenuItem(value: 'h2', child: Text('Heading 2')),
                PopupMenuItem(value: 'h3', child: Text('Heading 3')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'rtl', child: Text('RTL paragraph')),
                PopupMenuItem(value: 'ltr', child: Text('LTR paragraph')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'page', child: Text('Page break')),
                PopupMenuItem(value: 'section', child: Text('Section break')),
                PopupMenuItem(value: 'fit', child: Text('Fit page width')),
                PopupMenuDivider(),
                PopupMenuItem(value: 'table', child: Text('Table tools...')),
                PopupMenuItem(value: 'select', child: Text('Select all')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
