import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

/// Host-side helpers only.
/// QudsWordEditor remains the owner of scrolling, panning, selection and zoom.
class WordViewerViewport {
  const WordViewerViewport._();

  static bool fitWidth(
    WordEditorController controller, {
    double? width,
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty || viewport.extent.width <= 0) return false;

    final index = controller.visiblePageIndex
        .clamp(0, pages.length - 1)
        .toInt();
    final page = pages[index];

    if (page.width <= 0) return false;

    final availableWidth = math.max(
      1.0,
      (width ?? viewport.extent.width) - 16.0,
    );

    final scale = (availableWidth / page.width)
        .clamp(viewport.clampMin, viewport.clampMax)
        .toDouble();

    viewport.setScale(scale);

    if (resetScroll) viewport.origin = Offset.zero;

    controller.refresh();
    return true;
  }
}
