import 'package:flutter/material.dart';

import '../data/backend_client.dart';
import '../data/question_repository.dart';
import '../models/question.dart';
import '../models/tech_stack.dart';
import '../screens/bank_screen.dart';
import '../screens/home_screen.dart';
import '../screens/module_questions_screen.dart';
import '../screens/question_detail_screen.dart';
import '../screens/review_screen.dart';
import '../screens/settings_screen.dart';
import '../state/app_controller.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.repository,
    required this.controller,
    required this.backendClient,
    required this.categories,
    required this.selectedTechStack,
  });

  final QuestionRepository repository;
  final AppController controller;
  final BackendClient? backendClient;
  final List<TechCategory> categories;
  final SelectedTechStack selectedTechStack;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  late QuestionRepository _repository = widget.repository;
  bool _isRefreshing = false;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _repository = widget.repository;
    }
  }

  Future<void> _refreshQuestions() async {
    final backendClient = widget.backendClient;
    if (backendClient == null || _isRefreshing) {
      return;
    }

    setState(() => _isRefreshing = true);
    try {
      final repository = await QuestionRepository.pullLatestAndCache(
        backendClient: backendClient,
        selectedTechStack: widget.selectedTechStack,
      );
      if (!mounted) {
        return;
      }
      setState(() => _repository = repository);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已拉取服务端最新题目')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('拉取失败，请检查服务端是否可访问')),
      );
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _openQuestion(InterviewQuestion question) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => QuestionDetailScreen(
          question: question,
          controller: widget.controller,
        ),
      ),
    );
  }

  void _openModule(String module) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ModuleQuestionsScreen(
          module: module,
          repository: _repository.forTechStack(widget.selectedTechStack),
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        repository: _repository.forTechStack(widget.selectedTechStack),
        controller: widget.controller,
        categories: widget.categories,
        selectedTechStack: widget.selectedTechStack,
        onRefresh: _refreshQuestions,
        onOpenQuestion: _openQuestion,
        onOpenModule: _openModule,
      ),
      BankScreen(
        repository: _repository.forTechStack(widget.selectedTechStack),
        controller: widget.controller,
        isRefreshing: _isRefreshing,
        onRefresh: _refreshQuestions,
        onOpenQuestion: _openQuestion,
      ),
      ReviewScreen(
        repository: _repository.forTechStack(widget.selectedTechStack),
        controller: widget.controller,
        onRefresh: _refreshQuestions,
        onOpenQuestion: _openQuestion,
      ),
      SettingsScreen(
        controller: widget.controller,
        categories: widget.categories,
      ),
    ];
    final palette = context.palette;

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: palette.surface,
          border: Border(top: BorderSide(color: palette.border)),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          backgroundColor: Colors.transparent,
          indicatorColor: palette.accentMuted,
          elevation: 0,
          onDestinationSelected: (value) {
            FocusManager.instance.primaryFocus?.unfocus();
            setState(() => _index = value);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: '题库',
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.manage_search),
              label: '刷题',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: '复习',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune),
              selectedIcon: Icon(Icons.tune),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}
