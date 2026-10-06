import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import '../../core/storage/library_storage_service.dart';
import 'actions/content_actions.dart'
    as content_actions;
import 'content/library_content_helper.dart';
import 'text/text_editor_page.dart';
import 'widgets/library_helpers.dart';

final _repo =
    DatabaseRepository.instance;
final _storage =
    LibraryStorageService.instance;

class FolderPage extends StatefulWidget {
  final int subjectId;
  final int folderId;
  final String folderName;

  const FolderPage({
    super.key,
    required this.subjectId,
    required this.folderId,
    required this.folderName,
  });

  @override
  State<FolderPage> createState() =>
      _FolderPageState();
}

class _FolderPageState
    extends State<FolderPage> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final folderItems =
        await _repo.getFolders(
      parentId: widget.folderId,
    );

    final contentItems =
        await _repo.getContent(
      folderId: widget.folderId,
    );

    if (!mounted) return;

    setState(() {
      folders = folderItems
          .where(
            (item) =>
                item['subject_id'] ==
                widget.subjectId,
          )
          .toList();

      content = contentItems
          .where(
            (item) =>
                item['subject_id'] ==
                widget.subjectId,
          )
          .toList();

      loading = false;
    });
  }

  Future<String?> _ask(
    String title, [
    String? old,
  ]) async {
    final controller =
        TextEditingController(
      text: old ?? '',
    );

    final result =
        await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value =
                  controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(
                  context,
                  value,
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    return result;
  }

  Future<bool> _confirm(
    String title,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) =>
              AlertDialog(
            title: Text(title),
            content: const Text(
              'This item will be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  false,
                ),
                child:
                    const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.pop(
                  context,
                  true,
                ),
                child:
                    const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _newFolder() async {
    final name = await _ask(
      'New folder',
    );

    if (!mounted || name == null) {
      return;
    }

    final id =
        await _repo.insertFolder(
      name: name,
      parentId: widget.folderId,
      subjectId: widget.subjectId,
    );

    await _storage.folderDirectory(id);

    await load();
  }

  Future<void> _renameFolder(
    Map<String, dynamic> item,
  ) async {
    final name = await _ask(
      'Rename folder',
      item['name']?.toString(),
    );

    if (!mounted || name == null) {
      return;
    }

    await _storage.renameFolderDirectory(
      folderId: item['id'] as int,
      oldName: item['name'].toString(),
      newName: name,
      parentId: widget.folderId,
    );

    await _repo.renameFolder(
      folderId: item['id'] as int,
      name: name,
    );

    await load();
  }

  Future<void> _deleteFolder(
    Map<String, dynamic> item,
  ) async {
    if (!await _confirm(
      'Delete folder?',
    )) {
      return;
    }

    await _storage.prepareFolderDeletion(
      item['id'] as int,
    );

    await _repo.deleteFolder(
      item['id'] as int,
    );

    await load();
  }

  Future<void> _addContent() async {
    final type = await choose(context);

    if (!mounted || type == null) {
      return;
    }

    if (type == 'text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TextEditorPage(
            subjectId:
                widget.subjectId,
            folderId:
                widget.folderId,
          ),
        ),
      );
    } else {
      await content_actions.pickFile(
        type,
        widget.subjectId,
        widget.folderId,
      );
    }

    if (mounted) await load();
  }

  Future<void> _openFolder(
    Map<String, dynamic> item,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          subjectId:
              widget.subjectId,
          folderId:
              item['id'] as int,
          folderName:
              item['name']?.toString() ??
                  'Folder',
        ),
      ),
    );

    if (mounted) await load();
  }

  Future<void> _openContent(
    Map<String, dynamic> item,
  ) async {
    await openContent(
      context,
      item,
      widget.subjectId,
      widget.folderId,
    );

    if (mounted) await load();
  }

  Future<void> _moveContent(
    Map<String, dynamic> item,
  ) async {
    await moveContent(
      context,
      item,
      widget.subjectId,
      widget.folderId,
    );

    if (mounted) await load();
  }

  Future<void> _deleteContent(
    Map<String, dynamic> item,
  ) async {
    await content_actions
        .removeContent(
      context,
      item,
      load,
    );
  }

  Future<void> _renameContent(
    Map<String, dynamic> item,
  ) async {
    await content_actions
        .editContent(
      context,
      item,
      load,
    );
  }

  PopupMenuButton<String> _menu(
    Map<String, dynamic> item, {
    required bool isFolder,
  }) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (isFolder) {
          switch (value) {
            case 'rename':
              await _renameFolder(item);
              break;

            case 'share':
              final dir =
                  await _storage
                      .folderDirectory(
                item['id'] as int,
              );

              if (dir != null) {
                await _storage
                    .shareFolder(dir);
              }
              break;

            case 'delete':
              await _deleteFolder(item);
              break;
          }
        } else {
          switch (value) {
            case 'rename':
              await _renameContent(item);
              break;

            case 'move':
              await _moveContent(item);
              break;

            case 'share':
              await shareContent(item);
              break;

            case 'delete':
              await _deleteContent(item);
              break;
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'rename',
          child: Text(
            isFolder
                ? 'Rename folder'
                : 'Rename',
          ),
        ),
        if (!isFolder)
          const PopupMenuItem(
            value: 'move',
            child:
                Text('Move to folder'),
          ),
        const PopupMenuItem(
          value: 'share',
          child: Text('Share'),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            isFolder
                ? 'Delete folder'
                : 'Delete',
          ),
        ),
      ],
    );
  }

  void _topMenu() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
              ),
              title:
                  const Text('Add file'),
              onTap: () async {
                Navigator.pop(context);
                await _addContent();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.create_new_folder_outlined,
              ),
              title:
                  const Text('New folder'),
              onTap: () async {
                Navigator.pop(context);
                await _newFolder();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            tooltip: 'More',
            onPressed: _topMenu,
            icon: const Icon(
              Icons.more_vert,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child:
                  folders.isEmpty &&
                          content.isEmpty
                      ? ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(
                              height: 180,
                            ),
                            Center(
                              child: Text(
                                'No folders or materials yet.',
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding:
                              const EdgeInsets.only(
                            top: 8,
                            bottom: 24,
                          ),
                          children: [
                            if (folders.isNotEmpty) ...[
                              const Padding(
                                padding:
                                    EdgeInsets.fromLTRB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  'Folders',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...folders.map(
                                (item) =>
                                    ListTile(
                                  leading:
                                      const Icon(
                                    Icons.folder_outlined,
                                  ),
                                  title: Text(
                                    item['name']
                                        .toString(),
                                  ),
                                  trailing:
                                      _menu(
                                    item,
                                    isFolder:
                                        true,
                                  ),
                                  onTap: () =>
                                      _openFolder(
                                    item,
                                  ),
                                ),
                              ),
                            ],
                            if (content.isNotEmpty) ...[
                              const Padding(
                                padding:
                                    EdgeInsets.fromLTRB(
                                  16,
                                  20,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  'Materials',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                              ...content.map(
                                (item) =>
                                    ListTile(
                                  leading:
                                      Icon(
                                    contentIcon(
                                      item['type']
                                          ?.toString(),
                                    ),
                                  ),
                                  title: Text(
                                    item['title']
                                            ?.toString() ??
                                        'Material',
                                  ),
                                  subtitle:
                                      Text(
                                    item['type']
                                            ?.toString() ??
                                        '',
                                  ),
                                  trailing:
                                      _menu(
                                    item,
                                    isFolder:
                                        false,
                                  ),
                                  onTap: () =>
                                      _openContent(
                                    item,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
            ),
    );
  }
}
