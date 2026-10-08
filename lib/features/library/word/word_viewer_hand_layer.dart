import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerHandLayer extends StatefulWidget {
  final WordEditorController controller;
  final bool handMode;

  const WordViewerHandLayer({
    super.key,
    required this.controller,
    required this.handMode,
  });

  @override
  State<WordViewerHandLayer> createState() =>
      _WordViewerHandLayerState();
}

class _WordViewerHandLayerState
    extends State<WordViewerHandLayer> {
  double _lastGestureScale = 1.0;

  WordEditorController get _controller =>
      widget.controller;

  void _pan(DragUpdateDetails details) {
    if (!widget.handMode) {
      return;
    }

    final delta = details.delta;

    if (delta == Offset.zero) {
      return;
    }

    _controller.viewport.pan(delta);
    _controller.refresh();
  }

  void _scaleStart(
    ScaleStartDetails details,
  ) {
    _lastGestureScale = 1.0;
  }

  void _scaleUpdate(
    ScaleUpdateDetails details,
  ) {
    if (!widget.handMode) {
      return;
    }

    final viewport = _controller.viewport;

    final currentGestureScale =
        details.scale == 0
            ? _lastGestureScale
            : details.scale;

    final incrementalFactor =
        currentGestureScale /
        (_lastGestureScale == 0
            ? 1.0
            : _lastGestureScale);

    final oldScale = viewport.scale;

    final newScale = (oldScale * incrementalFactor)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    final actualFactor =
        oldScale == 0
            ? 1.0
            : newScale / oldScale;

    if ((actualFactor - 1).abs() > 0.00001) {
      final focalPoint = details.focalPoint;

      final oldOrigin = viewport.origin;

      final contentPoint =
          (focalPoint - oldOrigin) /
          oldScale;

      viewport.setScale(newScale);

      viewport.origin =
          focalPoint -
          contentPoint * newScale;
    }

    if (details.focalPointDelta != Offset.zero) {
      viewport.pan(
        details.focalPointDelta,
      );
    }

    _lastGestureScale =
        currentGestureScale;

    _controller.refresh();
  }

  void _scaleEnd(ScaleEndDetails details) {
    _lastGestureScale = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        QudsWordEditor(
          controller: _controller,
        ),
        if (widget.handMode)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: _pan,
              onScaleStart: _scaleStart,
              onScaleUpdate: _scaleUpdate,
              onScaleEnd: _scaleEnd,
            ),
          ),
      ],
    );
  }
}
