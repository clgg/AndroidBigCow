import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.item, required this.onTap});

  final DecoratedQuestion item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border.all(color: palette.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    item.question.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip(status: item.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${item.question.module} · ${item.question.tags.join(' / ')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class QuestionTagRow extends StatelessWidget {
  const QuestionTagRow({
    super.key,
    required this.status,
    required this.tags,
  });

  final ReviewStatus status;
  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          StatusChip(status: status),
          for (final tag in tags) ...[
            const SizedBox(width: 8),
            QuestionTagChip(label: tag),
          ],
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final ReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (backgroundColor, foregroundColor, borderColor) = switch (status) {
      ReviewStatus.mastered => (
          palette.success.withOpacity(0.12),
          palette.success,
          palette.success.withOpacity(0.28),
        ),
      ReviewStatus.nextReview => (
          palette.warning.withOpacity(0.14),
          palette.warning,
          palette.warning.withOpacity(0.30),
        ),
      ReviewStatus.notMastered => (
          palette.accent.withOpacity(0.12),
          palette.accent,
          palette.accent.withOpacity(0.28),
        ),
    };

    return QuestionTagChip(
      label: status.label,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }
}

class QuestionTagChip extends StatelessWidget {
  const QuestionTagChip({
    super.key,
    required this.label,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  final String label;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? palette.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? palette.border,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foregroundColor ?? palette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
