import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'actions/content_actions.dart' as content_actions;
import 'content/library_content_helper.dart';
import 'folder_page.dart';
import 'text/text_editor_page.dart';
import 'widgets/library_helpers.dart';

final _repo = DatabaseRepository.instance;

class SubjectPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const SubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<SubjectPage> createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final allFolders = await _repo.getFolders();
    final allContent = await _repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = allFolders
          .where(
            (item) =>
                item['subject_id'] == widget.subjectId &&
                item['parent_id'] == null,
          )
          .toList();

      content = allContent
          .where(
            (item) =>
                item['subject_id'] == widget.subjectId &&
                item['folder_id'] == null,
          )
          .toList();

      loading = false;
    });
  }

  Future<String?> _ask(
    String title, [
    String? old,
  ]) async {
    final controller = TextEditingController(
      text: old ?? '',
    );

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

  Future<bool> _confirm(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: const Text(
              'This item will be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  false,
                ),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  true,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _folder([
    Map<String, dynamic>? item,
  ]) async {
    final name = await _ask(
      item == null ? 'New folder' : 'Rename folder',
      item?['name']?.toString(),
    );

    if (!mounted || name == null) return;

    if (item == null) {
      await _repo.insertFolder(
        name: name,
        subjectId: widget.subjectId,
      );
    } else {
      await _repo.renameFolder(
        folderId: item['id'],
        name: name,
      );
    }

    await load();
  }

  Future<void> _deleteFolder(
    Map<String, dynamic> item,
  ) async {
    if (!await _confirm('Delete folder?')) {
      return;
    }

    await _repo.deleteFolder(item['id']);
    await load();
  }

  Future<void> _deleteContent(
    Map<String, dynamic> item,
  ) async {
    if (!await _confirm('Delete content?')) {
      return;
    }

    await _repo.deleteContent(item['id']);
    await load();
  }

  Future<void> _renameContent(
    Map<String, dynamic> item,
  ) async {
    await content_actions.editContent(
      context,
      item,
      load,
    );
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
          builder: (_) => TextEditorPage(
            subjectId: widget.subjectId,
          ),
        ),
      );

      if (mounted) {
        await load();
      }

      return;
    }

    await content_actions.pickFile(
      type,
      widget.subjectId,
      null,
    );

    if (mounted) {
      await load();
    }
  }

  Future<void> _openFolder(
    Map<String, dynamic> item,
  ) async {
    final folderId = item['id'];

    if (folderId is! int) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          subjectId: widget.subjectId,
          folderId: folderId,
          folderName:
              item['name']?.toString() ?? 'Folder',
        ),
      ),
    );

    if (mounted) {
      await load();
    }
  }

  Future<void> _openContent(
    Map<String, dynamic> item,
  ) async {
    await openContent(
      context,
      item,
      widget.subjectId,
      null,
    );

    if (mounted) {
      await load();
    }
  }

  PopupMenuButton<String> _menu({
    required bool isFolder,
    required Map<String, dynamic> item,
  }) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (isFolder) {
          if (value == 'rename') {
            _folder(item);
          } else {
            _deleteFolder(item);
          }
        } else {
          if (value == 'rename') {
            _renameContent(item);
          } else {
            _deleteContent(item);
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'rename',
          child: Text(
            isFolder ? 'Rename folder' : 'Rename',
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            isFolder ? 'Delete folder' : 'Delete',
          ),
        ),
      ],
    );
  }

  Widget _folderTile(
    Map<String, dynamic> item,
  ) {
    return ListTile(
      leading: const Icon(
        Icons.folder_outlined,
      ),
      title: Text(
        item['name']?.toString() ?? 'Folder',
      ),
      trailing: _menu(
        isFolder: true,
        item: item,
      ),
      onTap: () => _openFolder(item),
    );
  }

  Widget _contentTile(
    Map<String, dynamic> item,
  ) {
    return ListTile(
      leading: Icon(
        contentIcon(
          item['type']?.toString(),
        ),
      ),
      title: Text(
        item['title']?.toString() ??
            item['name']?.toString() ??
            'Material',
      ),
      trailing: _menu(
        isFolder: false,
        item: item,
      ),
      onTap: () => _openContent(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            tooltip: 'New folder',
            onPressed: _folder,
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Add material',
            onPressed: _addContent,
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: folders.isEmpty &&
                      content.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No folders or materials yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 24,
                      ),
                      children: [
                        if (folders.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
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
                          ...folders.map(_folderTile),
                        ],
                        if (content.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(
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
                          ...content.map(_contentTile),
                        ],
                      ],
                    ),
            ),
    );
  }
}
