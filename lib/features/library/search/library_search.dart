import '../../../core/database/database_repository.dart';

class LibrarySearchResult {
  final Map<String, dynamic> item;
  final bool isFolder;
  final String matchedName;
  final String path;

  const LibrarySearchResult({
    required this.item,
    required this.isFolder,
    required this.matchedName,
    required this.path,
  });
}

class LibrarySearch {
  static final DatabaseRepository _repo =
      DatabaseRepository.instance;

  static Future<List<LibrarySearchResult>> search(
    String query,
  ) async {
    final normalized = query.trim().toLowerCase();

    if (normalized.isEmpty) {
      return [];
    }

    final subjects = await _repo.getSubjects();
    final folders = await _repo.getFolders();
    final content = await _repo.getContent();

    final subjectNames = <int, String>{};

    for (final subject in subjects) {
      final id = subject['id'];

      if (id is int) {
        subjectNames[id] =
            subject['name']?.toString() ?? 'Subject';
      }
    }

    final childrenByParent =
        <int?, List<Map<String, dynamic>>>{};

    for (final folder in folders) {
      final id = folder['id'];

      if (id is! int) {
        continue;
      }

      final parentId = folder['parent_id'] is int
          ? folder['parent_id'] as int
          : null;

      childrenByParent
          .putIfAbsent(parentId, () => [])
          .add(folder);
    }

    final contentByFolder =
        <int?, List<Map<String, dynamic>>>{};

    for (final item in content) {
      final folderId = item['folder_id'] is int
          ? item['folder_id'] as int
          : null;

      contentByFolder
          .putIfAbsent(folderId, () => [])
          .add(item);
    }

    final results = <LibrarySearchResult>[];
    final visitedFolders = <int>{};

    void addContent(
      Map<String, dynamic> item,
      List<String> parentPath,
      String subjectName,
    ) {
      final name =
          item['title']?.toString() ?? 'Untitled';

      if (!name.toLowerCase().contains(normalized)) {
        return;
      }

      results.add(
        LibrarySearchResult(
          item: item,
          isFolder: false,
          matchedName: name,
          path: [
            subjectName,
            ...parentPath,
            name,
          ].join(' > '),
        ),
      );
    }

    void addFolder(
      Map<String, dynamic> folder,
      List<String> parentPath,
      String subjectName,
    ) {
      final folderId = folder['id'];

      if (folderId is! int ||
          visitedFolders.contains(folderId)) {
        return;
      }

      visitedFolders.add(folderId);

      final name =
          folder['name']?.toString() ?? 'Folder';

      final currentPath = [
        ...parentPath,
        name,
      ];

      if (name.toLowerCase().contains(normalized)) {
        results.add(
          LibrarySearchResult(
            item: folder,
            isFolder: true,
            matchedName: name,
            path: [
              subjectName,
              ...currentPath,
            ].join(' > '),
          ),
        );
      }

      for (final child
          in childrenByParent[folderId] ?? const []) {
        addFolder(
          child,
          currentPath,
          subjectName,
        );
      }

      for (final item
          in contentByFolder[folderId] ?? const []) {
        addContent(
          item,
          currentPath,
          subjectName,
        );
      }
    }

    for (final subject in subjects) {
      final subjectId = subject['id'];

      if (subjectId is! int) {
        continue;
      }

      final subjectName =
          subject['name']?.toString() ?? 'Subject';

      for (final folder
          in childrenByParent[null] ?? const []) {
        if (folder['subject_id'] == subjectId) {
          addFolder(
            folder,
            const [],
            subjectName,
          );
        }
      }

      for (final item
          in contentByFolder[null] ?? const []) {
        if (item['subject_id'] == subjectId) {
          addContent(
            item,
            const [],
            subjectName,
          );
        }
      }
    }

    return results;
  }
}
