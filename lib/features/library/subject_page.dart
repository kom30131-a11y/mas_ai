import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import '../folder_page.dart';

final _repo = DatabaseRepository.instance;

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
  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final allFolders = await _repo.getFolders();
    final allContent = await _repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = allFolders
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .where(
            (item) => item['parent_id'] == null,
          )
          .toList();

      content = allContent
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .where(
            (item) => item['folder_id'] == null,
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
        title: Text(widget.subjectName),
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
