import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarSearch extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarSearch({
    super.key,
    required this.controller,
  });

  Future<void> _search(BuildContext context) async {
    final field = TextEditingController();

    final query = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Find'),
          content: TextField(
            controller: field,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                field.text,
              ),
              child: const Text('Find'),
            ),
          ],
        );
      },
    );

    field.dispose();

    if (!context.mounted || query == null || query.trim().isEmpty) {
      return;
    }

    final hits = controller.find(
      OfficeFindOptions(
        query: query.trim(),
      ),
    );

    if (hits.isNotEmpty) {
      controller.revealFindHit(hits.first);
    }

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Find',
      onPressed: () => _search(context),
      icon: const Icon(Icons.search),
    );
  }
}
