import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class DuplicateFilesPage
    extends StatefulWidget {
  const DuplicateFilesPage({
    super.key,
  });

  @override
  State<DuplicateFilesPage>
      createState() =>
          _DuplicateFilesPageState();
}

class _DuplicateFilesPageState
    extends State<DuplicateFilesPage> {
  final repo =
      DatabaseRepository.instance;

  final storage =
      LibraryStorageService.instance;

  List<List<Map<String, dynamic>>>
      groups = [];

  Map<int, Map<String, dynamic>>
      contentById = {};

  bool loading = true;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    scan();
  }

  Future<void> scan() async {
    if (mounted) {
      setState(() => loading = true);
    }

    final contents =
        await repo.getContent();

    contentById = {
      for (final item in contents)
        item['id'] as int: item,
    };

    final files =
        await repo.getFiles();

    final byHash =
        <String,
            List<Map<String, dynamic>>>{};

    for (final file in files) {
      final path =
          file['file_path']
              ?.toString();

      if (path == null ||
          path.isEmpty) {
        continue;
      }

      final physical =
          File(path);

      if (!await physical.exists()) {
        continue;
      }

      final hash =
          await storage.hashFile(
        path,
      );

      if (file['file_hash']
              ?.toString() !=
          hash) {
        await repo.updateFileHash(
          fileId:
              file['id'] as int,
          hash: hash,
        );
      }

      byHash
          .putIfAbsent(
            hash,
            () => [],
          )
          .add(file);
    }

    final result = byHash
        .values
        .where(
          (group) =>
              group.length > 1,
        )
        .toList();

    if (!mounted) return;

    setState(() {
      groups = result;
      loading = false;
    });
  }

  Future<void> deleteDuplicates(
    List<Map<String, dynamic>>
        group,
  ) async {
    if (group.length < 2) return;

    setState(
      () => deleting = true,
    );

    try {
      final keep = group.first;

      for (final file
          in group.skip(1)) {
        final path =
            file['file_path']
                ?.toString();

        if (path != null &&
            path.isNotEmpty) {
          final physical =
              File(path);

          if (await physical.exists()) {
            await physical.delete();
          }
        }

        final contentId =
            file['content_id']
                as int?;

        if (contentId != null) {
          await repo.deleteContent(
            contentId,
          );
        }
      }

      final keepPath =
          keep['file_path']
              ?.toString();

      if (keepPath != null &&
          keepPath.isNotEmpty) {
        final hash =
            await storage.hashFile(
          keepPath,
        );

        await repo.updateFileHash(
          fileId:
              keep['id'] as int,
          hash: hash,
        );
      }

      await scan();
    } finally {
      if (mounted) {
        setState(
          () => deleting = false,
        );
      }
    }
  }

  String _name(
    Map<String, dynamic> file,
  ) {
    final contentId =
        file['content_id']
            as int?;

    return contentById[contentId]
            ?['title']
        ?.toString() ??
        file['file_name']
            .toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Duplicate files',
        ),
        actions: [
          IconButton(
            tooltip: 'Scan again',
            onPressed:
                loading ? null : scan,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : groups.isEmpty
              ? const Center(
                  child: Text(
                    'No duplicate files found.',
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(
                    12,
                    12,
                    12,
                    24,
                  ),
                  itemCount:
                      groups.length,
                  itemBuilder:
                      (_, index) {
                    final group =
                        groups[index];

                    final main =
                        group.first;

                    final copies =
                        group.length - 1;

                    return Card(
                      child: ListTile(
                        leading:
                            const Icon(
                          Icons.copy_all_outlined,
                        ),
                        title: Text(
                          _name(main),
                        ),
                        subtitle: Text(
                          '$copies duplicate ${copies == 1 ? 'copy' : 'copies'}',
                        ),
                        trailing:
                            FilledButton(
                          onPressed:
                              deleting
                                  ? null
                                  : () =>
                                      deleteDuplicates(
                                    group,
                                  ),
                          child:
                              const Text(
                            'Delete copies',
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
