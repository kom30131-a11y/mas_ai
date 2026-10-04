import 'package:flutter/material.dart';

import '../content/library_content_helper.dart';
import '../widgets/library_helpers.dart';
import 'library_search.dart';

class LibrarySearchPage extends StatefulWidget {
  const LibrarySearchPage({
    super.key,
  });

  @override
  State<LibrarySearchPage> createState() =>
      _LibrarySearchPageState();
}

class _LibrarySearchPageState
    extends State<LibrarySearchPage> {
  final controller = TextEditingController();

  List<LibrarySearchResult> results = [];
  bool loading = false;

  Future<void> search() async {
    final query = controller.text.trim();

    if (query.isEmpty) {
      setState(() => results = []);
      return;
    }

    setState(() => loading = true);

    final found = await LibrarySearch.search(query);

    if (!mounted) return;

    setState(() {
      results = found;
      loading = false;
    });
  }

  List<TextSpan> _highlight(
    String text,
    String query,
  ) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    var start = 0;

    while (true) {
      final index =
          lowerText.indexOf(lowerQuery, start);

      if (index < 0) {
        if (start < text.length) {
          spans.add(
            TextSpan(
              text: text.substring(start),
            ),
          );
        }

        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(
            index,
            index + query.length,
          ),
          style: TextStyle(
            fontWeight: FontWeight.w700,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
          ),
        ),
      );

      start = index + query.length;
    }

    return spans;
  }

  Future<void> openResult(
    LibrarySearchResult result,
  ) async {
    final item = result.item;
    final subjectId = item['subject_id'];

    if (subjectId is! int) return;

    await openContent(
      context,
      item,
      subjectId,
      item['folder_id'] as int?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = controller.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: (_) {
            setState(() {});
          },
          onSubmitted: (_) => search(),
          decoration: const InputDecoration(
            hintText: 'Search library',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: search,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : results.isEmpty
              ? Center(
                  child: Text(
                    query.isEmpty
                        ? 'Search your library'
                        : 'No results found',
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: results.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final result = results[index];
                    final item = result.item;
                    final type =
                        item['type']?.toString();

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      leading: Icon(
                        contentIcon(type),
                      ),
                      title: Text(
                        item['title']?.toString() ??
                            'Untitled',
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                      subtitle: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          if (result.folderName !=
                                  null &&
                              result
                                  .folderName!
                                  .isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 2,
                              ),
                              child: Text(
                                result.folderName!,
                                maxLines: 2,
                                overflow:
                                    TextOverflow.ellipsis,
                              ),
                            ),
                          const SizedBox(height: 5),
                          RichText(
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                            text: TextSpan(
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium,
                              children: _highlight(
                                result.snippet,
                                query,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () =>
                          openResult(result),
                    );
                  },
                ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
