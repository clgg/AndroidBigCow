import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final bootstrapFuture = () async {
      final repository = await QuestionRepository.loadFromAssets();
      final controller = AppController();
      await controller.load();
      return _Bootstrap(repository: repository, controller: controller);
    }();

    final results = await Future.wait([
      bootstrapFuture,
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    return results.first as _Bootstrap;
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
            home: const AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
                systemNavigationBarColor: Colors.white,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
              child: _LoadingScreen(),
            ),
          );
        }

        final bootstrap = snapshot.data!;
        return AnimatedBuilder(
          animation: bootstrap.controller,
          builder: (context, _) {
            final overlayStyle = _systemUiOverlayStyle(
              bootstrap.controller.themeStyle,
            );

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Android 面试题库',
              theme: AppTheme.data(bootstrap.controller.themeStyle),
              home: AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle,
                child: AppShell(
                  repository: bootstrap.repository,
                  controller: bootstrap.controller,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

SystemUiOverlayStyle _systemUiOverlayStyle(AppThemeStyle style) {
  final isDark = style == AppThemeStyle.dark;

  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemNavigationBarColor:
        isDark ? const Color(0xFF0D1420) : const Color(0xFFF6F8FC),
    systemNavigationBarIconBrightness:
        isDark ? Brightness.light : Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          child: Image(
            image: AssetImage('assets/branding/app_icon_master.png'),
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
