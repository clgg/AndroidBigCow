import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';
import 'question_detail_screen.dart';

class ModuleQuestionsScreen extends StatelessWidget {
  const ModuleQuestionsScreen({
    super.key,
    required this.module,
    required this.repository,
    required this.controller,
  });

  final String module;
  final QuestionRepository repository;
  final AppController controller;

  void _openQuestion(BuildContext context, InterviewQuestion question) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => QuestionDetailScreen(
          question: question,
          controller: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = repository.filter(module: module);
    final decoratedById = {
      for (final item in repository.withProgress(controller.progress))
        item.question.id: item,
    };

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(
        backgroundColor: context.palette.background,
        elevation: 0,
        title: Text(module),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final refreshedById = {
            for (final item in repository.withProgress(controller.progress))
              item.question.id: item,
          };

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(module, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '${questions.length} 道题，点击题卡查看标准答案和追问。',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              for (final question in questions)
                QuestionCard(
                  item:
                      refreshedById[question.id] ?? decoratedById[question.id]!,
                  onTap: () => _openQuestion(context, question),
                ),
            ],
          );
        },
      ),
    );
  }
}
