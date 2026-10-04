import 'package:flutter/material.dart';

import '../../../core/database/database_repository.dart';
import '../widgets/explain_stage.dart';
import 'active_recall_page.dart';

class RecallScopePage extends StatefulWidget {
  final int subjectId;
  final String sourceType;
  final int sourceId;
  final String title;
  final String sourceContent;
  final String mode;

  const RecallScopePage({
    super.key,
    required this.subjectId,
    required this.sourceType,
    required this.sourceId,
    required this.title,
    required this.sourceContent,
    this.mode = 'recall',
  });

  @override
  State<RecallScopePage> createState() => _RecallScopePageState();
}

class _RecallScopePageState extends State<RecallScopePage> {
  final repo = DatabaseRepository.instance;

  bool loading = true;
  bool wholeSource = true;

  List<Map<String, dynamic>> materials = [];
  List<Map<String, dynamic>> topics = [];
  final selectedTopicIds = <int>{};

  bool get isExplain => widget.mode == 'explain';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.sourceType == 'material') {
      final files = await repo.getFiles(
        contentId: widget.sourceId,
      );

      final parts = <String>[];

      final directText = widget.sourceContent.trim();

      if (directText.isNotEmpty) {
        parts.add(directText);
      }

      for (final file in files) {
        final text =
            file['extracted_text']?.toString().trim() ?? '';

        if (text.isNotEmpty) {
          parts.add(text);
        }
      }

      materials = [
        {
          'id': widget.sourceId,
          'title': widget.title,
          'content': parts.join('\n\n'),
        },
      ];
    } else {
      final rows = await repo.getContent(
        folderId: widget.sourceId,
      );

      materials = [];

      for (final item in rows) {
        final material = Map<String, dynamic>.from(item);

        final directText =
            material['content']?.toString().trim() ?? '';

        final parts = <String>[];

        if (directText.isNotEmpty) {
          parts.add(directText);
        }

        final contentId = material['id'];

        if (contentId is int) {
          final files = await repo.getFiles(
            contentId: contentId,
          );

          for (final file in files) {
            final text =
                file['extracted_text']?.toString().trim() ?? '';

            if (text.isNotEmpty) {
              parts.add(text);
            }
          }
        }

        material['content'] = parts.join('\n\n');
        materials.add(material);
      }
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
    if (!wholeSource && selectedTopicIds.isEmpty) {
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

    final combined = selectedMaterials
        .map(
          (item) => item['content']?.toString() ?? '',
        )
        .where(
          (text) => text.trim().isNotEmpty,
        )
        .join('\n\n');

    if (combined.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No readable study text was found.',
          ),
        ),
      );
      return;
    }

    if (isExplain) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
            ),
            body: ExplainStage(
              content: combined,
            ),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveRecallPage(
          title: widget.title,
          sourceContent: combined,
          selectedTopicIds: selectedTopicIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isExplain ? 'Explain' : 'Active Recall',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isExplain
                        ? 'What should Explain use?'
                        : 'What should Active Recall use?',
                    style: const TextStyle(
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
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: const Text(
                      'Entire source',
                    ),
                    subtitle: Text(
                      isExplain
                          ? 'Use the complete source.'
                          : 'Use the complete book, lecture, folder, '
                              'or material.',
                    ),
                  ),
                  const RadioListTile<bool>(
                    value: false,
                    title: Text(
                      'Specific topics',
                    ),
                    subtitle: Text(
                      'Choose only the topics you want to practice.',
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
                              value: selectedTopicIds.contains(id),
                              title: Text(
                                topic['name']?.toString() ?? 'Topic',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedTopicIds.add(id);
                                  } else {
                                    selectedTopicIds.remove(id);
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
              icon: Icon(
                isExplain
                    ? Icons.record_voice_over_outlined
                    : Icons.psychology_outlined,
              ),
              label: Text(
                isExplain ? 'Start Explain' : 'Start Active Recall',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
