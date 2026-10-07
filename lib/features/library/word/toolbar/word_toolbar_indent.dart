import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarIndent extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarIndent({
    super.key,
    required this.controller,
  });

  void _increase() {
    controller.setParagraphIndent(
      left: 720,
    );
    controller.refresh();
  }

  void _decrease() {
    controller.setParagraphIndent(
      left: 0,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Increase indent',
          onPressed: _increase,
          icon: const Icon(Icons.format_indent_increase),
        ),
        IconButton(
          tooltip: 'Decrease indent',
          onPressed: _decrease,
          icon: const Icon(Icons.format_indent_decrease),
        ),
      ],
    );
  }
}
