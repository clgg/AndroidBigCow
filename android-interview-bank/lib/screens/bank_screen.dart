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
    required this.onOpenQuestion,
  });

  final QuestionRepository repository;
  final AppController controller;
  final ValueChanged<InterviewQuestion> onOpenQuestion;

  @override
  State<BankScreen> createState() => _BankScreenState();
}

class _BankScreenState extends State<BankScreen> {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('待刷题库', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('搜索题目、模块、标签和答案要点。', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        TextField(
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
        _TagWrap(
          values: widget.repository.tags,
          selected: _tags,
          onToggle: (tag) => setState(() {
            if (_tags.contains(tag)) {
              _tags.remove(tag);
            } else {
              _tags.add(tag);
            }
          }),
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

class _TagWrap extends StatelessWidget {
  const _TagWrap({
    required this.values,
    required this.selected,
    required this.onToggle,
  });

  final List<String> values;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          FilterChip(
            label: Text(value),
            selected: selected.contains(value),
            onSelected: (_) => onToggle(value),
          ),
      ],
    );
  }
}
