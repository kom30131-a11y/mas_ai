import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarComment extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarComment({
    super.key,
    required this.controller,
  });

  Future<void> _addComment(BuildContext context) async {
    final field = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New comment'),
          content: TextField(
            controller: field,
            autofocus: true,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Comment',
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
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || text == null || text.isEmpty) return;

    controller.insertComment(
      text: text,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Comment',
      onPressed: () => _addComment(context),
      icon: const Icon(Icons.add_comment_outlined),
    );
  }
}
