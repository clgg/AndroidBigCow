import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/standard_answer_builder.dart';

class StandardAnswerView extends StatelessWidget {
  const StandardAnswerView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final sections = StandardAnswerBuilder.parse(text);
    final widgets = <Widget>[];

    var index = 0;
    while (index < sections.length) {
      final section = sections[index];
      if (_isCodeSection(section)) {
        final codeSections = <StandardAnswerSection>[];
        while (index < sections.length && _isCodeSection(sections[index])) {
          codeSections.add(sections[index]);
          index += 1;
        }
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 14));
        }
        widgets.add(_CodeTabs(sections: codeSections));
        continue;
      }

      if (widgets.isNotEmpty) {
        widgets.add(const SizedBox(height: 14));
      }
      widgets.add(_AnswerSection(section: section));
      index += 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _AnswerSection extends StatelessWidget {
  const _AnswerSection({required this.section});

  final StandardAnswerSection section;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ..._bodyLines(context, section.body),
      ],
    );
  }

  List<Widget> _bodyLines(BuildContext context, String body) {
    if (body.isEmpty) {
      return const [];
    }

    final palette = context.palette;
    final lines = body.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      if (trimmed.startsWith('• ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: palette.accent)),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(trimmed, style: Theme.of(context).textTheme.bodyMedium),
        ),
      );
    }

    return widgets;
  }
}

class _CodeTabs extends StatefulWidget {
  const _CodeTabs({required this.sections});

  final List<StandardAnswerSection> sections;

  @override
  State<_CodeTabs> createState() => _CodeTabsState();
}

class _CodeTabsState extends State<_CodeTabs> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selected = widget.sections[_selectedIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '代码实现',
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: palette.surfaceAlt,
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < widget.sections.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(widget.sections[i].title),
                          selected: i == _selectedIndex,
                          onSelected: (_) {
                            setState(() => _selectedIndex = i);
                          },
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF08111D)
                      : const Color(0xFF111827),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    _stripCodeFence(selected.body),
                    style: const TextStyle(
                      color: Color(0xFFE5E7EB),
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

bool _isCodeSection(StandardAnswerSection section) {
  const titles = {
    'c',
    'c++',
    'cpp',
    'go',
    'golang',
    'java',
    'javascript',
    'js',
    'kotlin',
    'python',
    'typescript',
    'ts',
  };
  return titles.contains(section.title.trim().toLowerCase());
}

String _stripCodeFence(String body) {
  final lines = body.trim().split('\n');
  if (lines.length >= 2 &&
      lines.first.trim().startsWith('```') &&
      lines.last.trim() == '```') {
    return lines.sublist(1, lines.length - 1).join('\n').trimRight();
  }
  return body.trimRight();
}
