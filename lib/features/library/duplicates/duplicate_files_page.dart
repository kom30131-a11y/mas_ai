import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class DuplicateFilesPage extends StatefulWidget {
  const DuplicateFilesPage({
    super.key,
  });

  @override
  State<DuplicateFilesPage> createState() =>
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
        <String, List<Map<String, dynamic>>>{};

    for (final file in files) {
      final path =
          file['file_path']?.toString();

      if (path == null ||
          path.isEmpty) {
        continue;
      }

      final physical =
          File(path);

      if (!await physical.exists()) {
        continue;
      }

      var hash =
          file['file_hash']?.toString() ??
              '';

      if (hash.isEmpty) {
        hash =
            await storage.hashFile(path);

        await repo.updateFileHash(
          fileId: file['id'] as int,
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

    final result = byHash.values
        .where(
          (group) => group.length > 1,
        )
        .toList();

    if (!mounted) return;

    setState(() {
      groups = result;
      loading = false;
    });
  }

  Future<void> _deleteCopy(
    Map<String, dynamic> file,
  ) async {
    final contentId =
        file['content_id'] as int?;

    final path =
        file['file_path']?.toString();

    if (path != null &&
        path.isNotEmpty) {
      final physical =
          File(path);

      if (await physical.exists()) {
        await physical.delete();
      }
    }

    if (contentId != null) {
      await repo.deleteContent(
        contentId,
      );
    }

    await scan();
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

                    final first =
                        group.first;

                    final firstContent =
                        contentById[
                          first['content_id']
                              as int
                        ];

                    return Card(
                      child:
                          ExpansionTile(
                        leading:
                            const Icon(
                          Icons
                              .copy_all_outlined,
                        ),
                        title: Text(
                          '${group.length} identical files',
                        ),
                        subtitle: Text(
                          firstContent?[
                                    'original_file_name'
                                  ]
                              ?.toString() ??
                              first['file_name']
                                  .toString(),
                        ),
                        children: [
                          for (final file
                              in group)
                            ListTile(
                              title: Text(
                                contentById[
                                      file['content_id']
                                          as int
                                    ]?[
                                      'title'
                                    ]
                                    ?.toString() ??
                                    file['file_name']
                                        .toString(),
                              ),
                              subtitle:
                                  Text(
                                file['file_path']
                                    .toString(),
                              ),
                              trailing:
                                  IconButton(
                                tooltip:
                                    'Delete copy',
                                icon:
                                    const Icon(
                                  Icons
                                      .delete_outline,
                                ),
                                onPressed:
                                    () =>
                                        _deleteCopy(
                                  file,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
