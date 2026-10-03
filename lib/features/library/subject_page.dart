import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'actions/content_actions.dart' as actions;
import 'content_viewer_page.dart';
import 'text/text_editor_page.dart';
import 'widgets/library_helpers.dart';

final repo = DatabaseRepository.instance;

Future<String?> ask(
  BuildContext context,
  String title, [
  String? old,
]) async {
  final controller = TextEditingController(text: old);

  final result = await showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final value = controller.text.trim();

            if (value.isNotEmpty) {
              Navigator.pop(context, value);
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

Future<bool> sure(
  BuildContext context,
  String title,
) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: const Text(
            'This item will be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ??
      false;
}

Future<String?> choose(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        [
          'PDF',
          'pdf',
          Icons.picture_as_pdf_outlined,
        ],
        [
          'Word',
          'word',
          Icons.description_outlined,
        ],
        [
          'PowerPoint',
          'ppt',
          Icons.slideshow_outlined,
        ],
        [
          'Text',
          'text',
          Icons.edit_note_outlined,
        ],
        [
          'Image',
          'image',
          Icons.image_outlined,
        ],
      ]
          .map(
            (item) => ListTile(
              leading: Icon(item[2] as IconData),
              title: Text(item[0] as String),
              onTap: () => Navigator.pop(
                context,
                item[1] as String,
              ),
            ),
          )
          .toList(),
    ),
  );
}

Future<void> openContent(
  BuildContext context,
  Map<String, dynamic> item,
  int subjectId,
  int? folderId,
) async {
  if (item['type'] == 'Text') {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TextEditorPage(
          subjectId: subjectId,
          folderId: folderId,
          item: item,
        ),
      ),
    );

    return;
  }

  final path = item['file_path']?.toString();

  if (path == null ||
      path.isEmpty ||
      !File(path).existsSync()) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File is no longer available.',
          ),
        ),
      );
    }

    return;
  }

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ContentViewerPage(
        title:
            item['title']?.toString() ?? 'Content',
        path: path,
        type:
            item['type']?.toString() ?? '',
        extractedText:
            item['content']?.toString(),
      ),
    ),
  );
}

class SubjectPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const SubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectPage> createState() => _SubjectState();
}

class _SubjectState extends State<SubjectPage> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final allFolders = await repo.getFolders();
    final allContent = await repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = allFolders
          .where(
            (item) =>
                item['subject_id'] ==
                    widget.subjectId &&
                item['parent_id'] == null,
          )
          .toList();

      content = allContent
          .where(
            (item) =>
                item['subject_id'] ==
                    widget.subjectId &&
                item['folder_id'] == null,
          )
          .toList();

      loading = false;
    });
  }

  Future<void> folder([
    Map<String, dynamic>? item,
  ]) async {
    final name = await ask(
      context,
      item == null
          ? 'New folder'
          : 'Rename folder',
      item?['name']?.toString(),
    );

    if (name == null) return;

    if (item == null) {
      await repo.insertFolder(
        name: name,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(
        folderId: item['id'] as int,
        name: name,
      );
    }

    if (!mounted) return;

    await load();
  }

  Future<void> deleteFolder(
    Map<String, dynamic> item,
  ) async {
    if (!await sure(
      context,
      'Delete folder?',
    )) {
      return;
    }

    await repo.deleteFolder(item['id'] as int);

    if (!mounted) return;

    await load();
  }

  Future<void> add() async {
    final type = await choose(context);

    if (type == null) return;

    if (type == 'text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextEditorPage(
            subjectId: widget.subjectId,
          ),
        ),
      );
    } else {
      await actions.pickFile(
        type,
        widget.subjectId,
        null,
      );
    }

    if (!mounted) return;

    await load();
  }

  Widget row(
    Map<String, dynamic> item,
    bool isFolder,
  ) {
    final title = isFolder
        ? item['name']?.toString() ?? 'Untitled'
        : item['title']?.toString() ?? 'Untitled';

    return ListTile(
      leading: Icon(
        isFolder
            ? Icons.folder_outlined
            : contentIcon(
                item['type']?.toString(),
              ),
      ),
      title: Text(title),
      onTap: () async {
        if (isFolder) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FolderPage(
                subjectId: widget.subjectId,
                folderId: item['id'] as int,
                folderName:
                    item['name']?.toString() ??
                        'Folder',
              ),
            ),
          );

          if (!mounted) return;

          await load();
        } else {
          await openContent(
            context,
            item,
            widget.subjectId,
            null,
          );

          if (!mounted) return;

          await load();
        }
      },
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (isFolder) {
            if (value == 'r') {
              folder(item);
            } else {
              deleteFolder(item);
            }
          } else {
            if (value == 'r') {
              actions.editContent(
                context,
                item,
                load,
              );
            } else {
              actions.removeContent(
                context,
                item,
                load,
              );
            }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'r',
            child: Text(
              isFolder
                  ? 'Rename folder'
                  : 'Rename',
            ),
          ),
          PopupMenuItem(
            value: 'd',
            child: Text(
              isFolder
                  ? 'Delete folder'
                  : 'Delete',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            onPressed: folder,
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          IconButton(
            onPressed: add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                children: [
                  if (folders.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        8,
                      ),
                      child: Text('Folders'),
                    ),
                    ...folders.map(
                      (item) => row(item, true),
                    ),
                  ],
                  if (content.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        8,
                      ),
                      child: Text('Content'),
                    ),
                    ...content.map(
                      (item) => row(item, false),
                    ),
                  ],
                  if (folders.isEmpty &&
                      content.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No content yet.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

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
  State<FolderPage> createState() => _FolderState();
}

class _FolderState extends State<FolderPage> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final folderItems = await repo.getFolders(
      parentId: widget.folderId,
    );

    final contentItems = await repo.getContent(
      folderId: widget.folderId,
    );

    if (!mounted) return;

    setState(() {
      folders = folderItems;
      content = contentItems;
      loading = false;
    });
  }

  Future<void> folder([
    Map<String, dynamic>? item,
  ]) async {
    final name = await ask(
      context,
      item == null
          ? 'New folder'
          : 'Rename folder',
      item?['name']?.toString(),
    );

    if (name == null) return;

    if (item == null) {
      await repo.insertFolder(
        name: name,
        parentId: widget.folderId,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(
        folderId: item['id'] as int,
        name: name,
      );
    }

    if (!mounted) return;

    await load();
  }

  Future<void> deleteFolder(
    Map<String, dynamic> item,
  ) async {
    if (!await sure(
      context,
      'Delete folder?',
    )) {
      return;
    }

    await repo.deleteFolder(item['id'] as int);

    if (!mounted) return;

    await load();
  }

  Future<void> add() async {
    final type = await choose(context);

    if (type == null) return;

    if (type == 'text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextEditorPage(
            subjectId: widget.subjectId,
            folderId: widget.folderId,
          ),
        ),
      );
    } else {
      await actions.pickFile(
        type,
        widget.subjectId,
        widget.folderId,
      );
    }

    if (!mounted) return;

    await load();
  }

  @override
  Widget build(BuildContext context) {
    final types =
        <String, List<Map<String, dynamic>>>{};

    for (final item in content) {
      final type =
          item['type']?.toString() ?? 'Other';

      types
          .putIfAbsent(
            type,
            () => <Map<String, dynamic>>[],
          )
          .add(item);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            onPressed: folder,
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          IconButton(
            onPressed: add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                children: [
                  if (folders.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        16,
                        16,
                        8,
                      ),
                      child: Text('Folders'),
                    ),
                    ...folders.map(
                      (item) => ListTile(
                        leading: const Icon(
                          Icons.folder_outlined,
                        ),
                        title: Text(
                          item['name']?.toString() ??
                              'Folder',
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FolderPage(
                                subjectId:
                                    widget.subjectId,
                                folderId:
                                    item['id'] as int,
                                folderName:
                                    item['name']
                                            ?.toString() ??
                                        'Folder',
                              ),
                            ),
                          );

                          if (!mounted) return;

                          await load();
                        },
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'r') {
                              folder(item);
                            } else {
                              deleteFolder(item);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'r',
                              child: Text(
                                'Rename folder',
                              ),
                            ),
                            PopupMenuItem(
                              value: 'd',
                              child: Text(
                                'Delete folder',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  ...types.entries.map(
                    (entry) => ListTile(
                      leading: Icon(
                        typeIcon(entry.key),
                      ),
                      title: Text(
                        typeLabel(entry.key),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ContentTypePage(
                              title:
                                  typeLabel(entry.key),
                              items: entry.value,
                              subjectId:
                                  widget.subjectId,
                              folderId:
                                  widget.folderId,
                            ),
                          ),
                        );

                        if (!mounted) return;

                        await load();
                      },
                    ),
                  ),
                  if (folders.isEmpty &&
                      types.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No content yet.',
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class ContentTypePage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int subjectId;
  final int folderId;

  const ContentTypePage({
    super.key,
    required this.title,
    required this.items,
    required this.subjectId,
    required this.folderId,
  });

  @override
  State<ContentTypePage> createState() =>
      _ContentTypeState();
}

class _ContentTypeState
    extends State<ContentTypePage> {
  late List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();

    items = List<Map<String, dynamic>>.from(
      widget.items,
    );
  }

  Future<void> refreshItems() async {
    final latest = await repo.getContent(
      folderId: widget.folderId,
    );

    if (!mounted) return;

    setState(() {
      items = latest
          .where(
            (item) =>
                item['type']?.toString() ==
                widget.items.first['type']?.toString(),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: items.isEmpty
          ? const Center(
              child: Text('No content'),
            )
          : ListView(
              children: items.map(
                (item) {
                  return ListTile(
                    leading: Icon(
                      contentIcon(
                        item['type']?.toString(),
                      ),
                    ),
                    title: Text(
                      item['title']?.toString() ??
                          'Untitled',
                    ),
                    onTap: () async {
                      await openContent(
                        context,
                        item,
                        widget.subjectId,
                        widget.folderId,
                      );

                      if (!mounted) return;

                      await refreshItems();
                    },
                    trailing:
                        PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'r') {
                          await actions.editContent(
                            context,
                            item,
                            refreshItems,
                          );
                        } else {
                          await actions.removeContent(
                            context,
                            item,
                            refreshItems,
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'r',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem(
                          value: 'd',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }
}
