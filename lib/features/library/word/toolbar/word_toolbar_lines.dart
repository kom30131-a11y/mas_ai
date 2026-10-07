import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarLines extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarLines({
    super.key,
    required this.controller,
  });

  void _toggle() {
    final section = controller.sectionAtCaret;
    final enabled = section.lineNumbers;

    controller.setLineNumbers(
      !enabled,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Line numbers',
      onPressed: _toggle,
      icon: const Icon(Icons.format_list_numbered),
    );
  }
}
