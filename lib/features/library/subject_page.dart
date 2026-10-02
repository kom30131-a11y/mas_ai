import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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
  final DatabaseRepository _repository =
      DatabaseRepository.instance;

  List<Map<String, dynamic>> _folders = [];
  List<Map<String, dynamic>> _content = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final folders = await _repository.getFolders();
    final content = await _repository.getContent();

    if (!mounted) return;

    setState(() {
      _folders = folders
          .where(
            (folder) =>
                folder['subject_id'] == widget.subjectId &&
                folder['parent_id'] == null,
          )
          .toList();

      _content = content
          .where(
            (item) =>
                item['subject_id'] == widget.subjectId &&
                item['folder_id'] == null,
          )
          .toList();

      _isLoading = false;
    });
  }

  Future<String?> _askForName({
    required String title,
    String? initialValue,
    String label = 'Folder name',
  }) async {
    final controller = TextEditingController(
      text: initialValue,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: label,
            ),
            onSubmitted: (value) {
              final name = value.trim();

              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    return result;
  }

  Future<void> _createFolder() async {
    final name = await _askForName(
      title: 'New Folder',
      label: 'Folder name',
    );

    if (name == null) return;

    await _repository.insertFolder(
      name: name,
      subjectId: widget.subjectId,
    );

    await _loadData();
  }

  Future<void> _renameFolder(
    int folderId,
    String currentName,
  ) async {
    final name = await _askForName(
      title: 'Rename Folder',
      initialValue: currentName,
      label: 'Folder name',
    );

    if (name == null) return;

    await _repository.renameFolder(
      folderId: folderId,
      name: name,
    );

    await _loadData();
  }

  Future<void> _deleteFolder(int folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'Delete this folder and all subfolders?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _repository.deleteFolder(folderId);

    await _loadData();
  }

  Future<void> _openFolder(
    int folderId,
    String folderName,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          folderId: folderId,
          folderName: folderName,
          subjectId: widget.subjectId,
        ),
      ),
    );

    await _loadData();
  }

  Future<void> _showAddContentMenu({
    int? folderId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.note_add_outlined),
                  ),
                  title: const Text('Text / Note'),
                  subtitle: const Text(
                    'Write study notes directly',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _createNote(folderId: folderId);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.attach_file),
                  ),
                  title: const Text('Choose File'),
                  subtitle: const Text(
                    'PDF, Word, PowerPoint, TXT or Image',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile(folderId: folderId);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _createNote({
    int? folderId,
  }) async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  autofocus: true,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Example: Cardiovascular drugs',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  minLines: 5,
                  maxLines: 10,
                  textCapitalization:
                      TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Write your study content...',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final title =
                    titleController.text.trim();
                final content =
                    contentController.text.trim();

                if (title.isNotEmpty &&
                    content.isNotEmpty) {
                  Navigator.pop(
                    context,
                    {
                      'title': title,
                      'content': content,
                    },
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    titleController.dispose();
    contentController.dispose();

    if (result == null) return;

    await _repository.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': result['title']!,
      'type': 'note',
      'content': result['content']!,
      'file_path': null,
      'original_file_name': null,
      'created_at':
          DateTime.now().toIso8601String(),
    });

    if (!mounted) return;

    if (folderId == null) {
      await _loadData();
    }
  }

  Future<void> _pickFile({
    int? folderId,
  }) async {
    try {
      final result =
          await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'ppt',
          'pptx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
        ],
        withData: false,
      );

      if (result == null ||
          result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      if (pickedFile.path == null) {
        _showMessage(
          'Unable to access the selected file.',
        );
        return;
      }

      final sourceFile =
          File(pickedFile.path!);

      if (!await sourceFile.exists()) {
        _showMessage(
          'The selected file does not exist.',
        );
        return;
      }

      final appDirectory =
          await getApplicationDocumentsDirectory();

      final contentDirectory = Directory(
        p.join(
          appDirectory.path,
          'mas_ai_content',
        ),
      );

      if (!await contentDirectory.exists()) {
        await contentDirectory.create(
          recursive: true,
        );
      }

      final extension =
          p.extension(pickedFile.name);

      final safeFileName =
          '${DateTime.now().millisecondsSinceEpoch}'
          '_${_sanitizeFileName(pickedFile.name)}';

      final destinationPath = p.join(
        contentDirectory.path,
        safeFileName,
      );

      final savedFile =
          await sourceFile.copy(destinationPath);

      final type =
          _getContentType(extension);

      String extractedText = '';

      if (type == 'text') {
        try {
          extractedText =
              await savedFile.readAsString();
        } catch (_) {
          extractedText = '';
        }
      }

      final contentId =
          await _repository.insertContent({
        'subject_id': widget.subjectId,
        'topic_id': null,
        'folder_id': folderId,
        'title': p.basenameWithoutExtension(
          pickedFile.name,
        ),
        'type': type,
        'content': extractedText,
        'file_path': savedFile.path,
        'original_file_name':
            pickedFile.name,
        'created_at':
            DateTime.now().toIso8601String(),
      });

      await _repository.insertFile({
        'content_id': contentId,
        'file_name': pickedFile.name,
        'file_path': savedFile.path,
        'mime_type':
            _getMimeType(extension),
        'file_size':
            await savedFile.length(),
        'extracted_text': extractedText,
        'created_at':
            DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      _showMessage(
        '${pickedFile.name} added successfully.',
      );

      if (folderId == null) {
        await _loadData();
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Failed to add content: $e',
      );
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(
      RegExp(r'[\\/:*?"<>|]'),
      '_',
    );
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'pdf';

      case '.doc':
      case '.docx':
        return 'word';

      case '.ppt':
      case '.pptx':
        return 'powerpoint';

      case '.txt':
        return 'text';

      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.webp':
      case '.gif':
        return 'image';

      default:
        return 'file';
    }
  }

  String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case '.pdf':
        return 'application/pdf';

      case '.doc':
        return 'application/msword';

      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case '.ppt':
        return 'application/vnd.ms-powerpoint';

      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case '.txt':
        return 'text/plain';

      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';

      case '.png':
        return 'image/png';

      case '.webp':
        return 'image/webp';

      case '.gif':
        return 'image/gif';

      default:
        return 'application/octet-stream';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  IconData _contentIcon(String type) {
    switch (type) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'word':
        return Icons.article_outlined;

      case 'powerpoint':
        return Icons.slideshow_outlined;

      case 'text':
        return Icons.text_snippet_outlined;

      case 'note':
        return Icons.note_outlined;

      case 'image':
        return Icons.image_outlined;

      default:
        return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            onPressed: _createFolder,
            tooltip: 'New Folder',
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          IconButton(
            onPressed: () {
              _showAddContentMenu();
            },
            tooltip: 'Add Content',
            icon: const Icon(
              Icons.add_box_outlined,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFolders(),
                  const SizedBox(height: 24),
                  _buildContent(),
                ],
              ),
      ),
    );
  }

  Widget _buildFolders() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          'Folders',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (_folders.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.folder_outlined,
              ),
              title: Text('No folders yet'),
            ),
          )
        else
          ..._folders.map(
            (folder) {
              final id = folder['id'] as int;
              final name =
                  folder['name'] as String;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.folder_outlined,
                    ),
                  ),
                  title: Text(name),
                  trailing:
                      PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameFolder(
                          id,
                          name,
                        );
                      } else if (value == 'delete') {
                        _deleteFolder(id);
                      }
                    },
                    itemBuilder: (context) =>
                        const [
                      PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                  onTap: () {
                    _openFolder(
                      id,
                      name,
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Content',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(
                      fontWeight:
                          FontWeight.w700,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAddContentMenu();
              },
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Add Content',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_content.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.description_outlined,
              ),
              title: Text(
                'No content yet',
              ),
              subtitle: Text(
                'Add PDF, Word, PowerPoint, '
                'text, notes or images.',
              ),
            ),
          )
        else
          ..._content.map(
            (item) {
              final title =
                  item['title'] as String;

              final type =
                  item['type'] as String;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(
                      _contentIcon(type),
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    type.toUpperCase(),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
