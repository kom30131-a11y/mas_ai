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
    final rows = await repo.getTopics(
      subjectId: widget.subjectId,
    );

    if (!mounted) return;

    setState(() {
      topics = rows;
    });
  }

  void _start() {
    if (!wholeMaterial && selectedTopicIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one topic.'),
        ),
      );
      return;
    }

    if (isExplain) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExplainStage(
            title: widget.title,
            content: widget.sourceContent,
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
          title: widget.title,
          sourceContent: widget.sourceContent,
          selectedTopicIds: selectedTopicIds.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: RadioGroup<bool>(
              groupValue: wholeMaterial,
              onChanged: (value) {
                if (value == null) return;

                setState(() {
                  wholeMaterial = value;

                  if (value) {
                    selectedTopicIds.clear();
                  }
                });
              },
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    title: const Text('Complete material'),
                  ),
                  RadioListTile<bool>(
                    value: false,
                    title: const Text('Specific topics'),
                  ),
                ],
              ),
            ),
          ),
          if (!wholeMaterial && topics.isNotEmpty)
            Card(
              child: Column(
                children: topics.map((topic) {
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
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
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
