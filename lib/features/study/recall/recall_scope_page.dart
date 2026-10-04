import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import 'active_recall_page.dart';

class RecallScopePage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final int folderId;
  final String folderName;
  final int materialId;
  final String materialTitle;

  const RecallScopePage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.folderId,
    required this.folderName,
    required this.materialId,
    required this.materialTitle,
  });

  @override
  State<RecallScopePage> createState() => _RecallScopePageState();
}

class _RecallScopePageState extends State<RecallScopePage> {
  final repo = DatabaseRepository.instance;

  bool loading = true;
  bool allContent = true;

  List<Map<String, dynamic>> topics = [];
  final Set<int> selectedTopicIds = {};

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final result = await repo.getTopics(
        subjectId: widget.subjectId,
      );

      if (!mounted) return;

      setState(() {
        topics = result;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });
    }
  }

  void _setAllContent(bool value) {
    setState(() {
      allContent = value;
      selectedTopicIds.clear();
    });
  }

  void _toggleTopic(int topicId) {
    setState(() {
      allContent = false;

      if (selectedTopicIds.contains(topicId)) {
        selectedTopicIds.remove(topicId);
      } else {
        selectedTopicIds.add(topicId);
      }
    });
  }

  Future<void> _startSession() async {
    if (!allContent && selectedTopicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اختر المحتوى أو Topic واحدًا على الأقل'),
        ),
      );
      return;
    }

    final materialContent = await repo.getContent(
      folderId: widget.folderId,
    );

    List<Map<String, dynamic>> selectedContent;

    if (allContent) {
      selectedContent = materialContent
          .where(
            (item) => item['id'] == widget.materialId,
          )
          .toList();

      if (selectedContent.isEmpty) {
        selectedContent = materialContent;
      }
    } else {
      selectedContent = await repo.getContentForTopics(
        selectedTopicIds.toList(),
      );
    }

    if (!mounted) return;

    if (selectedContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يوجد محتوى متاح للاختيار الحالي'),
        ),
      );
      return;
    }

    final sourceContent = selectedContent
        .map((item) {
          final title = item['title']?.toString().trim() ?? '';
          final content = item['content']?.toString().trim() ?? '';

          if (title.isEmpty) return content;

          return '$title\n$content';
        })
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');

    if (sourceContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('المحتوى المحدد فارغ'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActiveRecallPage(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          materialId: widget.materialId,
          materialTitle: widget.materialTitle,
          sourceContent: sourceContent,
          selectedTopicIds: allContent
              ? const []
              : selectedTopicIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recall Scope'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.materialTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.subjectName} • ${widget.folderName}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),

                Card(
                  child: RadioListTile<bool>(
                    value: true,
                    groupValue: allContent,
                    title: const Text('كل المحتوى'),
                    subtitle: const Text(
                      'استخدم كامل محتوى المادة',
                    ),
                    onChanged: (value) {
                      if (value == true) {
                        _setAllContent(true);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: false,
                          groupValue: allContent,
                          title: const Text('Topics محددة'),
                          subtitle: const Text(
                            'اختر Topics معينة للمراجعة',
                          ),
                          onChanged: (value) {
                            if (value == false) {
                              setState(() {
                                allContent = false;
                              });
                            }
                          },
                        ),

                        if (!allContent) ...[
                          const Divider(),

                          if (topics.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'لا توجد Topics مرتبطة بهذا Subject.',
                              ),
                            )
                          else
                            ...topics.map(
                              (topic) {
                                final id = topic['id'] as int;
                                final name =
                                    topic['name']?.toString() ?? '';

                                return CheckboxListTile(
                                  value: selectedTopicIds.contains(id),
                                  title: Text(name),
                                  onChanged: (_) {
                                    _toggleTopic(id);
                                  },
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Active Recall'),
                ),
              ],
            ),
    );
  }
}
