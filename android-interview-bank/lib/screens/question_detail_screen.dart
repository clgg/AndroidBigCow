import 'package:flutter/material.dart';

import '../models/question.dart';
import '../screens/ai_explainer_screen.dart';
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
              QuestionTagRow(status: status, tags: question.tags),
              const SizedBox(height: 16),
              _Section(title: '考察点', items: question.checkpoints),
              _StandardAnswerCard(question: question),
              _Section(title: '答案要点', items: question.answerPoints),
              _Section(title: '深挖追问', items: question.followUps),
              _Section(title: '常见误区', items: question.mistakes),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          AiExplainerScreen(question: question),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('用 AI 继续讲解'),
              ),
              const SizedBox(height: 10),
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

class _StandardAnswerCard extends StatelessWidget {
  const _StandardAnswerCard({required this.question});

  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标准答案', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _opening,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            if (question.answerPoints.isNotEmpty) ...[
              Text(
                '回答时可以按这几个层次展开：',
                style: TextStyle(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < question.answerPoints.length; i++)
                _NumberedPoint(index: i + 1, text: question.answerPoints[i]),
            ],
            if (question.checkpoints.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '面试官重点看你是否能覆盖：${question.checkpoints.join('；')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (question.mistakes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.warning.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '注意不要只背结论。常见扣分点是：${question.mistakes.join('；')}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String get _opening {
    return '这道题属于「${question.module}」模块。作答时先给出核心结论，再解释关键机制，最后补充边界场景或常见问题。这样回答比单独罗列名词更完整，也更容易体现你真的理解了题目。';
  }
}

class _NumberedPoint extends StatelessWidget {
  const _NumberedPoint({required this.index, required this.text});

  final int index;
  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: palette.accentMuted,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$index',
              style: TextStyle(
                color: palette.accent,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
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
