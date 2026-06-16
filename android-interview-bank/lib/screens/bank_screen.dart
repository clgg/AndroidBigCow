import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

class BankScreen extends StatefulWidget {
  const BankScreen({
    super.key,
    required this.repository,
    required this.controller,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onOpenQuestion,
  });

  final QuestionRepository repository;
  final AppController controller;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final ValueChanged<InterviewQuestion> onOpenQuestion;

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
  static const _primaryTags = [
    '高频',
    '基础',
    '进阶',
    '底层',
    '易混',
    '场景题',
    '性能',
    '架构',
  ];

  String _query = '';
  String? _module;
  final Set<String> _tags = {};

  @override
  Widget build(BuildContext context) {
    final filtered = widget.repository.filter(
      query: _query,
      module: _module,
      tags: _tags,
    );
    final decoratedById = {
      for (final item in widget.repository.withProgress(
        widget.controller.progress,
      ))
        item.question.id: item,
    };

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '待刷题库',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              FilledButton.icon(
                onPressed: widget.isRefreshing ? null : widget.onRefresh,
                icon: widget.isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_download_outlined),
                label: const Text('拉取最新题目'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('搜索题目、模块、标签和答案要点。',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          TextField(
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: '搜索 Handler、Binder、ANR...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: context.palette.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: context.palette.border),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _ChipScroller(
            values: ['全部', ...widget.repository.modules],
            selected: _module ?? '全部',
            onSelected: (value) => setState(() {
              _module = value == '全部' ? null : value;
            }),
          ),
          const SizedBox(height: 10),
          _CompactTagFilter(
            values: _primaryTags
                .where(widget.repository.tags.contains)
                .toList(growable: false),
            selected: _tags,
            onToggle: (tag) => setState(() {
              if (_tags.contains(tag)) {
                _tags.remove(tag);
              } else {
                _tags.add(tag);
              }
            }),
            onClear: _tags.isEmpty ? null : () => setState(_tags.clear),
          ),
          const SizedBox(height: 18),
          Text(
            '${filtered.length} 道题',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 10),
          if (filtered.isEmpty)
            AppCard(
              child: Text(
                '没有匹配的题目。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...filtered.map(
              (question) => QuestionCard(
                item: decoratedById[question.id]!,
                onTap: () => widget.onOpenQuestion(question),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChipScroller extends StatelessWidget {
  const _ChipScroller({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(value),
                selected: selected == value,
                onSelected: (_) => onSelected(value),
              ),
            ),
        ],
      ),
    );
  }
}

class _CompactTagFilter extends StatelessWidget {
  const _CompactTagFilter({
    required this.values,
    required this.selected,
    required this.onToggle,
    required this.onClear,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('常用标签', style: Theme.of(context).textTheme.labelMedium),
            const Spacer(),
            TextButton(
              onPressed: onClear,
              child: const Text('清空'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(value),
                    selected: selected.contains(value),
                    onSelected: (_) => onToggle(value),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
