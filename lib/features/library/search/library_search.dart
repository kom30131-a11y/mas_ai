حقimport '../../../core/database/database_repository.dart';

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

static final _repo = DatabaseRepository.instance;

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
        subject['name']?.toString() ?? 'Subject';
  }
}

final folderById = <int, Map<String, dynamic>>{};
final folderParent = <int, int?>{};

for (final folder in folders) {
  final id = folder['id'];

  if (id is! int) {
    continue;
  }

  folderById[id] = folder;

  final parentId = folder['parent_id'];

  folderParent[id] =
      parentId is int ? parentId : null;
}

String subjectPath(int subjectId) {
  return subjectNames[subjectId] ?? 'Subject';
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

    current = folderParent[current];
  }

  final folder = folderById[folderId];

  final subjectId = folder?['subject_id'];

  if (subjectId is int) {
    names.insert(
      0,
      subjectPath(subjectId),
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

  if (name.isEmpty) {
    continue;
  }

  if (!name.toLowerCase().contains(value)) {
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

  final folderId = material['folder_id'];

  String path;

  if (folderId is int) {
    final parentPath = folderPath(folderId);

    path = parentPath.isEmpty
        ? title
        : '$parentPath > $title';
  } else {
    final subjectId = material['subject_id'];

    final subjectName = subjectId is int
        ? subjectPath(subjectId)
        : 'Subject';

    path = '$subjectName > $title';
  }

  final titleMatch =
      title.toLowerCase().contains(value);

  final fileNameMatch =
      originalFileName
          .toLowerCase()
          .contains(value);

  if (!titleMatch && !fileNameMatch) {
    continue;
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
    final folderCompare =
        a.isFolder == b.isFolder ? 0 : a.isFolder ? -1 : 1;

    if (folderCompare != 0) {
      return folderCompare;
    }

    return a.path
        .toLowerCase()
        .compareTo(b.path.toLowerCase());
  },
);

return results;

}
}
