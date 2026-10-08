import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarStyles extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarStyles({
    super.key,
    required this.controller,
  });

  void _apply(String styleId) {
    controller.applyStyle(styleId);
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Styles',
      icon: const Icon(Icons.text_fields),
      onSelected: _apply,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'Normal',
          child: Text('Normal'),
        ),
        PopupMenuItem(
          value: 'Title',
          child: Text('Title'),
        ),
        PopupMenuItem(
          value: 'Subtitle',
          child: Text('Subtitle'),
        ),
        PopupMenuItem(
          value: 'Heading1',
          child: Text('Heading 1'),
        ),
        PopupMenuItem(
          value: 'Heading2',
          child: Text('Heading 2'),
        ),
        PopupMenuItem(
          value: 'Heading3',
          child: Text('Heading 3'),
        ),
      ],
    );
  }
}
