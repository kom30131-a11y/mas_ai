import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database_repository.dart';

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
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final fs = await repo.getFolders();
    final cs = await repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = fs.where((f) =>
          f['subject_id'] == widget.subjectId &&
          f['parent_id'] == null).toList();

      content = cs.where((c) =>
          c['subject_id'] == widget.subjectId &&
          c['folder_id'] == null).toList();

      loading = false;
    });
  }

  Future<String?> dialog(String title, [String value = '']) async {
    final c = TextEditingController(text: value);

    final result = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) Navigator.pop(d, v.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(d, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    c.dispose();
    return result;
  }

  Future<void> folder({
    int? parentId,
    int? id,
    String? oldName,
  }) async {
    final name = await dialog(
      id == null ? 'New Folder' : 'Rename Folder',
      oldName ?? '',
    );

    if (name == null) return;

    if (id == null) {
      await repo.insertFolder(
        name: name,
        parentId: parentId,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(folderId: id, name: name);
    }

    await load();
  }

  Future<void> removeFolder(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete Folder'),
            content: const Text(
              'Delete this folder and all subfolders?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok) {
      await repo.deleteFolder(id);
      await load();
    }
  }

  Future<void> addContent({int? folderId}) async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (d) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final x in _types)
              ListTile(
                leading: Icon(x.$2),
                title: Text(x.$1),
                onTap: () => Navigator.pop(d, x.$3),
              ),
          ],
        ),
      ),
    );

    if (type == null) return;

    final extensions = _extensions[type]!;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;

    if (path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to access the selected file.'),
          ),
        );
      }
      return;
    }

    final name = file.name;
    final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
    final now = DateTime.now().toIso8601String();

    final id = await repo.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(name),
      'type': typeName(ext),
      'content': '',
      'file_path': path,
      'original_file_name': name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': name,
      'file_path': path,
      'mime_type': mimeType(ext),
      'file_size': File(path).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await load();
  }

  void openFolder(int id, String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          folderId: id,
          folderName: name,
          subjectId: widget.subjectId,
        ),
      ),
    );
    load();
  }

  Widget tile(Map<String, dynamic> x, {bool isFolder = false}) {
    final id = x['id'] as int;
    final name = (isFolder ? x['name'] : x['title']) as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isFolder
                ? Icons.folder_outlined
                : iconFor(x['type'] as String),
          ),
        ),
        title: Text(name),
        subtitle: isFolder ? null : Text(x['type'] as String),
        trailing: isFolder
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'rename') {
                    folder(id: id, oldName: name);
                  } else {
                    removeFolder(id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              )
            : null,
        onTap: isFolder ? () => openFolder(id, name) : null,
      ),
    );
  }

  Widget section(
    String title,
    List<Map<String, dynamic>> items, {
    required bool isFolder,
    required VoidCallback add,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              onPressed: add,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Card(
            child: ListTile(
              leading: Icon(
                isFolder
                    ? Icons.folder_outlined
                    : Icons.description_outlined,
              ),
              title: Text(
                isFolder ? 'No folders yet' : 'No content yet',
              ),
            ),
          )
        else
          ...items.map(
            (x) => tile(x, isFolder: isFolder),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            onPressed: () => folder(),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            onPressed: () => addContent(),
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  section(
                    'Folders',
                    folders,
                    isFolder: true,
                    add: () => folder(),
                  ),
                  const SizedBox(height: 20),
                  section(
                    'Content',
                    content,
                    isFolder: false,
                    add: () => addContent(),
                  ),
                ],
              ),
            ),
    );
  }
}

class FolderPage extends StatefulWidget {
  final int folderId;
  final String folderName;
  final int subjectId;

  const FolderPage({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.subjectId,
  });

  @override
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final fs = await repo.getFolders(parentId: widget.folderId);
    final cs = await repo.getContent(folderId: widget.folderId);

    if (!mounted) return;

    setState(() {
      folders = fs;
      content = cs;
      loading = false;
    });
  }

  Future<void> addFolder() async {
    final c = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Folder name',
          ),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) {
              Navigator.pop(d, v.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(d, v);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    c.dispose();

    if (name == null) return;

    await repo.insertFolder(
      name: name,
      parentId: widget.folderId,
      subjectId: widget.subjectId,
    );

    await load();
  }

  Future<void> rename(int id, String old) async {
    final c = TextEditingController(text: old);

    final name = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Rename Folder'),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(d, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    c.dispose();

    if (name == null) return;

    await repo.renameFolder(folderId: id, name: name);
    await load();
  }

  Future<void> remove(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete Folder'),
            content: const Text(
              'Delete this folder and all subfolders?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (ok) {
      await repo.deleteFolder(id);
      await load();
    }
  }

  void open(int id, String name) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          folderId: id,
          folderName: name,
          subjectId: widget.subjectId,
        ),
      ),
    );
    load();
  }

  Future<void> addContent() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (d) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final x in _types)
              ListTile(
                leading: Icon(x.$2),
                title: Text(x.$1),
                onTap: () => Navigator.pop(d, x.$3),
              ),
          ],
        ),
      ),
    );

    if (type == null) return;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensions[type]!,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final path = file.path;

    if (path == null) return;

    final name = file.name;
    final ext = p.extension(name).replaceFirst('.', '').toLowerCase();
    final now = DateTime.now().toIso8601String();

    final id = await repo.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': widget.folderId,
      'title': p.basenameWithoutExtension(name),
      'type': typeName(ext),
      'content': '',
      'file_path': path,
      'original_file_name': name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': name,
      'file_path': path,
      'mime_type': mimeType(ext),
      'file_size': File(path).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await load();
  }

  Widget item(Map<String, dynamic> x, bool folder) {
    final id = x['id'] as int;
    final name = (folder ? x['name'] : x['title']) as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            folder
                ? Icons.folder_outlined
                : iconFor(x['type'] as String),
          ),
        ),
        title: Text(name),
        subtitle: folder ? null : Text(x['type'] as String),
        trailing: folder
            ? PopupMenuButton<String>(
                onSelected: (v) {
                  v == 'rename'
                      ? rename(id, name)
                      : remove(id);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete'),
                  ),
                ],
              )
            : null,
        onTap: folder ? () => open(id, name) : null,
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
            onPressed: addFolder,
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            onPressed: addContent,
            icon: const Icon(Icons.add_box_outlined),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Folders',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (folders.isEmpty)
                    const Text('No subfolders yet')
                  else
                    ...folders.map((x) => item(x, true)),
                  const SizedBox(height: 20),
                  Text(
                    'Content',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (content.isEmpty)
                    const Text('No content yet')
                  else
                    ...content.map((x) => item(x, false)),
                ],
              ),
            ),
    );
  }
}

const _types = [
  ('PDF', Icons.picture_as_pdf_outlined, 'pdf'),
  ('Word', Icons.description_outlined, 'word'),
  ('PowerPoint', Icons.slideshow_outlined, 'powerpoint'),
  ('Text', Icons.text_snippet_outlined, 'text'),
  ('Image', Icons.image_outlined, 'image'),
];

const _extensions = {
  'pdf': ['pdf'],
  'word': ['doc', 'docx'],
  'powerpoint': ['ppt', 'pptx'],
  'text': ['txt'],
  'image': ['jpg', 'jpeg', 'png', 'webp'],
};

String typeName(String e) {
  if (e == 'pdf') return 'PDF';
  if (e == 'doc' || e == 'docx') return 'Word';
  if (e == 'ppt' || e == 'pptx') return 'PowerPoint';
  if (e == 'txt') return 'Text';
  if (['jpg', 'jpeg', 'png', 'webp'].contains(e)) return 'Image';
  return 'File';
}

String? mimeType(String e) => {
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    }[e];

IconData iconFor(String type) => {
      'PDF': Icons.picture_as_pdf_outlined,
      'Word': Icons.description_outlined,
      'PowerPoint': Icons.slideshow_outlined,
      'Text': Icons.text_snippet_outlined,
      'Image': Icons.image_outlined,
    }[type] ??
    Icons.insert_drive_file_outlined;

_PickTile(
  String title,
  IconData icon,
  String value,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    onTap: () {},
  );
}
