import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarFont extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarFont({
    super.key,
    required this.controller,
  });

  void _apply(
    WmlRunProps props,
  ) {
    controller.applyRunFormat(props);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Bold',
          onPressed: () => _apply(
            WmlRunProps(
              bold: !controller.activeRunProps.bold,
            ),
          ),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: 'Italic',
          onPressed: () => _apply(
            WmlRunProps(
              italic: !controller.activeRunProps.italic,
            ),
          ),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: 'Underline',
          onPressed: () => _apply(
            WmlRunProps(
              underline: controller.activeRunProps.underline == null
                  ? true
                  : !controller.activeRunProps.underline!,
            ),
          ),
          icon: const Icon(Icons.format_underline),
        ),
        IconButton(
          tooltip: 'Strikethrough',
          onPressed: () => _apply(
            WmlRunProps(
              strike: !controller.activeRunProps.strike,
            ),
          ),
          icon: const Icon(Icons.strikethrough_s),
        ),
        IconButton(
          tooltip: 'Superscript',
          onPressed: () => _apply(
            WmlRunProps(
              vertAlign: controller.activeRunProps.vertAlign == 'superscript'
                  ? null
                  : 'superscript',
            ),
          ),
          icon: const Icon(Icons.superscript),
        ),
        IconButton(
          tooltip: 'Subscript',
          onPressed: () => _apply(
            WmlRunProps(
              vertAlign: controller.activeRunProps.vertAlign == 'subscript'
                  ? null
                  : 'subscript',
            ),
          ),
          icon: const Icon(Icons.subscript),
        ),
      ],
    );
  }
}
