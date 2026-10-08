import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerHandLayer extends StatelessWidget {
  final WordEditorController controller;
  final bool handMode;

  const WordViewerHandLayer({
    super.key,
    required this.controller,
    required this.handMode,
  });

  void _pan(
    DragUpdateDetails details,
  ) {
    controller.viewport.origin =
        controller.viewport.origin -
        Offset(
          details.delta.dx,
          details.delta.dy,
        );

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        QudsWordEditor(
          controller: controller,
        ),
        if (handMode)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: _pan,
          ),
      ],
    );
  }
}
