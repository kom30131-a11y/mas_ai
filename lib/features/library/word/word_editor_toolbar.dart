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

  void _run(void Function(WmlRunProps props) update) {
    controller.applyRunFormat(update);
  }

  void _paragraph(void Function(WmlParagraphProps props) update) {
    controller.applyParagraphFormat(update);
  }

  Future<void> _fontSize(BuildContext context) async {
    const sizes = <double>[8, 9, 10, 11, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48];
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: sizes.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final size = sizes[index];
            return ListTile(
              leading: const Icon(Icons.format_size),
              title: Text(
                size.toStringAsFixed(0),
                style: TextStyle(fontSize: size.clamp(12, 28)),
              ),
              onTap: () {
                Navigator.pop(context);
                _run((props) => props.fontSizeHalfPoints = (size * 2).round());
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _color(
    BuildContext context, {
    required bool highlight,
  }) async {
    const colors = <String>[
      '000000', '444444', 'D32F2F', '1976D2', '388E3C',
      'F57C00', '7B1FA2', '00838F', 'FFF59D',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            for (final hex in colors)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse('FF$hex', radix: 16)),
                ),
                title: Text(hex),
                onTap: () {
                  Navigator.pop(context);
                  _run((props) {
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

  Future<void> _tables(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
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

    Widget action({
      required String tooltip,
      required IconData icon,
      required VoidCallback? onPressed,
      bool active = false,
    }) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon, color: active ? primary : null),
      );
    }

    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              action(
                tooltip: 'Undo',
                icon: Icons.undo,
                onPressed: controller.canUndo ? controller.undo : null,
              ),
              action(
                tooltip: 'Redo',
                icon: Icons.redo,
                onPressed: controller.canRedo ? controller.redo : null,
              ),
              const VerticalDivider(width: 12),
              action(
                tooltip: 'Copy',
                icon: Icons.copy,
                onPressed: controller.canCopy
                    ? () => unawaited(controller.copyToClipboard())
                    : null,
              ),
              action(
                tooltip: 'Cut',
                icon: Icons.content_cut,
                onPressed: controller.canCut
                    ? () => unawaited(controller.cutToClipboard())
                    : null,
              ),
              action(
                tooltip: 'Paste',
                icon: Icons.paste,
                onPressed: controller.canPaste
                    ? () => unawaited(controller.pasteFromClipboard())
                    : null,
              ),
              const VerticalDivider(width: 12),
              action(
                tooltip: 'Bold',
                icon: Icons.format_bold,
                active: run.bold,
                onPressed: () => _run((props) => props.bold = !props.bold),
              ),
              action(
                tooltip: 'Italic',
                icon: Icons.format_italic,
                active: run.italic,
                onPressed: () => _run((props) => props.italic = !props.italic),
              ),
              action(
                tooltip: 'Underline',
                icon: Icons.format_underlined,
                active: run.underline != WmlUnderline.none,
                onPressed: () => _run((props) {
                  props.underline = props.underline == WmlUnderline.none
                      ? WmlUnderline.single
                      : WmlUnderline.none;
                }),
              ),
              action(
                tooltip: 'Strikethrough',
                icon: Icons.strikethrough_s,
                active: run.strike,
                onPressed: () => _run((props) => props.strike = !props.strike),
              ),
              action(
                tooltip: 'Font size',
                icon: Icons.format_size,
                onPressed: () => unawaited(_fontSize(context)),
              ),
              action(
                tooltip: 'Text color',
                icon: Icons.format_color_text,
                onPressed: () => unawaited(_color(context, highlight: false)),
              ),
              action(
                tooltip: 'Highlight',
                icon: Icons.highlight,
                onPressed: () => unawaited(_color(context, highlight: true)),
              ),
              const VerticalDivider(width: 12),
              action(
                tooltip: 'Align left',
                icon: Icons.format_align_left,
                onPressed: () => _paragraph(
                  (props) => props.justification = WmlJustification.left,
                ),
              ),
              action(
                tooltip: 'Center',
                icon: Icons.format_align_center,
                onPressed: () => _paragraph(
                  (props) => props.justification = WmlJustification.center,
                ),
              ),
              action(
                tooltip: 'Align right',
                icon: Icons.format_align_right,
                onPressed: () => _paragraph(
                  (props) => props.justification = WmlJustification.right,
                ),
              ),
              action(
                tooltip: 'Justify',
                icon: Icons.format_align_justify,
                onPressed: () => _paragraph(
                  (props) => props.justification = WmlJustification.justify,
                ),
              ),
              action(
                tooltip: 'Bulleted list',
                icon: Icons.format_list_bulleted,
                onPressed: () => controller.toggleList(numbered: false),
              ),
              action(
                tooltip: 'Numbered list',
                icon: Icons.format_list_numbered,
                onPressed: () => controller.toggleList(numbered: true),
              ),
              const VerticalDivider(width: 12),
              PopupMenuButton<String>(
                tooltip: 'More Word tools',
                icon: const Icon(Icons.more_horiz),
                onSelected: (value) {
                  switch (value) {
                    case 'h1': controller.applyHeading(1); break;
                    case 'h2': controller.applyHeading(2); break;
                    case 'h3': controller.applyHeading(3); break;
                    case 'rtl': controller.setParagraphDirection(rtl: true); break;
                    case 'ltr': controller.setParagraphDirection(rtl: false); break;
                    case 'page': controller.insertPageBreak(); break;
                    case 'section': controller.insertSectionBreak(); break;
                    case 'fit': onFitPage(); break;
                    case 'table': unawaited(_tables(context)); break;
                    case 'select': controller.selectAll(); break;
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
      ),
    );
  }
}
