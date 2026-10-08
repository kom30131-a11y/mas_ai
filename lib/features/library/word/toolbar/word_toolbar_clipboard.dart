import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarClipboard extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarClipboard({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Cut',
          onPressed: controller.canCut
              ? () {
                  controller.cut();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.content_cut),
        ),
        IconButton(
          tooltip: 'Copy',
          onPressed: controller.canCopy
              ? () {
                  controller.copy();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.content_copy),
        ),
        IconButton(
          tooltip: 'Paste',
          onPressed: controller.canPaste
              ? () {
                  controller.paste();
                  controller.refresh();
                }
              : null,
          icon: const Icon(Icons.content_paste),
        ),
        IconButton(
          tooltip: 'Select all',
          onPressed: () {
            controller.selectAll();
            controller.refresh();
          },
          icon: const Icon(Icons.select_all),
        ),
      ],
    );
  }
}
