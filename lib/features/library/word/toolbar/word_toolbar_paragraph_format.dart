import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarParagraphFormat extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarParagraphFormat({
    super.key,
    required this.controller,
  });

  void _apply(WmlJustification justification) {
    controller.applyParagraphFormat(
      (props) {
        props.justification = justification;
      },
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<WmlJustification>(
      tooltip: 'Paragraph alignment',
      icon: const Icon(Icons.format_align_left),
      onSelected: _apply,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: WmlJustification.left,
          child: Row(
            children: [
              Icon(Icons.format_align_left),
              SizedBox(width: 12),
              Text('Align left'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.center,
          child: Row(
            children: [
              Icon(Icons.format_align_center),
              SizedBox(width: 12),
              Text('Center'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.right,
          child: Row(
            children: [
              Icon(Icons.format_align_right),
              SizedBox(width: 12),
              Text('Align right'),
            ],
          ),
        ),
        PopupMenuItem(
          value: WmlJustification.both,
          child: Row(
            children: [
              Icon(Icons.format_align_justify),
              SizedBox(width: 12),
              Text('Justify'),
            ],
          ),
        ),
      ],
    );
  }
}
