import '../../../ai/ai_client.dart';
import '../../../ai/ai_models.dart';
import '../../../ai/ai_prompt_builder.dart';
import '../../../ai/ai_response_parser.dart';

class AnswerEvaluationService {
  AnswerEvaluationService._();

  static final instance = AnswerEvaluationService._();

  final _ai = AiClient.instance;

  Future<AnswerEvaluation> evaluate({
    required Map<String, dynamic> question,
    required String studentAnswer,
    required String language,
    String? studyContent,
  }) async {
    final request = AiPromptBuilder.build(
      task: AiTask.evaluateAnswer,
      language: language,
      content: [
        if (studyContent != null && studyContent.trim().isNotEmpty)
          {
            'content': studyContent,
          },
      ],
      settings: {
        'question': question,
        'student_answer': studentAnswer,
      },
    );

    final response = await _ai.send(request: request);

    return AiResponseParser.evaluation(response);
  }
}
