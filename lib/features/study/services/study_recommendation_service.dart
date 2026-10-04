import '../../../ai/ai_client.dart';
import '../../../ai/ai_models.dart';
import '../../../ai/ai_prompt_builder.dart';
import '../../../ai/ai_response_parser.dart';
import '../../../core/database/database_repository.dart';

class StudyRecommendationService {
  StudyRecommendationService._();

  static final instance = StudyRecommendationService._();

  final _repo = DatabaseRepository.instance;
  final _ai = AiClient.instance;

  Future<List<StudyRecommendation>> recommend({
    required String language,
  }) async {
    final topics = await _repo.getTopics();
    final attempts = await _repo.getAttempts();
    final reviews = await _repo.getReviews();

    if (topics.isEmpty) return [];

    final request = AiPromptBuilder.build(
      task: AiTask.recommendStudy,
      language: language,
      topics: topics,
      attempts: attempts,
      settings: {
        'reviews': reviews,
        'current_time': DateTime.now().toIso8601String(),
      },
    );

    final response = await _ai.send(request: request);

    final analysis = AiResponseParser.performance(response);

    return analysis.recommendations;
  }
}
