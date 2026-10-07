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

  static const rootName = 'MAS AI';

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

    _root = Directory('/storage/emulated/0/$rootName');
    await _root!.create(recursive: true);
    await _syncTree();
    return true;
  }

  Future<void> syncFolders() async {
    if (_root == null && !await ensureReady()) return;
    await _syncTree();
  }

  Future<Directory?> rootDirectory() async {
    if (_root == null && !await ensureReady()) return null;
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
    final dir = Directory(p.join(root.path, _safeName(subject['name'].toString())));
    await dir.create(recursive: true);
    return dir;
  }

  Future<Directory?> contentDirectory({required int subjectId, required int? folderId}) async {
    final subject = await subjectDirectory(subjectId);
    if (subject == null) return null;
    if (folderId == null) return subject;
    final folder = await _repo.getFolder(folderId);
    if (folder == null || folder['subject_id'] != subjectId) return null;
    return folderDirectory(folderId);
  }

  Future<String?> _folderPath(int folderId) async {
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

      final item = byId[current];
      if (item == null || item['subject_id'] != subjectId) return null;

      parts.insert(0, _safeName(item['name'].toString()));
      current = item['parent_id'] as int?;
    }

    return p.joinAll([
      root.path,
      _safeName(subject['name'].toString()),
      ...parts,
    ]);
  }

  Future<Directory?> folderDirectory(int folderId) async {
    final path = await _folderPath(folderId);
    if (path == null) return null;

    final dir = Directory(path);
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> copyImportedFile({required String sourcePath, required int subjectId, required int? folderId, required String originalName}) async {
    final dir = await contentDirectory(subjectId: subjectId, folderId: folderId);
    if (dir == null) throw const FileSystemException('MAS AI storage is unavailable.');
    final source = File(sourcePath);
    if (!await source.exists()) throw const FileSystemException('Source file not found.');
    final destination = await _uniqueFile(dir, originalName);
    if (p.normalize(source.path) == p.normalize(destination.path)) return source.path;
    await source.copy(destination.path);
    return destination.path;
  }

  Future<String> saveText({required int subjectId, required int? folderId, required String text, required String title, String? oldPath}) async {
    final dir = await contentDirectory(subjectId: subjectId, folderId: folderId);
    if (dir == null) throw const FileSystemException('MAS AI storage is unavailable.');
    final safeTitle = _safeName(title.trim().isEmpty ? 'Material' : title.trim());
    final requested = p.join(dir.path, '$safeTitle.txt');
    final target = File(requested);
    var path = requested;
    if (oldPath != null && oldPath.isNotEmpty) {
      final old = File(oldPath);
      if (await old.exists() && p.normalize(old.path) != p.normalize(requested)) {
        if (await target.exists()) {
          final unique = await _uniqueFile(dir, '$safeTitle.txt');
          await old.rename(unique.path);
          path = unique.path;
        } else {
          await old.rename(requested);
        }
      }
    }
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
    return file.path;
  }

  Future<void> moveContentFile({required Map<String, dynamic> content, required int? destinationFolderId}) async {
    final subjectId = content['subject_id'] as int?;
    if (subjectId == null) throw const FileSystemException('Content subject is missing.');
    final dir = await contentDirectory(subjectId: subjectId, folderId: destinationFolderId);
    if (dir == null) throw const FileSystemException('Destination folder unavailable.');
    final oldPath = content['file_path']?.toString();
    if (oldPath != null && oldPath.isNotEmpty) {
      final source = File(oldPath);
      if (await source.exists()) {
        final destination = await _uniqueFile(dir, p.basename(oldPath));
        if (p.normalize(source.path) != p.normalize(destination.path)) {
          await source.rename(destination.path);
          await _repo.moveContentToFolder(contentId: content['id'] as int, folderId: destinationFolderId, filePath: destination.path);
          await _repo.updateFilePath(contentId: content['id'] as int, filePath: destination.path);
          return;
        }
      }
    }
    await _repo.moveContentToFolder(contentId: content['id'] as int, folderId: destinationFolderId);
  }

  Future<void> renameContentFile({required Map<String, dynamic> content, required String newTitle}) async {
    final oldPath = content['file_path']?.toString();
    if (oldPath == null || oldPath.isEmpty) return;
    final source = File(oldPath);
    if (!await source.exists()) return;
    final extension = p.extension(source.path);
    final base = _safeName(newTitle.trim().isEmpty ? 'Material' : newTitle.trim());
    if (p.basenameWithoutExtension(source.path) == base) return;
    final destination = await _uniqueFile(source.parent, '$base$extension');
    await source.rename(destination.path);
    await _repo.updateFilePath(contentId: content['id'] as int, filePath: destination.path);
  }

  Future<void> deleteContentFile(Map<String, dynamic> content) async {
    final path = content['file_path']?.toString();
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) await file.delete();
  }

  Future<void> _replaceStoredPathPrefix({required String oldPrefix, required String newPrefix}) async {
    final contents = await _repo.getContent();
    final oldPath = p.normalize(oldPrefix);
    final newPath = p.normalize(newPrefix);
    for (final item in contents) {
      final path = item['file_path']?.toString();
      if (path == null || path.isEmpty) continue;
      final normalized = p.normalize(path);
      if (normalized != oldPath && !normalized.startsWith('$oldPath${p.separator}')) continue;
      final suffix = normalized.substring(oldPath.length);
      final updated = p.normalize('$newPath$suffix');
      await _repo.updateContent(contentId: item['id'] as int, filePath: updated);
      await _repo.updateFilePath(contentId: item['id'] as int, filePath: updated);
    }
  }

  Future<void> renameSubjectDirectory({required String oldName, required String newName}) async {
    final root = await rootDirectory();
    if (root == null) return;
    final oldDir = Directory(p.join(root.path, _safeName(oldName)));
    final newDir = Directory(p.join(root.path, _safeName(newName)));
    if (p.normalize(oldDir.path) == p.normalize(newDir.path)) return;
    if (await newDir.exists()) throw const FileSystemException('A folder with the new subject name already exists.');
    if (await oldDir.exists()) {
      await oldDir.rename(newDir.path);
    } else {
      await newDir.create(recursive: true);
    }
    await _replaceStoredPathPrefix(oldPrefix: oldDir.path, newPrefix: newDir.path);
  }

  Future<void> deleteSubjectDirectory(int subjectId) async {
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
    final dir = Directory(p.join(root.path, _safeName(subject['name'].toString())));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  Future<void> renameFolderDirectory({required int folderId, required String oldName, required String newName, int? parentId, int? subjectId}) async {
    final folder = await _repo.getFolder(folderId);
    if (folder == null) return;
    final parent = parentId ?? folder['parent_id'] as int?;
    final subject = subjectId ?? folder['subject_id'] as int?;
    Directory? parentDir;
    if (parent != null) {
      parentDir = await folderDirectory(parent);
    } else if (subject != null) {
      parentDir = await subjectDirectory(subject);
    }
    if (parentDir == null) return;
    final oldDir = Directory(p.join(parentDir.path, _safeName(oldName)));
    final newDir = Directory(p.join(parentDir.path, _safeName(newName)));
    if (p.normalize(oldDir.path) == p.normalize(newDir.path)) return;
    if (await newDir.exists()) throw const FileSystemException('A folder with the new name already exists here.');
    if (await oldDir.exists()) {
      await oldDir.rename(newDir.path);
    } else {
      await newDir.create(recursive: true);
    }
    await _replaceStoredPathPrefix(oldPrefix: oldDir.path, newPrefix: newDir.path);
  }

  Future<void> moveFolderDirectory({required int folderId, required int? destinationParentId}) async {
    final root = await rootDirectory();
    if (root == null) throw const FileSystemException('MAS AI storage is unavailable.');
    final folder = await _repo.getFolder(folderId);
    if (folder == null) throw const FileSystemException('Folder not found.');
    final subjectId = folder['subject_id'] as int?;
    if (subjectId == null) throw const FileSystemException('Folder subject is missing.');
    if (destinationParentId == folderId) throw const FileSystemException('A folder cannot be moved into itself.');
    if (destinationParentId != null) {
      final parent = await _repo.getFolder(destinationParentId);
      if (parent == null || parent['subject_id'] != subjectId) throw const FileSystemException('Invalid destination folder.');
      final folders = await _repo.getAllFolders();
      final byId = <int, Map<String, dynamic>>{for (final item in folders) item['id'] as int: item};
      int? current = destinationParentId;
      final visited = <int>{};
      while (current != null) {
        if (!visited.add(current)) throw const FileSystemException('Invalid folder hierarchy.');
        if (current == folderId) throw const FileSystemException('A folder cannot be moved into its own descendant.');
        current = byId[current]?['parent_id'] as int?;
      }
    }
    final sourcePath = await _folderPath(folderId);
    if (sourcePath == null) throw const FileSystemException('Source folder does not exist.');

    final source = Directory(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('Source folder does not exist.');
    }

    final parent = destinationParentId == null
        ? await subjectDirectory(subjectId)
        : await folderDirectory(destinationParentId);

    if (parent == null) {
      throw const FileSystemException('Destination folder is unavailable.');
    }

    final destination = Directory(
      p.join(parent.path, _safeName(folder['name'].toString())),
    );

    if (p.normalize(source.path) == p.normalize(destination.path)) return;

    if (await destination.exists()) {
      throw const FileSystemException(
        'A folder with the same name already exists in the destination.',
      );
    }

    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    await _replaceStoredPathPrefix(
      oldPrefix: source.path,
      newPrefix: destination.path,
    );
  }

  Future<void> prepareFolderDeletion(int folderId) async {
    final folder = await _repo.getFolder(folderId);
    if (folder == null) return;
    final subjectId = folder['subject_id'] as int?;
    if (subjectId == null) return;
    final root = await subjectDirectory(subjectId);
    if (root == null) return;
    final folders = await _repo.getAllFolders();
    final descendants = <int>{folderId};
    var changed = true;
    while (changed) {
      changed = false;
      for (final item in folders) {
        final id = item['id'] as int;
        final parent = item['parent_id'] as int?;
        if (parent != null && descendants.contains(parent) && !descendants.contains(id)) {
          descendants.add(id);
          changed = true;
        }
      }
    }
    final contents = await _repo.getContent();
    for (final item in contents) {
      final currentFolder = item['folder_id'] as int?;
      if (!descendants.contains(currentFolder)) continue;
      final path = item['file_path']?.toString();
      if (path != null && path.isNotEmpty) {
        final source = File(path);
        if (await source.exists()) {
          final destination = await _uniqueFile(root, p.basename(path));
          await source.rename(destination.path);
          await _repo.moveContentToFolder(contentId: item['id'] as int, folderId: null, filePath: destination.path);
          await _repo.updateFilePath(contentId: item['id'] as int, filePath: destination.path);
          continue;
        }
      }
      await _repo.moveContentToFolder(contentId: item['id'] as int, folderId: null);
    }
    final dir = await folderDirectory(folderId);
    if (dir != null && await dir.exists()) await dir.delete(recursive: true);
  }

  Future<String> hashFile(String path) async => (await sha256.bind(File(path).openRead()).first).toString();

  Future<void> shareFile(String path) async => Share.shareXFiles([XFile(path)]);

  Future<void> shareFolder(Directory directory) async {
    final temp = await getTemporaryDirectory();
    final zipPath = p.join(temp.path, '${p.basename(directory.path)}_${DateTime.now().millisecondsSinceEpoch}.zip');
    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    await encoder.addDirectory(directory);
    await encoder.close();
    await Share.shareXFiles([XFile(zipPath)]);
  }

  Future<void> _syncTree() async {
    final root = _root;
    if (root == null) return;
    await root.create(recursive: true);
    for (final name in ['Content', 'Backups', 'Exports']) {
      await Directory(p.join(root.path, name)).create(recursive: true);
    }
    final subjects = await _repo.getSubjects();
    final byId = <int, Map<String, dynamic>>{for (final s in subjects) s['id'] as int: s};
    for (final subject in subjects) {
      await Directory(p.join(root.path, _safeName(subject['name'].toString()))).create(recursive: true);
    }
    final folders = await _repo.getAllFolders();
    for (final folder in folders) {
      final subjectId = folder['subject_id'] as int?;
      if (subjectId == null || byId[subjectId] == null) continue;
      final parts = <String>[];
      int? current = folder['id'] as int?;
      final visited = <int>{};
      while (current != null) {
        if (!visited.add(current)) break;
        Map<String, dynamic>? currentFolder;
        for (final item in folders) {
          if (item['id'] == current) {
            currentFolder = item;
            break;
          }
        }
        if (currentFolder == null) break;
        parts.insert(0, _safeName(currentFolder['name'].toString()));
        current = currentFolder['parent_id'] as int?;
      }
      if (parts.isEmpty) continue;
      await Directory(p.joinAll([root.path, _safeName(byId[subjectId]!['name'].toString()), ...parts])).create(recursive: true);
    }
  }

  Future<File> _uniqueFile(Directory directory, String name) async {
    final original = _safeName(p.basename(name));
    final extension = p.extension(original);
    final base = extension.isEmpty ? original : original.substring(0, original.length - extension.length);
    var file = File(p.join(directory.path, original));
    var index = 1;
    while (await file.exists()) {
      file = File(p.join(directory.path, '$base ($index)$extension'));
      index++;
    }
    return file;
  }

  String _safeName(String value) {
    final cleaned = value.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(RegExp(r'\.{2,}'), '.').trim();
    if (cleaned.isEmpty || cleaned == '.') return 'Untitled';
    return cleaned;
  }
}
