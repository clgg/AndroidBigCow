import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../models/question.dart';
import '../models/user_progress.dart';

class QuestionRepository {
  QuestionRepository(List<InterviewQuestion> questions)
    : _questions = List.unmodifiable(questions);

  final List<InterviewQuestion> _questions;
  final Random _random = Random();

  static Future<QuestionRepository> loadFromAsset([
    String path = 'assets/question_bank.json',
  ]) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List;
    return QuestionRepository(
      decoded
          .cast<Map<String, Object?>>()
          .map(InterviewQuestion.fromJson)
          .toList(growable: false),
    );
  }

  List<InterviewQuestion> get all => _questions;

  List<String> get modules {
    final modules = <String>[];
    for (final question in _questions) {
      if (!modules.contains(question.module)) {
        modules.add(question.module);
      }
    }
    return modules;
  }

  List<String> get tags {
    final tags = <String>{};
    for (final question in _questions) {
      tags.addAll(question.tags);
    }
    return tags.toList(growable: false)..sort();
  }

  List<InterviewQuestion> search(String query) {
    return filter(query: query);
  }

  List<InterviewQuestion> filter({
    String query = '',
    String? module,
    Set<String> tags = const {},
  }) {
    return _questions
        .where((question) {
          final moduleMatches = module == null || question.module == module;
          final tagsMatch = tags.isEmpty || tags.every(question.tags.contains);
          return moduleMatches && tagsMatch && question.matches(query);
        })
        .toList(growable: false);
  }

  InterviewQuestion? byId(String id) {
    for (final question in _questions) {
      if (question.id == id) {
        return question;
      }
    }
    return null;
  }

  InterviewQuestion randomQuestion([List<InterviewQuestion>? source]) {
    final pool = source == null || source.isEmpty ? _questions : source;
    return pool[_random.nextInt(pool.length)];
  }

  List<DecoratedQuestion> withProgress(UserProgress progress) {
    return _questions
        .map((question) {
          final state = progress.stateFor(question.id);
          return DecoratedQuestion(
            question: question,
            status: state.status ?? question.seedStatus,
            isFavorite: state.isFavorite,
          );
        })
        .toList(growable: false);
  }
}
