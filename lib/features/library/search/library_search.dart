import '../../../core/database/database_repository.dart';

class LibrarySearchResult {
  final Map<String, dynamic> item;
  final String path;
  final String matchedName;
  final bool isFolder;

  const LibrarySearchResult({
    required this.item,
    required this.path,
    required this.matchedName,
    required this.isFolder,
  });
}

class LibrarySearch {
  LibrarySearch._();

  static final DatabaseRepository _repo =
      DatabaseRepository.instance;

  static Future<List<Map<String, dynamic>>> _getAllFolders() async {
    final folders = <Map<String, dynamic>>[];
    final visited = <int>{};

    Future<void> load(int? parentId) async {
      final children = await _repo.getFolders(
        parentId: parentId,
      );

      for (final folder in children) {
        final id = folder['id'];

        if (id is! int || !visited.add(id)) {
          continue;
        }

        folders.add(folder);

        await load(id);
      }
    }

    await load(null);

    return folders;
  }

  static Future<List<LibrarySearchResult>> search(
    String query,
  ) async {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return [];
    }

    final subjects = await _repo.getSubjects();
    final folders = await _getAllFolders();
    final materials = await _repo.getContent();

    final subjectNames = <int, String>{};

    for (final subject in subjects) {
      final id = subject['id'];

      if (id is int) {
        subjectNames[id] =
            subject['name']?.toString().trim() ?? 'Subject';
      }
    }

    final folderById = <int, Map<String, dynamic>>{};
    final parentById = <int, int?>{};

    for (final folder in folders) {
      final id = folder['id'];

      if (id is! int) {
        continue;
      }

      folderById[id] = folder;

      final parentId = folder['parent_id'];

      parentById[id] =
          parentId is int ? parentId : null;
    }

    String subjectNameFor(int? subjectId) {
      if (subjectId is int) {
        return subjectNames[subjectId] ?? 'Subject';
      }

      return 'Subject';
    }

    String folderPath(int folderId) {
      final names = <String>[];
      final visited = <int>{};

      int? current = folderId;

      while (current != null &&
          visited.add(current)) {
        final folder = folderById[current];

        if (folder == null) {
          break;
        }

        final name =
            folder['name']?.toString().trim() ?? '';

        if (name.isNotEmpty) {
          names.insert(0, name);
        }

        current = parentById[current];
      }

      final folder = folderById[folderId];

      final subjectId = folder?['subject_id'];

      names.insert(
        0,
        subjectNameFor(subjectId),
      );

      return names.join(' > ');
    }

    final results = <LibrarySearchResult>[];

    // ============================================================
    // Folders
    // ============================================================

    for (final folder in folders) {
      final id = folder['id'];

      if (id is! int) {
        continue;
      }

      final name =
          folder['name']?.toString().trim() ?? '';

      if (name.isEmpty) {
        continue;
      }

      if (!name.toLowerCase().contains(normalized)) {
        continue;
      }

      results.add(
        LibrarySearchResult(
          item: folder,
          path: folderPath(id),
          matchedName: name,
          isFolder: true,
        ),
      );
    }

    // ============================================================
    // Materials
    // ============================================================

    for (final material in materials) {
      final title =
          material['title']?.toString().trim() ?? '';

      final originalFileName =
          material['original_file_name']
                  ?.toString()
                  .trim() ??
              '';

      final searchableNames = [
        title,
        originalFileName,
      ].where(
        (value) => value.isNotEmpty,
      );

      var matched = false;

      for (final name in searchableNames) {
        if (name.toLowerCase().contains(normalized)) {
          matched = true;
          break;
        }
      }

      if (!matched) {
        continue;
      }

      final folderId = material['folder_id'];

      final String path;

      if (folderId is int) {
        final parentPath = folderPath(folderId);

        path = parentPath.isEmpty
            ? (title.isNotEmpty
                ? title
                : originalFileName)
            : '$parentPath > '
                '${title.isNotEmpty ? title : originalFileName}';
      } else {
        final subjectName =
            subjectNameFor(material['subject_id']);

        path =
            '$subjectName > '
            '${title.isNotEmpty ? title : originalFileName}';
      }

      final matchedName =
          title.isNotEmpty ? title : originalFileName;

      results.add(
        LibrarySearchResult(
          item: material,
          path: path,
          matchedName: matchedName,
          isFolder: false,
        ),
      );
    }

    // ============================================================
    // Sort
    // ============================================================

    int rank(String name) {
      final value = name.toLowerCase();

      if (value == normalized) {
        return 0;
      }

      if (value.startsWith(normalized)) {
        return 1;
      }

      if (value.contains(normalized)) {
        return 2;
      }

      return 3;
    }

    results.sort(
      (a, b) {
        final rankCompare = rank(
              a.matchedName,
            ).compareTo(
              rank(b.matchedName),
            );

        if (rankCompare != 0) {
          return rankCompare;
        }

        if (a.isFolder != b.isFolder) {
          return a.isFolder ? -1 : 1;
        }

        return a.path.toLowerCase().compareTo(
              b.path.toLowerCase(),
            );
      },
    );

    return results;
  }
}
