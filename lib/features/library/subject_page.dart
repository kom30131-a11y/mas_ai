import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../core/database/database_repository.dart';

final repo = DatabaseRepository.instance;

class SubjectPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  const SubjectPage({super.key, required this.subjectId, required this.subjectName});
  @override State<SubjectPage> createState() => _SubjectState();
}

class _SubjectState extends State<SubjectPage> {
  List<Map<String, dynamic>> folders = [], content = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    final f = await repo.getFolders(), c = await repo.getContent();
    if (!mounted) return;
    setState(() {
      folders = f.where((x) => x['subject_id'] == widget.subjectId && x['parent_id'] == null).toList();
      content = c.where((x) => x['subject_id'] == widget.subjectId && x['folder_id'] == null).toList();
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { final v = c.text.trim(); if (v.isNotEmpty) Navigator.pop(context, v); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder([Map<String, dynamic>? x]) async {
    final n = await dialog(x == null ? 'New folder' : 'Rename folder', x?['name']);
    if (!mounted || n == null) return;
    if (x == null) {
      await repo.insertFolder(name: n, subjectId: widget.subjectId);
    } else {
      await repo.renameFolder(folderId: x['id'], name: n);
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
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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

  Future<void> add({int? folderId}) async {
    final t = await choose();
    if (t == null) return;
    if (t == 'text') {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => TextEditor(subjectId: widget.subjectId, folderId: folderId),
      ));
      if (mounted) await load();
      return;
    }
    await pickFile(t, widget.subjectId, folderId);
    if (mounted) await load();
  }

  Future<String?> choose() => showModalBottomSheet<String>(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ['PDF', 'pdf', Icons.picture_as_pdf_outlined],
        ['Word', 'word', Icons.description_outlined],
        ['PowerPoint', 'ppt', Icons.slideshow_outlined],
        ['Text', 'text', Icons.edit_note_outlined],
        ['Image', 'image', Icons.image_outlined],
      ].map((x) => ListTile(
        leading: Icon(x[2] as IconData),
        title: Text(x[0] as String),
        onTap: () => Navigator.pop(context, x[1] as String),
      )).toList(),
    ),
  );

  Future<void> rename(Map<String, dynamic> x) async {
    final n = await dialog('Rename', x['title']);
    if (!mounted || n == null) return;
    await repo.updateContent(contentId: x['id'], title: n);
    await load();
  }

  Future<void> deleteContent(Map<String, dynamic> x) async {
    if (await confirm('Delete content?')) {
      await repo.deleteContent(x['id']);
      await load();
    }
  }

  Widget item(Map<String, dynamic> x, bool isFolder) => ListTile(
    leading: Icon(isFolder ? Icons.folder_outlined : icon(x['type'])),
    title: Text(isFolder ? x['name'] : (x['title'] ?? 'Untitled')),
    onTap: () async {
      if (isFolder) {
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => FolderPage(
            subjectId: widget.subjectId,
            folderId: x['id'],
            folderName: x['name'],
          ),
        ));
        if (mounted) await load();
      } else if (x['type'] == 'Text') {
        if (!mounted) return;
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => TextEditor(
            subjectId: widget.subjectId,
            folderId: null,
            item: x,
          ),
        ));
        if (mounted) await load();
      }
    },
    trailing: PopupMenuButton<String>(
      onSelected: (v) {
        if (isFolder) {
          v == 'r' ? folder(x) : deleteFolder(x);
        } else {
          v == 'r' ? rename(x) : deleteContent(x);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'r', child: Text(isFolder ? 'Rename folder' : 'Rename')),
        PopupMenuItem(value: 'd', child: Text(isFolder ? 'Delete folder' : 'Delete')),
      ],
    ),
  );

  Widget section(String title, List<Map<String, dynamic>> data, bool isFolder) {
    if (data.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title)),
        ...data.map((x) => item(x, isFolder)),
      ],
    );
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.subjectName),
      actions: [
        IconButton(onPressed: () => folder(), icon: const Icon(Icons.create_new_folder_outlined)),
        IconButton(onPressed: () => add(), icon: const Icon(Icons.add)),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(children: [
              section('Folders', folders, true),
              section('Content', content, false),
            ]),
          ),
  );
}

class FolderPage extends StatefulWidget {
  final int subjectId, folderId;
  final String folderName;
  const FolderPage({super.key, required this.subjectId, required this.folderId, required this.folderName});
  @override State<FolderPage> createState() => _FolderState();
}

class _FolderState extends State<FolderPage> {
  List<Map<String, dynamic>> folders = [], content = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    final f = await repo.getFolders(parentId: widget.folderId);
    final c = await repo.getContent(folderId: widget.folderId);
    if (!mounted) return;
    setState(() { folders = f; content = c; loading = false; });
  }

  Future<String?> choose() => showModalBottomSheet<String>(
    context: context,
    builder: (_) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ['PDF', 'pdf', Icons.picture_as_pdf_outlined],
        ['Word', 'word', Icons.description_outlined],
        ['PowerPoint', 'ppt', Icons.slideshow_outlined],
        ['Text', 'text', Icons.edit_note_outlined],
        ['Image', 'image', Icons.image_outlined],
      ].map((x) => ListTile(
        leading: Icon(x[2] as IconData),
        title: Text(x[0] as String),
        onTap: () => Navigator.pop(context, x[1] as String),
      )).toList(),
    ),
  );

  Future<void> add() async {
    final t = await choose();
    if (t == null) return;
    if (t == 'text') {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => TextEditor(subjectId: widget.subjectId, folderId: widget.folderId),
      ));
      if (mounted) await load();
      return;
    }
    await pickFile(t, widget.subjectId, widget.folderId);
    if (mounted) await load();
  }

  Future<String?> dialog(String title, [String? old]) async {
    final c = TextEditingController(text: old);
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { final v = c.text.trim(); if (v.isNotEmpty) Navigator.pop(context, v); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<void> folder([Map<String, dynamic>? x]) async {
    final n = await dialog(x == null ? 'New folder' : 'Rename folder', x?['name']);
    if (!mounted || n == null) return;
    if (x == null) {
      await repo.insertFolder(name: n, parentId: widget.folderId, subjectId: widget.subjectId);
    } else {
      await repo.renameFolder(folderId: x['id'], name: n);
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
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
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

  Future<void> rename(Map<String, dynamic> x) async {
    final n = await dialog('Rename', x['title']);
    if (!mounted || n == null) return;
    await repo.updateContent(contentId: x['id'], title: n);
    await load();
  }

  Future<void> deleteContent(Map<String, dynamic> x) async {
    if (await confirm('Delete content?')) {
      await repo.deleteContent(x['id']);
      await load();
    }
  }

  Widget sectionFolders() {
    if (folders.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text('Folders')),
        ...folders.map((x) => ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(x['name']),
          onTap: () async {
            if (!mounted) return;
            await Navigator.push(context, MaterialPageRoute(
              builder: (_) => FolderPage(
                subjectId: widget.subjectId,
                folderId: x['id'],
                folderName: x['name'],
              ),
            ));
            if (mounted) await load();
          },
          trailing: PopupMenuButton<String>(
            onSelected: (v) => v == 'r' ? folder(x) : deleteFolder(x),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'r', child: Text('Rename folder')),
              PopupMenuItem(value: 'd', child: Text('Delete folder')),
            ],
          ),
        )),
      ],
    );
  }

  Widget typeFolder(String type, List<Map<String, dynamic>> items) => ListTile(
    leading: Icon(typeIcon(type)),
    title: Text(typeLabel(type)),
    trailing: const Icon(Icons.chevron_right),
    onTap: () async {
      if (!mounted) return;
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ContentTypePage(
          title: typeLabel(type),
          items: items,
          subjectId: widget.subjectId,
          folderId: widget.folderId,
        ),
      ));
      if (mounted) await load();
    },
  );

  List<Widget> contentTypes() {
    final types = <String, List<Map<String, dynamic>>>{};
    for (final x in content) {
      final t = x['type']?.toString() ?? 'Other';
      types.putIfAbsent(t, () => []).add(x);
    }
    return types.entries.map((e) => typeFolder(e.key, e.value)).toList();
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.folderName),
      actions: [
        IconButton(onPressed: () => folder(), icon: const Icon(Icons.create_new_folder_outlined)),
        IconButton(onPressed: add, icon: const Icon(Icons.add)),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: load,
            child: ListView(children: [sectionFolders(), ...contentTypes()]),
          ),
  );
}

class ContentTypePage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final int subjectId, folderId;
  const ContentTypePage({
    super.key,
    required this.title,
    required this.items,
    required this.subjectId,
    required this.folderId,
  });
  @override State<ContentTypePage> createState() => _ContentTypeState();
}

class _ContentTypeState extends State<ContentTypePage> {
  late List<Map<String, dynamic>> items;

  @override void initState() {
    super.initState();
    items = List<Map<String, dynamic>>.from(widget.items);
  }

  Future<String?> dialog(String old) async {
    final c = TextEditingController(text: old);
    final r = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: c, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () { final v = c.text.trim(); if (v.isNotEmpty) Navigator.pop(context, v); },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    c.dispose();
    return r;
  }

  Future<bool> confirm() async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete content?'),
            content: const Text('This item will be deleted.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> rename(Map<String, dynamic> x) async {
    final n = await dialog(x['title'] ?? 'Untitled');
    if (!mounted || n == null) return;
    await repo.updateContent(contentId: x['id'], title: n);
    if (mounted) setState(() => x['title'] = n);
  }

  Future<void> remove(Map<String, dynamic> x) async {
    if (await confirm()) {
      await repo.deleteContent(x['id']);
      if (mounted) setState(() => items.remove(x));
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: items.isEmpty
        ? const Center(child: Text('No content'))
        : ListView(children: [
            for (final x in items)
              ListTile(
                leading: Icon(icon(x['type'])),
                title: Text(x['title'] ?? 'Untitled'),
                onTap: x['type'] == 'Text'
                    ? () async {
                        if (!mounted) return;
                        await Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TextEditor(
                            subjectId: widget.subjectId,
                            folderId: widget.folderId,
                            item: x,
                          ),
                        ));
                      }
                    : null,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => v == 'r' ? rename(x) : remove(x),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'r', child: Text('Rename')),
                    PopupMenuItem(value: 'd', child: Text('Delete')),
                  ],
                ),
              ),
          ]),
  );
}

Future<void> pickFile(String type, int subjectId, int? folderId) async {
  final extensions = <String>[
    if (type == 'pdf') 'pdf',
    if (type == 'word') ...['doc', 'docx'],
    if (type == 'ppt') ...['ppt', 'pptx'],
    if (type == 'image') ...['jpg', 'jpeg', 'png', 'webp'],
  ];

  try {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    final path = f.path;
    if (path == null) return;

    final now = DateTime.now().toIso8601String();
    final id = await repo.insertContent({
      'subject_id': subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(path),
      'type': typeName(type),
      'content': '',
      'file_path': path,
      'original_file_name': f.name,
      'created_at': now,
    });

    await repo.insertFile({
      'content_id': id,
      'file_name': f.name,
      'file_path': path,
      'mime_type': mime(type),
      'file_size': f.size,
      'extracted_text': null,
      'created_at': now,
    });
  } catch (_) {}
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
  @override State<TextEditor> createState() => _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late TextEditingController title, text;

  @override void initState() {
    super.initState();
    title = TextEditingController(text: widget.item?['title'] ?? '');
    text = TextEditingController(text: widget.item?['content'] ?? '');
  }

  @override void dispose() {
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

  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.item == null ? 'New text' : 'Edit text'),
      actions: [
        IconButton(onPressed: save, icon: const Icon(Icons.save_outlined)),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'Title'),
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
      ]),
    ),
  );
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

IconData typeIcon(String type) => icon(type);

String typeLabel(String type) => switch (type) {
  'PDF' => 'PDF',
  'Word' => 'Word',
  'PowerPoint' => 'PowerPoint',
  'Image' => 'Images',
  'Text' => 'Text',
  _ => type,
};
