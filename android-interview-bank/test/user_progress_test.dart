import 'package:android_interview_bank/models/question.dart';
import 'package:android_interview_bank/models/user_progress.dart';
import 'package:android_interview_bank/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('serializes user progress with favorites and review status', () {
    const progress = UserProgress(
      questionStates: {
        'handler-loop': QuestionProgress(
          isFavorite: true,
          status: ReviewStatus.nextReview,
        ),
      },
    );

    final restored = UserProgress.fromJson(progress.toJson());

    expect(restored.stateFor('handler-loop').isFavorite, isTrue);
    expect(restored.stateFor('handler-loop').status, ReviewStatus.nextReview);
  });

  test('updates favorite and status immutably', () {
    final progress = const UserProgress()
        .setFavorite('java-hashmap', true)
        .setStatus('java-hashmap', ReviewStatus.mastered);

    expect(progress.stateFor('java-hashmap').isFavorite, isTrue);
    expect(progress.stateFor('java-hashmap').status, ReviewStatus.mastered);
  });

  test('persists progress and theme style', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController();

    await controller.load();
    await controller.setThemeStyle(AppThemeStyle.dark);
    await controller.toggleFavorite('handler-loop');
    await controller.setReviewStatus('handler-loop', ReviewStatus.nextReview);

    final restored = AppController();
    await restored.load();

    expect(restored.themeStyle, AppThemeStyle.dark);
    expect(restored.progress.stateFor('handler-loop').isFavorite, isTrue);
    expect(
      restored.progress.stateFor('handler-loop').status,
      ReviewStatus.nextReview,
    );
  });
}
