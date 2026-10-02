import 'package:flutter/material.dart';

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
    setState(() {
      _isLoading = true;
    });

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
        Text(
          'Content',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
    setState(() {
      _isLoading = true;
    });

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
      builder: (context) {
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
      builder: (context) {
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
        Text(
          'Content',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
