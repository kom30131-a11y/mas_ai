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

String get type {
if (isFolder) return 'Folder';
return item['type']?.toString() ?? 'File';
}
}

class LibrarySearch {
LibrarySearch._();

static final DatabaseRepository _repo =
DatabaseRepository.instance;

static Future<List<Map<String, dynamic>>> _getAllFolders() async {
final result = <Map<String, dynamic>>[];
final visited = <int>{};

Future<void> load(int? parentId) async {
  final folders = await _repo.getFolders(
    parentId: parentId,
  );

  for (final folder in folders) {
    final id = folder['id'];

    if (id is! int || !visited.add(id)) {
      continue;
    }

    result.add(folder);
    await load(id);
  }
}

await load(null);

return result;

}

static Future<List<LibrarySearchResult>> search(
String query,
) async {
final value = query.trim().toLowerCase();

if (value.isEmpty) {
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

final foldersById = <int, Map<String, dynamic>>{};
final parentById = <int, int?>{};

for (final folder in folders) {
  final id = folder['id'];

  if (id is! int) {
    continue;
  }

  foldersById[id] = folder;

  final parentId = folder['parent_id'];

  parentById[id] =
      parentId is int ? parentId : null;
}

String subjectName(int subjectId) {
  return subjectNames[subjectId] ?? 'Subject';
}

String folderPath(int folderId) {
  final names = <String>[];
  final visited = <int>{};

  int? current = folderId;

  while (current != null &&
      visited.add(current)) {
    final folder = foldersById[current];

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

  final folder = foldersById[folderId];
  final subjectId = folder?['subject_id'];

  if (subjectId is int) {
    names.insert(
      0,
      subjectName(subjectId),
    );
  }

  return names.join(' > ');
}

final results = <LibrarySearchResult>[];

// ------------------------------------------------------------
// FOLDERS
// ------------------------------------------------------------

for (final folder in folders) {
  final id = folder['id'];

  if (id is! int) {
    continue;
  }

  final name =
      folder['name']?.toString().trim() ?? '';

  if (name.isEmpty ||
      !name.toLowerCase().contains(value)) {
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

// ------------------------------------------------------------
// MATERIALS
// ------------------------------------------------------------

for (final material in materials) {
  final title =
      material['title']?.toString().trim() ?? '';

  final originalFileName =
      material['original_file_name']
              ?.toString()
              .trim() ??
          '';

  final titleMatch =
      title.toLowerCase().contains(value);

  final fileNameMatch =
      originalFileName.toLowerCase().contains(value);

  if (!titleMatch && !fileNameMatch) {
    continue;
  }

  final folderId = material['folder_id'];

  final String path;

  if (folderId is int) {
    final parentPath = folderPath(folderId);

    path = parentPath.isEmpty
        ? title
        : '$parentPath > $title';
  } else {
    final subjectId = material['subject_id'];

    final subject = subjectId is int
        ? subjectName(subjectId)
        : 'Subject';

    path = '$subject > $title';
  }

  results.add(
    LibrarySearchResult(
      item: material,
      path: path,
      matchedName: title.isNotEmpty
          ? title
          : originalFileName,
      isFolder: false,
    ),
  );
}

results.sort(
  (a, b) {
    final aName = a.matchedName.toLowerCase();
    final bName = b.matchedName.toLowerCase();

    int rank(String name) {
      if (name == value) return 0;
      if (name.startsWith(value)) return 1;
      if (name.contains(value)) return 2;
      return 3;
    }

    final rankCompare =
        rank(aName).compareTo(rank(bName));

    if (rankCompare != 0) {
      return rankCompare;
    }

    if (a.isFolder != b.isFolder) {
      return a.isFolder ? -1 : 1;
    }

    return a.path
        .toLowerCase()
        .compareTo(
          b.path.toLowerCase(),
        );
  },
);

return results;

}
}
