import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database_repository.dart';

final repo = DatabaseRepository.instance;

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

  Future<String?> dialog(String title, [String? old]) async {
    final c = TextEditingController(text: old);
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder([Map<String, dynamic>? x]) async {
    final n = await dialog(
      x == null ? 'New folder' : 'Rename folder',
      x?['name'],
    );
    if (!mounted || n == null) return;

    if (x == null) {
      await repo.insertFolder(
        name: n,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(
        folderId: x['id'],
        name: n,
      );
    }
    await load();
  }

  Future<bool> confirm(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: const Text('This item will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> deleteFolder(Map<String, dynamic> x) async {
    if (await confirm('Delete folder?')) {
      await repo.deleteFolder(x['id']);
      await load();
    }
  }

  Future<void> deleteContent(Map<String, dynamic> x) async {
    if (await confirm('Delete content?')) {
      await repo.deleteContent(x['id']);
      await load();
    }
  }

  Future<void> rename(Map<String, dynamic> x) async {
    final n = await dialog('Rename', x['title']);
    if (!mounted || n == null) return;
    await repo.updateContent(contentId: x['id'], title: n);
    await load();
  }

  Future<String?> choose() {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _type('PDF', 'pdf', Icons.picture_as_pdf_outlined),
          _type('Word', 'word', Icons.description_outlined),
          _type('PowerPoint', 'ppt', Icons.slideshow_outlined),
          _type('Text', 'text', Icons.edit_note_outlined),
          _type('Image', 'image', Icons.image_outlined),
        ],
      ),
    );
  }

  ListTile _type(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> add({int? folderId}) async {
    final t = await choose();
    if (!mounted || t == null) return;

    if (t == 'text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextEditor(
            subjectId: widget.subjectId,
            folderId: folderId,
          ),
        ),
      );
      if (mounted) await load();
      return;
    }

    await pickFile(t, widget.subjectId, folderId);
    if (mounted) await load();
  }

  Widget item(Map<String, dynamic> x, bool isFolder) {
    return ListTile(
      leading: Icon(
        isFolder ? Icons.folder_outlined : icon(x['type']),
      ),
      title: Text(
        isFolder ? x['name'] : (x['title'] ?? 'Untitled'),
      ),
      onTap: isFolder
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FolderPage(
                    subjectId: widget.subjectId,
                    folderId: x['id'],
                    folderName: x['name'],
                  ),
                ),
              );
              if (mounted) await load();
            }
          : x['type'] == 'Text'
              ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TextEditor(
                        subjectId: widget.subjectId,
                        folderId: null,
                        item: x,
                      ),
                    ),
                  );
                  if (mounted) await load();
                }
              : null,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (isFolder) {
            v == 'r' ? folder(x) : deleteFolder(x);
          } else {
            v == 'r' ? rename(x) : deleteContent(x);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'r',
            child: Text(isFolder ? 'Rename folder' : 'Rename'),
          ),
          PopupMenuItem(
            value: 'd',
            child: Text(isFolder ? 'Delete folder' : 'Delete'),
          ),
        ],
      ),
    );
  }

  Widget section(
    String title,
    List<Map<String, dynamic>> data,
    bool isFolder,
  ) {
    if (data.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title),
        ),
        ...data.map((x) => item(x, isFolder)),
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
            onPressed: () => add(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                children: [
                  section('Folders', folders, true),
                  section('Content', content, false),
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

  Future<String?> dialog(String title, [String? old]) async {
    final c = TextEditingController(text: old);
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final v = c.text.trim();
              if (v.isNotEmpty) Navigator.pop(context, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder([Map<String, dynamic>? x]) async {
    final n = await dialog(
      x == null ? 'New folder' : 'Rename folder',
      x?['name'],
    );
    if (!mounted || n == null) return;

    if (x == null) {
      await repo.insertFolder(
        name: n,
        parentId: widget.folderId,
        subjectId: widget.subjectId,
      );
    } else {
      await repo.renameFolder(
        folderId: x['id'],
        name: n,
      );
    }
    await load();
  }

  Future<bool> confirm(String title) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(title),
            content: const Text('This item will be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> deleteFolder(Map<String, dynamic> x) async {
    if (await confirm('Delete folder?')) {
      await repo.deleteFolder(x['id']);
      await load();
    }
  }

  Future<void> deleteContent(Map<String, dynamic> x) async {
    if (await confirm('Delete content?')) {
      await repo.deleteContent(x['id']);
      await load();
    }
  }

  Future<void> rename(Map<String, dynamic> x) async {
    final n = await dialog('Rename', x['title']);
    if (!mounted || n == null) return;
    await repo.updateContent(contentId: x['id'], title: n);
    await load();
  }

  Future<void> add() async {
    final t = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _type('PDF', 'pdf', Icons.picture_as_pdf_outlined),
          _type('Word', 'word', Icons.description_outlined),
          _type('PowerPoint', 'ppt', Icons.slideshow_outlined),
          _type('Text', 'text', Icons.edit_note_outlined),
          _type('Image', 'image', Icons.image_outlined),
        ],
      ),
    );

    if (!mounted || t == null) return;

    if (t == 'text') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TextEditor(
            subjectId: widget.subjectId,
            folderId: widget.folderId,
          ),
        ),
      );
      if (mounted) await load();
      return;
    }

    await pickFile(t, widget.subjectId, widget.folderId);
    if (mounted) await load();
  }

  ListTile _type(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Widget folderItem(Map<String, dynamic> x) {
    return ListTile(
      leading: const Icon(Icons.folder_outlined),
      title: Text(x['name']),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FolderPage(
              subjectId: widget.subjectId,
              folderId: x['id'],
              folderName: x['name'],
            ),
          ),
        );
        if (mounted) await load();
      },
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          v == 'r' ? folder(x) : deleteFolder(x);
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'r',
            child: Text('Rename folder'),
          ),
          PopupMenuItem(
            value: 'd',
            child: Text('Delete folder'),
          ),
        ],
      ),
    );
  }

  Widget contentItem(Map<String, dynamic> x) {
    return ListTile(
      leading: Icon(icon(x['type'])),
      title: Text(x['title'] ?? 'Untitled'),
      onTap: x['type'] == 'Text'
          ? () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TextEditor(
                    subjectId: widget.subjectId,
                    folderId: widget.folderId,
                    item: x,
                  ),
                ),
              );
              if (mounted) await load();
            }
          : null,
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          v == 'r' ? rename(x) : deleteContent(x);
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            onPressed: () => folder(),
            icon: const Icon(Icons.create_new_folder_outlined),
          ),
          IconButton(
            onPressed: add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: load,
              child: ListView(
                children: [
                  if (folders.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Folders'),
                    ),
                  ...folders.map(folderItem),
                  if (content.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text('Content'),
                    ),
                  ...content.map(contentItem),
                ],
              ),
            ),
    );
  }
}

class TextEditor extends StatefulWidget {
  final int subjectId;
  final int? folderId;
  final Map<String, dynamic>? item;

  const TextEditor({
    super.key,
    required this.subjectId,
    required this.folderId,
    this.item,
  });

  @override
  State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late TextEditingController title, text;

  @override
  void initState() {
    super.initState();
    title = TextEditingController(
      text: widget.item?['title'] ?? '',
    );
    text = TextEditingController(
      text: widget.item?['content'] ?? '',
    );
  }

  @override
  void dispose() {
    title.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final t = title.text.trim();
    if (t.isEmpty) return;

    if (widget.item == null) {
      await repo.insertContent({
        'subject_id': widget.subjectId,
        'topic_id': null,
        'folder_id': widget.folderId,
        'title': t,
        'type': 'Text',
        'content': text.text,
        'file_path': null,
        'original_file_name': null,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      await repo.updateContent(
        contentId: widget.item!['id'],
        title: t,
        content: text.text,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'New text' : 'Edit text'),
        actions: [
          IconButton(
            onPressed: save,
            icon: const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: text,
                expands: true,
                maxLines: null,
                minLines: null,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> pickFile(
  String type,
  int subjectId,
  int? folderId,
) async {
  final extensions = <String>[
    if (type == 'pdf') 'pdf',
    if (type == 'word') ...['doc', 'docx'],
    if (type == 'ppt') ...['ppt', 'pptx'],
    if (type == 'image') ...['jpg', 'jpeg', 'png', 'webp'],
  ];

  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );

    if (files.isEmpty) return;

    final file = files.first;
    if (file.path == null) return;

    final id = await repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(file.name),
      'type': typeName(type),
      'content': null,
      'file_path': file.path,
      'original_file_name': file.name,
      'created_at': DateTime.now().toIso8601String(),
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': file.name,
      'file_path': file.path,
      'mime_type': mime(type),
      'file_size': file.size,
      'extracted_text': null,
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (_) {}
}

String typeName(String type) => switch (type) {
      'pdf' => 'PDF',
      'word' => 'Word',
      'ppt' => 'PowerPoint',
      'image' => 'Image',
      _ => 'Text',
    };

String? mime(String type) => switch (type) {
      'pdf' => 'application/pdf',
      'word' => 'application/msword',
      'ppt' => 'application/vnd.ms-powerpoint',
      'image' => 'image/*',
      _ => null,
    };

IconData icon(String? type) => switch (type) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'Word' => Icons.description_outlined,
      'PowerPoint' => Icons.slideshow_outlined,
      'Image' => Icons.image_outlined,
      'Text' => Icons.article_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
