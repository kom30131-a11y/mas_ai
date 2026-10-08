import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarStatistics extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarStatistics({
    super.key,
    required this.controller,
  });

  Future<void> _show(BuildContext context) async {
    final stats = controller.documentStats;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Document statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Words: ${stats.words}'),
              const SizedBox(height: 8),
              Text('Characters: ${stats.characters}'),
              const SizedBox(height: 8),
              Text('Characters without spaces: ${stats.charactersNoSpaces}'),
              const SizedBox(height: 8),
              Text('Paragraphs: ${stats.paragraphs}'),
              const SizedBox(height: 8),
              Text('Pages: ${stats.pages}'),
              const SizedBox(height: 8),
              Text('Sections: ${controller.sectionCount}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Word count',
      onPressed: () => _show(context),
      icon: const Icon(Icons.analytics_outlined),
    );
  }
}
