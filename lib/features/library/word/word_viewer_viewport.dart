import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  static bool fitWidth(
    WordEditorController controller, {
    double? width,
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty || viewport.extent.width <= 0) {
      return false;
    }

    final index = controller.visiblePageIndex.clamp(
      0,
      pages.length - 1,
    );
    final page = pages.indexWhere((p) => p.width > 0) != -1 ? pages[index] : pages.first;

    if (page.width <= 0) {
      return false;
    }

    final availableWidth = math.max(
      1.0,
      width ?? viewport.extent.width,
    );

    final scale = (availableWidth / page.width)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    viewport.setScale(scale);

    if (resetScroll) {
      viewport.origin = Offset.zero;
    }

    controller.refresh();
    return true;
  }
}
