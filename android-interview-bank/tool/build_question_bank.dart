import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  final sourceFiles =
      root
          .listSync()
          .whereType<File>()
          .where((file) => RegExp(r'^\d{2}-.+\.md$').hasMatch(_name(file)))
          .where((file) {
            final name = _name(file);
            return !name.startsWith('00-') && !name.startsWith('01-');
          })
          .toList()
        ..sort((a, b) => _name(a).compareTo(_name(b)));

  final questions = <Map<String, Object?>>[];
  for (final file in sourceFiles) {
    questions.addAll(_parseFile(file));
  }

  final asset = File('assets/question_bank.json');
  asset.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  asset.writeAsStringSync('${encoder.convert(questions)}\n');
  stdout.writeln('Generated ${questions.length} questions.');
}

List<Map<String, Object?>> _parseFile(File file) {
  final lines = file.readAsLinesSync();
  final module = _moduleName(file, lines);
  final blocks = <List<String>>[];
  List<String>? current;

  for (final line in lines) {
    if (line.startsWith('## Q:')) {
      if (current != null) {
        blocks.add(current);
      }
      current = [line];
    } else if (current != null) {
      current.add(line);
    }
  }
  if (current != null) {
    blocks.add(current);
  }

  return [
    for (var i = 0; i < blocks.length; i++)
      _parseBlock(
        id: '${_slug(module)}-${i + 1}',
        module: module,
        lines: blocks[i],
      ),
  ];
}

Map<String, Object?> _parseBlock({
  required String id,
  required String module,
  required List<String> lines,
}) {
  final title = lines.first.replaceFirst('## Q:', '').trim();
  final tagsLine = lines.firstWhere(
    (line) => line.startsWith('标签：'),
    orElse: () => '标签：基础',
  );
  final statusLine = lines.firstWhere(
    (line) => line.startsWith('复习状态：'),
    orElse: () => '复习状态：未掌握',
  );

  return {
    'id': id,
    'module': module,
    'title': title,
    'tags': tagsLine
        .replaceFirst('标签：', '')
        .split('/')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList(),
    'reviewStatus': statusLine.replaceFirst('复习状态：', '').trim(),
    'checkpoints': _section(lines, '考察点：'),
    'answerPoints': _section(lines, '答案要点：'),
    'followUps': _section(lines, '深挖追问：'),
    'mistakes': _section(lines, '常见误区：'),
    if (_section(lines, '标准答案：').isNotEmpty)
      'standardAnswer': _section(lines, '标准答案：').join('\n\n'),
  };
}

List<String> _section(List<String> lines, String title) {
  final start = lines.indexWhere((line) => line.trim() == title);
  if (start == -1) {
    return const [];
  }

  final items = <String>[];
  for (final line in lines.skip(start + 1)) {
    if (_isSectionTitle(line)) {
      break;
    }
    final trimmed = line.trim();
    if (trimmed.startsWith('- ')) {
      items.add(trimmed.substring(2).trim());
    }
  }
  return items;
}

bool _isSectionTitle(String line) {
  return line.endsWith('：') && !line.trim().startsWith('- ');
}

String _moduleName(File file, List<String> lines) {
  final heading = lines.firstWhere(
    (line) => line.startsWith('# '),
    orElse: () => _name(
      file,
    ).replaceFirst(RegExp(r'^\d{2}-'), '').replaceFirst('.md', ''),
  );
  return heading.replaceFirst('# ', '').trim();
}

String _slug(String value) {
  final ascii = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return ascii.isEmpty ? value.hashCode.abs().toString() : ascii;
}

String _name(File file) {
  return file.uri.pathSegments.last;
}
