import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarLines extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarLines({
    super.key,
    required this.controller,
  });

  void _toggle() {
    controller.setLineNumbers(
      !controller.sectionAtCaret.lineNumbers,
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
