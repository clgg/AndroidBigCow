import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/backend_config.dart';
import '../models/question.dart';
import '../models/tech_stack.dart';
import '../models/user_progress.dart';

class BackendClient {
  BackendClient({
    http.Client? httpClient,
    this.baseUrl = BackendConfig.baseUrl,
    this.timeout = BackendConfig.timeout,
  }) : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String baseUrl;
  final Duration timeout;

  Uri _uri(String path, [Map<String, String?> query = const {}]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null && entry.value!.isNotEmpty)
            entry.key: entry.value,
      },
    );
  }

  Future<List<TechCategory>> fetchTechCategories() async {
    final response = await _get('/api/tech/categories');
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .cast<Map<String, Object?>>()
        .map(TechCategory.fromJson)
        .toList(growable: false);
  }

  Future<List<InterviewQuestion>> fetchQuestions({
    String? categoryId,
    String? languageId,
  }) async {
    final response = await _get('/api/questions', {
      'category': categoryId,
      'language': languageId,
    });
    final decoded = jsonDecode(response.body) as List;
    return decoded
        .cast<Map<String, Object?>>()
        .map(InterviewQuestion.fromJson)
        .toList(growable: false);
  }

  Future<List<InterviewQuestion>> fetchLatestQuestions({
    String? categoryId,
    String? languageId,
    int sinceVersion = 0,
  }) async {
    final response = await _get('/api/questions/latest', {
      'category': categoryId,
      'language': languageId,
      'sinceVersion': sinceVersion.toString(),
    });
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    final questions = decoded['questions'] as List? ?? const [];
    return questions
        .cast<Map<String, Object?>>()
        .map(InterviewQuestion.fromJson)
        .toList(growable: false);
  }

  Future<QuestionSyncResult> syncQuestions({
    required String categoryId,
    required String languageId,
    required int afterVersion,
    int limit = 100,
  }) async {
    final response = await _get('/api/questions/sync', {
      'category': categoryId,
      'language': languageId,
      'afterVersion': afterVersion.toString(),
      'limit': limit.toString(),
    });
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    final questions = decoded['questions'] as List? ?? const [];
    final deletedIds = decoded['deletedIds'] as List? ?? const [];
    return QuestionSyncResult(
      latestVersion:
          (decoded['latestVersion'] as num?)?.toInt() ?? afterVersion,
      nextAfterVersion:
          (decoded['nextAfterVersion'] as num?)?.toInt() ?? afterVersion,
      hasMore: decoded['hasMore'] == true,
      questions: questions
          .cast<Map<String, Object?>>()
          .map(InterviewQuestion.fromJson)
          .toList(growable: false),
      deletedIds: deletedIds.map((id) => id.toString()).toList(growable: false),
    );
  }

  Future<void> syncProgress({
    required String clientId,
    required UserProgress progress,
    SelectedTechStack? selectedTechStack,
  }) async {
    final states = progress.questionStates;
    final summary = {
      'totalTouched': states.length,
      'favoriteCount': states.values.where((state) => state.isFavorite).length,
      'notMasteredCount': states.values
          .where((state) => state.status == ReviewStatus.notMastered)
          .length,
      'masteredCount': states.values
          .where((state) => state.status == ReviewStatus.mastered)
          .length,
      'nextReviewCount': states.values
          .where((state) => state.status == ReviewStatus.nextReview)
          .length,
    };

    await _post('/api/progress/sync', {
      'clientId': clientId,
      'techCategory': selectedTechStack?.categoryId,
      'techLanguage': selectedTechStack?.languageId,
      'summary': summary,
      'questionStates': progress.toJson()['questionStates'],
    });
  }

  Future<http.Response> _get(
    String path, [
    Map<String, String?> query = const {},
  ]) async {
    final response = await _httpClient.get(_uri(path, query)).timeout(timeout);
    _throwIfFailed(response);
    return response;
  }

  Future<http.Response> _post(String path, Map<String, Object?> body) async {
    final response = await _httpClient
        .post(
          _uri(path),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(timeout);
    _throwIfFailed(response);
    return response;
  }

  void _throwIfFailed(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendException(
        'Backend request failed: ${response.statusCode} ${response.body}',
      );
    }
  }
}

class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

class QuestionSyncResult {
  const QuestionSyncResult({
    required this.latestVersion,
    required this.nextAfterVersion,
    required this.hasMore,
    required this.questions,
    required this.deletedIds,
  });

  final int latestVersion;
  final int nextAfterVersion;
  final bool hasMore;
  final List<InterviewQuestion> questions;
  final List<String> deletedIds;
}
