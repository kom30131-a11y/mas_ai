import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class MoveContentPage extends StatefulWidget {
  final Map<String, dynamic> content;
  final int? currentFolderId;
  final int subjectId;

  const MoveContentPage({
    super.key,
    required this.content,
    required this.currentFolderId,
    required this.subjectId,
  });

  @override
  State<MoveContentPage> createState() =>
      _MoveContentPageState();
}

class _MoveContentPageState
    extends State<MoveContentPage> {
  final repo = DatabaseRepository.instance;
  final storage =
      LibraryStorageService.instance;

  List<Map<String, dynamic>> folders = [];

  bool loading = true;
  bool moving = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final all =
        await repo.getAllFolders();

    if (!mounted) return;

    setState(() {
      folders = all
          .where(
            (item) =>
                item['subject_id'] ==
                widget.subjectId,
          )
          .toList();

      loading = false;
    });
  }

  Future<void> moveTo(
    int? folderId,
  ) async {
    if (folderId ==
        widget.currentFolderId) {
      Navigator.pop(context, false);
      return;
    }

    setState(() => moving = true);

    try {
      await storage.moveContentFile(
        content: widget.content,
        destinationFolderId: folderId,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (!mounted) return;

      setState(() => moving = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not move this file.',
          ),
        ),
      );
    }
  }

  String pathFor(int? folderId) {
    if (folderId == null) {
      return 'Library root';
    }

    final byId =
        <int, Map<String, dynamic>>{
      for (final item in folders)
        item['id'] as int: item,
    };

    final names = <String>[];

    int? current = folderId;

    while (current != null) {
      final item = byId[current];

      if (item == null) break;

      names.insert(
        0,
        item['name'].toString(),
      );

      current =
          item['parent_id'] as int?;
    }

    return names.join(' / ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Move material',
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : ListView(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.library_books_outlined,
                  ),
                  title: const Text(
                    'Library root',
                  ),
                  subtitle:
                      Text(pathFor(null)),
                  trailing:
                      widget.currentFolderId ==
                              null
                          ? const Icon(
                              Icons.check,
                            )
                          : null,
                  onTap: moving
                      ? null
                      : () => moveTo(null),
                ),
                for (final folder in folders)
                  ListTile(
                    leading: const Icon(
                      Icons.folder_outlined,
                    ),
                    title: Text(
                      folder['name']
                          .toString(),
                    ),
                    subtitle: Text(
                      pathFor(
                        folder['id'] as int,
                      ),
                    ),
                    trailing:
                        widget.currentFolderId ==
                                folder['id']
                            ? const Icon(
                                Icons.check,
                              )
                            : null,
                    onTap: moving
                        ? null
                        : () => moveTo(
                              folder['id']
                                  as int,
                            ),
                  ),
              ],
            ),
    );
  }
}
