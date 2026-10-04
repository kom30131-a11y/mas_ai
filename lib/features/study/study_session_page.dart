import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';

class StudySessionPage extends StatefulWidget {
  final int subjectId;
  final int topicId;
  final int contentId;
  final String title;

  const StudySessionPage({
    super.key,
    required this.subjectId,
    required this.topicId,
    required this.contentId,
    required this.title,
  });

  @override
  State<StudySessionPage> createState() =>
      _StudySessionPageState();
}

class _StudySessionPageState
    extends State<StudySessionPage> {
  final repo = DatabaseRepository.instance;

  Map<String, dynamic>? material;
  bool loading = true;
  int stage = 0;

  static const stages = [
    'Learn',
    'Recall',
    'Explain',
    'Quick Test',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final content = await repo.getContent();

    if (!mounted) return;

    Map<String, dynamic>? found;

    for (final item in content) {
      if (item['id'] == widget.contentId) {
        found = item;
        break;
      }
    }

    setState(() {
      material = found;
      loading = false;
    });
  }

  void _next() {
    if (stage < stages.length - 1) {
      setState(() => stage++);
    } else {
      Navigator.pop(context);
    }
  }

  void _back() {
    if (stage > 0) {
      setState(() => stage--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : material == null
              ? const Center(
                  child: Text('Material not found.'),
                )
              : Column(
                  children: [
                    _header(),
                    Expanded(
                      child: _stageContent(),
                    ),
                    _buttons(),
                  ],
                ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            stages[stage],
            style: Theme.of(context)
                .textTheme
                .titleLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (stage + 1) / stages.length,
          ),
          const SizedBox(height: 6),
          Text(
            '${stage + 1} / ${stages.length}',
            style: Theme.of(context)
                .textTheme
                .bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _stageContent() {
    switch (stage) {
      case 0:
        return _learn();
      case 1:
        return _recall();
      case 2:
        return _explain();
      case 3:
        return _quickTest();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _learn() {
    final content =
        material!['content']?.toString() ?? '';

    return _card(
      'Study',
      content.isEmpty
          ? 'No readable text is available for this material.'
          : content,
    );
  }

  Widget _recall() {
    return _card(
      'Recall',
      'Close the material and recall the key information from memory.',
    );
  }

  Widget _explain() {
    return _card(
      'Explain',
      'Explain the important points in your own words.',
    );
  }

  Widget _quickTest() {
    return _card(
      'Quick Test',
      'The question engine will use this material as its source.',
    );
  }

  Widget _card(
    String title,
    String text,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall,
              ),
              const SizedBox(height: 20),
              SelectableText(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (stage > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _back,
                  child: const Text('Back'),
                ),
              ),
            if (stage > 0)
              const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _next,
                child: Text(
                  stage == stages.length - 1
                      ? 'Finish'
                      : 'Continue',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

الخطوة التالية: ربط "TopicDetailPage" بهذا الملف عند فتح الـMaterial، ثم نبني "Recall" و"Explain" فعليًا بدل النصوص المؤقتة.
