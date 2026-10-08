import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarHyperlink extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarHyperlink({
    super.key,
    required this.controller,
  });

  Future<void> _insert(BuildContext context) async {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert hyperlink'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Text',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (urlController.text.trim().isEmpty) return;
                Navigator.pop(context, true);
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );

    final text = textController.text.trim();
    final url = urlController.text.trim();

    textController.dispose();
    urlController.dispose();

    if (!context.mounted || result != true || url.isEmpty) return;

    controller.insertHyperlink(
      text: text.isEmpty ? url : text,
      target: url,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Hyperlink',
      onPressed: () => _insert(context),
      icon: const Icon(Icons.link),
    );
  }
}
