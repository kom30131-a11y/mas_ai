import 'dart:convert';

import '../../../core/database/database_repository.dart';

class LibrarySearchResult {
  final Map<String, dynamic> item;
  final String? folderName;
  final String snippet;

  const LibrarySearchResult({
    required this.item,
    required this.folderName,
    required this.snippet,
  });
}

class LibrarySearch {
  LibrarySearch._();

  static final _repo = DatabaseRepository.instance;

  static Future<List<LibrarySearchResult>> search(
    String query,
  ) async {
    final value = query.trim().toLowerCase();

    if (value.isEmpty) return [];

    final folders = await _repo.getFolders();
    final content = await _repo.getContent();

    final folderNames = <int, String>{
      for (final folder in folders)
        if (folder['id'] is int)
          folder['id'] as int:
              folder['name']?.toString() ?? '',
    };

    final results = <LibrarySearchResult>[];

    for (final item in content) {
      final title = item['title']?.toString() ?? '';
      final folderId = item['folder_id'] as int?;
      final folderName = folderId == null
          ? null
          : folderNames[folderId];

      final text = _plainText(
        item['content']?.toString(),
      );

      final titleMatch =
          title.toLowerCase().contains(value);

      final folderMatch =
          folderName?.toLowerCase().contains(value) ??
              false;

      final textMatch =
          text.toLowerCase().contains(value);

      if (!titleMatch && !folderMatch && !textMatch) {
        continue;
      }

      final sourceText = textMatch
          ? text
          : titleMatch
              ? title
              : folderName ?? '';

      results.add(
        LibrarySearchResult(
          item: item,
          folderName: folderName,
          snippet: _snippet(
            sourceText,
            value,
          ),
        ),
      );
    }

    return results;
  }

  static String _plainText(String? content) {
    if (content == null || content.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(content);

      if (decoded is List) {
        final buffer = StringBuffer();

        for (final operation in decoded) {
          if (operation is! Map) continue;

          final insert = operation['insert'];

          if (insert is String) {
            buffer.write(insert);
          }
        }

        return buffer.toString();
      }
    } catch (_) {}

    return content;
  }

  static String _snippet(
    String text,
    String query,
  ) {
    final lower = text.toLowerCase();
    final index = lower.indexOf(query);

    if (index < 0) {
      return text.length > 120
          ? '${text.substring(0, 120)}…'
          : text;
    }

    const radius = 60;

    final start =
        (index - radius).clamp(0, text.length);

    final end =
        (index + query.length + radius)
            .clamp(0, text.length);

    final prefix = start > 0 ? '…' : '';
    final suffix =
        end < text.length ? '…' : '';

    return '$prefix'
        '${text.substring(start, index)}'
        '${text.substring(index, index + query.length)}'
        '${text.substring(index + query.length, end)}'
        '$suffix';
  }
}
