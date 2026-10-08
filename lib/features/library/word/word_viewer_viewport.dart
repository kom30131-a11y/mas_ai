import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  static const double _pointsToPixels = 96 / 72;
  static const double _pageSideGutter = 64;
  static const double _scrollBar = 14;

  static bool fitWidth(
    WordEditorController controller, {
    double? width,
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty) return false;

    final index = controller.visiblePageIndex
        .clamp(0, pages.length - 1)
        .toInt();

    final page = pages[index];

    if (page.width <= 0) return false;

    final viewWidth = width ?? viewport.extent.width;

    if (viewWidth <= _scrollBar) return false;

    final availableWidth = math.max(
      1.0,
      viewWidth - _scrollBar,
    );

    final pageWidthAtScaleOne =
        page.width * _pointsToPixels;

    if (pageWidthAtScaleOne <= 0) return false;

    final scale = (availableWidth / pageWidthAtScaleOne)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    viewport.setScale(scale);

    viewport.origin = Offset(
      _pageSideGutter,
      resetScroll ? 0 : viewport.origin.dy,
    );

    controller.refresh();
    return true;
  }
}
