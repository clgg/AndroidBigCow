enum ReviewStatus {
  notMastered('未掌握'),
  mastered('已掌握'),
  nextReview('下次复习');

  const ReviewStatus(this.label);

  final String label;

  static ReviewStatus fromJson(String? value) {
    return ReviewStatus.values.firstWhere(
      (status) => status.name == value || status.label == value,
      orElse: () => ReviewStatus.notMastered,
    );
  }
}

class InterviewQuestion {
  const InterviewQuestion({
    required this.id,
    required this.module,
    required this.title,
    required this.tags,
    required this.seedStatus,
    required this.checkpoints,
    required this.answerPoints,
    required this.followUps,
    required this.mistakes,
    this.techCategory = 'client',
    this.techLanguage = 'android',
    this.standardAnswer,
    this.version = 1,
    this.updatedAt,
  });

  final String id;
  final String module;
  final String title;
  final List<String> tags;
  final ReviewStatus seedStatus;
  final List<String> checkpoints;
  final List<String> answerPoints;
  final List<String> followUps;
  final List<String> mistakes;
  final String techCategory;
  final String techLanguage;
  final String? standardAnswer;
  final int version;
  final String? updatedAt;

  factory InterviewQuestion.fromJson(Map<String, Object?> json) {
    return InterviewQuestion(
      id: json['id'] as String,
      module: json['module'] as String,
      title: json['title'] as String,
      tags: _stringList(json['tags']),
      seedStatus: ReviewStatus.fromJson(json['reviewStatus'] as String?),
      checkpoints: _stringList(json['checkpoints']),
      answerPoints: _stringList(json['answerPoints']),
      followUps: _stringList(json['followUps']),
      mistakes: _stringList(json['mistakes']),
      techCategory: json['techCategory'] as String? ?? 'client',
      techLanguage: json['techLanguage'] as String? ?? 'android',
      standardAnswer: json['standardAnswer'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'module': module,
      'title': title,
      'tags': tags,
      'reviewStatus': seedStatus.name,
      'checkpoints': checkpoints,
      'answerPoints': answerPoints,
      'followUps': followUps,
      'mistakes': mistakes,
      'techCategory': techCategory,
      'techLanguage': techLanguage,
      if (standardAnswer != null) 'standardAnswer': standardAnswer,
      'version': version,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    return [
      module,
      techCategory,
      techLanguage,
      title,
      ...tags,
      ...checkpoints,
      ...answerPoints,
      ...followUps,
      ...mistakes,
      if (standardAnswer != null) standardAnswer!,
    ].any((value) => value.toLowerCase().contains(normalized));
  }
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }
  return value.whereType<String>().toList(growable: false);
}

class DecoratedQuestion {
  const DecoratedQuestion({
    required this.question,
    required this.status,
    required this.isFavorite,
  });

  final InterviewQuestion question;
  final ReviewStatus status;
  final bool isFavorite;
}
