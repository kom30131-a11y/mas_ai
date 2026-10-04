import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';
import 'study_session_page.dart';

final _repo = DatabaseRepository.instance;

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
  List<Map<String, dynamic>> topics = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await _repo.getTopics(
      subjectId: widget.subjectId,
    );

    if (!mounted) return;

    setState(() {
      topics = data;
      loading = false;
    });
  }

  Future<void> addTopic() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New topic'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Topic name',
              hintText: 'Enter topic name',
            ),
            onSubmitted: (_) {
              final value = controller.text.trim();

              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (name == null || name.trim().isEmpty) return;

    await _repo.insertTopic({
      'subject_id': widget.subjectId,
      'name': name.trim(),
    });

    if (!mounted) return;

    await load();
  }

  Future<void> deleteTopic(
    Map<String, dynamic> topic,
  ) async {
    final id = topic['id'];

    if (id is! int) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete topic?'),
          content: Text(
            'Delete "${topic['name']?.toString() ?? 'Topic'}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                context,
                false,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                true,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _repo.deleteTopic(id);

    if (!mounted) return;

    await load();
  }

  Future<void> openTopic(
    Map<String, dynamic> topic,
  ) async {
    final id = topic['id'];

    if (id is! int) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TopicDetailPage(
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
          topicId: id,
          topicName:
              topic['name']?.toString() ?? 'Topic',
        ),
      ),
    );

    if (!mounted) return;

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTopic,
        child: const Icon(Icons.add),
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
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final topic = topics[index];

                        return Card(
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
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
                            trailing:
                                PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  deleteTopic(topic);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Delete'),
                                ),
                              ],
                            ),
                            onTap: () => openTopic(topic),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class TopicDetailPage extends StatefulWidget {
  final int subjectId;
  final String subjectName;
  final int topicId;
  final String topicName;

  const TopicDetailPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
  });

  @override
  State<TopicDetailPage> createState() =>
      _TopicDetailPageState();
}

class _TopicDetailPageState
    extends State<TopicDetailPage> {
  List<Map<String, dynamic>> materials = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await _repo.getContent(
      topicId: widget.topicId,
    );

    if (!mounted) return;

    setState(() {
      materials = data;
      loading = false;
    });
  }

  IconData materialIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'doc':
      case 'docx':
        return Icons.description_outlined;

      case 'ppt':
      case 'pptx':
        return Icons.slideshow_outlined;

      case 'txt':
        return Icons.text_snippet_outlined;

      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;

      case 'text':
        return Icons.article_outlined;

      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Future<void> openMaterial(
    Map<String, dynamic> material,
  ) async {
    final id = material['id'];

    if (id is! int) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudySessionPage(
          subjectId: widget.subjectId,
          topicId: widget.topicId,
          contentId: id,
          title: material['title']?.toString() ??
              'Material',
        ),
      ),
    );

    if (!mounted) return;

    await load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.topicName),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: load,
              child: materials.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: Text(
                            'No learning materials yet.',
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: materials.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (_, index) {
                        final material =
                            materials[index];

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              materialIcon(
                                material['type']
                                    ?.toString(),
                              ),
                            ),
                            title: Text(
                              material['title']
                                      ?.toString() ??
                                  'Untitled',
                            ),
                            subtitle: Text(
                              material['type']
                                      ?.toString() ??
                                  'Material',
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                            ),
                            onTap: () =>
                                openMaterial(material),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
