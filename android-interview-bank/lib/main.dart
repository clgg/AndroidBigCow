import 'package:flutter/material.dart';

import 'data/question_repository.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InterviewBankApp());
}

class InterviewBankApp extends StatefulWidget {
  const InterviewBankApp({super.key});

  @override
  State<InterviewBankApp> createState() => _InterviewBankAppState();
}

class _InterviewBankAppState extends State<InterviewBankApp> {
  late final Future<_Bootstrap> _bootstrap = _load();

  Future<_Bootstrap> _load() async {
    final repository = await QuestionRepository.loadFromAsset();
    final controller = AppController();
    await controller.load();
    return _Bootstrap(repository: repository, controller: controller);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Bootstrap>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.data(AppThemeStyle.blue),
            home: const _LoadingScreen(),
          );
        }

        final bootstrap = snapshot.data!;
        return AnimatedBuilder(
          animation: bootstrap.controller,
          builder: (context, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Android 面试题库',
              theme: AppTheme.data(bootstrap.controller.themeStyle),
              home: AppShell(
                repository: bootstrap.repository,
                controller: bootstrap.controller,
              ),
            );
          },
        );
      },
    );
  }
}

class _Bootstrap {
  const _Bootstrap({required this.repository, required this.controller});

  final QuestionRepository repository;
  final AppController controller;
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
