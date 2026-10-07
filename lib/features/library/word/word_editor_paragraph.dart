import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorParagraph {
  const WordEditorParagraph._();

  static void left(WordEditorController c) {
    c.applyParagraphFormat(
      (p) => p.justification = WmlJustification.left,
    );
  }

  static void center(WordEditorController c) {
    c.applyParagraphFormat(
      (p) => p.justification = WmlJustification.center,
    );
  }

  static void right(WordEditorController c) {
    c.applyParagraphFormat(
      (p) => p.justification = WmlJustification.right,
    );
  }

  static void justify(WordEditorController c) {
    c.applyParagraphFormat(
      (p) => p.justification = WmlJustification.justify,
    );
  }

  static void rtl(WordEditorController c) {
    c.setParagraphDirection(rtl: true);
  }

  static void ltr(WordEditorController c) {
    c.setParagraphDirection(rtl: false);
  }

  static void bullets(WordEditorController c) {
    c.toggleList(numbered: false);
  }

  static void numbering(WordEditorController c) {
    c.toggleList(numbered: true);
  }

  static void heading(WordEditorController c, int level) {
    c.applyHeading(level);
  }

  static void normal(WordEditorController c) {
    c.applyParagraphFormat((p) {
      p.headingLevel = null;
      p.styleId = 'Normal';
    });
  }

  static void spacing(
    WordEditorController c, {
    double? before,
    double? after,
    double? line,
  }) {
    c.applyParagraphFormat((p) {
      if (before != null) {
        p.spacingBefore = before;
        p.explicitSpacingBefore = true;
      }

      if (after != null) {
        p.spacingAfter = after;
        p.explicitSpacingAfter = true;
      }

      if (line != null) {
        p.lineSpacing = line;
        p.explicitLineSpacing = true;
      }
    });
  }

  static void indent(
    WordEditorController c, {
    double? left,
    double? right,
    double? firstLine,
    double? hanging,
  }) {
    c.setParagraphIndent(
      left: left,
      right: right,
      firstLine: firstLine,
      hanging: hanging,
    );
  }

  static void keepTogether(WordEditorController c, bool value) {
    c.applyParagraphFormat((p) => p.keepTogether = value);
  }

  static void pageBreakBefore(WordEditorController c, bool value) {
    c.applyParagraphFormat((p) => p.pageBreakBefore = value);
  }

  static void columnBreakBefore(WordEditorController c, bool value) {
    c.applyParagraphFormat((p) => p.columnBreakBefore = value);
  }

  static void paragraphShading(
    WordEditorController c,
    String? hex,
  ) {
    c.setParagraphShading(hex);
  }

  static void paragraphBorder(
    WordEditorController c,
    String? hex,
  ) {
    c.setParagraphBorder(hex);
  }

  static void dropCap(
    WordEditorController c,
    int lines,
  ) {
    c.setDropCap(lines);
  }

  static void addTabStop(
    WordEditorController c,
    double position,
  ) {
    c.addTabStop(position);
  }
}
