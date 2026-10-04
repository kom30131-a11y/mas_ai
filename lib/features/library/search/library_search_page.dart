import 'package:flutter/material.dart';

import '../content/library_content_helper.dart';
import '../subject_page.dart';
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
  setState(() {
    results = [];
    loading = false;
  });
  return;
}

setState(() {
  loading = true;
});

final found = await LibrarySearch.search(query);

if (!mounted) {
  return;
}

setState(() {
  results = found;
  loading = false;
});

}

List<TextSpan> highlight(
BuildContext context,
String text,
String query,
) {
if (query.isEmpty) {
return [
TextSpan(text: text),
];
}

final spans = <TextSpan>[];

final lowerText = text.toLowerCase();
final lowerQuery = query.toLowerCase();

var start = 0;

while (start < text.length) {
  final index =
      lowerText.indexOf(lowerQuery, start);

  if (index < 0) {
    spans.add(
      TextSpan(
        text: text.substring(start),
      ),
    );
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
        color: Theme.of(context)
            .colorScheme
            .primary,
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

if (subjectId is! int) {
  return;
}

if (result.isFolder) {
  final folderId = item['id'];

  if (folderId is! int) {
    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FolderPage(
        subjectId: subjectId,
        folderId: folderId,
        folderName:
            item['name']?.toString() ??
                'Folder',
      ),
    ),
  );

  return;
}

await openContent(
  context,
  item,
  subjectId,
  item['folder_id'] is int
      ? item['folder_id'] as int
      : null,
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
      textInputAction:
          TextInputAction.search,
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
      if (controller.text.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          onPressed: () {
            controller.clear();

            setState(() {
              results = [];
            });
          },
          icon: const Icon(Icons.clear),
        ),
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
              padding:
                  const EdgeInsets.all(12),
              itemCount: results.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1),
              itemBuilder: (_, index) {
                final result =
                    results[index];

                final item = result.item;

                final icon =
                    result.isFolder
                        ? Icons.folder_outlined
                        : contentIcon(
                            item['type']
                                ?.toString(),
                          );

                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    child: Icon(icon),
                  ),
                  title: RichText(
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    text: TextSpan(
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                      children: highlight(
                        context,
                        result.matchedName,
                        query,
                      ),
                    ),
                  ),
                  subtitle: Padding(
                    padding:
                        const EdgeInsets.only(
                      top: 5,
                    ),
                    child: Text(
                      result.path,
                      maxLines: 3,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
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
