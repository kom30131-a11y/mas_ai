class Subject {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Subject({
    this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'] as int?,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Topic {
  final int? id;
  final int subjectId;
  final String name;
  final double mastery;
  final DateTime createdAt;

  const Topic({
    this.id,
    required this.subjectId,
    required this.name,
    this.mastery = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'name': name,
        'mastery': mastery,
        'created_at': createdAt.toIso8601String(),
      };

  factory Topic.fromMap(Map<String, dynamic> map) => Topic(
        id: map['id'] as int?,
        subjectId: map['subject_id'] as int,
        name: map['name'] as String,
        mastery: (map['mastery'] as num).toDouble(),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class StudyContent {
  final int? id;
  final int? subjectId;
  final int? topicId;
  final String title;
  final String type;
  final String content;
  final DateTime createdAt;

  const StudyContent({
    this.id,
    this.subjectId,
    this.topicId,
    required this.title,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'subject_id': subjectId,
        'topic_id': topicId,
        'title': title,
        'type': type,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory StudyContent.fromMap(Map<String, dynamic> map) => StudyContent(
        id: map['id'] as int?,
        subjectId: map['subject_id'] as int?,
        topicId: map['topic_id'] as int?,
        title: map['title'] as String,
        type: map['type'] as String,
        content: map['content'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Question {
  final int? id;
  final int? contentId;
  final int? topicId;
  final String type;
  final String question;
  final String answer;
  final String? options;
  final String? explanation;
  final DateTime createdAt;

  const Question({
    this.id,
    this.contentId,
    this.topicId,
    required this.type,
    required this.question,
    required this.answer,
    this.options,
    this.explanation,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content_id': contentId,
        'topic_id': topicId,
        'type': type,
        'question': question,
        'answer': answer,
        'options': options,
        'explanation': explanation,
        'created_at': createdAt.toIso8601String(),
      };

  factory Question.fromMap(Map<String, dynamic> map) => Question(
        id: map['id'] as int?,
        contentId: map['content_id'] as int?,
        topicId: map['topic_id'] as int?,
        type: map['type'] as String,
        question: map['question'] as String,
        answer: map['answer'] as String,
        options: map['options'] as String?,
        explanation: map['explanation'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
