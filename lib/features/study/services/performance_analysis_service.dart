import '../../../ai/ai_client.dart';
import '../../../ai/ai_models.dart';
import '../../../ai/ai_prompt_builder.dart';
import '../../../ai/ai_response_parser.dart';
import '../../../core/database/database_repository.dart';

class PerformanceAnalysisService {
  PerformanceAnalysisService._();

  static final instance = PerformanceAnalysisService._();

  final _repo = DatabaseRepository.instance;
  final _ai = AiClient.instance;

  Future<PerformanceAnalysis> analyze({
    required String language,
  }) async {
    final topics = await _repo.getTopics();
    final attempts = await _repo.getAttempts();

    if (topics.isEmpty || attempts.isEmpty) {
      return const PerformanceAnalysis();
    }

    final content = await _repo.getContent();

    final request = AiPromptBuilder.build(
      task: AiTask.analyzePerformance,
      language: language,
      topics: topics,
      content: content,
      attempts: attempts,
    );

    final response = await _ai.send(request: request);

    return AiResponseParser.performance(response);
  }
}
