import 'dart:convert';

import 'ai_models.dart';

class AiResponseParser {
  AiResponseParser._();

  static List<GeneratedQuestion> questions(String response) {
    final data = _decode(response);
    final items = _list(data['questions']);

    return items.map((item) {
      return GeneratedQuestion(
        type: _string(item['type'], 'mcq'),
        question: _string(item['question']),
        answer: _string(item['answer']),
        options: _strings(item['options']),
        explanation: _string(item['explanation']),
        difficulty: _string(item['difficulty'], 'medium'),
        topicId: _int(item['topic_id']),
        contentId: _int(item['content_id']),
        topicName: _string(item['topic_name']),
      );
    }).toList();
  }

  static AnswerEvaluation evaluation(String response) {
    final data = _decode(response);

    return AnswerEvaluation(
      isCorrect: data['is_correct'] == true,
      errorReason: _string(data['error_reason']),
      explanation: _string(data['explanation']),
      knowledgeGap: _string(data['knowledge_gap']),
      masteryChange: _double(data['mastery_change']),
      recommendedAction: _string(data['recommended_action']),
    );
  }

  static PerformanceAnalysis performance(String response) {
    final data = _decode(response);

    return PerformanceAnalysis(
      topics: _topicPerformance(data['topics']),
      reviewPlans: _reviewPlans(data['review_plans']),
      recommendations: _recommendations(data['recommendations']),
      strengths: _strings(data['strengths']),
      weaknesses: _strings(data['weaknesses']),
      summary: _string(data['summary']),
    );
  }

  static Map<String, dynamic> _decode(String response) {
    final cleaned = response
        .trim()
        .replaceFirst('```json', '')
        .replaceFirst('```', '')
        .trim();

    final decoded = jsonDecode(cleaned);

    if (decoded is! Map) {
      throw const FormatException('AI response must be a JSON object.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  static List<Map<String, dynamic>> _list(dynamic value) {
    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<TopicPerformance> _topicPerformance(dynamic value) {
    return _list(value).map((item) {
      return TopicPerformance(
        topicId: _int(item['topic_id']) ?? 0,
        topicName: _string(item['topic_name']),
        mastery: _double(item['mastery']),
        state: _string(item['state'], 'learning'),
        weak: item['weak'] == true,
        attempts: _int(item['attempts']) ?? 0,
        correct: _int(item['correct']) ?? 0,
        strengths: _strings(item['strengths']),
        weaknesses: _strings(item['weaknesses']),
        knowledgeGaps: _strings(item['knowledge_gaps']),
      );
    }).toList();
  }

  static List<ReviewPlan> _reviewPlans(dynamic value) {
    return _list(value).map((item) {
      return ReviewPlan(
        topicId: _int(item['topic_id']) ?? 0,
        topicName: _string(item['topic_name']),
        priority: _string(item['priority'], 'normal'),
        intervalDays: _int(item['interval_days']) ?? 1,
        reason: _string(item['reason']),
        recommendedActivity: _string(item['recommended_activity']),
        focus: _string(item['focus']),
      );
    }).toList();
  }

  static List<StudyRecommendation> _recommendations(dynamic value) {
    return _list(value).map((item) {
      return StudyRecommendation(
        priority: _string(item['priority'], 'normal'),
        action: _string(item['action']),
        reason: _string(item['reason']),
        topicIds: _ints(item['topic_ids']),
        estimatedMinutes: _int(item['estimated_minutes']) ?? 0,
      );
    }).toList();
  }

  static String _string(dynamic value, [String fallback = '']) {
    return value?.toString().trim() ?? fallback;
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static double _double(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _strings(dynamic value) {
    if (value is! List) return [];

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static List<int> _ints(dynamic value) {
    if (value is! List) return [];

    return value
        .map(_int)
        .whereType<int>()
        .toList();
  }
}
