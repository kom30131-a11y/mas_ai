import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorInsert {
  const WordEditorInsert._();

  static void pageBreak(WordEditorController c) {
    c.insertPageBreak();
  }

  static void sectionBreak(WordEditorController c) {
    c.insertSectionBreak();
  }

  static void columnBreak(WordEditorController c) {
    c.insertColumnBreak();
  }

  static void paragraphBreak(WordEditorController c) {
    c.insertParagraphBreak();
  }

  static void table(
    WordEditorController c, {
    int rows = 3,
    int columns = 3,
  }) {
    c.insertTable(rows: rows, columns: columns);
  }

  static void row(WordEditorController c) {
    if (!c.isInTable) return;

    c.insertTableRow(
      after: true,
      table: c.selectedTable,
    );
  }

  static void column(WordEditorController c) {
    if (!c.isInTable) return;

    c.insertTableColumn(
      after: true,
      table: c.selectedTable,
    );
  }

  static void mergeCells(WordEditorController c) {
    if (c.canMergeTableCells) {
      c.mergeTableCells();
    }
  }

  static void splitCells(WordEditorController c) {
    if (c.canUnmergeTableCells) {
      c.unmergeTableCells();
    }
  }

  static void autoFitTable(WordEditorController c) {
    if (c.isInTable) {
      c.autoFitTable(WordTableAutoFit.window);
    }
  }

  static void deleteTable(WordEditorController c) {
    final table = c.selectedTable;
    if (table != null) {
      c.deleteTable(table: table);
    }
  }

  static void hyperlink(
    WordEditorController c, {
    required String text,
    required String target,
  }) {
    c.insertHyperlink(
      text: text,
      target: target,
    );
  }

  static void comment(
    WordEditorController c, {
    String text = '',
    String author = 'MedLibra',
  }) {
    c.insertComment(
      text: text,
      author: author,
      initials: 'ML',
    );
  }

  static void footnote(
    WordEditorController c, {
    String text = '',
    bool endnote = false,
  }) {
    c.insertFootnote(
      text: text,
      endnote: endnote,
    );
  }

  static void equationText(
    WordEditorController c,
    String text,
  ) {
    c.insertEquationText(text);
  }

  static void tableOfContents(
    WordEditorController c, {
    int minLevel = 1,
    int maxLevel = 3,
  }) {
    c.insertTableOfContents(
      minLevel: minLevel,
      maxLevel: maxLevel,
      title: 'Table of Contents',
    );
  }

  static void caption(
    WordEditorController c, {
    String label = 'Figure',
    String text = '',
  }) {
    c.insertCaption(
      label: label,
      text: text,
    );
  }

  static void field(
    WordEditorController c,
    WmlFieldKind kind,
  ) {
    c.insertField(kind);
  }

  static Future<void> showInsertMenu(
    BuildContext context,
    WordEditorController controller,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Table 3 × 3'),
              onTap: () {
                Navigator.pop(context);
                table(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Page break'),
              onTap: () {
                Navigator.pop(context);
                pageBreak(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.view_column),
              title: const Text('Column break'),
              onTap: () {
                Navigator.pop(context);
                columnBreak(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment_outlined),
              title: const Text('Comment'),
              onTap: () {
                Navigator.pop(context);
                comment(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Footnote'),
              onTap: () {
                Navigator.pop(context);
                footnote(controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.functions),
              title: const Text('Equation'),
              onTap: () {
                Navigator.pop(context);
                equationText(controller, 'x = ');
              },
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Table of contents'),
              onTap: () {
                Navigator.pop(context);
                tableOfContents(controller);
              },
            ),
          ],
        ),
      ),
    );
  }
}
