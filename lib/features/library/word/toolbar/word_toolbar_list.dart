import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarList extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarList({
    super.key,
    required this.controller,
  });

  void _toggle(String kind) {
    controller.toggleList(
      kind: kind,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Bulleted list',
          onPressed: () => _toggle('bullet'),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Numbered list',
          onPressed: () => _toggle('number'),
          icon: const Icon(Icons.format_list_numbered),
        ),
      ],
    );
  }
}
