import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarParagraph extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarParagraph({
    super.key,
    required this.controller,
  });

  void _align(WmlJustification value) {
    controller.applyParagraphFormat(
      (props) {
        props.justification = value;
      },
    );
    controller.refresh();
  }

  void _indent(double value) {
    controller.setParagraphIndent(
      left: value,
    );
    controller.refresh();
  }

  void _list(bool numbered) {
    controller.toggleList(
      numbered: numbered,
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Align left',
          onPressed: () => _align(WmlJustification.left),
          icon: const Icon(Icons.format_align_left),
        ),
        IconButton(
          tooltip: 'Center',
          onPressed: () => _align(WmlJustification.center),
          icon: const Icon(Icons.format_align_center),
        ),
        IconButton(
          tooltip: 'Align right',
          onPressed: () => _align(WmlJustification.right),
          icon: const Icon(Icons.format_align_right),
        ),
        IconButton(
          tooltip: 'Justify',
          onPressed: () => _align(WmlJustification.both),
          icon: const Icon(Icons.format_align_justify),
        ),
        IconButton(
          tooltip: 'Bulleted list',
          onPressed: () => _list(false),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Numbered list',
          onPressed: () => _list(true),
          icon: const Icon(Icons.format_list_numbered),
        ),
        IconButton(
          tooltip: 'Increase indent',
          onPressed: () => _indent(36),
          icon: const Icon(Icons.format_indent_increase),
        ),
        IconButton(
          tooltip: 'Decrease indent',
          onPressed: () => _indent(0),
          icon: const Icon(Icons.format_indent_decrease),
        ),
      ],
    );
  }
}
