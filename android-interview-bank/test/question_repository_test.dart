import 'package:android_interview_bank/data/question_repository.dart';
import 'package:android_interview_bank/models/question.dart';
import 'package:android_interview_bank/models/tech_stack.dart';
import 'package:android_interview_bank/models/user_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final questions = <InterviewQuestion>[
    const InterviewQuestion(
      id: 'java-hashmap',
      module: 'Java',
      title: 'HashMap 的底层结构是什么？为什么线程不安全？',
      tags: ['高频', '基础', '易混'],
      seedStatus: ReviewStatus.notMastered,
      checkpoints: ['数组、链表、红黑树结构。'],
      answerPoints: ['HashMap 底层是数组加链表。'],
      followUps: ['为什么容量通常是 2 的幂？'],
      mistakes: ['只说 HashMap 会死循环，不区分 JDK 版本。'],
    ),
    const InterviewQuestion(
      id: 'android-activity',
      module: 'Android 基础',
      title: 'Activity 生命周期有哪些关键回调？',
      tags: ['高频', '基础'],
      seedStatus: ReviewStatus.notMastered,
      checkpoints: ['生命周期回调顺序。'],
      answerPoints: ['常见回调包括 onCreate、onStart、onResume。'],
      followUps: ['onSaveInstanceState 一定会调用吗？'],
      mistakes: ['把 onDestroy 当成必定调用的清理点。'],
    ),
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
  ];

  test('groups questions by module in source order', () {
    final repository = QuestionRepository(questions);

    expect(repository.modules, ['Java', 'Android 基础', 'Handler / 线程 / 协程']);
  });

  test('searches title, module, tags, and answer text', () {
    final repository = QuestionRepository(questions);

    expect(repository.search('线程').map((question) => question.id), [
      'java-hashmap',
      'handler-loop',
    ]);
  });

  test('filters by module and tags together', () {
    final repository = QuestionRepository(questions);

    final result = repository.filter(module: 'Android 基础', tags: {'基础'});

    expect(result.map((question) => question.id), ['android-activity']);
  });

  test('overlays favorite and review status from user progress', () {
    final repository = QuestionRepository(questions);
    const progress = UserProgress(
      questionStates: {
        'handler-loop': QuestionProgress(
          isFavorite: true,
          status: ReviewStatus.nextReview,
        ),
      },
    );

    final decorated = repository.withProgress(progress);
    final handler = decorated.singleWhere(
      (item) => item.question.id == 'handler-loop',
    );

    expect(handler.isFavorite, isTrue);
    expect(handler.status, ReviewStatus.nextReview);
  });

  test('filters questions by selected tech stack', () {
    final repository = QuestionRepository([
      ...questions,
      const InterviewQuestion(
        id: 'ios-arc',
        module: 'Swift',
        title: 'ARC 的基本原理是什么？',
        tags: ['iOS'],
        seedStatus: ReviewStatus.notMastered,
        checkpoints: ['引用计数。'],
        answerPoints: ['ARC 通过编译器插入 retain/release 管理对象生命周期。'],
        followUps: ['循环引用如何处理？'],
        mistakes: ['以为 ARC 等于 GC。'],
        techCategory: 'client',
        techLanguage: 'ios',
      ),
    ]);

    final android = repository.forTechStack(
      const SelectedTechStack(categoryId: 'client', languageId: 'android'),
    );
    final ios = repository.forTechStack(
      const SelectedTechStack(categoryId: 'client', languageId: 'ios'),
    );

    expect(android.all.map((question) => question.id), [
      'java-hashmap',
      'android-activity',
      'handler-loop',
    ]);
    expect(ios.all.map((question) => question.id), ['ios-arc']);
  });

  test('loads bundled base and extension assets together', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final repository = await QuestionRepository.loadFromAssets();
    final uniqueIds = repository.all.map((question) => question.id).toSet();

    expect(repository.all.length, 322);
    expect(uniqueIds.length, repository.all.length);
    expect(repository.modules.length, 12);
    expect(repository.filter(module: 'Java').length, greaterThanOrEqualTo(27));
  });
}
