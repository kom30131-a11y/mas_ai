import 'dart:convert';

import '../../../core/database/database_repository.dart';

class LibrarySearchResult {
  final Map<String, dynamic> item;
  final String? folderName;
  final String snippet;
  final bool isFolder;
  final int? folderId;

  const LibrarySearchResult({
    required this.item,
    required this.folderName,
    required this.snippet,
    this.isFolder = false,
    this.folderId,
  });
}

class LibrarySearch {
  LibrarySearch._();

  static final _repo = DatabaseRepository.instance;

  static Future<List<Map<String, dynamic>>> _allFolders() async {
    final result = <Map<String, dynamic>>[];

    Future<void> load(int? parentId) async {
      final folders = await _repo.getFolders(
        parentId: parentId,
      );

      result.addAll(folders);

      for (final folder in folders) {
        final id = folder['id'];

        if (id is int) {
          await load(id);
        }
      }
    }

    await load(null);

    return result;
  }

  static Future<List<LibrarySearchResult>> search(
    String query,
  ) async {
    final value = query.trim().toLowerCase();

    if (value.isEmpty) return [];

    final folders = await _allFolders();
    final content = await _repo.getContent();
    final files = await _repo.getFiles();

    final folderNames = <int, String>{};
    final folderParents = <int, int?>{};

    for (final folder in folders) {
      final id = folder['id'];

      if (id is! int) continue;

      folderNames[id] =
          folder['name']?.toString() ?? '';

      final parent = folder['parent_id'];

      folderParents[id] =
          parent is int ? parent : null;
    }

    String folderPath(int folderId) {
      final names = <String>[];
      int? current = folderId;

      while (current != null) {
        final name = folderNames[current];

        if (name != null && name.isNotEmpty) {
          names.insert(0, name);
        }

        current = folderParents[current];
      }

      return names.join(' / ');
    }

    final folderResults =
        <LibrarySearchResult>[];

    for (final folder in folders) {
      final id = folder['id'];

      if (id is! int) continue;

      final name =
          folder['name']?.toString() ?? '';

      final path = folderPath(id);

      if (name.toLowerCase().contains(value) ||
          path.toLowerCase().contains(value)) {
        folderResults.add(
          LibrarySearchResult(
            item: folder,
            folderName: path,
            snippet: _snippet(
              path,
              value,
            ),
            isFolder: true,
            folderId: id,
          ),
        );
      }
    }

    final filesByContent =
        <int, List<Map<String, dynamic>>>{};

    for (final file in files) {
      final contentId = file['content_id'];

      if (contentId is int) {
        filesByContent
            .putIfAbsent(
              contentId,
              () => <Map<String, dynamic>>[],
            )
            .add(file);
      }
    }

    final results = <LibrarySearchResult>[
      ...folderResults,
    ];

    for (final item in content) {
      final title =
          item['title']?.toString() ?? '';

      final originalFileName =
          item['original_file_name']?.toString() ?? '';

      final folderId =
          item['folder_id'] is int
              ? item['folder_id'] as int
              : null;

      final folderName = folderId == null
          ? null
          : folderPath(folderId);

      final contentText = _plainText(
        item['content']?.toString(),
      );

      final extractedTexts = <String>[];

      final linkedFiles =
          filesByContent[item['id']];

      if (linkedFiles != null) {
        for (final file in linkedFiles) {
          final extracted =
              file['extracted_text']?.toString();

          if (extracted != null &&
              extracted.trim().isNotEmpty) {
            extractedTexts.add(extracted);
          }
        }
      }

      final extractedText =
          extractedTexts.join('\n');

      final titleMatch =
          title.toLowerCase().contains(value);

      final fileNameMatch =
          originalFileName
              .toLowerCase()
              .contains(value);

      final folderMatch =
          folderName
                  ?.toLowerCase()
                  .contains(value) ??
              false;

      final contentMatch =
          contentText.toLowerCase().contains(value);

      final extractedTextMatch =
          extractedText
              .toLowerCase()
              .contains(value);

      if (!titleMatch &&
          !fileNameMatch &&
          !folderMatch &&
          !contentMatch &&
          !extractedTextMatch) {
        continue;
      }

      String sourceText;

      if (contentMatch) {
        sourceText = contentText;
      } else if (extractedTextMatch) {
        sourceText = extractedText;
      } else if (fileNameMatch) {
        sourceText = originalFileName;
      } else if (titleMatch) {
        sourceText = title;
      } else {
        sourceText = folderName ?? '';
      }

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
    if (content == null ||
        content.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(content);

      if (decoded is List) {
        return _deltaText(decoded);
      }

      if (decoded is Map) {
        final ops = decoded['ops'];

        if (ops is List) {
          return _deltaText(ops);
        }
      }
    } catch (_) {}

    return content;
  }

  static String _deltaText(List<dynamic> operations) {
    final buffer = StringBuffer();

    for (final operation in operations) {
      if (operation is! Map) continue;

      final insert = operation['insert'];

      if (insert is String) {
        buffer.write(insert);
      } else if (insert is Map) {
        final text = insert['text'];

        if (text is String) {
          buffer.write(text);
        }
      }
    }

    return buffer.toString();
  }

  static String _snippet(
    String text,
    String query,
  ) {
    final lower = text.toLowerCase();
    final index = lower.indexOf(query);

    if (index < 0) {
      return text.length > 140
          ? '${text.substring(0, 140)}…'
          : text;
    }

    const radius = 70;

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
