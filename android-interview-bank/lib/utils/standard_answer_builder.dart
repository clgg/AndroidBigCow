import '../models/question.dart';

class StandardAnswerSection {
  const StandardAnswerSection({required this.title, required this.body});

  final String title;
  final String body;
}

class StandardAnswerBuilder {
  const StandardAnswerBuilder._();

  static String build(InterviewQuestion question) {
    final buffer = StringBuffer();

    buffer.writeln('【一句话回答】');
    buffer.writeln(_oneLineAnswer(question));
    buffer.writeln();

    if (question.answerPoints.isNotEmpty) {
      buffer.writeln('【详细讲解】');
      for (final point in _detailPoints(question)) {
        buffer.writeln(point);
        buffer.writeln();
      }
    }

    if (question.checkpoints.isNotEmpty) {
      buffer.writeln('【需要掌握的知识点】');
      for (final checkpoint in question.checkpoints) {
        buffer.writeln('• ${_expandCheckpoint(checkpoint)}');
      }
      buffer.writeln();
    }

    if (question.mistakes.isNotEmpty) {
      buffer.writeln('【学习时别踩这些坑】');
      for (final mistake in question.mistakes) {
        buffer.writeln('• $mistake');
      }
    }

    return buffer.toString().trimRight();
  }

  static List<StandardAnswerSection> parse(String text) {
    final sections = <StandardAnswerSection>[];
    final lines = text.split('\n');
    String? title;
    final body = <String>[];

    void flush() {
      if (title == null) {
        return;
      }
      sections.add(
        StandardAnswerSection(
          title: title!,
          body: body.join('\n').trim(),
        ),
      );
      body.clear();
    }

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('【') && trimmed.endsWith('】')) {
        flush();
        title = trimmed.substring(1, trimmed.length - 1);
        continue;
      }
      if (title != null) {
        body.add(line);
      }
    }
    flush();

    if (sections.isEmpty && text.trim().isNotEmpty) {
      sections.add(const StandardAnswerSection(title: '标准答案', body: ''));
      sections[0] = StandardAnswerSection(title: '标准答案', body: text.trim());
    }

    return sections;
  }

  static String resolve(InterviewQuestion question) {
    final custom = question.standardAnswer?.trim();
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    return build(question);
  }

  static String _oneLineAnswer(InterviewQuestion question) {
    if (question.answerPoints.isEmpty) {
      return '这道题属于「${question.module}」，需要结合核心机制、适用场景和常见边界来理解。';
    }

    final first = question.answerPoints.first;
    if (first.length >= 28 || question.answerPoints.length == 1) {
      return first;
    }

    return '$first ${question.answerPoints[1]}';
  }

  static Iterable<String> _detailPoints(InterviewQuestion question) {
    if (question.answerPoints.isEmpty) {
      return const [];
    }

    final oneLine = _oneLineAnswer(question);
    var start = 0;

    if (oneLine.contains(question.answerPoints.first)) {
      start = 1;
    }
    if (start < question.answerPoints.length &&
        oneLine.contains(question.answerPoints[start])) {
      start += 1;
    }

    if (start >= question.answerPoints.length) {
      return question.answerPoints;
    }

    return question.answerPoints.skip(start);
  }

  static String _expandCheckpoint(String checkpoint) {
    return checkpoint.trim();
  }
}
