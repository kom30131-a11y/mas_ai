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
  State<SubjectPage> createState() => _LibraryState();
}

class _LibraryState extends State<SubjectPage> {
  final repo = DatabaseRepository.instance;
  List<Map<String, dynamic>> folders = [], content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final f = await repo.getFolders();
    final c = await repo.getContent();
    if (!mounted) return;
    setState(() {
      folders = f.where((x) =>
          x['subject_id'] == widget.subjectId && x['parent_id'] == null).toList();
      content = c.where((x) =>
          x['subject_id'] == widget.subjectId && x['folder_id'] == null).toList();
      loading = false;
    });
  }

  Future<String?> nameDialog(String title, [String value = '']) async {
    final c = TextEditingController(text: value);
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) Navigator.pop(d, c.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder({int? parent, int? id, String old = ''}) async {
    final name = await nameDialog(
      id == null ? 'New Folder' : 'Rename Folder',
      old,
    );
    if (name == null) return;

    if (id == null) {
      await repo.insertFolder(
        name: name,
        parentId: parent,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(folderId: id, name: name);
    }
    await load();
  }

  Future<void> deleteFolder(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete Folder'),
            content: const Text('Delete this folder and all subfolders?'),
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
          children: const [
            _TypeTile('PDF', Icons.picture_as_pdf_outlined, 'pdf'),
            _TypeTile('Word', Icons.description_outlined, 'word'),
            _TypeTile('PowerPoint', Icons.slideshow_outlined, 'ppt'),
            _TypeTile('Text', Icons.text_snippet_outlined, 'txt'),
            _TypeTile('Image', Icons.image_outlined, 'image'),
          ],
        ),
      ),
    );

    if (type == null) return;

    final ext = {
      'pdf': ['pdf'],
      'word': ['doc', 'docx'],
      'ppt': ['ppt', 'pptx'],
      'txt': ['txt'],
      'image': ['jpg', 'jpeg', 'png', 'webp'],
    }[type]!;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final name = file.name;
    final e = p.extension(name).replaceFirst('.', '').toLowerCase();
    final now = DateTime.now().toIso8601String();

    final id = await repo.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(name),
      'type': contentType(e),
      'content': '',
      'file_path': path,
      'original_file_name': name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': name,
      'file_path': path,
      'mime_type': mimeType(e),
      'file_size': File(path).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await load();
  }

  Future<void> openFolder(int id, String name) async {
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
    await load();
  }

  Widget item(Map<String, dynamic> x, bool isFolder) {
    final id = x['id'] as int;
    final name = (isFolder ? x['name'] : x['title']) as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isFolder ? Icons.folder_outlined : iconFor(x['type'])),
        ),
        title: Text(name),
        subtitle: isFolder ? null : Text(x['type']),
        trailing: isFolder
            ? PopupMenuButton<String>(
                onSelected: (v) => v == 'rename'
                    ? folder(id: id, old: name)
                    : deleteFolder(id),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : null,
        onTap: isFolder ? () => openFolder(id, name) : null,
      ),
    );
  }

  Widget section(String title, List<Map<String, dynamic>> data, bool folders) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (data.isEmpty)
            Text(folders ? 'No folders yet' : 'No content yet')
          else
            ...data.map((x) => item(x, folders)),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.subjectName),
          actions: [
            IconButton(
              onPressed: () => folder(),
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
                    section('Folders', folders, true),
                    const SizedBox(height: 20),
                    section('Content', content, false),
                  ],
                ),
              ),
      );
}

class FolderPage extends StatefulWidget {
  final int folderId, subjectId;
  final String folderName;

  const FolderPage({
    super.key,
    required this.folderId,
    required this.folderName,
    required this.subjectId,
  });

  @override
  State<FolderPage> createState() => _FolderState();
}

class _FolderState extends State<FolderPage> {
  final repo = DatabaseRepository.instance;
  List<Map<String, dynamic>> folders = [], content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final f = await repo.getFolders(parentId: widget.folderId);
    final c = await repo.getContent(folderId: widget.folderId);
    if (!mounted) return;
    setState(() {
      folders = f;
      content = c;
      loading = false;
    });
  }

  Future<String?> nameDialog(String title, [String value = '']) async {
    final c = TextEditingController(text: value);
    final r = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (c.text.trim().isNotEmpty) Navigator.pop(d, c.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder() async {
    final name = await nameDialog('New Folder');
    if (name == null) return;

    await repo.insertFolder(
      name: name,
      parentId: widget.folderId,
      subjectId: widget.subjectId,
    );
    await load();
  }

  Future<void> deleteFolder(int id) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Delete Folder'),
            content: const Text('Delete this folder and all subfolders?'),
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

  Future<void> addContent() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (d) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _TypeTile('PDF', Icons.picture_as_pdf_outlined, 'pdf'),
            _TypeTile('Word', Icons.description_outlined, 'word'),
            _TypeTile('PowerPoint', Icons.slideshow_outlined, 'ppt'),
            _TypeTile('Text', Icons.text_snippet_outlined, 'txt'),
            _TypeTile('Image', Icons.image_outlined, 'image'),
          ],
        ),
      ),
    );

    if (type == null) return;

    final ext = {
      'pdf': ['pdf'],
      'word': ['doc', 'docx'],
      'ppt': ['ppt', 'pptx'],
      'txt': ['txt'],
      'image': ['jpg', 'jpeg', 'png', 'webp'],
    }[type]!;

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final path = file.path;
    if (path == null) return;

    final name = file.name;
    final e = p.extension(name).replaceFirst('.', '').toLowerCase();
    final now = DateTime.now().toIso8601String();

    final id = await repo.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': widget.folderId,
      'title': p.basenameWithoutExtension(name),
      'type': contentType(e),
      'content': '',
      'file_path': path,
      'original_file_name': name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': name,
      'file_path': path,
      'mime_type': mimeType(e),
      'file_size': File(path).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await load();
  }

  Future<void> openFolder(int id, String name) async {
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
    await load();
  }

  Widget item(Map<String, dynamic> x, bool isFolder) {
    final id = x['id'] as int;
    final name = (isFolder ? x['name'] : x['title']) as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(isFolder ? Icons.folder_outlined : iconFor(x['type'])),
        ),
        title: Text(name),
        subtitle: isFolder ? null : Text(x['type']),
        trailing: isFolder
            ? PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'rename') {
                    final n = await nameDialog('Rename Folder', name);
                    if (n != null) {
                      await repo.renameFolder(folderId: id, name: n);
                      await load();
                    }
                  } else {
                    await deleteFolder(id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : null,
        onTap: isFolder ? () => openFolder(id, name) : null,
      ),
    );
  }

  Widget section(String title, List<Map<String, dynamic>> data, bool folders) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (data.isEmpty)
            Text(folders ? 'No subfolders yet' : 'No content yet')
          else
            ...data.map((x) => item(x, folders)),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.folderName),
          actions: [
            IconButton(
              onPressed: folder,
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
                    section('Folders', folders, true),
                    const SizedBox(height: 20),
                    section('Content', content, false),
                  ],
                ),
              ),
      );
}

class _TypeTile extends StatelessWidget {
  final String title, value;
  final IconData icon;

  const _TypeTile(this.title, this.icon, this.value);

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => Navigator.pop(context, value),
      );
}

String contentType(String e) => {
      'pdf': 'PDF',
      'doc': 'Word',
      'docx': 'Word',
      'ppt': 'PowerPoint',
      'pptx': 'PowerPoint',
      'txt': 'Text',
      'jpg': 'Image',
      'jpeg': 'Image',
      'png': 'Image',
      'webp': 'Image',
    }[e] ??
    'File';

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
    }[type] ?? Icons.insert_drive_file_outlined;
