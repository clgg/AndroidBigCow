import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
import '../state/app_controller.dart';
import '../widgets/question_card.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({
    super.key,
    required this.repository,
    required this.controller,
    required this.onOpenQuestion,
  });

  final QuestionRepository repository;
  final AppController controller;
  final ValueChanged<InterviewQuestion> onOpenQuestion;

  @override
  Widget build(BuildContext context) {
    final decorated = repository.withProgress(controller.progress);
    final nextReview = decorated
        .where((item) => item.status == ReviewStatus.nextReview)
        .toList(growable: false);
    final notMastered = decorated
        .where((item) => item.status == ReviewStatus.notMastered)
        .toList(growable: false);
    final favorites = decorated
        .where((item) => item.isFavorite)
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('复习队列', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('集中处理下次复习、未掌握和收藏题。', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _ReviewMetric(
                label: '下次复习',
                value: '${nextReview.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReviewMetric(
                label: '未掌握',
                value: '${notMastered.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ReviewMetric(label: '收藏', value: '${favorites.length}'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _Section(
          title: '下次复习',
          items: nextReview,
          onOpenQuestion: onOpenQuestion,
          empty: '暂无下次复习题。',
        ),
        _Section(
          title: '收藏题',
          items: favorites,
          onOpenQuestion: onOpenQuestion,
          empty: '还没有收藏题。',
        ),
      ],
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  const _ReviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.items,
    required this.onOpenQuestion,
    required this.empty,
  });

  final String title;
  final List<DecoratedQuestion> items;
  final ValueChanged<InterviewQuestion> onOpenQuestion;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        if (items.isEmpty)
          AppCard(child: Text(empty))
        else
          ...items.map(
            (item) => QuestionCard(
              item: item,
              onTap: () => onOpenQuestion(item.question),
            ),
          ),
      ],
    );
  }
}
