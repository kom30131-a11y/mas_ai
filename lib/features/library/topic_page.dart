import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import '../study/study_session_page.dart';

class TopicPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const TopicPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<TopicPage> createState() => _TopicPageState();
}

class _TopicPageState extends State<TopicPage> {
  final repo = DatabaseRepository.instance;

  List<Map<String, dynamic>> topics = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await repo.getTopics(
      subjectId: widget.subjectId,
    );

    if (!mounted) return;

    setState(() {
      topics = data;
      loading = false;
    });
  }

  Future<void> openTopic(
    Map<String, dynamic> topic,
  ) async {
    final id = topic['id'];

    if (id is! int) return;

    final content = await repo.getContent(
      topicId: id,
    );

    if (!mounted) return;

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No study material is available for this topic.',
          ),
        ),
      );
      return;
    }

    final first = content.first;
    final contentId = first['id'];

    if (contentId is! int) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudySessionPage(
          subjectId: widget.subjectId,
          topicId: id,
          contentId: contentId,
          title: first['title']?.toString() ??
              first['name']?.toString() ??
              topic['name']?.toString() ??
              'Study Session',
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
              child: topics.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No topics yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: topics.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final topic = topics[index];

                        final mastery =
                            (topic['mastery'] as num?)
                                    ?.toDouble() ??
                                0.0;

                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.topic_outlined,
                              ),
                            ),
                            title: Text(
                              topic['name']?.toString() ??
                                  'Topic',
                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(
                                top: 6,
                              ),
                              child: Text(
                                'Mastery ${mastery.toStringAsFixed(0)}%',
                              ),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () =>
                                openTopic(topic),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
