import '../../../ai/ai_client.dart';
import '../../../ai/ai_models.dart';
import '../../../ai/ai_prompt_builder.dart';
import '../../../ai/ai_response_parser.dart';
import '../../../core/database/database_repository.dart';

class ReviewPlanningService {
  ReviewPlanningService._();

  static final instance = ReviewPlanningService._();

  final _repo = DatabaseRepository.instance;
  final _ai = AiClient.instance;

  Future<PerformanceAnalysis> plan({
    required String language,
  }) async {
    final topics = await _repo.getTopics();
    final attempts = await _repo.getAttempts();
    final reviews = await _repo.getReviews();

    if (topics.isEmpty) {
      return const PerformanceAnalysis();
    }

    final request = AiPromptBuilder.build(
      task: AiTask.planReview,
      language: language,
      topics: topics,
      attempts: attempts,
      settings: {
        'existing_reviews': reviews,
        'current_time': DateTime.now().toIso8601String(),
      },
    );

    final response = await _ai.send(request: request);

    return AiResponseParser.performance(response);
  }
}
