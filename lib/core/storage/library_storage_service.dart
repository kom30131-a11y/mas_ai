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

  Future<bool> ensureReady({
    bool requestPermission = false,
  }) async {
    if (!Platform.isAndroid) {
      final base = await getApplicationDocumentsDirectory();

      _root = Directory(
        p.join(base.path, rootName),
      );

      await _root!.create(recursive: true);

      return true;
    }

    if (!await Permission.manageExternalStorage.isGranted) {
      if (!requestPermission) return false;

      final status =
          await Permission.manageExternalStorage.request();

      if (!status.isGranted) return false;
    }

    _root = Directory(
      '/storage/emulated/0/$rootName',
    );

    await _root!.create(recursive: true);

    return true;
  }

  Future<void> syncFolders() async {
    if (!await ensureReady()) return;

    final folders = await _repo.getAllFolders();

    for (final folder in folders) {
      await folderDirectory(
        folder['id'] as int,
      );
    }
  }

  Future<Directory?> rootDirectory() async {
    if (_root == null && !await ensureReady()) {
      return null;
    }

    return _root;
  }

  Future<Directory?> folderDirectory(
    int? folderId,
  ) async {
    final root = await rootDirectory();

    if (root == null) return null;

    if (folderId == null) return root;

    final parts = <String>[];

    int? current = folderId;

    while (current != null) {
      final folder = await _repo.getFolder(current);

      if (folder == null) return null;

      parts.insert(
        0,
        folder['name'].toString(),
      );

      current = folder['parent_id'] as int?;
    }

    final directory = Directory(
      p.joinAll([
        root.path,
        ...parts,
      ]),
    );

    await directory.create(
      recursive: true,
    );

    return directory;
  }

  Future<String> copyImportedFile({
    required String sourcePath,
    required int? folderId,
    required String originalName,
  }) async {
    final folder = await folderDirectory(folderId);

    if (folder == null) {
      throw const FileSystemException(
        'MAS AI storage is unavailable.',
      );
    }

    final source = File(sourcePath);

    if (!await source.exists()) {
      throw const FileSystemException(
        'Source file not found.',
      );
    }

    final destination = await _uniqueFile(
      folder,
      originalName,
    );

    if (p.normalize(source.path) ==
        p.normalize(destination.path)) {
      return source.path;
    }

    await source.copy(
      destination.path,
    );

    return destination.path;
  }

  Future<String> saveText({
    required String text,
    required String title,
    required int? folderId,
    String? oldPath,
  }) async {
    final folder = await folderDirectory(folderId);

    if (folder == null) {
      throw const FileSystemException(
        'MAS AI storage is unavailable.',
      );
    }

    final name = '$title.txt';

    final file = oldPath == null
        ? await _uniqueFile(folder, name)
        : File(oldPath);

    await file.parent.create(
      recursive: true,
    );

    await file.writeAsString(text);

    return file.path;
  }

  Future<void> moveContentFile({
    required Map<String, dynamic> content,
    required int? destinationFolderId,
  }) async {
    final oldPath =
        content['file_path']?.toString();

    final folder =
        await folderDirectory(destinationFolderId);

    if (folder == null) {
      throw const FileSystemException(
        'Destination folder unavailable.',
      );
    }

    if (oldPath != null && oldPath.isNotEmpty) {
      final source = File(oldPath);

      if (await source.exists()) {
        final destination = await _uniqueFile(
          folder,
          p.basename(oldPath),
        );

        if (p.normalize(source.path) !=
            p.normalize(destination.path)) {
          await source.rename(
            destination.path,
          );

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

  Future<void> prepareFolderDeletion(
    int folderId,
  ) async {
    final root = await rootDirectory();

    if (root == null) return;

    final folders = await _repo.getAllFolders();

    final descendants = <int>{folderId};

    var changed = true;

    while (changed) {
      changed = false;

      for (final folder in folders) {
        final id = folder['id'] as int;
        final parent =
            folder['parent_id'] as int?;

        if (parent != null &&
            descendants.contains(parent) &&
            !descendants.contains(id)) {
          descendants.add(id);
          changed = true;
        }
      }
    }

    final contents = await _repo.getContent();

    for (final item in contents) {
      final current =
          item['folder_id'] as int?;

      if (!descendants.contains(current)) {
        continue;
      }

      final path =
          item['file_path']?.toString();

      if (path != null && path.isNotEmpty) {
        final source = File(path);

        if (await source.exists()) {
          final destination =
              await _uniqueFile(
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

    final folder =
        await _repo.getFolder(folderId);

    if (folder != null) {
      final directory =
          await folderDirectory(folderId);

      if (directory != null &&
          await directory.exists()) {
        await directory.delete(
          recursive: true,
        );
      }
    }
  }

  Future<void> renameFolderDirectory({
    required int folderId,
    required String oldName,
    required String newName,
    int? parentId,
  }) async {
    final parent =
        await folderDirectory(parentId);

    if (parent == null) return;

    final oldDirectory = Directory(
      p.join(parent.path, oldName),
    );

    final newDirectory = Directory(
      p.join(parent.path, newName),
    );

    if (await oldDirectory.exists() &&
        p.normalize(oldDirectory.path) !=
            p.normalize(newDirectory.path)) {
      await oldDirectory.rename(
        newDirectory.path,
      );
    } else {
      await newDirectory.create(
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
    await Share.shareXFiles(
      [XFile(path)],
    );
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

    await encoder.addDirectory(
      directory,
    );

    await encoder.close();

    await Share.shareXFiles(
      [XFile(zipPath)],
    );
  }

  Future<File> _uniqueFile(
    Directory directory,
    String name,
  ) async {
    final safeName =
        name.trim().isEmpty
            ? 'Material'
            : name.trim();

    final extension =
        p.extension(safeName);

    final base = extension.isEmpty
        ? safeName
        : safeName.substring(
            0,
            safeName.length -
                extension.length,
          );

    var candidate = File(
      p.join(
        directory.path,
        safeName,
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
}
