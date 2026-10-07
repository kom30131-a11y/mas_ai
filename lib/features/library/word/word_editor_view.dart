import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordEditorView {
  const WordEditorView._();

  static void refresh(WordEditorController c) {
    c.relayout();
    c.refresh();
  }

  static void fitLayout(WordEditorController c) {
    c.fitPaintMetrics();
    c.refresh();
  }

  static void pageUp(WordEditorController c) {
    if (c.pageCount <= 0) return;

    final index = c.visiblePageIndex;
    final target = (index - 1).clamp(0, c.pageCount - 1);

    c.revealPage(target);
    c.refresh();
  }

  static void pageDown(WordEditorController c) {
    if (c.pageCount <= 0) return;

    final index = c.visiblePageIndex;
    final target = (index + 1).clamp(0, c.pageCount - 1);

    c.revealPage(target);
    c.refresh();
  }

  static void firstPage(WordEditorController c) {
    if (c.pageCount == 0) return;

    c.revealPage(0);
    c.refresh();
  }

  static void lastPage(WordEditorController c) {
    if (c.pageCount == 0) return;

    c.revealPage(c.pageCount - 1);
    c.refresh();
  }

  static Future<void> showViewMenu(
    BuildContext context,
    WordEditorController c,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              leading: const Icon(Icons.fit_screen),
              title: const Text('Fit page'),
              onTap: () {
                fitLayout(c);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh layout'),
              onTap: () {
                refresh(c);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.first_page),
              title: const Text('First page'),
              onTap: () {
                firstPage(c);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigate_before),
              title: const Text('Previous page'),
              onTap: () {
                pageUp(c);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigate_next),
              title: const Text('Next page'),
              onTap: () {
                pageDown(c);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.last_page),
              title: const Text('Last page'),
              onTap: () {
                lastPage(c);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
