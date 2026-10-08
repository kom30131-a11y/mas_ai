import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  static const double _pointsToPixels = 96 / 72;

  // Quds Word renderer uses the same values internally.
  static const double _pageSideGutter = 64;
  static const double _scrollBar = 14;

  static bool fitWidth(
    WordEditorController controller, {
    double? width,
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty) {
      return false;
    }

    final index = controller.visiblePageIndex
        .clamp(
          0,
          pages.length - 1,
        )
        .toInt();

    final page = pages[index];

    if (page.width <= 0) {
      return false;
    }

    final viewWidth =
        width ?? viewport.extent.width;

    if (viewWidth <= 1) {
      return false;
    }

    final availableWidth = math.max(
      1,
      viewWidth - _scrollBar,
    );

    final pageWidthAtScaleOne =
        page.width * _pointsToPixels;

    if (pageWidthAtScaleOne <= 0) {
      return false;
    }

    final oldScale =
        viewport.scale <= 0
            ? 1.0
            : viewport.scale;

    final oldTop =
        resetScroll
            ? 0.0
            : viewport.origin.dy / oldScale;

    final newScale =
        (availableWidth / pageWidthAtScaleOne)
            .clamp(
              viewport.clampMin,
              viewport.clampMax,
            )
            .toDouble();

    viewport.setScale(newScale);

    final pageWidth =
        pageWidthAtScaleOne * viewport.scale;

    final pageLeft =
        availableWidth > pageWidth + (_pageSideGutter * 2)
            ? (availableWidth - pageWidth) / 2
            : _pageSideGutter;

    viewport.origin = Offset(
      pageLeft,
      oldTop * viewport.scale,
    );

    controller.refresh();

    return true;
  }

  static void zoomIn(
    WordEditorController controller,
  ) {
    final viewport = controller.viewport;

    final scale = (viewport.scale * 1.10)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    viewport.setScale(scale);
    controller.refresh();
  }

  static void zoomOut(
    WordEditorController controller,
  ) {
    final viewport = controller.viewport;

    final scale = (viewport.scale / 1.10)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    viewport.setScale(scale);
    controller.refresh();
  }

  static void actualSize(
    WordEditorController controller,
  ) {
    final viewport = controller.viewport;

    viewport.setScale(
      1.0.clamp(
        viewport.clampMin,
        viewport.clampMax,
      ),
    );

    controller.refresh();
  }

  static String pageInfo(
    WordEditorController controller,
  ) {
    if (controller.pageCount <= 0) {
      return '0 / 0';
    }

    return '${controller.visiblePageIndex + 1} / '
        '${controller.pageCount}';
  }

  static void nextPage(
    WordEditorController controller,
  ) {
    if (controller.visiblePageIndex >=
        controller.pageCount - 1) {
      return;
    }

    controller.viewport.origin += Offset(
      0,
      controller.pageSize.height *
          controller.viewport.scale,
    );

    controller.refresh();
  }

  static void previousPage(
    WordEditorController controller,
  ) {
    if (controller.visiblePageIndex <= 0) {
      return;
    }

    controller.viewport.origin -= Offset(
      0,
      controller.pageSize.height *
          controller.viewport.scale,
    );

    controller.refresh();
  }

  static void relayout(
    WordEditorController controller,
  ) {
    controller.fitPaintMetrics();
    controller.relayout();
    controller.refresh();
  }
}
