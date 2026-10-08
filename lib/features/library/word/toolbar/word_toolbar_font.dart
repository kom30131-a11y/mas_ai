import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarFont extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarFont({
    super.key,
    required this.controller,
  });

  void _apply({
    bool? bold,
    bool? italic,
    WmlUnderline? underline,
    bool? strike,
    WmlVertAlign? vertAlign,
  }) {
    controller.applyRunFormat(
      (props) {
        if (bold != null) props.bold = bold;
        if (italic != null) props.italic = italic;
        if (underline != null) props.underline = underline;
        if (strike != null) props.strike = strike;
        if (vertAlign != null) props.vertAlign = vertAlign;
      },
    );
    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final props = controller.activeRunProps;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Bold',
          onPressed: () => _apply(
            bold: !props.bold,
          ),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: 'Italic',
          onPressed: () => _apply(
            italic: !props.italic,
          ),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: 'Underline',
          onPressed: () => _apply(
            underline: props.underline == WmlUnderline.none
                ? WmlUnderline.single
                : WmlUnderline.none,
          ),
          icon: const Icon(Icons.format_underline),
        ),
        IconButton(
          tooltip: 'Strikethrough',
          onPressed: () => _apply(
            strike: !props.strike,
          ),
          icon: const Icon(Icons.strikethrough_s),
        ),
        IconButton(
          tooltip: 'Superscript',
          onPressed: () => _apply(
            vertAlign: props.vertAlign == WmlVertAlign.superscript
                ? WmlVertAlign.baseline
                : WmlVertAlign.superscript,
          ),
          icon: const Icon(Icons.superscript),
        ),
        IconButton(
          tooltip: 'Subscript',
          onPressed: () => _apply(
            vertAlign: props.vertAlign == WmlVertAlign.subscript
                ? WmlVertAlign.baseline
                : WmlVertAlign.subscript,
          ),
          icon: const Icon(Icons.subscript),
        ),
      ],
    );
  }
}
