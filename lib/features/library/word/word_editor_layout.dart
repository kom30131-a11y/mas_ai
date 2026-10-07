import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorLayout {
  const WordEditorLayout._();

  static void a4(WordEditorController c) {
    c.setPageSize(OfficePageSize.a4Portrait);
    c.relayout();
  }

  static void a4Landscape(WordEditorController c) {
    c.setPageSize(OfficePageSize.a4Landscape);
    c.setPageLandscape(true);
    c.relayout();
  }

  static void portrait(WordEditorController c) {
    c.setPageLandscape(false);
    c.relayout();
  }

  static void landscape(WordEditorController c) {
    c.setPageLandscape(true);
    c.relayout();
  }

  static void normalMargins(WordEditorController c) {
    c.setPageMargins(const OfficePageMargins());
    c.relayout();
  }

  static void narrowMargins(WordEditorController c) {
    c.setPageMargins(
      const OfficePageMargins(
        topTwips: 720,
        rightTwips: 720,
        bottomTwips: 720,
        leftTwips: 720,
        headerTwips: 500,
        footerTwips: 500,
      ),
    );
    c.relayout();
  }

  static void wideMargins(WordEditorController c) {
    c.setPageMargins(
      const OfficePageMargins(
        topTwips: 1440,
        rightTwips: 1440,
        bottomTwips: 1440,
        leftTwips: 1440,
        headerTwips: 900,
        footerTwips: 900,
      ),
    );
    c.relayout();
  }

  static void columns(
    WordEditorController c, {
    required int count,
    double spacing = 36,
    bool separator = false,
  }) {
    c.setSectionColumns(
      count,
      space: spacing,
      sep: separator,
    );
    c.relayout();
  }

  static void singleColumn(WordEditorController c) {
    columns(c, count: 1);
  }

  static void twoColumns(WordEditorController c) {
    columns(c, count: 2);
  }

  static void threeColumns(WordEditorController c) {
    columns(c, count: 3);
  }

  static void watermark(
    WordEditorController c,
    String text,
  ) {
    c.setWatermark(text);
    c.relayout();
  }

  static void removeWatermark(WordEditorController c) {
    c.setWatermark('');
    c.relayout();
  }
}
