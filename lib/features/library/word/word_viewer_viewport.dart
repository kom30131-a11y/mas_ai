import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerViewport {
  const WordViewerViewport._();

  /// Fits the current page to the available width.
  ///
  /// Unlike the old implementation, this does NOT use the page height.
  /// Therefore long A4 pages remain readable instead of being shrunk
  /// to fit the whole page vertically.
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

    final index = controller.visiblePageIndex
        .clamp(0, pages.length - 1);

    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return false;
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

    final scale =
        (availableWidth / page.width)
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

  /// Calculates the size needed to show exactly one page.
  ///
  /// Quds internally uses a 24px top/page-stack spacing and a 64px
  /// side gutter. We account for those values here so the host can
  /// clip the RenderBox to one real page instead of showing pieces
  /// of adjacent pages.
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

    final index = controller.visiblePageIndex
        .clamp(0, pages.length - 1);

    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return Size(
        width ?? viewport.extent.width,
        viewport.extent.height,
      );
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

    final scale =
        (availableWidth / page.width)
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

  /// Positions the current page so its real page surface starts at
  /// the top-left of the reader viewport.
  ///
  /// The negative horizontal offset compensates Quds' internal
  /// 64px side gutter when the page is fitted exactly to the phone.
  static void positionSinglePage(
    WordEditorController controller, {
    double? width,
  }) {
    final viewport = controller.viewport;
    final pages = controller.documentLaidOut.pages;

    if (pages.isEmpty || viewport.extent.width <= 0) {
      return;
    }

    final index = controller.visiblePageIndex
        .clamp(0, pages.length - 1);

    final page = pages[index];

    if (page.width <= 0 || page.height <= 0) {
      return;
    }

    final availableWidth =
        math.max(1.0, width ?? viewport.extent.width);

    final scale =
        (availableWidth / page.width)
            .clamp(
              viewport.clampMin,
              viewport.clampMax,
            )
            .toDouble();

    viewport.setScale(scale);

    // Quds page stack starts at 24 logical pixels.
    // Its normal compact reader gutter is 64 logical pixels.
    viewport.origin = const Offset(-64, 24);

    controller.refresh();
  }

  /// Legacy entry point kept so existing toolbar code continues to
  /// compile and existing callers remain safe.
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
      stackHeight +=
          page.height * viewport.scale + 24;

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

    final next = (current + delta)
        .clamp(0, pages.length - 1);

    if (next == current) return;

    var top = 24.0;

    for (var i = 0; i < next; i++) {
      top += pages[i].height *
              controller.viewport.scale +
          24;
    }

    controller.viewport.origin = Offset(
      controller.viewport.origin.dx,
      top,
    );

    controller.refresh();
  }
}
