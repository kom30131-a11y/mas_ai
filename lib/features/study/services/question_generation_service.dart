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

    final allTopics = await _repo.getTopics();

    for (final topicId in topicIds) {
      topics.addAll(
        allTopics.where(
          (topic) => topic['id'] == topicId,
        ),
      );

      final items = await _content.getTopicContent(
        topicId,
      );

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

    final response = await _ai.send(
      request: request,
    );

    return AiResponseParser.questions(
      response,
    );
  }

  Future<List<GeneratedQuestion>> generateFromContent({
    required String sourceContent,
    required int contentId,
    required List<int> topicIds,
    required int count,
    required String language,
    String difficulty = 'mixed',
    List<String> types = const [
      'free_recall',
      'fill_blank',
      'short_answer',
    ],
  }) async {
    if (sourceContent.trim().isEmpty) {
      return [];
    }

    final allTopics = await _repo.getTopics();

    final topics = allTopics.where((topic) {
      final id = topic['id'];

      return id is int && topicIds.contains(id);
    }).toList();

    final request = AiPromptBuilder.build(
      task: AiTask.generateQuestions,
      language: language,
      topics: topics,
      content: [
        {
          'id': contentId,
          'content': sourceContent,
        },
      ],
      settings: {
        'count': count,
        'difficulty': difficulty,
        'types': types,
        'interleaved': false,
        'mode': 'active_recall',
        'source_scope': topicIds.isEmpty
            ? 'complete_material'
            : 'selected_topics',
      },
    );

    final response = await _ai.send(
      request: request,
    );

    return AiResponseParser.questions(
      response,
    );
  }
}
