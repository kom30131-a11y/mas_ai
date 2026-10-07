import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarDirection extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarDirection({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Left to right',
          onPressed: () {
            controller.setParagraphDirection(
              rightToLeft: false,
            );
            controller.refresh();
          },
          icon: const Icon(Icons.format_textdirection_l_to_r),
        ),
        IconButton(
          tooltip: 'Right to left',
          onPressed: () {
            controller.setParagraphDirection(
              rightToLeft: true,
            );
            controller.refresh();
          },
          icon: const Icon(Icons.format_textdirection_r_to_l),
        ),
      ],
    );
  }
}
