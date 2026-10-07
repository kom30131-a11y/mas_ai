import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorFormatting {
  const WordEditorFormatting._();

  static void toggleBold(WordEditorController c) {
    c.applyRunFormat((p) => p.bold = !p.bold);
  }

  static void toggleItalic(WordEditorController c) {
    c.applyRunFormat((p) => p.italic = !p.italic);
  }

  static void toggleUnderline(WordEditorController c) {
    c.applyRunFormat(
      (p) => p.underline = p.underline == WmlUnderline.none
          ? WmlUnderline.single
          : WmlUnderline.none,
    );
  }

  static void toggleStrike(WordEditorController c) {
    c.applyRunFormat((p) => p.strike = !p.strike);
  }

  static void toggleSuperscript(WordEditorController c) {
    c.applyRunFormat(
      (p) => p.vertAlign = p.vertAlign == WmlVertAlign.superscript
          ? WmlVertAlign.baseline
          : WmlVertAlign.superscript,
    );
  }

  static void toggleSubscript(WordEditorController c) {
    c.applyRunFormat(
      (p) => p.vertAlign = p.vertAlign == WmlVertAlign.subscript
          ? WmlVertAlign.baseline
          : WmlVertAlign.subscript,
    );
  }

  static void fontSize(WordEditorController c, double points) {
    c.applyRunFormat(
      (p) => p.fontSizeHalfPoints = (points * 2).round(),
    );
  }

  static void fontFamily(WordEditorController c, String family) {
    c.applyRunFormat((p) {
      p.asciiFont = family;
      p.csFont = family;
    });
  }

  static void textColor(WordEditorController c, String hex) {
    c.applyRunFormat((p) => p.color = hex);
  }

  static void highlight(WordEditorController c, String? hex) {
    c.applyRunFormat((p) => p.highlight = hex);
  }

  static void clearHighlight(WordEditorController c) {
    highlight(c, null);
  }

  static void heading(WordEditorController c, int level) {
    c.applyHeading(level);
  }

  static void normal(WordEditorController c) {
    c.applyStyle('Normal');
  }

  static Future<void> chooseFontSize(
    BuildContext context,
    WordEditorController controller,
  ) async {
    const values = <double>[
      8,
      9,
      10,
      11,
      12,
      14,
      16,
      18,
      20,
      22,
      24,
      28,
      32,
      36,
      48,
      72,
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: values.length,
          itemBuilder: (_, i) {
            final size = values[i];
            return ListTile(
              leading: const Icon(Icons.format_size),
              title: Text(
                size.toStringAsFixed(0),
                style: TextStyle(fontSize: size.clamp(12, 30)),
              ),
              onTap: () {
                Navigator.pop(context);
                fontSize(controller, size);
              },
            );
          },
        ),
      ),
    );
  }

  static Future<void> chooseFont(
    BuildContext context,
    WordEditorController controller,
  ) async {
    const fonts = <String>[
      'Arial',
      'Times New Roman',
      'Courier New',
      'Calibri',
      'Liberation Sans',
      'Liberation Serif',
      'Noto Naskh Arabic',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: fonts.length,
          itemBuilder: (_, i) {
            final font = fonts[i];
            return ListTile(
              title: Text(font),
              onTap: () {
                Navigator.pop(context);
                fontFamily(controller, font);
              },
            );
          },
        ),
      ),
    );
  }

  static Future<void> chooseColor(
    BuildContext context,
    WordEditorController controller, {
    bool highlightMode = false,
  }) async {
    const colors = <String>[
      '000000',
      'FFFFFF',
      'FF0000',
      'D32F2F',
      '1976D2',
      '388E3C',
      'F57C00',
      '7B1FA2',
      '00838F',
      '795548',
      'FFF59D',
      'C8E6C9',
      'BBDEFB',
      'FFCCBC',
    ];

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: GridView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: colors.length,
          itemBuilder: (_, i) {
            final hex = colors[i];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(context);
                if (highlightMode) {
                  highlight(controller, hex);
                } else {
                  textColor(controller, hex);
                }
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(int.parse('FF$hex', radix: 16)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
