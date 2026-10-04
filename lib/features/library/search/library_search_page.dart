import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../content/library_content_helper.dart';
import '../subject_page.dart';
import 'library_search.dart';

enum SearchFilter {
all,
folders,
files,
}

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
List<String> recentSearches = [];

SearchFilter filter = SearchFilter.all;

Timer? _debounce;
int _searchRequest = 0;

bool loading = false;

@override
void initState() {
super.initState();
_loadRecentSearches();
}

Future<void> _loadRecentSearches() async {
final prefs =
await SharedPreferences.getInstance();

final saved =
    prefs.getStringList('library_recent_searches') ??
        [];

if (!mounted) return;

setState(() {
  recentSearches = saved;
});

}

Future<void> _saveRecentSearch(
String query,
) async {
final value = query.trim();

if (value.isEmpty) {
  return;
}

recentSearches.removeWhere(
  (item) =>
      item.toLowerCase() ==
      value.toLowerCase(),
);

recentSearches.insert(0, value);

if (recentSearches.length > 8) {
  recentSearches =
      recentSearches.take(8).toList();
}

final prefs =
    await SharedPreferences.getInstance();

await prefs.setStringList(
  'library_recent_searches',
  recentSearches,
);

if (!mounted) return;

setState(() {});

}

Future<void> _clearRecentSearches() async {
recentSearches.clear();

final prefs =
    await SharedPreferences.getInstance();

await prefs.remove(
  'library_recent_searches',
);

if (!mounted) return;

setState(() {});

}

void _onQueryChanged(String value) {
_debounce?.cancel();

final query = value.trim();

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

_debounce = Timer(
  const Duration(milliseconds: 350),
  search,
);

}

Future<void> search() async {
final query = controller.text.trim();

if (query.isEmpty) {
  setState(() {
    results = [];
    loading = false;
  });
  return;
}

final request = ++_searchRequest;

setState(() {
  loading = true;
});

final found =
    await LibrarySearch.search(query);

if (!mounted ||
    request != _searchRequest) {
  return;
}

setState(() {
  results = found;
  loading = false;
});

await _saveRecentSearch(query);

}

List<LibrarySearchResult> get filteredResults {
switch (filter) {
case SearchFilter.folders:
return results
.where((item) => item.isFolder)
.toList();

  case SearchFilter.files:
    return results
        .where((item) => !item.isFolder)
        .toList();

  case SearchFilter.all:
    return results;
}

}

List<TextSpan> _highlight(
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

final lowerText =
    text.toLowerCase();

final lowerQuery =
    query.toLowerCase();

var start = 0;

while (start < text.length) {
  final index =
      lowerText.indexOf(
    lowerQuery,
    start,
  );

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
        text: text.substring(
          start,
          index,
        ),
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
        fontWeight: FontWeight.w800,
        color: Theme.of(context)
            .colorScheme
            .primary,
      ),
    ),
  );

  start =
      index + query.length;
}

return spans;

}

IconData _typeIcon(
LibrarySearchResult result,
) {
if (result.isFolder) {
return Icons.folder_outlined;
}

return contentIcon(
  result.item['type']?.toString(),
);

}

String _typeLabel(
LibrarySearchResult result,
) {
if (result.isFolder) {
return 'Folder';
}

final type =
    result.item['type']
            ?.toString()
            .trim() ??
        '';

switch (type.toLowerCase()) {
  case 'pdf':
    return 'PDF';

  case 'word':
    return 'Word';

  case 'ppt':
  case 'powerpoint':
    return 'PowerPoint';

  case 'text':
    return 'Text';

  case 'image':
    return 'Image';

  default:
    return type.isEmpty
        ? 'File'
        : type;
}

}

Future<void> _openResult(
LibrarySearchResult result,
) async {
final item = result.item;

final subjectId =
    item['subject_id'];

if (subjectId is! int) {
  return;
}

if (result.isFolder) {
  final folderId =
      item['id'];

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

void _useRecentSearch(
String value,
) {
controller.text = value;
controller.selection =
TextSelection.collapsed(
offset: controller.text.length,
);

search();

}

Widget _buildFilterBar() {
return SingleChildScrollView(
scrollDirection: Axis.horizontal,
padding: const EdgeInsets.fromLTRB(
12,
8,
12,
8,
),
child: Row(
children: [
_filterChip(
label: 'All',
filter: SearchFilter.all,
),
const SizedBox(width: 8),
_filterChip(
label: 'Folders',
filter: SearchFilter.folders,
),
const SizedBox(width: 8),
_filterChip(
label: 'Files',
filter: SearchFilter.files,
),
],
),
);
}

Widget filterChip({
required String label,
required SearchFilter filter,
}) {
return FilterChip(
label: Text(label),
selected: this.filter == filter,
onSelected: () {
setState(() {
this.filter = filter;
});
},
);
}

Widget _buildRecentSearches() {
if (recentSearches.isEmpty) {
return const SizedBox.shrink();
}

return ListView(
  padding: const EdgeInsets.all(16),
  children: [
    Row(
      children: [
        const Expanded(
          child: Text(
            'Recent searches',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        TextButton(
          onPressed: _clearRecentSearches,
          child: const Text('Clear'),
        ),
      ],
    ),
    const SizedBox(height: 8),
    ...recentSearches.map(
      (value) => ListTile(
        contentPadding:
            EdgeInsets.zero,
        leading: const Icon(
          Icons.history,
        ),
        title: Text(value),
        trailing: const Icon(
          Icons.north_west,
          size: 18,
        ),
        onTap: () =>
            _useRecentSearch(value),
      ),
    ),
  ],
);

}

Widget _buildEmptyState() {
final query =
controller.text.trim();

if (query.isEmpty) {
  return _buildRecentSearches();
}

final visible =
    filteredResults;

if (visible.isNotEmpty) {
  return const SizedBox.shrink();
}

return Center(
  child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off,
          size: 52,
          color: Theme.of(context)
              .colorScheme
              .outline,
        ),
        const SizedBox(height: 16),
        Text(
          'No results found',
          style: Theme.of(context)
              .textTheme
              .titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Try another file or folder name.',
          textAlign:
              TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium,
        ),
      ],
    ),
  ),
);

}

Widget _buildResult(
LibrarySearchResult result,
) {
final item = result.item;

final titleStyle =
    Theme.of(context)
        .textTheme
        .titleMedium;

return ListTile(
  contentPadding:
      const EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  ),
  leading: CircleAvatar(
    child: Icon(
      _typeIcon(result),
    ),
  ),
  title: RichText(
    maxLines: 2,
    overflow:
        TextOverflow.ellipsis,
    text: TextSpan(
      style: titleStyle,
      children: _highlight(
        context,
        result.matchedName,
        controller.text.trim(),
      ),
    ),
  ),
  subtitle: Padding(
    padding:
        const EdgeInsets.only(top: 6),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          result.path,
          maxLines: 3,
          overflow:
              TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          _typeLabel(result),
          style: Theme.of(context)
              .textTheme
              .labelMedium,
        ),
      ],
    ),
  ),
  trailing: const Icon(
    Icons.chevron_right,
  ),
  onTap: () => _openResult(result),
);

}

@override
Widget build(BuildContext context) {
final visible =
filteredResults;

return Scaffold(
  appBar: AppBar(
    titleSpacing: 0,
    title: TextField(
      controller: controller,
      autofocus: true,
      textInputAction:
          TextInputAction.search,
      onChanged: _onQueryChanged,
      onSubmitted: (_) => search(),
      decoration:
          const InputDecoration(
        hintText:
            'Search files and folders',
        border: InputBorder.none,
      ),
    ),
    actions: [
      if (controller.text.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          onPressed: () {
            _debounce?.cancel();
            controller.clear();

            setState(() {
              results = [];
              loading = false;
            });
          },
          icon: const Icon(
            Icons.clear,
          ),
        ),
      IconButton(
        tooltip: 'Search',
        onPressed: search,
        icon: const Icon(
          Icons.search,
        ),
      ),
    ],
  ),
  body: Column(
    children: [
      _buildFilterBar(),
      const Divider(height: 1),
      Expanded(
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : visible.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding:
                        const EdgeInsets.only(
                      top: 8,
                      bottom: 24,
                    ),
                    itemCount:
                        visible.length,
                    separatorBuilder:
                        (_, __) =>
                            const Divider(
                      height: 1,
                    ),
                    itemBuilder:
                        (_, index) =>
                            _buildResult(
                      visible[index],
                    ),
                  ),
      ),
    ],
  ),
);

}

@override
void dispose() {
_debounce?.cancel();
controller.dispose();
super.dispose();
}
}
