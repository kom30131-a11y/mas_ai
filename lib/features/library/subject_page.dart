import 'package:flutter/material.dart';

import '../../core/database/database_repository.dart';

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
  final DatabaseRepository _repository =
      DatabaseRepository.instance;

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _content = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjectData();
  }

  Future<void> _loadSubjectData() async {
    setState(() {
      _isLoading = true;
    });

    final topics = await _repository.getTopics(
      subjectId: widget.subjectId,
    );

    final content = await _repository.getContent();

    if (!mounted) return;

    setState(() {
      _topics = topics;
      _content = content
          .where(
            (item) => item['subject_id'] == widget.subjectId,
          )
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubjectData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        _buildTopicsSection(),
        const SizedBox(height: 24),
        _buildContentSection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              child: Icon(
                Icons.folder,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.subjectName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${_topics.length} topics • '
                    '${_content.length} content items',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topics',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (_topics.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.topic_outlined),
              title: Text('No topics yet'),
              subtitle: Text(
                'Topics will appear here.',
              ),
            ),
          )
        else
          ..._topics.map(
            (topic) {
              final name =
                  topic['name'] as String;

              final mastery =
                  (topic['mastery'] as num).toDouble();

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.topic_outlined,
                    ),
                  ),
                  title: Text(name),
                  subtitle: Text(
                    'Mastery: '
                    '${(mastery * 100).round()}%',
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Content',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        if (_content.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(
                Icons.description_outlined,
              ),
              title: Text('No content yet'),
              subtitle: Text(
                'PDFs, notes and other learning '
                'content will appear here.',
              ),
            ),
          )
        else
          ..._content.map(
            (item) {
              final title =
                  item['title'] as String;

              final type =
                  item['type'] as String;

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.description_outlined,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(type),
                ),
              );
            },
          ),
      ],
    );
  }
}
