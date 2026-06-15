import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/standard_answer_builder.dart';

class StandardAnswerView extends StatelessWidget {
  const StandardAnswerView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final sections = StandardAnswerBuilder.parse(text);
    final palette = context.palette;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          Text(
            sections[i].title,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ..._bodyLines(context, sections[i].body),
        ],
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
