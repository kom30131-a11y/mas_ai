import '../../../ai/ai_client.dart';
import '../../../ai/ai_models.dart';
import '../../../ai/ai_prompt_builder.dart';
import '../../../ai/ai_response_parser.dart';
import '../../../core/database/database_repository.dart';
import 'study_content_service.dart';

class QuestionGenerationService {
  QuestionGenerationService._();

  static final instance = QuestionGenerationService._();

  final _repo = DatabaseRepository.instance;
  final _content = StudyContentService.instance;
  final _ai = AiClient.instance;

  Future<List<GeneratedQuestion>> generate({
    required List<int> topicIds,
    required int count,
    required String language,
    String difficulty = 'mixed',
    List<String> types = const [
      'mcq',
      'true_false',
      'fill_blank',
    ],
    bool interleaved = true,
  }) async {
    final topics = <Map<String, dynamic>>[];
    final content = <Map<String, dynamic>>[];

    for (final topicId in topicIds) {
      final topicRows = await _repo.getTopics();

      topics.addAll(
        topicRows.where((topic) => topic['id'] == topicId),
      );

      final items = await _content.getTopicContent(topicId);
      content.addAll(items);
    }

    if (content.isEmpty) return [];

    final request = AiPromptBuilder.build(
      task: AiTask.generateQuestions,
      language: language,
      topics: topics,
      content: content,
      settings: {
        'count': count,
        'difficulty': difficulty,
        'types': types,
        'interleaved': interleaved,
      },
    );

    final response = await _ai.send(request: request);

    return AiResponseParser.questions(response);
  }
}
