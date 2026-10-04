import 'package:flutter/material.dart';

import '../content_viewer_page.dart';
import '../text/text_editor_page.dart';
import '../actions/content_actions.dart' as actions;
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

  Future<void> openResult(
    LibrarySearchResult result,
  ) async {
    final item = result.item;
    final type = item['type']?.toString() ?? '';
    final subjectId = item['subject_id'] as int;
    final folderId = item['folder_id'] as int?;

    if (type == 'Text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextEditorPage(
            subjectId: subjectId,
            folderId: folderId,
            item: item,
          ),
        ),
      );

      return;
    }

    final path = item['file_path']?.toString();

    if (path == null || path.isEmpty) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentViewerPage(
          title:
              item['title']?.toString() ?? 'Content',
          path: path,
          type: type,
          extractedText:
              item['content']?.toString(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => search(),
          decoration: const InputDecoration(
            hintText: 'Search library',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
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
                    controller.text.trim().isEmpty
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

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      leading: Icon(
                        contentIcon(
                          item['type']?.toString(),
                        ),
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
                          if (result.folderName != null)
                            Text(
                              result.folderName!,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text(
                            result.snippet,
                            maxLines: 3,
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      onTap: () => openResult(result),
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
