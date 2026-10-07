import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

import 'toolbar/word_toolbar_clipboard.dart';
import 'toolbar/word_toolbar_columns.dart';
import 'toolbar/word_toolbar_color.dart';
import 'toolbar/word_toolbar_comment.dart';
import 'toolbar/word_toolbar_direction.dart';
import 'toolbar/word_toolbar_document.dart';
import 'toolbar/word_toolbar_equation.dart';
import 'toolbar/word_toolbar_font.dart';
import 'toolbar/word_toolbar_footnote.dart';
import 'toolbar/word_toolbar_formatting.dart';
import 'toolbar/word_toolbar_header_footer.dart';
import 'toolbar/word_toolbar_history.dart';
import 'toolbar/word_toolbar_hyperlink.dart';
import 'toolbar/word_toolbar_insert.dart';
import 'toolbar/word_toolbar_lines.dart';
import 'toolbar/word_toolbar_list.dart';
import 'toolbar/word_toolbar_margin.dart';
import 'toolbar/word_toolbar_page.dart';
import 'toolbar/word_toolbar_paragraph.dart';
import 'toolbar/word_toolbar_paragraph_format.dart';
import 'toolbar/word_toolbar_review.dart';
import 'toolbar/word_toolbar_section.dart';
import 'toolbar/word_toolbar_spacing.dart';
import 'toolbar/word_toolbar_statistics.dart';
import 'toolbar/word_toolbar_styles.dart';
import 'toolbar/word_toolbar_table.dart';
import 'toolbar/word_toolbar_text.dart';
import 'toolbar/word_toolbar_toc.dart';
import 'toolbar/word_toolbar_view.dart';
import 'toolbar/word_toolbar_watermark.dart';

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
                WordToolbarFormatting(
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
                WordToolbarText(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarColor(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarStyles(
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
                WordToolbarParagraphFormat(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarSpacing(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarDirection(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarList(
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
                WordToolbarDocument(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarComment(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarHyperlink(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarFootnote(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarEquation(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarToc(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarHeaderFooter(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarSection(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarColumns(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarMargin(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarWatermark(
                  controller: controller,
                ),
              ),
              _group(
                context,
                WordToolbarLines(
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
                WordToolbarStatistics(
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
