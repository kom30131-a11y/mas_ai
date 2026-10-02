import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/database/database_repository.dart';
import 'content_viewer_page.dart';

final repo = DatabaseRepository.instance;

Future<String?> ask(
  BuildContext c,
  String title, [
  String? old,
]) async {
  final x = TextEditingController(text: old);

  final r = await showDialog<String>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: x,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => x.text.trim().isEmpty
              ? null
              : Navigator.pop(c, x.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  x.dispose();
  return r;
}

Future<bool> sure(
  BuildContext c,
  String title,
) async =>
    await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: const Text('This item will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ??
    false;

Future<String?> choose(BuildContext c) =>
    showModalBottomSheet<String>(
      context: c,
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
              (x) => ListTile(
                leading: Icon(x[2] as IconData),
                title: Text(x[0] as String),
                onTap: () => Navigator.pop(
                  c,
                  x[1],
                ),
              ),
            )
            .toList(),
      ),
    );

Future<void> openContent(
  BuildContext c,
  Map<String, dynamic> x,
  int subjectId,
  int? folderId,
) async {
  if (x['type'] == 'Text') {
    await Navigator.push(
      c,
      MaterialPageRoute(
        builder: (_) => TextEditor(
          subjectId: subjectId,
          folderId: folderId,
          item: x,
        ),
      ),
    );
    return;
  }

  final path = x['file_path']?.toString();

  if (path == null ||
      path.isEmpty ||
      !File(path).existsSync()) {
    if (c.mounted) {
      ScaffoldMessenger.of(c).showSnackBar(
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
    c,
    MaterialPageRoute(
      builder: (_) => ContentViewerPage(
        title: x['title'] ?? 'Content',
        path: path,
        type: x['type'] ?? '',
        extractedText: x['content']?.toString(),
      ),
    ),
  );
}

Future<void> pickFile(
  String type,
  int subjectId,
  int? folderId,
) async {
  final ext = {
    'pdf': ['pdf'],
    'word': ['doc', 'docx'],
    'ppt': ['ppt', 'pptx'],
    'image': [
      'jpg',
      'jpeg',
      'png',
      'webp',
    ],
  }[type]!;

  try {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ext,
    );

    if (files.isEmpty) return;

    final f = files.first;
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
      'file_size': await f.length(),
      'extracted_text': null,
      'created_at': now,
    });
  } catch (_) {}
}

Future<void> editContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  final n = await ask(
    c,
    'Rename',
    x['title'],
  );

  if (n == null) return;

  await repo.updateContent(
    contentId: x['id'],
    title: n,
  );

  refresh();
}

Future<void> removeContent(
  BuildContext c,
  Map<String, dynamic> x,
  VoidCallback refresh,
) async {
  if (await sure(c, 'Delete content?')) {
    await repo.deleteContent(x['id']);
    refresh();
  }
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
    final f = await repo.getFolders();
    final c = await repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = f
          .where(
            (x) =>
                x['subject_id'] == widget.subjectId &&
                x['parent_id'] == null,
          )
          .toList();

      content = c
          .where(
            (x) =>
                x['subject_id'] == widget.subjectId &&
                x['folder_id'] == null,
          )
          .toList();

      loading = false;
    });
  }

  Future<void> folder([
    Map<String, dynamic>? x,
  ]) async {
    final n = await ask(
      context,
      x == null ? 'New folder' : 'Rename folder',
      x?['name'],
    );

    if (n == null) return;

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

    if (!mounted) return;
    load();
  }

  Future<void> deleteFolder(
    Map<String, dynamic> x,
  ) async {
    if (await sure(context, 'Delete folder?')) {
      await repo.deleteFolder(x['id']);

      if (!mounted) return;
      load();
    }
  }

  Future<void> add() async {
    final navigator = Navigator.of(context);
    final t = await choose(context);

    if (t == null) return;

    if (t == 'text') {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => TextEditor(
            subjectId: widget.subjectId,
            folderId: null,
          ),
        ),
      );
    } else {
      await pickFile(
        t,
        widget.subjectId,
        null,
      );
    }

    if (!mounted) return;
    load();
  }

  Widget row(
    Map<String, dynamic> x,
    bool folder,
  ) {
    return ListTile(
      leading: Icon(
        folder
            ? Icons.folder_outlined
            : icon(x['type']),
      ),
      title: Text(
        folder
            ? x['name']
            : (x['title'] ?? 'Untitled'),
      ),
      onTap: () async {
        if (folder) {
          final navigator = Navigator.of(context);

          await navigator.push(
            MaterialPageRoute(
              builder: (_) => FolderPage(
                subjectId: widget.subjectId,
                folderId: x['id'],
                folderName: x['name'],
              ),
            ),
          );

          if (!mounted) return;
          load();
        } else {
          await openContent(
            context,
            x,
            widget.subjectId,
            null,
          );

          if (!mounted) return;
          load();
        }
      },
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (folder) {
            v == 'r'
                ? this.folder(x)
                : deleteFolder(x);
          } else {
            v == 'r'
                ? editContent(
                    context,
                    x,
                    load,
                  )
                : removeContent(
                    context,
                    x,
                    load,
                  );
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'r',
            child: Text(
              folder ? 'Rename folder' : 'Rename',
            ),
          ),
          PopupMenuItem(
            value: 'd',
            child: Text(
              folder ? 'Delete folder' : 'Delete',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
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
                        (x) => row(x, true),
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
                        (x) => row(x, false),
                      ),
                    ],
                  ],
                ),
              ),
      );
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
    final f = await repo.getFolders(
      parentId: widget.folderId,
    );

    final c = await repo.getContent(
      folderId: widget.folderId,
    );

    if (mounted) {
      setState(() {
        folders = f;
        content = c;
        loading = false;
      });
    }
  }

  Future<void> folder([
    Map<String, dynamic>? x,
  ]) async {
    final n = await ask(
      context,
      x == null ? 'New folder' : 'Rename folder',
      x?['name'],
    );

    if (n == null) return;

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

    if (!mounted) return;
    load();
  }

  Future<void> deleteFolder(
    Map<String, dynamic> x,
  ) async {
    if (await sure(context, 'Delete folder?')) {
      await repo.deleteFolder(x['id']);

      if (!mounted) return;
      load();
    }
  }

  Future<void> add() async {
    final navigator = Navigator.of(context);
    final t = await choose(context);

    if (t == null) return;

    if (t == 'text') {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => TextEditor(
            subjectId: widget.subjectId,
            folderId: widget.folderId,
          ),
        ),
      );
    } else {
      await pickFile(
        t,
        widget.subjectId,
        widget.folderId,
      );
    }

    if (!mounted) return;
    load();
  }

  @override
  Widget build(BuildContext c) {
    final types =
        <String, List<Map<String, dynamic>>>{};

    for (final x in content) {
      types
          .putIfAbsent(
            x['type']?.toString() ?? 'Other',
            () => [],
          )
          .add(x);
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
                      (x) => ListTile(
                        leading: const Icon(
                          Icons.folder_outlined,
                        ),
                        title: Text(x['name']),
                        onTap: () async {
                          final navigator =
                              Navigator.of(context);

                          await navigator.push(
                            MaterialPageRoute(
                              builder: (_) => FolderPage(
                                subjectId:
                                    widget.subjectId,
                                folderId: x['id'],
                                folderName: x['name'],
                              ),
                            ),
                          );

                          if (!mounted) return;
                          load();
                        },
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'r'
                                  ? folder(x)
                                  : deleteFolder(x),
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
                    (e) => ListTile(
                      leading: Icon(
                        typeIcon(e.key),
                      ),
                      title: Text(
                        typeLabel(e.key),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ContentTypePage(
                            title: typeLabel(e.key),
                            items: e.value,
                            subjectId:
                                widget.subjectId,
                            folderId: widget.folderId,
                          ),
                        ),
                      ).then((_) {
                        if (mounted) load();
                      }),
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
    items = List.from(widget.items);
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: items.isEmpty
            ? const Center(
                child: Text('No content'),
              )
            : ListView(
                children: items
                    .map(
                      (x) => ListTile(
                        leading: Icon(
                          icon(x['type']),
                        ),
                        title: Text(
                          x['title'] ?? 'Untitled',
                        ),
                        onTap: () => openContent(
                          c,
                          x,
                          widget.subjectId,
                          widget.folderId,
                        ),
                        trailing:
                            PopupMenuButton<String>(
                          onSelected: (v) =>
                              v == 'r'
                                  ? editContent(
                                      c,
                                      x,
                                      () => setState(
                                        () {},
                                      ),
                                    )
                                  : removeContent(
                                      c,
                                      x,
                                      () => setState(
                                        () => items
                                            .remove(x),
                                      ),
                                    ),
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
                      ),
                    )
                    .toList(),
              ),
      );
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
  State<TextEditor> createState() =>
      _TextEditorState();
}

class _TextEditorState extends State<TextEditor> {
  late final TextEditingController title;
  late final TextEditingController text;

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
        'created_at':
            DateTime.now().toIso8601String(),
      });
    } else {
      await repo.updateContent(
        contentId: widget.item!['id'],
        title: t,
        content: text.text,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext c) => Scaffold(
        appBar: AppBar(
          title: Text(
            widget.item == null
                ? 'New text'
                : 'Edit text',
          ),
          actions: [
            IconButton(
              onPressed: save,
              icon: const Icon(
                Icons.save_outlined,
              ),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: title,
                decoration:
                    const InputDecoration(
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
                  textAlignVertical:
                      TextAlignVertical.top,
                  decoration:
                      const InputDecoration(
                    labelText: 'Text',
                    border:
                        OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

String typeName(String t) => {
      'pdf': 'PDF',
      'word': 'Word',
      'ppt': 'PowerPoint',
      'image': 'Image',
    }[t] ??
    'Text';

String? mime(String t) => {
      'pdf': 'application/pdf',
      'word': 'application/msword',
      'ppt': 'application/vnd.ms-powerpoint',
      'image': 'image/*',
    }[t];

IconData icon(String? t) => switch (t) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'Word' => Icons.description_outlined,
      'PowerPoint' => Icons.slideshow_outlined,
      'Image' => Icons.image_outlined,
      'Text' => Icons.article_outlined,
      _ => Icons.insert_drive_file_outlined,
    };

IconData typeIcon(String t) => icon(t);

String typeLabel(String t) => {
      'Image': 'Images',
    }[t] ??
    t;
                        
