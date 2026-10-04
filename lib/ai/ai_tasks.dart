import 'ai_models.dart';

class AiTasks {
  AiTasks._();

  static String name(AiTask task) {
    switch (task) {
      case AiTask.generateQuestions:
        return 'generate_questions';
      case AiTask.evaluateAnswer:
        return 'evaluate_answer';
      case AiTask.analyzePerformance:
        return 'analyze_performance';
      case AiTask.planReview:
        return 'plan_review';
      case AiTask.recommendStudy:
        return 'recommend_study';
    }
  }

  static String instruction(AiTask task) {
    switch (task) {
      case AiTask.generateQuestions:
        return '''
Generate varied questions from the supplied study content.

Requirements:
- Use only the supplied content.
- Support multiple question types.
- Vary difficulty.
- Avoid repetitive questions.
- Mix related topics when multiple topics are supplied.
- Include the correct answer and explanation.
- Return structured JSON only.
''';

      case AiTask.evaluateAnswer:
        return '''
Evaluate the student's answer against the supplied study content.

Determine:
- whether the answer is correct,
- the reason for an incorrect answer,
- the underlying knowledge gap,
- the explanation,
- the recommended next action,
- the effect on mastery.

Return structured JSON only.
''';

      case AiTask.analyzePerformance:
        return '''
Analyze the student's performance using the supplied attempts and topic data.

Identify:
- strengths,
- weaknesses,
- recurring errors,
- knowledge gaps,
- topic mastery,
- topics needing priority,
- recommended study actions.

Do not invent performance data.

Return structured JSON only.
''';

      case AiTask.planReview:
        return '''
Analyze the supplied learning performance and recommend review priorities.

Consider:
- mastery,
- recent performance,
- repeated errors,
- forgotten or weak topics,
- previous review results.

Recommend appropriate review intervals and activities.

Return structured JSON only.
''';

      case AiTask.recommendStudy:
        return '''
Create the student's next study recommendations from the supplied data.

Prioritize:
- weak topics,
- overdue reviews,
- recurring errors,
- important knowledge gaps,
- interleaved practice when appropriate.

Give a clear action, reason, topics, and estimated study time.

Return structured JSON only.
''';
    }
  }
}
