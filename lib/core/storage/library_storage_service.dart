import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database_repository.dart';

class LibraryStorageService {
  LibraryStorageService._();

  static final instance = LibraryStorageService._();

  static const rootName = 'MedLibra';

  final _repo = DatabaseRepository.instance;
  Directory? _root;

  Future<bool> ensureReady({bool requestPermission = false}) async {
    if (!Platform.isAndroid) {
      final base = await getApplicationDocumentsDirectory();
      _root = Directory(p.join(base.path, rootName));
      await _root!.create(recursive: true);
      await _syncTree();
      return true;
    }

    if (!await Permission.manageExternalStorage.isGranted) {
      if (!requestPermission) return false;
      final status = await Permission.manageExternalStorage.request();
      if (!status.isGranted) return false;
    }

    final target = Directory('/storage/emulated/0/$rootName');
    final legacy = Directory('/storage/emulated/0/MAS AI');

    if (!await target.exists() && await legacy.exists()) {
      try {
        await legacy.rename(target.path);
      } catch (_) {}
    }

    _root = target;
    await _root!.create(recursive: true);
    await _syncTree();
    return true;
  }

  Future<void> syncFolders() async {
    if (_root == null) {
      final ready = await ensureReady();
      if (!ready) return;
    }

    await _syncTree();
  }

  Future<Directory?> rootDirectory() async {
    if (_root == null) {
      final ready = await ensureReady();
      if (!ready) return null;
    }

    return _root;
  }

  Future<Directory?> subjectDirectory(int subjectId) async {
    final root = await rootDirectory();
    if (root == null) return null;

    final subjects = await _repo.getSubjects();

    Map<String, dynamic>? subject;

    for (final item in subjects) {
      if (item['id'] == subjectId) {
        subject = item;
        break;
      }
    }

    if (subject == null) return null;

    final directory = Directory(
      p.join(
        root.path,
        _safeName(subject['name'].toString()),
      ),
    );

    await directory.create(recursive: true);

    return directory;
  }

  Future<Directory?> contentDirectory({
    required int subjectId,
    required int? folderId,
  }) async {
    final subject = await subjectDirectory(subjectId);

    if (subject == null) return null;

    if (folderId == null) return subject;

    final folder = await _repo.getFolder(folderId);

    if (folder == null || folder['subject_id'] != subjectId) {
      return null;
    }

    return folderDirectory(folderId);
  }

  Future<Directory?> folderDirectory(int folderId) async {
    final root = await rootDirectory();

    if (root == null) return null;

    final folders = await _repo.getAllFolders();

    final byId = <int, Map<String, dynamic>>{
      for (final folder in folders) folder['id'] as int: folder,
    };

    final folder = byId[folderId];

    if (folder == null) return null;

    final subjectId = folder['subject_id'] as int?;

    if (subjectId == null) return null;

    final subjects = await _repo.getSubjects();

    Map<String, dynamic>? subject;

    for (final item in subjects) {
      if (item['id'] == subjectId) {
        subject = item;
        break;
      }
    }

    if (subject == null) return null;

    final parts = <String>[];
    int? current = folderId;
    final visited = <int>{};

    while (current != null) {
      if (!visited.add(current)) return null;

      final currentFolder = byId[current];

      if (currentFolder == null) return null;

      if (currentFolder['subject_id'] != subjectId) {
        return null;
      }

      parts.insert(
        0,
        _safeName(currentFolder['name'].toString()),
      );

      current = currentFolder['parent_id'] as int?;
    }

    final directory = Directory(
      p.joinAll([
        root.path,
        _safeName(subject['name'].toString()),
        ...parts,
      ]),
    );

    await directory.create(recursive: true);

    return directory;
  }

  Future<String> copyImportedFile({
    required String sourcePath,
    required int subjectId,
    required int? folderId,
    required String originalName,
  }) async {
    final destinationDir = await contentDirectory(
      subjectId: subjectId,
      folderId: folderId,
    );

    if (destinationDir == null) {
      throw const FileSystemException(
        'MedLibra storage is unavailable.',
      );
    }

    final source = File(sourcePath);

    if (!await source.exists()) {
      throw const FileSystemException(
        'Source file not found.',
      );
    }

    final destination = await _uniqueFile(
      destinationDir,
      originalName,
    );

    if (p.normalize(source.path) ==
        p.normalize(destination.path)) {
      return source.path;
    }

    await source.copy(destination.path);

    return destination.path;
  }

  Future<String> saveText({
    required int subjectId,
    required int? folderId,
    required String text,
    required String title,
    String? oldPath,
  }) async {
    final directory = await contentDirectory(
      subjectId: subjectId,
      folderId: folderId,
    );

    if (directory == null) {
      throw const FileSystemException(
        'MedLibra storage is unavailable.',
      );
    }

    final safeTitle = _safeName(
      title.trim().isEmpty ? 'Material' : title.trim(),
    );

    final requested = p.join(
      directory.path,
      '$safeTitle.txt',
    );

    final target = File(requested);

    String path = requested;

    if (oldPath != null && oldPath.isNotEmpty) {
      final old = File(oldPath);

      if (await old.exists() &&
          p.normalize(old.path) !=
              p.normalize(requested)) {
        if (await target.exists()) {
          final unique = await _uniqueFile(
            directory,
            '$safeTitle.txt',
          );

          await old.rename(unique.path);
          path = unique.path;
        } else {
          await old.rename(requested);
          path = requested;
        }
      }
    }

    final file = File(path);

    await file.parent.create(recursive: true);
    await file.writeAsString(text);

    return file.path;
  }

  Future<void> moveContentFile({
    required Map<String, dynamic> content,
    required int? destinationFolderId,
  }) async {
    final subjectId = content['subject_id'] as int?;

    if (subjectId == null) {
      throw const FileSystemException(
        'Content subject is missing.',
      );
    }

    final destinationDir = await contentDirectory(
      subjectId: subjectId,
      folderId: destinationFolderId,
    );

    if (destinationDir == null) {
      throw const FileSystemException(
        'Destination folder unavailable.',
      );
    }

    final oldPath = content['file_path']?.toString();

    if (oldPath != null && oldPath.isNotEmpty) {
      final source = File(oldPath);

      if (await source.exists()) {
        final destination = await _uniqueFile(
          destinationDir,
          p.basename(oldPath),
        );

        if (p.normalize(source.path) !=
            p.normalize(destination.path)) {
          await source.rename(destination.path);

          await _repo.moveContentToFolder(
            contentId: content['id'] as int,
            folderId: destinationFolderId,
            filePath: destination.path,
          );

          await _repo.updateFilePath(
            contentId: content['id'] as int,
            filePath: destination.path,
          );

          return;
        }
      }
    }

    await _repo.moveContentToFolder(
      contentId: content['id'] as int,
      folderId: destinationFolderId,
    );
  }

  Future<void> renameContentFile({
    required Map<String, dynamic> content,
    required String newTitle,
  }) async {
    final oldPath = content['file_path']?.toString();

    if (oldPath == null || oldPath.isEmpty) return;

    final source = File(oldPath);

    if (!await source.exists()) return;

    final directory = source.parent;
    final extension = p.extension(source.path);

    final base = _safeName(
      newTitle.trim().isEmpty
          ? 'Material'
          : newTitle.trim(),
    );

    final currentBase =
        p.basenameWithoutExtension(source.path);

    if (currentBase == base) return;

    final destination = await _uniqueFile(
      directory,
      '$base$extension',
    );

    await source.rename(destination.path);

    await _repo.updateFilePath(
      contentId: content['id'] as int,
      filePath: destination.path,
    );
  }

  Future<void> deleteContentFile(
    Map<String, dynamic> content,
  ) async {
    final path = content['file_path']?.toString();

    if (path != null && path.isNotEmpty) {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<void> _replaceStoredPathPrefix({
    required String oldPrefix,
    required String newPrefix,
  }) async {
    final contents = await _repo.getContent();

    final normalizedOld = p.normalize(oldPrefix);
    final normalizedNew = p.normalize(newPrefix);

    for (final item in contents) {
      final path = item['file_path']?.toString();

      if (path == null || path.isEmpty) continue;

      final normalizedPath = p.normalize(path);

      if (normalizedPath != normalizedOld &&
          !normalizedPath.startsWith(
            '$normalizedOld${p.separator}',
          )) {
        continue;
      }

      final suffix =
          normalizedPath.substring(normalizedOld.length);

      final newPath = p.normalize(
        '$normalizedNew$suffix',
      );

      await _repo.updateContent(
        contentId: item['id'] as int,
        filePath: newPath,
      );

      await _repo.updateFilePath(
        contentId: item['id'] as int,
        filePath: newPath,
      );
    }
  }

  Future<void> renameSubjectDirectory({
    required String oldName,
    required String newName,
  }) async {
    final root = await rootDirectory();

    if (root == null) return;

    final oldPath = Directory(
      p.join(root.path, _safeName(oldName)),
    );

    final newPath = Directory(
      p.join(root.path, _safeName(newName)),
    );

    if (p.normalize(oldPath.path) ==
        p.normalize(newPath.path)) {
      return;
    }

    if (await newPath.exists()) {
      throw const FileSystemException(
        'A folder with the new subject name already exists.',
      );
    }

    if (await oldPath.exists()) {
      await oldPath.rename(newPath.path);
    } else {
      await newPath.create(recursive: true);
    }

    await _replaceStoredPathPrefix(
      oldPrefix: oldPath.path,
      newPrefix: newPath.path,
    );
  }

  Future<void> deleteSubjectDirectory(
    int subjectId,
  ) async {
    final root = await rootDirectory();

    if (root == null) return;

    final subjects = await _repo.getSubjects();

    Map<String, dynamic>? subject;

    for (final item in subjects) {
      if (item['id'] == subjectId) {
        subject = item;
        break;
      }
    }

    if (subject == null) return;

    final directory = Directory(
      p.join(
        root.path,
        _safeName(subject['name'].toString()),
      ),
    );

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> renameFolderDirectory({
    required int folderId,
    required String oldName,
    required String newName,
    int? parentId,
    int? subjectId,
  }) async {
    final folder = await _repo.getFolder(folderId);

    if (folder == null) return;

    final resolvedParentId =
        parentId ?? folder['parent_id'] as int?;

    final resolvedSubjectId =
        subjectId ?? folder['subject_id'] as int?;

    Directory? parent;

    if (resolvedParentId != null) {
      parent = await folderDirectory(
        resolvedParentId,
      );
    } else if (resolvedSubjectId != null) {
      parent = await subjectDirectory(
        resolvedSubjectId,
      );
    }

    if (parent == null) return;

    final oldDirectory = Directory(
      p.join(
        parent.path,
        _safeName(oldName),
      ),
    );

    final newDirectory = Directory(
      p.join(
        parent.path,
        _safeName(newName),
      ),
    );

    if (p.normalize(oldDirectory.path) ==
        p.normalize(newDirectory.path)) {
      return;
    }

    if (await newDirectory.exists()) {
      throw const FileSystemException(
        'A folder with the new name already exists here.',
      );
    }

    if (await oldDirectory.exists()) {
      await oldDirectory.rename(
        newDirectory.path,
      );
    } else {
      await newDirectory.create(
        recursive: true,
      );
    }

    await _replaceStoredPathPrefix(
      oldPrefix: oldDirectory.path,
      newPrefix: newDirectory.path,
    );
  }

  Future<void> prepareFolderDeletion(
    int folderId,
  ) async {
    final folder = await _repo.getFolder(folderId);

    if (folder == null) return;

    final subjectId =
        folder['subject_id'] as int?;

    if (subjectId == null) return;

    final root =
        await subjectDirectory(subjectId);

    if (root == null) return;

    final folders =
        await _repo.getAllFolders();

    final descendants = <int>{folderId};

    var changed = true;

    while (changed) {
      changed = false;

      for (final item in folders) {
        final id = item['id'] as int;
        final parent =
            item['parent_id'] as int?;

        if (parent != null &&
            descendants.contains(parent) &&
            !descendants.contains(id)) {
          descendants.add(id);
          changed = true;
        }
      }
    }

    final contents =
        await _repo.getContent();

    for (final item in contents) {
      final currentFolder =
          item['folder_id'] as int?;

      if (!descendants.contains(currentFolder)) {
        continue;
      }

      final path =
          item['file_path']?.toString();

      if (path != null && path.isNotEmpty) {
        final source = File(path);

        if (await source.exists()) {
          final destination = await _uniqueFile(
            root,
            p.basename(path),
          );

          await source.rename(
            destination.path,
          );

          await _repo.moveContentToFolder(
            contentId: item['id'] as int,
            folderId: null,
            filePath: destination.path,
          );

          await _repo.updateFilePath(
            contentId: item['id'] as int,
            filePath: destination.path,
          );

          continue;
        }
      }

      await _repo.moveContentToFolder(
        contentId: item['id'] as int,
        folderId: null,
      );
    }

    final directory =
        await folderDirectory(folderId);

    if (directory != null &&
        await directory.exists()) {
      await directory.delete(
        recursive: true,
      );
    }
  }

  Future<String> hashFile(
    String path,
  ) async {
    final digest =
        await sha256.bind(
      File(path).openRead(),
    ).first;

    return digest.toString();
  }

  Future<void> shareFile(
    String path,
  ) async {
    await Share.shareXFiles([
      XFile(path),
    ]);
  }

  Future<void> shareFolder(
    Directory directory,
  ) async {
    final temp =
        await getTemporaryDirectory();

    final zipPath = p.join(
      temp.path,
      '${p.basename(directory.path)}_${DateTime.now().millisecondsSinceEpoch}.zip',
    );

    final encoder = ZipFileEncoder();

    encoder.create(zipPath);

    await encoder.addDirectory(directory);

    await encoder.close();

    await Share.shareXFiles([
      XFile(zipPath),
    ]);
  }

  Future<void> _syncTree() async {
    final root = _root;

    if (root == null) return;

    await root.create(
      recursive: true,
    );

    await Directory(
      p.join(root.path, 'Content'),
    ).create(recursive: true);

    await Directory(
      p.join(root.path, 'Backups'),
    ).create(recursive: true);

    await Directory(
      p.join(root.path, 'Exports'),
    ).create(recursive: true);

    final subjects =
        await _repo.getSubjects();

    final byId =
        <int, Map<String, dynamic>>{
      for (final subject in subjects)
        subject['id'] as int: subject,
    };

    for (final subject in subjects) {
      final directory = Directory(
        p.join(
          root.path,
          _safeName(
            subject['name'].toString(),
          ),
        ),
      );

      await directory.create(
        recursive: true,
      );
    }

    final folders =
        await _repo.getAllFolders();

    for (final folder in folders) {
      final subjectId =
          folder['subject_id'] as int?;

      if (subjectId == null ||
          byId[subjectId] == null) {
        continue;
      }

      final parts = <String>[];

      int? current =
          folder['id'] as int?;

      final visited = <int>{};

      while (current != null) {
        if (!visited.add(current)) {
          break;
        }

        Map<String, dynamic>? currentFolder;

        for (final item in folders) {
          if (item['id'] == current) {
            currentFolder = item;
            break;
          }
        }

        if (currentFolder == null) {
          break;
        }

        parts.insert(
          0,
          _safeName(
            currentFolder['name'].toString(),
          ),
        );

        current =
            currentFolder['parent_id'] as int?;
      }

      if (parts.isEmpty) continue;

      final directory = Directory(
        p.joinAll([
          root.path,
          _safeName(
            byId[subjectId]!['name'].toString(),
          ),
          ...parts,
        ]),
      );

      await directory.create(
        recursive: true,
      );
    }
  }

  Future<File> _uniqueFile(
    Directory directory,
    String name,
  ) async {
    final original =
        _safeName(p.basename(name));

    final extension =
        p.extension(original);

    final base = extension.isEmpty
        ? original
        : original.substring(
            0,
            original.length -
                extension.length,
          );

    var candidate = File(
      p.join(
        directory.path,
        original,
      ),
    );

    var index = 1;

    while (await candidate.exists()) {
      candidate = File(
        p.join(
          directory.path,
          '$base ($index)$extension',
        ),
      );

      index++;
    }

    return candidate;
  }

  String _safeName(String value) {
    final cleaned = value
        .replaceAll(
          RegExp(r'[\\/:*?"<>|]'),
          '_',
        )
        .replaceAll(
          RegExp(r'\.{2,}'),
          '.',
        )
        .trim();

    if (cleaned.isEmpty ||
        cleaned == '.') {
      return 'Untitled';
    }

    return cleaned;
  }
}
