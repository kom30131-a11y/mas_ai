import 'dart:ui';

import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorLayout {
  const WordEditorLayout._();

  static void a4(WordEditorController c) {
    c.setPageSize(WmlPageSize.a4());
    c.setPageLandscape(false);
    c.refresh();
  }

  static void letter(WordEditorController c) {
    c.setPageSize(WmlPageSize.letter());
    c.setPageLandscape(false);
    c.refresh();
  }

  static void legal(WordEditorController c) {
    c.setPageSize(WmlPageSize.legal());
    c.setPageLandscape(false);
    c.refresh();
  }

  static void portrait(WordEditorController c) {
    c.setPageLandscape(false);
    c.refresh();
  }

  static void landscape(WordEditorController c) {
    c.setPageLandscape(true);
    c.refresh();
  }

  static void margins(
    WordEditorController c, {
    int top = 1134,
    int right = 1134,
    int bottom = 1134,
    int left = 1134,
  }) {
    c.setPageMargins(
      WmlPageMargins(
        top: top,
        right: right,
        bottom: bottom,
        left: left,
      ),
    );
    c.refresh();
  }

  static void normalMargins(
    WordEditorController c,
  ) {
    c.setPageMargins(
      const WmlPageMargins(),
    );
    c.refresh();
  }

  static void narrowMargins(
    WordEditorController c,
  ) {
    margins(
      c,
      top: 720,
      right: 720,
      bottom: 720,
      left: 720,
    );
  }

  static void wideMargins(
    WordEditorController c,
  ) {
    margins(
      c,
      top: 1440,
      right: 1440,
      bottom: 1440,
      left: 1440,
    );
  }

  static void columns(
    WordEditorController c,
    int count, {
    double space = 36,
    bool separator = false,
  }) {
    c.setSectionColumns(
      count.clamp(1, 4),
      space: space,
      sep: separator,
    );
    c.refresh();
  }

  static void singleColumn(
    WordEditorController c,
  ) {
    columns(c, 1);
  }

  static void twoColumns(
    WordEditorController c,
  ) {
    columns(c, 2);
  }

  static void threeColumns(
    WordEditorController c,
  ) {
    columns(c, 3);
  }

  static void pageBreak(
    WordEditorController c,
  ) {
    c.insertPageBreak();
    c.refresh();
  }

  static void columnBreak(
    WordEditorController c,
  ) {
    c.insertColumnBreak();
    c.refresh();
  }

  static void sectionBreak(
    WordEditorController c,
  ) {
    c.insertSectionBreak();
    c.refresh();
  }

  static void header(
    WordEditorController c,
  ) {
    c.beginHeaderFooterEdit(
      c.visiblePageIndex,
      footer: false,
    );
    c.refresh();
  }

  static void footer(
    WordEditorController c,
  ) {
    c.beginHeaderFooterEdit(
      c.visiblePageIndex,
      footer: true,
    );
    c.refresh();
  }

  static void exitHeaderFooter(
    WordEditorController c,
  ) {
    c.endHeaderFooterEdit();
    c.refresh();
  }

  static void differentFirstPage(
    WordEditorController c,
    bool value,
  ) {
    c.setDifferentFirstPage(value);
    c.refresh();
  }

  static void differentOddEven(
    WordEditorController c,
    bool value,
  ) {
    c.setDifferentOddEven(value);
    c.refresh();
  }

  static void lineNumbers(
    WordEditorController c,
    bool value,
  ) {
    c.setLineNumbers(value);
    c.refresh();
  }

  static void watermark(
    WordEditorController c,
    String text,
  ) {
    c.setWatermark(text);
    c.refresh();
  }

  static void clearWatermark(
    WordEditorController c,
  ) {
    c.setWatermark('');
    c.refresh();
  }

  static void fitWidth(
    WordEditorController c,
  ) {
    final pages = c.documentLaidOut.pages;

    if (pages.isEmpty ||
        c.viewport.extent.width <= 0) {
      return;
    }

    final index = c.visiblePageIndex.clamp(
      0,
      pages.length - 1,
    );

    final page = pages[index];

    if (page.width <= 0) return;

    final available =
        (c.viewport.extent.width - 16)
            .clamp(
              1.0,
              double.infinity,
            )
            .toDouble();

    final scale =
        (available / page.width)
            .clamp(
              c.viewport.clampMin,
              c.viewport.clampMax,
            )
            .toDouble();

    c.viewport.setScale(scale);
    c.refresh();
  }

  static void zoomIn(
    WordEditorController c,
  ) {
    final scale =
        (c.viewport.scale * 1.1)
            .clamp(
              c.viewport.clampMin,
              c.viewport.clampMax,
            )
            .toDouble();

    c.viewport.setScale(scale);
    c.refresh();
  }

  static void zoomOut(
    WordEditorController c,
  ) {
    final scale =
        (c.viewport.scale / 1.1)
            .clamp(
              c.viewport.clampMin,
              c.viewport.clampMax,
            )
            .toDouble();

    c.viewport.setScale(scale);
    c.refresh();
  }

  static void actualSize(
    WordEditorController c,
  ) {
    final scale =
        1.0
            .clamp(
              c.viewport.clampMin,
              c.viewport.clampMax,
            )
            .toDouble();

    c.viewport.setScale(scale);
    c.refresh();
  }

  static String pageInfo(
    WordEditorController c,
  ) {
    if (c.pageCount == 0) {
      return '0 / 0';
    }

    return '${c.visiblePageIndex + 1} / ${c.pageCount}';
  }

  static void nextPage(
    WordEditorController c,
  ) {
    if (c.visiblePageIndex >=
        c.pageCount - 1) {
      return;
    }

    c.viewport.origin =
        c.viewport.origin +
        Offset(
          0,
          c.pageSize.height *
              c.viewport.scale,
        );

    c.refresh();
  }

  static void previousPage(
    WordEditorController c,
  ) {
    if (c.visiblePageIndex <= 0) {
      return;
    }

    c.viewport.origin =
        c.viewport.origin +
        Offset(
          0,
          -c.pageSize.height *
              c.viewport.scale,
        );

    c.refresh();
  }

  static void relayout(
    WordEditorController c,
  ) {
    c.fitPaintMetrics();
    c.relayout();
    c.refresh();
  }
}
