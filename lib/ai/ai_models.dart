class GeneratedQuestion {
  final String type;
  final String question;
  final String answer;
  final List<String> options;
  final String explanation;
  final int? topicId;
  final int? contentId;

  const GeneratedQuestion({
    required this.type,
    required this.question,
    required this.answer,
    this.options = const [],
    this.explanation = '',
    this.topicId,
    this.contentId,
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
  final double masteryChange;

  const AnswerEvaluation({
    required this.isCorrect,
    this.errorReason = '',
    this.explanation = '',
    this.masteryChange = 0,
  });
}
