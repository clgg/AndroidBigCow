import 'package:flutter/material.dart';

import '../models/tech_stack.dart';
import '../screens/tech_stack_selection_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.categories,
  });

  final AppController controller;
  final List<TechCategory> categories;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        Text('我的', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('切换技术栈、视觉风格和本地复习进度。',
            style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 16),
        AppCard(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: palette.accentMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.layers_outlined, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前技术栈',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      controller.selectedTechStack == null
                          ? '未选择'
                          : TechStackCatalog.labelFor(
                              controller.selectedTechStack!,
                              categories,
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => TechStackSelectionScreen(
                        controller: controller,
                        categories: categories,
                        showBackButton: true,
                      ),
                    ),
                  );
                },
                child: const Text('切换'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('风格', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final style in AppThemeStyle.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => controller.setThemeStyle(style),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.themeStyle == style
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: controller.themeStyle == style
                                ? palette.accent
                                : palette.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(style.label),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
          onPressed: () => _confirmReset(context),
          icon: const Icon(Icons.refresh),
          label: const Text('重置本地进度'),
        ),
      ],
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置进度'),
        content: const Text('收藏和复习状态会清空，题库内容不会删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.resetProgress();
    }
  }
}
