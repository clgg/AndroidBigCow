import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
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
    final mastered = decorated
        .where((item) => item.status == ReviewStatus.mastered)
        .length;
    final nextReview = decorated
        .where((item) => item.status == ReviewStatus.nextReview)
        .toList(growable: false);
    final favorites = decorated.where((item) => item.isFavorite).length;
    final progress = repository.all.isEmpty
        ? 0.0
        : mastered / repository.all.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('Android 面试题库', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          '按模块刷题，标记状态，离线复习重点题。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '本周已减少重复出现 $mastered 次',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      color: context.palette.success,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: context.palette.surfaceAlt,
                  color: context.palette.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Metric(label: '题目', value: '${repository.all.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(label: '下次复习', value: '${nextReview.length}'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Metric(label: '收藏', value: '$favorites'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PrimaryAction(
          label: '随机刷一题',
          icon: Icons.shuffle,
          onTap: () => onOpenQuestion(repository.randomQuestion()),
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: '模块浏览',
          action: '${repository.modules.length} 个模块',
        ),
        const SizedBox(height: 10),
        ...repository.modules
            .map((module) {
              final count = repository.filter(module: module).length;
              return AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$count 道题 · 高频 / 底层 / 场景题',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: context.palette.textSecondary,
                    ),
                  ],
                ),
              );
            })
            .expand((widget) => [widget, const SizedBox(height: 10)]),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        Text(action, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
