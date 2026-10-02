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
    _loadSubjectData();
  }

  Future<void> _loadSubjectData() async {
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
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Folder name',
              hintText: 'Example: Cardiovascular',
            ),
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await _repository.insertFolder(
      name: name.trim(),
      subjectId: widget.subjectId,
    );

    await _loadSubjectData();
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
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
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
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await _repository.renameFolder(
      folderId: folderId,
      name: name.trim(),
    );

    await _loadSubjectData();
  }

  Future<void> _deleteFolder(int folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'Delete this folder and its subfolders?',
          ),
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
        );
      },
    );

    if (confirmed != true) return;

    await _repository.deleteFolder(folderId);
    await _loadSubjectData();
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

    await _loadSubjectData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        actions: [
          IconButton(
            onPressed: _createFolder,
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
            tooltip: 'New Folder',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubjectData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildFoldersSection(),
        const SizedBox(height: 24),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.folder,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subjectName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_folders.length} folders • '
                    '${_content.length} content items',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoldersSection() {
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
              subtitle: Text(
                'Use the add button above to create a folder.',
              ),
            ),
          )
        else
          ..._folders.map(
            (folder) {
              final id = folder['id'] as int;
              final name = folder['name'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_outlined),
                  ),
                  title: Text(name),
                  trailing: PopupMenuButton<String>(
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
                  onTap: () => _openFolder(id, name),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContentSection() {
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
              leading: Icon(Icons.description_outlined),
              title: Text('No content yet'),
              subtitle: Text(
                'Content added to this subject will appear here.',
              ),
            ),
          )
        else
          ..._content.map(
            (item) {
              final title = item['title'] as String;
              final type = item['type'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
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
    _loadFolderData();
  }

  Future<void> _loadFolderData() async {
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
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Folder name',
            ),
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
              child: const Text('Create'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await _repository.insertFolder(
      name: name.trim(),
      parentId: widget.folderId,
      subjectId: widget.subjectId,
    );

    await _loadFolderData();
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
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await _repository.renameFolder(
      folderId: folderId,
      name: name.trim(),
    );

    await _loadFolderData();
  }

  Future<void> _deleteFolder(int folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Folder'),
          content: const Text(
            'Delete this folder and its subfolders?',
          ),
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
        );
      },
    );

    if (confirmed != true) return;

    await _repository.deleteFolder(folderId);
    await _loadFolderData();
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

    await _loadFolderData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        actions: [
          IconButton(
            onPressed: _createFolder,
            icon: const Icon(
              Icons.create_new_folder_outlined,
            ),
            tooltip: 'New Folder',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFolderData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24,
      ),
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
              title: Text('No subfolders yet'),
              subtitle: Text(
                'Use the add button above to create one.',
              ),
            ),
          )
        else
          ..._folders.map(
            (folder) {
              final id = folder['id'] as int;
              final name = folder['name'] as String;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.folder_outlined),
                  ),
                  title: Text(name),
                  trailing: PopupMenuButton<String>(
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
                  onTap: () => _openFolder(id, name),
                ),
              );
            },
          ),
