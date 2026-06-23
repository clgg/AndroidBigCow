import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import 'backend_client.dart';
import 'question_local_store.dart';
import '../models/question.dart';
import '../models/tech_stack.dart';
import '../models/user_progress.dart';

class QuestionRepository {
  QuestionRepository(List<InterviewQuestion> questions)
      : _questions = List.unmodifiable(questions);

  final List<InterviewQuestion> _questions;
  final Random _random = Random();

  static const defaultAssetPaths = [
    'assets/question_bank.json',
    'assets/question_bank_extension_2026_06.json',
    'assets/question_bank_flutter_2026_06.json',
  ];

  static Future<QuestionRepository> loadFromAsset([
    String path = 'assets/question_bank.json',
  ]) {
    return loadFromAssets([path]);
  }

  static Future<QuestionRepository> loadFromAssets([
    List<String> paths = defaultAssetPaths,
  ]) async {
    final questions = <InterviewQuestion>[];
    final seenIds = <String>{};
    for (final path in paths) {
      final loaded = await _loadQuestions(path);
      for (final question in loaded) {
        if (seenIds.add(question.id)) {
          questions.add(question);
        }
      }
    }
    return QuestionRepository(questions);
  }

  static Future<QuestionRepository> loadFromSources({
    BackendClient? backendClient,
    List<String> paths = defaultAssetPaths,
  }) async {
    final localRepository = await loadFromAssets(paths);
    try {
      final store = await QuestionLocalStore.open();
      final cachedRemoteQuestions = await store.allQuestions();
      return QuestionRepository(
        _mergeQuestions(localRepository.all, cachedRemoteQuestions),
      );
    } catch (_) {
      return localRepository;
    }
  }

  static Future<QuestionRepository> pullLatestAndCache({
    required BackendClient backendClient,
    required SelectedTechStack selectedTechStack,
    List<String> paths = defaultAssetPaths,
  }) async {
    final localRepository = await loadFromAssets(paths);
    final store = await QuestionLocalStore.open();
    var afterVersion = await store.latestVersion(selectedTechStack);
    var guard = 0;
    while (guard < 50) {
      guard += 1;
      final result = await backendClient.syncQuestions(
        categoryId: selectedTechStack.categoryId,
        languageId: selectedTechStack.languageId,
        afterVersion: afterVersion,
      );
      await store.upsertAll(result.questions);
      await store.deleteByIds(result.deletedIds);
      afterVersion = result.nextAfterVersion;
      if (!result.hasMore) {
        break;
      }
    }
    final cachedRemoteQuestions = await store.allQuestions();

    return QuestionRepository(
      _mergeQuestions(localRepository.all, cachedRemoteQuestions),
    );
  }

  static Future<List<InterviewQuestion>> _loadQuestions(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List;
    return decoded
        .cast<Map<String, Object?>>()
        .map(InterviewQuestion.fromJson)
        .toList(growable: false);
  }

  static List<InterviewQuestion> _mergeQuestions(
    List<InterviewQuestion> localQuestions,
    List<InterviewQuestion> remoteQuestions,
  ) {
    final merged = <String, InterviewQuestion>{
      for (final question in localQuestions) question.id: question,
    };
    for (final question in remoteQuestions) {
      merged[question.id] = question;
    }
    return merged.values.toList(growable: false);
  }

  List<InterviewQuestion> get all => _questions;

  QuestionRepository forTechStack(SelectedTechStack stack) {
    return QuestionRepository(
      _questions
          .where(
            (question) =>
                question.techCategory == stack.categoryId &&
                question.techLanguage == stack.languageId,
          )
          .toList(growable: false),
    );
  }

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
    return _questions.where((question) {
      final moduleMatches = module == null || question.module == module;
      final tagsMatch = tags.isEmpty || tags.every(question.tags.contains);
      return moduleMatches && tagsMatch && question.matches(query);
    }).toList(growable: false);
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
    return _questions.map((question) {
      final state = progress.stateFor(question.id);
      return DecoratedQuestion(
        question: question,
        status: state.status ?? question.seedStatus,
        isFavorite: state.isFavorite,
      );
    }).toList(growable: false);
  }
}
