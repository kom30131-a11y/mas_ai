import 'dart:convert';

import 'ai_models.dart';
import 'ai_tasks.dart';

class AiPromptBuilder {
  AiPromptBuilder._();

  static Map<String, dynamic> build({
    required AiTask task,
    required String language,
    List<Map<String, dynamic>> topics = const [],
    List<Map<String, dynamic>> content = const [],
    List<Map<String, dynamic>> attempts = const [],
    Map<String, dynamic> settings = const {},
  }) {
    return {
      'task': AiTasks.name(task),
      'instruction': AiTasks.instruction(task),
      'language': language,
      'rules': _rules(task),
      'topics': topics,
      'content': content,
      'attempts': attempts,
      'settings': settings,
    };
  }

  static List<String> _rules(AiTask task) {
    return [
      'Use only supplied study content and performance data.',
      'Do not invent facts, questions, performance, or learning history.',
      'Keep medical terminology accurate.',
      'Return valid JSON only.',
      'Respect the requested language.',
      if (task == AiTask.generateQuestions)
        'Questions must be varied in type, difficulty, wording, and topic.',
      if (task == AiTask.analyzePerformance)
        'Distinguish evidence-based weaknesses from insufficient data.',
      if (task == AiTask.planReview)
        'Review recommendations must be based on actual performance data.',
      if (task == AiTask.recommendStudy)
        'Prioritize the highest-value learning actions.',
    ];
  }

  static String encode(Map<String, dynamic> request) {
    return jsonEncode(request);
  }
}
