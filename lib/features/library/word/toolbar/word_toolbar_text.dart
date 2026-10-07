import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarText extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarText({
    super.key,
    required this.controller,
  });

  Future<void> _fontSize(BuildContext context) async {
    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        final field = TextEditingController();

        return AlertDialog(
          title: const Text('Font size'),
          content: TextField(
            controller: field,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
            ),
            autofocus: true,
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
                final value = double.tryParse(field.text);
                if (value == null || value <= 0) return;
                Navigator.pop(context, value);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );

    if (value == null) return;

    controller.applyRunFormat(
      WmlRunProps(
        fontSizeHalfPoints: (value * 2).round(),
      ),
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
