import '../../../core/database/database_repository.dart';

class StudyContentService {
  StudyContentService._();

  static final instance = StudyContentService._();

  final DatabaseRepository _repo = DatabaseRepository.instance;

  Future<List<Map<String, dynamic>>> getTopics(
    int subjectId,
  ) {
    return _repo.getTopics(subjectId: subjectId);
  }

  Future<List<Map<String, dynamic>>> getTopicContent(
    int topicId,
  ) {
    return _repo.getContent(topicId: topicId);
  }

  Future<List<Map<String, dynamic>>> getContentFiles(
    int contentId,
  ) {
    return _repo.getFiles(contentId: contentId);
  }

  Future<Map<String, dynamic>?> getContentWithFiles(
    int contentId,
  ) async {
    final content = await _repo.getContent();

    Map<String, dynamic>? item;

    for (final row in content) {
      if (row['id'] == contentId) {
        item = Map<String, dynamic>.from(row);
        break;
      }
    }

    if (item == null) return null;

    item['files'] = await _repo.getFiles(
      contentId: contentId,
    );

    return item;
  }

  Future<String> getStudyText(
    int contentId,
  ) async {
    final item = await getContentWithFiles(contentId);

    if (item == null) return '';

    final contentText =
        item['content']?.toString().trim() ?? '';

    if (contentText.isNotEmpty) {
      return contentText;
    }

    final files =
        (item['files'] as List?) ?? const [];

    final parts = <String>[];

    for (final file in files) {
      final text =
          file['extracted_text']?.toString().trim() ?? '';

      if (text.isNotEmpty) {
        parts.add(text);
      }
    }

    return parts.join('\n\n');
  }
}
