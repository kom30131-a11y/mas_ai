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

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Zoom out',
          onPressed: () {
            controller.viewport.zoomOut();
            controller.refresh();
          },
          icon: const Icon(Icons.zoom_out),
        ),
        IconButton(
          tooltip: 'Zoom in',
          onPressed: () {
            controller.viewport.zoomIn();
            controller.refresh();
          },
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton(
          tooltip: 'Fit width',
          onPressed: onFitPage,
          icon: const Icon(Icons.fit_width),
        ),
        IconButton(
          tooltip: 'Actual size',
          onPressed: () {
            controller.viewport.setScale(1);
            controller.refresh();
          },
          icon: const Icon(Icons.fullscreen),
        ),
      ],
    );
  }
}
