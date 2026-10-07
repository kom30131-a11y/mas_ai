import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  static double _pageTop(
    WordEditorController controller,
    int pageIndex,
  ) {
    final pages = controller.documentLaidOut.pages;
    var top = 24.0;

    for (var i = 0; i < pageIndex; i++) {
      top += pages[i].height * controller.viewport.scale + 24;
    }

    return top;
  }

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

    final index =
        controller.visiblePageIndex.clamp(0, pages.length - 1);
    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return false;
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

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

  static Size singlePageSize(
    WordEditorController controller, {
    double? width,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty) {
      return Size(
        width ?? viewport.extent.width,
        viewport.extent.height,
      );
    }

    final index =
        controller.visiblePageIndex.clamp(0, pages.length - 1);
    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return Size(
        width ?? viewport.extent.width,
        viewport.extent.height,
      );
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

    final scale = (availableWidth / page.width)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    return Size(
      availableWidth,
      page.height * scale + 24,
    );
  }

  static void positionSinglePage(
    WordEditorController controller, {
    double? width,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty || viewport.extent.width <= 0) {
      return;
    }

    final index =
        controller.visiblePageIndex.clamp(0, pages.length - 1);
    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return;
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

    final scale = (availableWidth / page.width)
        .clamp(
          viewport.clampMin,
          viewport.clampMax,
        )
        .toDouble();

    viewport.setScale(scale);

    viewport.origin = Offset(
      -64,
      _pageTop(controller, index),
    );

    controller.refresh();
  }

  static bool fitCurrentPage(
    WordEditorController controller, {
    bool resetScroll = false,
  }) {
    return fitWidth(
      controller,
      resetScroll: resetScroll,
    );
  }

  static void clamp(WordEditorController controller) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty) return;

    var stackHeight = 24.0;
    var maxWidth = 0.0;

    for (final page in pages) {
      stackHeight += page.height * viewport.scale + 24;

      if (page.width > maxWidth) {
        maxWidth = page.width;
      }
    }

    final content = Size(
      maxWidth * viewport.scale + 128,
      stackHeight,
    );

    viewport.clampTo(
      content: content,
      view: viewport.extent,
    );
  }

  static void jumpToPage(
    WordEditorController controller,
    int delta,
  ) {
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty) return;

    final current = controller.visiblePageIndex;
    final next =
        (current + delta).clamp(0, pages.length - 1);

    if (next == current) return;

    final top = _pageTop(controller, next);

    controller.viewport.origin = Offset(
      -64,
      top,
    );

    controller.refresh();
  }
}
