import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarParagraph extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarParagraph({
    super.key,
    required this.controller,
  });

  void _format(
    BuildContext context,
    WmlParagraphProps props,
  ) {
    controller.applyParagraphFormat(props);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Align left',
          onPressed: () => _format(
            context,
            WmlParagraphProps(
              justification: 'left',
            ),
          ),
          icon: const Icon(Icons.format_align_left),
        ),
        IconButton(
          tooltip: 'Center',
          onPressed: () => _format(
            context,
            WmlParagraphProps(
              justification: 'center',
            ),
          ),
          icon: const Icon(Icons.format_align_center),
        ),
        IconButton(
          tooltip: 'Align right',
          onPressed: () => _format(
            context,
            WmlParagraphProps(
              justification: 'right',
            ),
          ),
          icon: const Icon(Icons.format_align_right),
        ),
        IconButton(
          tooltip: 'Justify',
          onPressed: () => _format(
            context,
            WmlParagraphProps(
              justification: 'both',
            ),
          ),
          icon: const Icon(Icons.format_align_justify),
        ),
        IconButton(
          tooltip: 'Bulleted list',
          onPressed: () => controller.toggleList(
            kind: 'bullet',
          ),
          icon: const Icon(Icons.format_list_bulleted),
        ),
        IconButton(
          tooltip: 'Numbered list',
          onPressed: () => controller.toggleList(
            kind: 'number',
          ),
          icon: const Icon(Icons.format_list_numbered),
        ),
        IconButton(
          tooltip: 'Increase indent',
          onPressed: () => controller.setParagraphIndent(
            left: 720,
          ),
          icon: const Icon(Icons.format_indent_increase),
        ),
        IconButton(
          tooltip: 'Decrease indent',
          onPressed: () => controller.setParagraphIndent(
            left: 0,
          ),
          icon: const Icon(Icons.format_indent_decrease),
        ),
      ],
    );
  }
}
