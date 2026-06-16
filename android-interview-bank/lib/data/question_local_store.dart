import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/question.dart';
import '../models/tech_stack.dart';

class QuestionLocalStore {
  QuestionLocalStore._(this._database);

  final Database _database;

  static Future<QuestionLocalStore> open() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      p.join(databasePath, 'interview_question_bank.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE questions (
            id TEXT PRIMARY KEY,
            tech_category TEXT NOT NULL,
            tech_language TEXT NOT NULL,
            module TEXT NOT NULL,
            title TEXT NOT NULL,
            payload_json TEXT NOT NULL,
            version INTEGER NOT NULL DEFAULT 1,
            updated_at TEXT
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_local_questions_stack ON questions(tech_category, tech_language)',
        );
        await db.execute(
          'CREATE INDEX idx_local_questions_version ON questions(tech_category, tech_language, version)',
        );
      },
    );
    return QuestionLocalStore._(database);
  }

  Future<List<InterviewQuestion>> allQuestions() async {
    final rows = await _database.query(
      'questions',
      orderBy: 'tech_category, tech_language, module, title',
    );
    return rows.map(_questionFromRow).toList(growable: false);
  }

  Future<int> latestVersion(SelectedTechStack stack) async {
    final rows = await _database.rawQuery(
      '''
      SELECT COALESCE(MAX(version), 0) AS version
      FROM questions
      WHERE tech_category = ? AND tech_language = ?
      ''',
      [stack.categoryId, stack.languageId],
    );
    return (rows.first['version'] as int?) ?? 0;
  }

  Future<void> upsertAll(List<InterviewQuestion> questions) async {
    if (questions.isEmpty) {
      return;
    }
    final batch = _database.batch();
    for (final question in questions) {
      batch.insert(
        'questions',
        _questionToRow(question),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> deleteByIds(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final batch = _database.batch();
    for (final id in ids) {
      batch.delete('questions', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Map<String, Object?> _questionToRow(InterviewQuestion question) {
    return {
      'id': question.id,
      'tech_category': question.techCategory,
      'tech_language': question.techLanguage,
      'module': question.module,
      'title': question.title,
      'payload_json': jsonEncode(question.toJson()),
      'version': question.version,
      'updated_at': question.updatedAt,
    };
  }

  InterviewQuestion _questionFromRow(Map<String, Object?> row) {
    return InterviewQuestion.fromJson(
      Map<String, Object?>.from(
        jsonDecode(row['payload_json'] as String) as Map,
      ),
    );
  }
}
