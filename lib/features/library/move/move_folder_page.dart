import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../../../core/storage/library_storage_service.dart';

class MoveFolderPage extends StatefulWidget {
  final int folderId;
  final int subjectId;
  final int? currentParentId;

  const MoveFolderPage({
    super.key,
    required this.folderId,
    required this.subjectId,
    required this.currentParentId,
  });

  @override
  State<MoveFolderPage> createState() =>
      _MoveFolderPageState();
}

class _MoveFolderPageState
    extends State<MoveFolderPage> {
  final repo = DatabaseRepository.instance;
  final storage = LibraryStorageService.instance;

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
          .where(
            (item) =>
                item['id'] !=
                widget.folderId,
          )
          .toList();

      loading = false;
    });
  }

  bool isInside(
    int folderId,
  ) {
    var current = folderId;
    final visited = <int>{};

    while (true) {
      if (!visited.add(current)) {
        return true;
      }

      if (current == widget.folderId) {
        return true;
      }

      final item = folders
          .where(
            (x) =>
                x['id'] == current,
          )
          .cast<Map<String, dynamic>>()
          .firstOrNull;

      if (item == null) return false;

      final parent =
          item['parent_id'] as int?;

      if (parent == null) return false;

      current = parent;
    }
  }

  String pathFor(
    int? folderId,
  ) {
    if (folderId == null) {
      return 'MAS AI';
    }

    final byId = <int, Map<String, dynamic>>{
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

    return 'MAS AI / ${names.join(' / ')}';
  }

  Future<void> moveTo(
    int? parentId,
  ) async {
    if (parentId == widget.currentParentId) {
      Navigator.pop(context, false);
      return;
    }

    if (parentId != null &&
        isInside(parentId)) {
      return;
    }

    setState(() => moving = true);

    try {
      await storage.moveFolderDirectory(
        folderId: widget.folderId,
        destinationParentId: parentId,
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
            'Could not move this folder.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final destinations = folders
        .where(
          (item) =>
              !isInside(
            item['id'] as int,
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Move folder'),
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
                    Icons.home_outlined,
                  ),
                  title:
                      const Text('MAS AI'),
                  subtitle:
                      const Text(
                    'Root',
                  ),
                  trailing:
                      widget.currentParentId ==
                              null
                          ? const Icon(
                              Icons.check,
                            )
                          : null,
                  onTap: moving
                      ? null
                      : () => moveTo(null),
                ),
                for (final folder
                    in destinations)
                  ListTile(
                    leading:
                        const Icon(
                      Icons.folder_outlined,
                    ),
                    title: Text(
                      folder['name']
                          .toString(),
                    ),
                    subtitle: Text(
                      pathFor(
                        folder['id']
                            as int,
                      ),
                    ),
                    trailing:
                        widget.currentParentId ==
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
