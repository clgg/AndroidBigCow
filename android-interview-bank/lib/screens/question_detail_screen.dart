import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/question.dart';
import '../screens/ai_explainer_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../utils/standard_answer_builder.dart';
import '../widgets/question_card.dart';
import '../widgets/standard_answer_view.dart';

class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({
    super.key,
    required this.question,
    required this.controller,
  });

  final InterviewQuestion question;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.progress.stateFor(question.id);
        final status = state.status ?? question.seedStatus;
        final palette = context.palette;

        return Scaffold(
          backgroundColor: palette.background,
          appBar: AppBar(
            backgroundColor: palette.background,
            elevation: 0,
            title: Text(question.module),
            actions: [
              IconButton(
                tooltip: state.isFavorite ? '取消收藏' : '收藏',
                onPressed: () => controller.toggleFavorite(question.id),
                icon: Icon(state.isFavorite ? Icons.star : Icons.star_border),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Text(
                question.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              QuestionTagRow(status: status, tags: question.tags),
              const SizedBox(height: 16),
              _Section(title: '考察点', items: question.checkpoints),
              _StandardAnswerCard(question: question),
              _Section(title: '答案要点', items: question.answerPoints),
              _FollowUpSection(question: question),
              _Section(title: '常见误区', items: question.mistakes),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) =>
                          AiExplainerScreen(question: question),
                    ),
                  );
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('用 AI 继续讲解'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: palette.success,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.mastered,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Pass，之后不再刷到'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.nextReview,
                ),
                icon: const Icon(Icons.schedule),
                label: const Text('保留，稍后复习'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => controller.setReviewStatus(
                  question.id,
                  ReviewStatus.notMastered,
                ),
                child: const Text('标记为未掌握'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StandardAnswerCard extends StatefulWidget {
  const _StandardAnswerCard({required this.question});

  final InterviewQuestion question;

  @override
  State<_StandardAnswerCard> createState() => _StandardAnswerCardState();
}

class _StandardAnswerCardState extends State<_StandardAnswerCard> {
  AudioPlayer? _player;
  bool _isPreparing = false;

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.question.standardAnswerAudioUrl;
    if (url == null || url.isEmpty || _isPreparing) {
      return;
    }

    var player = _player;
    if (player == null) {
      setState(() => _isPreparing = true);
      try {
        player = AudioPlayer();
        await player.setUrl(url);
        _player = player;
      } catch (_) {
        await player?.dispose();
        _player = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('音频加载失败')),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() => _isPreparing = false);
        }
      }
    }

    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final answer = StandardAnswerBuilder.resolve(widget.question);
    final audioUrl = widget.question.standardAnswerAudioUrl;
    final hasAudio = audioUrl != null && audioUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '标准答案',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (hasAudio)
                  StreamBuilder<PlayerState>(
                    stream: _player?.playerStateStream,
                    builder: (context, snapshot) {
                      final playerState = snapshot.data;
                      final isPlaying = playerState?.playing == true;
                      final isLoading = _isPreparing ||
                          playerState?.processingState ==
                              ProcessingState.loading ||
                          playerState?.processingState ==
                              ProcessingState.buffering;
                      return IconButton.filledTonal(
                        tooltip: isPlaying ? '暂停标准答案音频' : '播放标准答案音频',
                        onPressed: isLoading ? null : _toggleAudio,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                isPlaying
                                    ? Icons.pause
                                    : Icons.volume_up_outlined,
                              ),
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            StandardAnswerView(text: answer),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: context.palette.accent)),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FollowUpSection extends StatelessWidget {
  const _FollowUpSection({required this.question});

  final InterviewQuestion question;

  @override
  Widget build(BuildContext context) {
    if (question.followUps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('深挖追问', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            for (final item in question.followUps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '• ',
                        style: TextStyle(color: context.palette.accent),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(item),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: '用 AI 搜索追问',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => AiExplainerScreen(
                              question: question,
                              prompt: item,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 18),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
