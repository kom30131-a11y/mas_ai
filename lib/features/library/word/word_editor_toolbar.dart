import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

import 'toolbar/word_toolbar_clipboard.dart';
import 'toolbar/word_toolbar_font.dart';
import 'toolbar/word_toolbar_history.dart';
import 'toolbar/word_toolbar_insert.dart';
import 'toolbar/word_toolbar_page.dart';
import 'toolbar/word_toolbar_paragraph.dart';
import 'toolbar/word_toolbar_review.dart';
import 'toolbar/word_toolbar_table.dart';
import 'toolbar/word_toolbar_view.dart';

class WordEditorToolbar extends StatelessWidget {
  final WordEditorController controller;
  final VoidCallback onFitPage;

  const WordEditorToolbar({
    super.key,
    required this.controller,
    required this.onFitPage,
  });

  Widget _group(
    BuildContext context,
    Widget child,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 3,
        vertical: 4,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 2,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _group(
                context,
                WordToolbarHistory(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarClipboard(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarFont(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarParagraph(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarInsert(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarTable(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarReview(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarPage(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarView(
                  controller: controller,
                  onFitPage: onFitPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
