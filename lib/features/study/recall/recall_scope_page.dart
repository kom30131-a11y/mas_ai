import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../services/study_content_service.dart';
import '../widgets/explain_stage.dart';
import 'active_recall_page.dart';

class RecallScopePage extends StatefulWidget {
  final int subjectId;
  final int folderId;
  final int materialId;
  final String materialTitle;
  final String mode;

  const RecallScopePage({
    super.key,
    required this.subjectId,
    required this.folderId,
    required this.materialId,
    required this.materialTitle,
    this.mode = 'recall',
  });

  @override
  State<RecallScopePage> createState() => _RecallScopePageState();
}

class _RecallScopePageState extends State<RecallScopePage> {
  final repo = DatabaseRepository.instance;
  final contentService = StudyContentService.instance;

  bool loading = true;
  bool wholeMaterial = true;

  List<Map<String, dynamic>> topics = [];
  final selectedTopicIds = <int>{};

  bool get isExplain => widget.mode == 'explain';

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final folderContent = await repo.getContent(
      folderId: widget.folderId,
    );

    final topicIds = folderContent
        .map((item) => item['topic_id'])
        .whereType<int>()
        .toSet();

    final allTopics = await repo.getTopics(
      subjectId: widget.subjectId,
    );

    final filtered = topicIds.isEmpty
        ? allTopics
        : allTopics.where((topic) {
            final id = topic['id'];
            return id is int && topicIds.contains(id);
          }).toList();

    if (!mounted) return;

    setState(() {
      topics = filtered;
      loading = false;
    });
  }

  void _setWholeMaterial(bool value) {
    setState(() {
      wholeMaterial = value;

      if (value) {
        selectedTopicIds.clear();
      }
    });
  }

  void _toggleTopic(int topicId) {
    setState(() {
      wholeMaterial = false;

      if (selectedTopicIds.contains(topicId)) {
        selectedTopicIds.remove(topicId);
      } else {
        selectedTopicIds.add(topicId);
      }
    });
  }

  Future<String> _buildSourceContent() async {
    if (wholeMaterial) {
      return contentService.getStudyText(
        widget.materialId,
      );
    }

    final rows = await repo.getContentForTopics(
      selectedTopicIds.toList(),
    );

    final parts = <String>[];

    for (final row in rows) {
      if (row['folder_id'] != widget.folderId) {
        continue;
      }

      final id = row['id'];

      if (id is! int) continue;

      final text = await contentService.getStudyText(id);

      if (text.trim().isEmpty) continue;

      final title =
          row['title']?.toString().trim() ?? '';

      parts.add(
        title.isEmpty ? text : '$title\n$text',
      );
    }

    return parts.join('\n\n');
  }

  Future<void> _start() async {
    if (!wholeMaterial && selectedTopicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one topic.',
          ),
        ),
      );
      return;
    }

    final sourceContent = await _buildSourceContent();

    if (!mounted) return;

    if (sourceContent.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No readable study content was found.',
          ),
        ),
      );
      return;
    }

    if (isExplain) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExplainStage(
            title: widget.materialTitle,
            materialId: widget.materialId,
            content: sourceContent,
            selectedTopicIds: selectedTopicIds.toList(),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveRecallPage(
          title: widget.materialTitle,
          materialId: widget.materialId,
          sourceContent: sourceContent,
          selectedTopicIds: selectedTopicIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialTitle),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                RadioGroup<bool>(
                  groupValue: wholeMaterial,
                  onChanged: (value) {
                    if (value == null) return;
                    _setWholeMaterial(value);
                  },
                  child: Card(
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          title: const Text(
                            'Complete material',
                          ),
                        ),
                        RadioListTile<bool>(
                          value: false,
                          title: const Text(
                            'Specific topics',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!wholeMaterial)
                  Card(
                    child: topics.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No topics are available for '
                              'this material.',
                            ),
                          )
                        : Column(
                            children: topics.map((topic) {
                              final id = topic['id'];

                              if (id is! int) {
                                return const SizedBox.shrink();
                              }

                              return CheckboxListTile(
                                value:
                                    selectedTopicIds.contains(id),
                                title: Text(
                                  topic['name']
                                          ?.toString() ??
                                      'Topic',
                                ),
                                onChanged: (_) {
                                  _toggleTopic(id);
                                },
                              );
                            }).toList(),
                          ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: _start,
                    child: Text(
                      isExplain
                          ? 'Start Explain'
                          : 'Start Active Recall',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
