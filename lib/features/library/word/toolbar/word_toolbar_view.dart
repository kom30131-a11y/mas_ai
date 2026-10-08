import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordToolbarView extends StatelessWidget {
  final WordEditorController controller;
  final VoidCallback onFitPage;

  const WordToolbarView({
    super.key,
    required this.controller,
    required this.onFitPage,
  });

  void _zoom(double factor) {
    final viewport = controller.viewport;

    viewport.setScale(
      (viewport.scale * factor)
          .clamp(
            viewport.clampMin,
            viewport.clampMax,
          )
          .toDouble(),
    );

    controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Zoom out',
          onPressed: () => _zoom(0.9),
          icon: const Icon(Icons.zoom_out),
        ),
        IconButton(
          tooltip: 'Zoom in',
          onPressed: () => _zoom(1.1),
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton(
          tooltip: 'Fit page',
          onPressed: onFitPage,
          icon: const Icon(Icons.fit_screen),
        ),
        IconButton(
          tooltip: 'Actual size',
          onPressed: () {
            controller.viewport.setScale(
              1.0.clamp(
                controller.viewport.clampMin,
                controller.viewport.clampMax,
              ).toDouble(),
            );

            controller.refresh();
          },
          icon: const Icon(Icons.fullscreen),
        ),
      ],
    );
  }
}
