import 'package:flutter/material.dart';

import '../models/question.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({
    super.key,
    required this.question,
    required this.controller,
  });

  final InterviewQuestion question;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.progress.stateFor(question.id);
        final status = state.status ?? question.seedStatus;
        final palette = context.palette;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.background,
            elevation: 0,
            title: Text(question.module),
            actions: [
              IconButton(
                tooltip: state.isFavorite ? '取消收藏' : '收藏',
                onPressed: () => controller.toggleFavorite(question.id),
                icon: Icon(state.isFavorite ? Icons.star : Icons.star_border),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                question.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(status: status),
                  for (final tag in question.tags)
                    Chip(
                      label: Text(tag),
                      backgroundColor: palette.accentMuted,
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(title: '考察点', items: question.checkpoints),
              _Section(title: '答案要点', items: question.answerPoints),
              _Section(title: '深挖追问', items: question.followUps),
              _Section(title: '常见误区', items: question.mistakes),
              const SizedBox(height: 14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.success,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.mastered,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Pass，之后不再刷到'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.nextReview,
                ),
                icon: const Icon(Icons.schedule),
                label: const Text('保留，稍后复习'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.notMastered,
                ),
                child: const Text('标记为未掌握'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: context.palette.accent)),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
