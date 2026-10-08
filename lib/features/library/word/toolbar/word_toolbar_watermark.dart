import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarWatermark extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarWatermark({
    super.key,
    required this.controller,
  });

  Future<void> _watermark(BuildContext context) async {
    final field = TextEditingController();

    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Watermark'),
          content: TextField(
            controller: field,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Watermark text',
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
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || value == null || value.isEmpty) return;

    controller.setWatermark(
      text: value,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Watermark',
      onPressed: () => _watermark(context),
      icon: const Icon(Icons.watermark),
    );
  }
}
