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
    String label = 'Name',
  }) async {
    final controller = TextEditingController(
      text: initialValue,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
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
                Navigator.pop(dialogContext, name);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'Delete this folder and all subfolders?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

  Future<void> _addContent({
    required int? folderId,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.pop(sheetContext, 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Word'),
                onTap: () {
                  Navigator.pop(sheetContext, 'word');
                },
              ),
              ListTile(
                leading: const Icon(Icons.slideshow_outlined),
                title: const Text('PowerPoint'),
                onTap: () {
                  Navigator.pop(sheetContext, 'powerpoint');
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet_outlined),
                title: const Text('Text file'),
                onTap: () {
                  Navigator.pop(sheetContext, 'text');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Image'),
                onTap: () {
                  Navigator.pop(sheetContext, 'image');
                },
            ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    await _pickContent(
      type: result,
      folderId: folderId,
    );
  }

  Future<void> _pickContent({
    required String type,
    required int? folderId,
  }) async {
    List<String> extensions;

    switch (type) {
      case 'pdf':
        extensions = ['pdf'];
        break;

      case 'word':
        extensions = ['doc', 'docx'];
        break;

      case 'powerpoint':
        extensions = ['ppt', 'pptx'];
        break;

      case 'text':
        extensions = ['txt'];
        break;

      case 'image':
        extensions = [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ];
        break;

      default:
        return;
    }

    final result = await FilePicker().pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.path == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to access the selected file.'),
        ),
      );

      return;
    }

    final filePath = file.path!;
    final fileName = file.name;
    final extension = p
        .extension(fileName)
        .replaceFirst('.', '')
        .toLowerCase();

    String contentType;

    switch (extension) {
      case 'pdf':
        contentType = 'PDF';
        break;

      case 'doc':
      case 'docx':
        contentType = 'Word';
        break;

      case 'ppt':
      case 'pptx':
        contentType = 'PowerPoint';
        break;

      case 'txt':
        contentType = 'Text';
        break;

      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        contentType = 'Image';
        break;

      default:
        contentType = 'File';
    }

    final now = DateTime.now().toIso8601String();

    final contentId = await _repository.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': folderId,
      'title': p.basenameWithoutExtension(fileName),
      'type': contentType,
      'content': '',
      'file_path': filePath,
      'original_file_name': fileName,
      'created_at': now,
    });

    await _repository.insertFile({
      'content_id': contentId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': _mimeType(extension),
      'file_size': File(filePath).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await _loadData();
  }

  String? _mimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';

      case 'doc':
        return 'application/msword';

      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

      case 'ppt':
        return 'application/vnd.ms-powerpoint';

      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';

      case 'txt':
        return 'text/plain';

      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';

      case 'png':
        return 'image/png';

      case 'webp':
        return 'image/webp';

      default:
        return null;
    }
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
              _addContent(folderId: null);
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
              leading: Icon(Icons.folder_outlined),
              title: Text('No folders yet'),
            ),
          )
        else
          ..._folders.map(
            (folder) {
              final id = folder['id'] as int;
              final name = folder['name'] as String;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_outlined),
                  ),
                  title: Text(name),
                  trailing:
                      PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'rename') {
                        _renameFolder(id, name);
                      } else if (value == 'delete') {
                        _deleteFolder(id);
                      }
                    },
                    itemBuilder: (context) => const [
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
                    _openFolder(id, name);
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              onPressed: () {
                _addContent(folderId: null);
              },
              tooltip: 'Add Content',
              icon: const Icon(Icons.add),
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
              title: Text('No content yet'),
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
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.description_outlined,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(type),
                ),
              );
            },
          ),
      ],
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

    final folders = await _repository.getFolders(
      parentId: widget.folderId,
    );

    final content = await _repository.getContent(
      folderId: widget.folderId,
    );

    if (!mounted) return;

    setState(() {
      _folders = folders;
      _content = content;
      _isLoading = false;
    });
  }

  Future<void> _createFolder() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization:
                TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
            onSubmitted: (value) {
              final name = value.trim();

              if (name.isNotEmpty) {
                Navigator.pop(dialogContext, name);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null) return;

    await _repository.insertFolder(
      name: name,
      parentId: widget.folderId,
      subjectId: widget.subjectId,
    );

    await _loadData();
  }

  Future<void> _renameFolder(
    int folderId,
    String currentName,
  ) async {
    final controller = TextEditingController(
      text: currentName,
    );

    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();

                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

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
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'Delete this folder and all subfolders?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
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

  Future<void> _addContent() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                ),
                title: const Text('PDF'),
                onTap: () {
                  Navigator.pop(sheetContext, 'pdf');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                ),
                title: const Text('Word'),
                onTap: () {
                  Navigator.pop(sheetContext, 'word');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.slideshow_outlined,
                ),
                title: const Text('PowerPoint'),
                onTap: () {
                  Navigator.pop(
                    sheetContext,
                    'powerpoint',
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.text_snippet_outlined,
                ),
                title: const Text('Text file'),
                onTap: () {
                  Navigator.pop(sheetContext, 'text');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.image_outlined,
                ),
                title: const Text('Image'),
                onTap: () {
                  Navigator.pop(sheetContext, 'image');
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    await _pickContent(result);
  }

  Future<void> _pickContent(String type) async {
    List<String> extensions;

    switch (type) {
      case 'pdf':
        extensions = ['pdf'];
        break;
      case 'word':
        extensions = ['doc', 'docx'];
        break;
      case 'powerpoint':
        extensions = ['ppt', 'pptx'];
        break;
      case 'text':
        extensions = ['txt'];
        break;
      case 'image':
        extensions = [
          'jpg',
          'jpeg',
          'png',
          'webp',
        ];
        break;
      default:
        return;
    }

    final result = await FilePicker().pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: false,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;

    if (file.path == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to access the selected file.',
          ),
        ),
      );

      return;
    }

    final filePath = file.path!;
    final fileName = file.name;
    final extension = p
        .extension(fileName)
        .replaceFirst('.', '')
        .toLowerCase();

    String contentType;

    switch (extension) {
      case 'pdf':
        contentType = 'PDF';
        break;
      case 'doc':
      case 'docx':
        contentType = 'Word';
        break;
      case 'ppt':
      case 'pptx':
        contentType = 'PowerPoint';
        break;
      case 'txt':
        contentType = 'Text';
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        contentType = 'Image';
        break;
      default:
        contentType = 'File';
    }

    final now = DateTime.now().toIso8601String();

    final contentId =
        await _repository.insertContent({
      'subject_id': widget.subjectId,
      'topic_id': null,
      'folder_id': widget.folderId,
      'title': p.basenameWithoutExtension(
        fileName,
      ),
      'type': contentType,
      'content': '',
      'file_path': filePath,
      'original_file_name': fileName,
      'created_at': now,
    });

    await _repository.insertFile({
      'content_id': contentId,
      'file_name': fileName,
      'file_path': filePath,
      'mime_type': _mimeType(extension),
      'file_size': File(filePath).lengthSync(),
      'extracted_text': null,
      'created_at': now,
    });

    await _loadData();
  }

  String? _mimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return null;
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            onPressed: _createFolder,
            tooltip: 'New Folder',
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
          ),
          IconButton(
            onPressed: _addContent,
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
                physics:
                    const AlwaysScrollableScrollPhysics(),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
              title: Text('No subfolders yet'),
            ),
          )
        else
          ..._folders.map(
            (folder) {
              final id = folder['id'] as int;
              final name = folder['name'] as String;

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
                        _renameFolder(id, name);
                      } else if (value == 'delete') {
                        _deleteFolder(id);
                      }
                    },
                    itemBuilder: (context) => const [
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
                    _openFolder(id, name);
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              onPressed: _addContent,
              tooltip: 'Add Content',
              icon: const Icon(Icons.add),
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
              title: Text('No content yet'),
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
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.description_outlined,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(type),
                ),
              );
            },
          ),
      ],
    );
  }
}
 
