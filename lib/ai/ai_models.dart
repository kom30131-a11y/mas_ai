enum AiTask {
  generateQuestions,
  evaluateAnswer,
  analyzePerformance,
  planReview,
  recommendStudy,
}

class GeneratedQuestion {
  final String type;
  final String question;
  final String answer;
  final List<String> options;
  final String explanation;
  final String difficulty;
  final int? topicId;
  final int? contentId;
  final String topicName;

  const GeneratedQuestion({
    required this.type,
    required this.question,
    required this.answer,
    this.options = const [],
    this.explanation = '',
    this.difficulty = 'medium',
    this.topicId,
    this.contentId,
    this.topicName = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'question': question,
      'answer': answer,
      'options': options.join('|'),
      'explanation': explanation,
      'topic_id': topicId,
      'content_id': contentId,
    };
  }
}

class AnswerEvaluation {
  final bool isCorrect;
  final String errorReason;
  final String explanation;
  final String knowledgeGap;
  final double masteryChange;
  final String recommendedAction;

  const AnswerEvaluation({
    required this.isCorrect,
    this.errorReason = '',
    this.explanation = '',
    this.knowledgeGap = '',
    this.masteryChange = 0,
    this.recommendedAction = '',
  });
}

class TopicPerformance {
  final int topicId;
  final String topicName;
  final double mastery;
  final String state;
  final bool weak;
  final int attempts;
  final int correct;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> knowledgeGaps;

  const TopicPerformance({
    required this.topicId,
    required this.topicName,
    required this.mastery,
    required this.state,
    required this.weak,
    required this.attempts,
    required this.correct,
    this.strengths = const [],
    this.weaknesses = const [],
    this.knowledgeGaps = const [],
  });
}

class ReviewPlan {
  final int topicId;
  final String topicName;
  final String priority;
  final int intervalDays;
  final String reason;
  final String recommendedActivity;
  final String focus;

  const ReviewPlan({
    required this.topicId,
    required this.topicName,
    required this.priority,
    required this.intervalDays,
    required this.reason,
    required this.recommendedActivity,
    this.focus = '',
  });
}

class StudyRecommendation {
  final String priority;
  final String action;
  final String reason;
  final List<int> topicIds;
  final int estimatedMinutes;

  const StudyRecommendation({
    required this.priority,
    required this.action,
    required this.reason,
    this.topicIds = const [],
    this.estimatedMinutes = 0,
  });
}

class PerformanceAnalysis {
  final List<TopicPerformance> topics;
  final List<ReviewPlan> reviewPlans;
  final List<StudyRecommendation> recommendations;
  final List<String> strengths;
  final List<String> weaknesses;
  final String summary;

  const PerformanceAnalysis({
    this.topics = const [],
    this.reviewPlans = const [],
    this.recommendations = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.summary = '',
  });
}
