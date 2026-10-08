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

  void _pan(DragUpdateDetails details) {
    controller.viewport.origin -= details.delta;
    controller.refresh();
  }

  void _scaleStart(ScaleStartDetails details) {}

  void _scaleUpdate(ScaleUpdateDetails details) {
    if (details.scale == 1) {
      controller.viewport.origin -= details.focalPointDelta;
      controller.refresh();
      return;
    }

    final viewport = controller.viewport;
    final oldScale = viewport.scale;
    final newScale = (oldScale * details.scale)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    if ((newScale - oldScale).abs() < 0.0001) {
      viewport.origin -= details.focalPointDelta;
      controller.refresh();
      return;
    }

    final focalPoint = details.focalPoint;
    final oldOrigin = viewport.origin;

    final contentPoint = (focalPoint - oldOrigin) / oldScale;

    viewport.setScale(newScale);

    viewport.origin =
        focalPoint - contentPoint * newScale - details.focalPointDelta;

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
            onScaleStart: _scaleStart,
            onScaleUpdate: _scaleUpdate,
          ),
      ],
    );
  }
}
