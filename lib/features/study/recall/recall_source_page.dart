import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import 'recall_scope_page.dart';

class RecallSourcePage extends StatefulWidget {
  final int subjectId;

  const RecallSourcePage({
    super.key,
    required this.subjectId,
  });

  @override
  State<RecallSourcePage> createState() => _RecallSourcePageState();
}

class _RecallSourcePageState extends State<RecallSourcePage> {
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> folders = [];
  List<Map<String, dynamic>> content = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allFolders = await repo.getFolders();
    final allContent = await repo.getContent();

    if (!mounted) return;

    setState(() {
      folders = allFolders
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .toList();

      content = allContent
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .toList();

      loading = false;
    });
  }

  Future<void> _openScope({
    required String sourceType,
    required int sourceId,
    required String title,
    required String sourceContent,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RecallScopePage(
          subjectId: widget.subjectId,
          sourceType: sourceType,
          sourceId: sourceId,
          title: title,
          sourceContent: sourceContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose study source',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose the lecture, book, folder, or material '
                  'you want to use for Active Recall.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (folders.isEmpty && content.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No study materials are available.',
              ),
            ),
          )
        else ...[
          if (folders.isNotEmpty) ...[
            const Text(
              'Folders / Lectures',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...folders.map(
              (folder) => Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.folder_outlined,
                  ),
                  title: Text(
                    folder['name']?.toString() ??
                        'Folder',
                  ),
                  subtitle: const Text(
                    'Choose this source',
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () => _openScope(
                    sourceType: 'folder',
                    sourceId: folder['id'] as int,
                    title: folder['name']?.toString() ??
                        'Folder',
                    sourceContent: '',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          const Text(
            'Materials',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
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
                  item['title']?.toString() ??
                      item['name']?.toString() ??
                      'Material',
                ),
                subtitle: Text(
                  item['type']?.toString() ??
                      'Material',
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                ),
                onTap: () => _openScope(
                  sourceType: 'material',
                  sourceId: item['id'] as int,
                  title: item['title']?.toString() ??
                      'Material',
                  sourceContent:
                      item['content']?.toString() ?? '',
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
