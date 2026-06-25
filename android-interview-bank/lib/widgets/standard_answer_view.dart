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
    final code = _formatCodeForDisplay(
      _stripCodeFence(selected.body),
      selected.title,
    );

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
                constraints: const BoxConstraints(maxHeight: 360),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF08111D)
                      : const Color(0xFF111827),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        code,
                        style: const TextStyle(
                          color: Color(0xFFE5E7EB),
                          fontFamily: 'monospace',
                          fontSize: 12,
                          height: 1.45,
                        ),
                      ),
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

String _formatCodeForDisplay(String code, String language) {
  final normalizedLanguage = language.trim().toLowerCase();
  if (normalizedLanguage == 'python' || normalizedLanguage == 'py') {
    return code.trimRight();
  }
  if (code.trim().contains('\n')) {
    return code.trimRight();
  }
  if (!_usesBraceSyntax(normalizedLanguage)) {
    return code.trimRight();
  }
  return _formatBraceSyntax(code);
}

bool _usesBraceSyntax(String language) {
  const languages = {
    'c',
    'c++',
    'cpp',
    'go',
    'golang',
    'java',
    'javascript',
    'js',
    'kotlin',
    'typescript',
    'ts',
  };
  return languages.contains(language);
}

String _formatBraceSyntax(String code) {
  final buffer = StringBuffer();
  var indent = 0;
  var parenDepth = 0;
  var inString = false;
  var stringQuote = '';
  var escaped = false;
  var pendingSpace = false;

  bool endsWithOpenBoundary() {
    final text = buffer.toString();
    return text.isEmpty || RegExp(r'[\s({\[]$').hasMatch(text);
  }

  void writeIndent() {
    buffer.write('  ' * indent);
  }

  void newline({bool trimRight = true}) {
    var text = buffer.toString();
    if (trimRight) {
      text = text.replaceFirst(RegExp(r'[ \t]+$'), '');
      buffer
        ..clear()
        ..write(text);
    }
    if (!buffer.toString().endsWith('\n')) {
      buffer.writeln();
    }
    writeIndent();
    pendingSpace = false;
  }

  for (var i = 0; i < code.length; i++) {
    final char = code[i];

    if (inString) {
      buffer.write(char);
      if (escaped) {
        escaped = false;
      } else if (char == '\\') {
        escaped = true;
      } else if (char == stringQuote) {
        inString = false;
        stringQuote = '';
      }
      continue;
    }

    if (char == '"' || char == "'" || char == '`') {
      if (pendingSpace && !endsWithOpenBoundary()) {
        buffer.write(' ');
      }
      pendingSpace = false;
      inString = true;
      stringQuote = char;
      buffer.write(char);
      continue;
    }

    if (char.trim().isEmpty) {
      pendingSpace = true;
      continue;
    }

    if (pendingSpace && !endsWithOpenBoundary()) {
      buffer.write(' ');
    }
    pendingSpace = false;

    if (char == '(' || char == '[') {
      parenDepth += 1;
      buffer.write(char);
      continue;
    }
    if (char == ')' || char == ']') {
      parenDepth = parenDepth > 0 ? parenDepth - 1 : 0;
      buffer.write(char);
      continue;
    }
    if (char == '{') {
      buffer.write(' {');
      indent += 1;
      newline();
      continue;
    }
    if (char == '}') {
      indent = indent > 0 ? indent - 1 : 0;
      newline();
      buffer.write('}');
      if (i + 1 < code.length && code[i + 1] != ';' && code[i + 1] != ',') {
        newline();
      }
      continue;
    }
    if (char == ';' && parenDepth == 0) {
      buffer.write(';');
      newline();
      continue;
    }

    buffer.write(char);
  }

  return buffer
      .toString()
      .split('\n')
      .map((line) => line.trimRight())
      .join('\n')
      .trimRight();
}
