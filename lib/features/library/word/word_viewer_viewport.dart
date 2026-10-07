import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  static bool fitCurrentPage(
    WordEditorController controller, {
    bool resetScroll = false,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty ||
        viewport.extent.width <= 0 ||
        viewport.extent.height <= 0) {
      return false;
    }

    final currentIndex = controller.visiblePageIndex
        .clamp(0, pages.length - 1);
    final page = pages[currentIndex];

    if (page.width <= 0 || page.height <= 0) return false;

    const padding = 24.0;
    final availableWidth =
        math.max(1.0, viewport.extent.width - padding);
    final availableHeight =
        math.max(1.0, viewport.extent.height - padding);

    final widthScale = availableWidth / page.width;
    final heightScale = availableHeight / page.height;
    final scale = math
        .min(widthScale, heightScale)
        .clamp(viewport.clampMin, viewport.clampMax)
        .toDouble();

    viewport.setScale(scale);

    final pageTop = controller.documentLaidOut.pageStackTop(
      currentIndex,
      scale,
    );

    viewport.origin = Offset(
      0,
      resetScroll ? 0 : pageTop,
    );

    clamp(controller);
    controller.refresh();
    return true;
  }

  static void clamp(WordEditorController controller) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty || viewport.extent.isEmpty) return;

    var maxWidth = 0.0;
    for (final page in pages) {
      maxWidth = math.max(maxWidth, page.width);
    }

    if (maxWidth <= 0) return;

    final lastPage = pages.last;
    final contentHeight =
        controller.documentLaidOut.pageStackTop(
          lastPage.index,
          viewport.scale,
        ) +
        (lastPage.height * viewport.scale);

    viewport.clampTo(
      content: Size(
        maxWidth * viewport.scale,
        contentHeight,
      ),
      view: viewport.extent,
      pad: 24,
    );
  }

  static void jumpToPage(
    WordEditorController controller,
    int delta,
  ) {
    final pages = controller.documentLaidOut.pages;
    if (pages.isEmpty) return;

    final current = controller.visiblePageIndex;
    final next = (current + delta).clamp(0, pages.length - 1);
    if (next == current) return;

    jumpToPageIndex(controller, next);
  }

  static void jumpToPageIndex(
    WordEditorController controller,
    int pageIndex,
  ) {
    final pages = controller.documentLaidOut.pages;
    if (pages.isEmpty) return;

    final next = pageIndex.clamp(0, pages.length - 1);
    final viewport = controller.viewport;

    viewport.origin = Offset(
      viewport.origin.dx,
      controller.documentLaidOut.pageStackTop(
        next,
        viewport.scale,
      ),
    );

    clamp(controller);
    controller.refresh();
  }
}
