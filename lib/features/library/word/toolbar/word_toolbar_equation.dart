import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarEquation extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarEquation({
    super.key,
    required this.controller,
  });

  Future<void> _insert(BuildContext context) async {
    final field = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert equation'),
          content: TextField(
            controller: field,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Equation',
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
                final text = field.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(context, text);
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || value == null || value.isEmpty) return;

    controller.insertEquation(value);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Equation',
      onPressed: () => _insert(context),
      icon: const Icon(Icons.functions),
    );
  }
}
