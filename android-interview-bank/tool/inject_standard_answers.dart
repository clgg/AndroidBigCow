import 'dart:convert';
import 'dart:io';

import 'package:android_interview_bank/models/question.dart';
import 'package:android_interview_bank/utils/standard_answer_builder.dart';

Future<void> main() async {
  const paths = [
    'assets/question_bank.json',
    'assets/question_bank_extension_2026_06.json',
  ];

  var total = 0;
  for (final path in paths) {
    total += await _inject(path);
  }

  stdout.writeln('Injected standardAnswer for $total questions.');
}

Future<int> _inject(String path) async {
  final file = File(path);
  final decoded = jsonDecode(await file.readAsString()) as List;
  final questions = decoded.cast<Map<String, Object?>>();

  for (final item in questions) {
    final question = InterviewQuestion.fromJson(item);
    item['standardAnswer'] = StandardAnswerBuilder.build(question);
  }

  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString('${encoder.convert(questions)}\n');
  stdout.writeln('Updated ${questions.length} questions in $path');
  return questions.length;
}
