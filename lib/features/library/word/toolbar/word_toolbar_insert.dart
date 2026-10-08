import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarInsert extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarInsert({
    super.key,
    required this.controller,
  });

  Future<void> _insertTable(BuildContext context) async {
    final rows = await _number(
      context,
      'Rows',
      3,
    );

    if (!context.mounted || rows == null) return;

    final columns = await _number(
      context,
      'Columns',
      3,
    );

    if (!context.mounted || columns == null) return;

    controller.insertTable(
      rows: rows,
      columns: columns,
    );
    controller.refresh();
  }

  Future<int?> _number(
    BuildContext context,
    String title,
    int initial,
  ) async {
    final field = TextEditingController(text: '$initial');

    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: field,
            keyboardType: TextInputType.number,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(field.text.trim());

                if (value == null || value < 1) return;

                Navigator.pop(
                  context,
                  value,
                );
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    field.dispose();
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Insert table',
          onPressed: () => _insertTable(context),
          icon: const Icon(Icons.table_chart),
        ),
        IconButton(
          tooltip: 'Insert page break',
          onPressed: () {
            controller.insertPageBreak();
            controller.refresh();
          },
          icon: const Icon(Icons.insert_page_break),
        ),
        IconButton(
          tooltip: 'Insert paragraph break',
          onPressed: () {
            controller.insertParagraphBreak();
            controller.refresh();
          },
          icon: const Icon(Icons.keyboard_return),
        ),
      ],
    );
  }
}
