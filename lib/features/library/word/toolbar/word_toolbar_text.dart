import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarText extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarText({
    super.key,
    required this.controller,
  });

  Future<void> _fontSize(BuildContext context) async {
    final field = TextEditingController();

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Font size'),
          content: TextField(
            controller: field,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration: const InputDecoration(
              hintText: '12',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final size = double.tryParse(field.text.trim());
                if (size == null || size <= 0) return;
                Navigator.pop(context, size);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || value == null) return;

    controller.applyRunFormat(
      (props) {
        props.fontSizeHalfPoints = (value * 2).round();
      },
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Font size',
      onPressed: () => _fontSize(context),
      icon: const Icon(Icons.format_size),
    );
  }
}
