import 'package:flutter/material.dart';
import 'package:quds_office_editor/quds_office_editor.dart';

class WordViewerSearch {
  const WordViewerSearch._();

  static Future<void> show(
    BuildContext context,
    WordEditorController controller, {
    required bool replace,
  }) async {
    final queryController = TextEditingController();
    final replacementController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final session = controller.findSession;
            final total = session.hits.length;
            final current = total == 0
                ? 0
                : (session.index.clamp(0, total - 1) + 1);

            void runSearch() {
              final query = queryController.text.trim();

              if (query.isEmpty) {
                controller.closeFind();
                setState(() {});
                return;
              }

              final hits = controller.find(
                OfficeFindOptions(query: query),
              );

              final hit = hits.isEmpty
                  ? null
                  : controller.findSession.current;

              if (hit != null) {
                controller.revealFindHit(hit);
                controller.refresh();
              }

              setState(() {});
            }

            void revealNext() {
              final hit = controller.findNext();
              if (hit != null) {
                controller.revealFindHit(hit);
                controller.refresh();
                setState(() {});
              }
            }

            void revealPrevious() {
              final hit = controller.findPrevious();
              if (hit != null) {
                controller.revealFindHit(hit);
                controller.refresh();
                setState(() {});
              }
            }

            void replaceAll() {
              final query = queryController.text.trim();
              if (query.isEmpty) return;

              final count = controller.replaceAll(
                OfficeFindOptions(
                  query: query,
                  replaceWith: replacementController.text,
                ),
              );

              if (count > 0) {
                controller.find(
                  OfficeFindOptions(query: query),
                );
              }

              setState(() {});

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    count == 0
                        ? 'No matches found.'
                        : '$count replacement(s) made.',
                  ),
                ),
              );
            }

            return AlertDialog(
              title: Text(
                replace
                    ? 'Find and replace'
                    : 'Find in document',
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: queryController,
                        autofocus: true,
                        textInputAction:
                            replace
                                ? TextInputAction.next
                                : TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'Find',
                          prefixIcon:
                              const Icon(Icons.search),
                          suffixText: total == 0
                              ? null
                              : '$current/$total',
                        ),
                        onSubmitted: (_) => runSearch(),
                      ),
                      if (replace) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: replacementController,
                          textInputAction: TextInputAction.done,
                          decoration: const InputDecoration(
                            labelText: 'Replace with',
                            prefixIcon:
                                Icon(Icons.find_replace),
                          ),
                        ),
                      ],
                      if (total > 0) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$total match(es)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Previous match',
                              onPressed: revealPrevious,
                              icon: const Icon(
                                Icons.keyboard_arrow_up,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next match',
                              onPressed: revealNext,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
                if (replace)
                  FilledButton(
                    onPressed: replaceAll,
                    child: const Text('Replace all'),
                  ),
                FilledButton(
                  onPressed: runSearch,
                  child: const Text('Find'),
                ),
              ],
            );
          },
        );
      },
    );

    queryController.dispose();
    replacementController.dispose();
  }
}
