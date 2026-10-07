import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarDocument extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarDocument({
    super.key,
    required this.controller,
  });

  Future<void> _document(BuildContext context) async {
    final value = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.table_of_contents),
                title: const Text('Table of contents'),
                onTap: () => Navigator.pop(context, 'toc'),
              ),
              ListTile(
                leading: const Icon(Icons.functions),
                title: const Text('Equation'),
                onTap: () => Navigator.pop(context, 'equation'),
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Hyperlink'),
                onTap: () => Navigator.pop(context, 'link'),
              ),
              ListTile(
                leading: const Icon(Icons.comment),
                title: const Text('Comment'),
                onTap: () => Navigator.pop(context, 'comment'),
              ),
              ListTile(
                leading: const Icon(Icons.notes),
                title: const Text('Footnote'),
                onTap: () => Navigator.pop(context, 'footnote'),
              ),
            ],
          ),
        );
      },
    );

    if (!context.mounted || value == null) return;

    switch (value) {
      case 'toc':
        controller.insertTableOfContents();
        break;
      case 'equation':
        controller.insertEquation();
        break;
      case 'link':
        controller.insertHyperlink();
        break;
      case 'comment':
        controller.insertComment();
        break;
      case 'footnote':
        controller.insertFootnote();
        break;
    }

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Document',
      onPressed: () => _document(context),
      icon: const Icon(Icons.library_books_outlined),
    );
  }
}
