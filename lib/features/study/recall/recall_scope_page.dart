import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import 'active_recall_page.dart';

class RecallScopePage extends StatefulWidget {
  final int subjectId;
  final String sourceType;
  final int sourceId;
  final String title;
  final String sourceContent;

  const RecallScopePage({
    super.key,
    required this.subjectId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.sourceContent,
  });

  @override
  State<RecallScopePage> createState() =>
      _RecallScopePageState();
}

class _RecallScopePageState
    extends State<RecallScopePage> {
  final repo = DatabaseRepository.instance;

  bool loading = true;
  bool wholeSource = true;

  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> topics = [];
  final selectedTopicIds = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.sourceType == 'material') {
      materials = [
        {
          'id': widget.sourceId,
          'title': widget.title,
          'content': widget.sourceContent,
        },
      ];
    } else {
      materials = await repo.getContent(
        folderId: widget.sourceId,
      );
    }

    topics = await repo.getTopics(
      subjectId: widget.subjectId,
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  void _start() {
    if (!wholeSource &&
        selectedTopicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Select at least one topic.',
          ),
        ),
      );
      return;
    }

    final selectedMaterials = wholeSource
        ? materials
        : materials.where((material) {
            final topicId = material['topic_id'];

            return topicId is int &&
                selectedTopicIds.contains(topicId);
          }).toList();

    if (selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No material was found for the selected topics.',
          ),
        ),
      );
      return;
    }

    final combined = selectedMaterials
        .map(
          (item) =>
              item['content']?.toString() ?? '',
        )
        .where((text) => text.trim().isNotEmpty)
        .join('\n\n');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveRecallPage(
          title: widget.title,
          sourceContent: combined,
          selectedTopicIds:
              selectedTopicIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

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
                  widget.title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'What should Active Recall use?',
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
        Card(
          child: RadioGroup<bool>(
            groupValue: wholeSource,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                wholeSource = value;
              });
            },
            child: Column(
              children: const [
                RadioListTile<bool>(
                  value: true,
                  title: Text(
                    'Entire source',
                  ),
                  subtitle: Text(
                    'Use the complete book, lecture, '
                    'folder, or material.',
                  ),
                ),
                RadioListTile<bool>(
                  value: false,
                  title: Text(
                    'Specific topics',
                  ),
                  subtitle: Text(
                    'Choose only the topics you want '
                    'to practice.',
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!wholeSource) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: topics.isEmpty
                  ? const Text(
                      'No topics are available yet.',
                    )
                  : Column(
                      children: topics.map(
                        (topic) {
                          final id = topic['id'];

                          if (id is! int) {
                            return const SizedBox.shrink();
                          }

                          return CheckboxListTile(
                            value: selectedTopicIds
                                .contains(id),
                            title: Text(
                              topic['name']
                                      ?.toString() ??
                                  'Topic',
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  selectedTopicIds
                                      .add(id);
                                } else {
                                  selectedTopicIds
                                      .remove(id);
                                }
                              });
                            },
                          );
                        },
                      ).toList(),
                    ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: FilledButton.icon(
            onPressed: _start,
            icon: const Icon(
              Icons.psychology_outlined,
            ),
            label: const Text(
              'Start Active Recall',
            ),
          ),
        ),
      ],
    );
  }
}
