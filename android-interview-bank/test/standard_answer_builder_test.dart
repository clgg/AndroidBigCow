import 'package:android_interview_bank/models/question.dart';
import 'package:android_interview_bank/utils/standard_answer_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds learning-oriented standard answer sections', () {
    const question = InterviewQuestion(
      id: 'java-hashmap',
      module: 'Java',
      title: 'HashMap 的底层结构是什么？为什么线程不安全？',
      tags: ['高频'],
      seedStatus: ReviewStatus.notMastered,
      checkpoints: ['数组、链表、红黑树结构。'],
      answerPoints: [
        'HashMap 底层是数组加链表，JDK 8 后链表过长会转为红黑树。',
        '线程不安全的核心原因是内部结构修改没有同步保护。',
      ],
      followUps: ['为什么容量通常是 2 的幂？'],
      mistakes: ['只说 HashMap 会死循环，不区分 JDK 版本。'],
    );

    final answer = StandardAnswerBuilder.build(question);
    final sections = StandardAnswerBuilder.parse(answer);

    expect(sections.map((section) => section.title), [
      '一句话回答',
      '详细讲解',
      '需要掌握的知识点',
      '学习时别踩这些坑',
    ]);
    expect(answer, contains('HashMap 底层是数组加链表'));
    expect(answer, contains('只说 HashMap 会死循环'));
  });

  test('prefers custom standardAnswer when present', () {
    const question = InterviewQuestion(
      id: 'custom',
      module: 'Java',
      title: '示例题',
      tags: ['基础'],
      seedStatus: ReviewStatus.notMastered,
      checkpoints: [],
      answerPoints: ['默认答案'],
      followUps: [],
      mistakes: [],
      standardAnswer: '【一句话回答】\n自定义标准答案',
    );

    expect(StandardAnswerBuilder.resolve(question), contains('自定义标准答案'));
  });
}
