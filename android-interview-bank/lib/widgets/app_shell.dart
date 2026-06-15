import 'package:flutter/material.dart';

import '../data/question_repository.dart';
import '../models/question.dart';
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
  });

  final QuestionRepository repository;
  final AppController controller;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

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
          repository: widget.repository,
          controller: widget.controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        repository: widget.repository,
        controller: widget.controller,
        onOpenQuestion: _openQuestion,
        onOpenModule: _openModule,
      ),
      BankScreen(
        repository: widget.repository,
        controller: widget.controller,
        onOpenQuestion: _openQuestion,
      ),
      ReviewScreen(
        repository: widget.repository,
        controller: widget.controller,
        onOpenQuestion: _openQuestion,
      ),
      SettingsScreen(controller: widget.controller),
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
          onDestinationSelected: (value) => setState(() => _index = value),
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
