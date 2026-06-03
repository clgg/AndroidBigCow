import 'question.dart';

class QuestionProgress {
  const QuestionProgress({this.isFavorite = false, this.status});

  final bool isFavorite;
  final ReviewStatus? status;

  factory QuestionProgress.fromJson(Map<String, Object?> json) {
    return QuestionProgress(
      isFavorite: json['isFavorite'] == true,
      status: json['status'] == null
          ? null
          : ReviewStatus.fromJson(json['status'] as String?),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'isFavorite': isFavorite,
      if (status != null) 'status': status!.name,
    };
  }

  QuestionProgress copyWith({bool? isFavorite, ReviewStatus? status}) {
    return QuestionProgress(
      isFavorite: isFavorite ?? this.isFavorite,
      status: status ?? this.status,
    );
  }
}

class UserProgress {
  const UserProgress({this.questionStates = const {}});

  final Map<String, QuestionProgress> questionStates;

  factory UserProgress.fromJson(Map<String, Object?> json) {
    final rawStates = json['questionStates'];
    if (rawStates is! Map) {
      return const UserProgress();
    }

    return UserProgress(
      questionStates: rawStates.map((key, value) {
        return MapEntry(
          key.toString(),
          QuestionProgress.fromJson(Map<String, Object?>.from(value as Map)),
        );
      }),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'questionStates': questionStates.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    };
  }

  QuestionProgress stateFor(String questionId) {
    return questionStates[questionId] ?? const QuestionProgress();
  }

  UserProgress setFavorite(String questionId, bool isFavorite) {
    final next = Map<String, QuestionProgress>.from(questionStates);
    next[questionId] = stateFor(questionId).copyWith(isFavorite: isFavorite);
    return UserProgress(questionStates: next);
  }

  UserProgress setStatus(String questionId, ReviewStatus status) {
    final next = Map<String, QuestionProgress>.from(questionStates);
    next[questionId] = stateFor(questionId).copyWith(status: status);
    return UserProgress(questionStates: next);
  }
}
