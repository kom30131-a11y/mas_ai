import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarFormat extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarFormat({
    super.key,
    required this.controller,
  });

  void _apply(WmlRunProps props) {
    controller.applyRunFormat(props);
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
            WmlRunProps(bold: props.bold != true),
          ),
          icon: const Icon(Icons.format_bold),
        ),
        IconButton(
          tooltip: 'Italic',
          onPressed: () => _apply(
            WmlRunProps(italic: props.italic != true),
          ),
          icon: const Icon(Icons.format_italic),
        ),
        IconButton(
          tooltip: 'Underline',
          onPressed: () => _apply(
            WmlRunProps(
              underline: props.underline == true ? null : true,
            ),
          ),
          icon: const Icon(Icons.format_underline),
        ),
        IconButton(
          tooltip: 'Strikethrough',
          onPressed: () => _apply(
            WmlRunProps(strike: props.strike != true),
          ),
          icon: const Icon(Icons.strikethrough_s),
        ),
      ],
    );
  }
}
