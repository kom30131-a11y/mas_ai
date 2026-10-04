import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';

final _repo = DatabaseRepository.instance;

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
  State<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends State<FolderPage> {
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final folderItems = await _repo.getFolders(
      parentId: widget.folderId,
    );

    final contentItems = await _repo.getContent(
      folderId: widget.folderId,
    );

    if (!mounted) return;

    setState(() {
      folders = folderItems
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .toList();

      content = contentItems
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .toList();

      loading = false;
    });
  }

  Future<void> openFolder(
    Map<String, dynamic> folder,
  ) async {
    final id = folder['id'];

    if (id is! int) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FolderPage(
          subjectId: widget.subjectId,
          folderId: id,
          folderName:
              folder['name']?.toString() ?? 'Folder',
        ),
      ),
    );

    if (mounted) {
      await load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: folders.isEmpty && content.isEmpty
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
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (folders.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(
                              bottom: 8,
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
                        ...folders.map(
                          (folder) => Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.folder_outlined,
                              ),
                              title: Text(
                                folder['name']
                                        ?.toString() ??
                                    'Folder',
                              ),
                              trailing: const Icon(
                                Icons.chevron_right,
                              ),
                              onTap: () =>
                                  openFolder(folder),
                            ),
                          ),
                        ),
                        if (content.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Materials',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...content.map(
                            (item) => Card(
                              child: ListTile(
                                leading: const Icon(
                                  Icons.description_outlined,
                                ),
                                title: Text(
                                  item['title']
                                          ?.toString() ??
                                      item['name']
                                          ?.toString() ??
                                      'Material',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
    );
  }
}
