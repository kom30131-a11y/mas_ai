import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarHistory extends StatelessWidget {
  final WordEditorController controller;

  const WordToolbarHistory({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Undo',
          onPressed: controller.canUndo
              ? controller.undo
              : null,
          icon: const Icon(Icons.undo),
        ),
        IconButton(
          tooltip: 'Redo',
          onPressed: controller.canRedo
              ? controller.redo
              : null,
          icon: const Icon(Icons.redo),
        ),
      ],
    );
  }
}
