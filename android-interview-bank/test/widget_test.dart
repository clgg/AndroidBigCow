import 'package:android_interview_bank/data/question_repository.dart';
import 'package:android_interview_bank/models/question.dart';
import 'package:android_interview_bank/state/app_controller.dart';
import 'package:android_interview_bank/theme/app_theme.dart';
import 'package:android_interview_bank/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('loads app shell with main tabs', (tester) async {
    final fixture = await _pumpAppShell(tester);

    expect(fixture.repository.all, hasLength(1));
    expect(find.text('Android 面试题库'), findsOneWidget);
    expect(find.text('题库'), findsWidgets);
    expect(find.text('刷题'), findsOneWidget);
    expect(find.text('复习'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });

  testWidgets('opens module list and question detail from home',
      (tester) async {
    await _pumpAppShell(tester);

    await tester.tap(find.text('Handler / 线程 / 协程').first);
    await tester.pumpAndSettle();

    expect(find.text('1 道题，点击题卡查看标准答案和追问。'), findsOneWidget);

    await tester.tap(find.text('Handler、Looper、MessageQueue 之间是什么关系？'));
    await tester.pumpAndSettle();

    expect(find.text('标准答案'), findsOneWidget);
    expect(find.text('一句话回答'), findsOneWidget);
    expect(find.textContaining('作答时先给出核心结论'), findsNothing);
  });
}

Future<_ShellFixture> _pumpAppShell(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final controller = AppController();
  await controller.load();
  final repository = QuestionRepository([
    const InterviewQuestion(
      id: 'handler-loop',
      module: 'Handler / 线程 / 协程',
      title: 'Handler、Looper、MessageQueue 之间是什么关系？',
      tags: ['高频', '基础', '易混'],
      seedStatus: ReviewStatus.notMastered,
      checkpoints: ['消息循环。'],
      answerPoints: ['Looper 负责在线程中开启消息循环。'],
      followUps: ['Looper.loop 为什么不会让主线程退出？'],
      mistakes: ['以为 Handler 自己创建线程。'],
    ),
  ]);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.data(AppThemeStyle.blue),
      home: AppShell(repository: repository, controller: controller),
    ),
  );

  return _ShellFixture(repository: repository);
}

class _ShellFixture {
  const _ShellFixture({required this.repository});

  final QuestionRepository repository;
}
