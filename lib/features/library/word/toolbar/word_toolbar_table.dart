import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarTable extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarTable({
    super.key,
    required this.controller,
  });

  bool get _table => controller.isInTable;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Insert row',
          onPressed: _table
              ? () {
                  controller.insertTableRow(after: true);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.add_box),
        ),
        IconButton(
          tooltip: 'Insert column',
          onPressed: _table
              ? () {
                  controller.insertTableColumn(after: true);
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.view_column),
        ),
        IconButton(
          tooltip: 'Delete row',
          onPressed: _table
              ? () {
                  controller.deleteTableRow();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        IconButton(
          tooltip: 'Delete column',
          onPressed: _table
              ? () {
                  controller.deleteTableColumn();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.view_column_outlined),
        ),
        IconButton(
          tooltip: 'Merge cells',
          onPressed: controller.canMergeTableCells
              ? () {
                  controller.mergeTableCells();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.call_merge),
        ),
        IconButton(
          tooltip: 'Split cells',
          onPressed: controller.canUnmergeTableCells
              ? () {
                  controller.unmergeTableCells();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.call_split),
        ),
        IconButton(
          tooltip: 'AutoFit contents',
          onPressed: _table
              ? () {
                  controller.autoFitTable(
                    WordTableAutoFit.contents,
                  );
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.fit_screen),
        ),
        IconButton(
          tooltip: 'AutoFit window',
          onPressed: _table
              ? () {
                  controller.autoFitTable(
                    WordTableAutoFit.window,
                  );
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.width_full),
        ),
        IconButton(
          tooltip: 'Delete table',
          onPressed: _table
              ? () {
                  controller.deleteTable();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}
