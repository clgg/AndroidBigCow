import 'package:flutter/material.dart';

import '../models/tech_stack.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

class TechStackSelectionScreen extends StatefulWidget {
  const TechStackSelectionScreen({
    super.key,
    required this.controller,
    required this.categories,
    this.showBackButton = false,
  });

  final AppController controller;
  final List<TechCategory> categories;
  final bool showBackButton;

  @override
  State<TechStackSelectionScreen> createState() =>
      _TechStackSelectionScreenState();
}

class _TechStackSelectionScreenState extends State<TechStackSelectionScreen> {
  late String _categoryId = widget.controller.selectedTechStack?.categoryId ??
      widget.categories.first.id;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final selectedCategory =
        _categoryById(_categoryId) ?? widget.categories.first;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(widget.showBackButton ? '切换技术栈' : '选择技术栈'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            widget.showBackButton ? '选择新的题库方向' : '你想先刷哪类技术？',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '选择一次后会进入对应题库，也可以在“我的”页面随时切换。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 18),
          Text('技术类别', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in widget.categories)
                ChoiceChip(
                  label: Text(category.label),
                  selected: category.id == _categoryId,
                  onSelected: (_) => setState(() => _categoryId = category.id),
                ),
            ],
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCategory.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  selectedCategory.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('开发语言 / 方向', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          for (final language in selectedCategory.languages)
            _LanguageTile(
              category: selectedCategory,
              language: language,
              isSelected: widget.controller.selectedTechStack?.categoryId ==
                      selectedCategory.id &&
                  widget.controller.selectedTechStack?.languageId ==
                      language.id,
              onTap: () => _select(selectedCategory, language),
            ),
        ],
      ),
    );
  }

  Future<void> _select(TechCategory category, TechLanguage language) async {
    await widget.controller.setSelectedTechStack(
      SelectedTechStack(categoryId: category.id, languageId: language.id),
    );
    if (mounted && widget.showBackButton) {
      Navigator.of(context).pop();
    }
  }

  TechCategory? _categoryById(String id) {
    for (final category in widget.categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.category,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final TechCategory category;
  final TechLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? palette.accent : palette.accentMuted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  language.label.characters.first,
                  style: TextStyle(
                    color: isSelected ? palette.onAccent : palette.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      language.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle : Icons.chevron_right,
                color: isSelected ? palette.success : palette.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
