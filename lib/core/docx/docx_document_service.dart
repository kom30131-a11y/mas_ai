import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:quds_office_editor/quds_office_editor.dart';

import '../storage/library_storage_service.dart';

class DocxDocumentService {
  DocxDocumentService._();

  static final instance = DocxDocumentService._();

  final _storage = LibraryStorageService.instance;

  Future<Uint8List> readBytes(String path) async {
    final file = File(path);

    if (!await file.exists()) {
      throw const FileSystemException(
        'DOCX file not found.',
      );
    }

    return file.readAsBytes();
  }

  Future<WordEditorController> openController({
    required String path,
    required OfficeSurfaceConfig config,
  }) async {
    final bytes = await readBytes(path);

    final controller = WordEditorController(
      config: config,
    );

    try {
      await controller.loadBytesAsync(bytes);
      return controller;
    } catch (_) {
      controller.dispose();
      rethrow;
    }
  }

  Future<void> writeAtomic(
    String path,
    Uint8List bytes,
  ) async {
    final target = File(path);
    final temp = File('$path.mas_ai_tmp');
    final backup = File('$path.mas_ai_bak');

    await target.parent.create(
      recursive: true,
    );

    await temp.writeAsBytes(
      bytes,
      flush: true,
    );

    var movedOriginal = false;

    try {
      if (await backup.exists()) {
        await backup.delete();
      }

      if (await target.exists()) {
        await target.rename(
          backup.path,
        );

        movedOriginal = true;
      }

      await temp.rename(
        target.path,
      );

      if (await backup.exists()) {
        await backup.delete();
      }
    } catch (_) {
      if (await temp.exists()) {
        await temp.delete();
      }

      if (movedOriginal &&
          await backup.exists() &&
          !await target.exists()) {
        await backup.rename(
          target.path,
        );
      }

      rethrow;
    }
  }

  Future<String> writeDraft({
    required int contentId,
    required String originalPath,
    required Uint8List bytes,
  }) async {
    final root = await _storage.rootDirectory();

    if (root == null) {
      throw const FileSystemException(
        'MAS AI storage is unavailable.',
      );
    }

    final directory = Directory(
      p.join(
        root.path,
        'Backups',
        'Drafts',
      ),
    );

    await directory.create(
      recursive: true,
    );

    final base = p
        .basenameWithoutExtension(
          originalPath,
        )
        .replaceAll(
          RegExp(r'[\\/:*?"<>|]'),
          '_',
        );

    final path = p.join(
      directory.path,
      '${contentId}_$base.draft.docx',
    );

    await writeAtomic(
      path,
      bytes,
    );

    return path;
  }

  Future<String> exportCopy({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final root = await _storage.rootDirectory();

    if (root == null) {
      throw const FileSystemException(
        'MAS AI storage is unavailable.',
      );
    }

    final directory = Directory(
      p.join(
        root.path,
        'Exports',
      ),
    );

    await directory.create(
      recursive: true,
    );

    final safeName = fileName.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );

    final extension =
        p.extension(safeName).toLowerCase() == '.docx'
            ? ''
            : '.docx';

    final base = p.basenameWithoutExtension(
      safeName,
    );

    var output = File(
      p.join(
        directory.path,
        '$base$extension',
      ),
    );

    var index = 1;

    while (await output.exists()) {
      output = File(
        p.join(
          directory.path,
          '$base ($index)$extension',
        ),
      );

      index++;
    }

    await output.writeAsBytes(
      bytes,
      flush: true,
    );

    return output.path;
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
