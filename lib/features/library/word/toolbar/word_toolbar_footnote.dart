import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarFootnote extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarFootnote({
    super.key,
    required this.controller,
  });

  Future<void> _insert(BuildContext context) async {
    final field = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert footnote'),
          content: TextField(
            controller: field,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Footnote text',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = field.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(context, value);
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || text == null || text.isEmpty) return;

    controller.insertFootnote(
      text: text,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Footnote',
      onPressed: () => _insert(context),
      icon: const Icon(Icons.notes),
    );
  }
}
