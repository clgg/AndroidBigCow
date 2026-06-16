import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/backend_client.dart';
import 'data/question_repository.dart';
import 'models/tech_stack.dart';
import 'screens/tech_stack_selection_screen.dart';
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
      final backendClient = BackendClient();
      final repository = await QuestionRepository.loadFromSources(
        backendClient: null,
      );
      final controller = AppController(backendClient: backendClient);
      await controller.load();
      return _Bootstrap(
        repository: repository,
        controller: controller,
        backendClient: backendClient,
        categories: TechStackCatalog.categories,
      );
    }();

    return bootstrapFuture;
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
              title: '技术面试题库',
              theme: AppTheme.data(bootstrap.controller.themeStyle),
              home: AnnotatedRegion<SystemUiOverlayStyle>(
                value: overlayStyle,
                child: bootstrap.controller.selectedTechStack == null
                    ? TechStackSelectionScreen(
                        controller: bootstrap.controller,
                        categories: bootstrap.categories,
                      )
                    : AppShell(
                        repository: bootstrap.repository,
                        controller: bootstrap.controller,
                        backendClient: bootstrap.backendClient,
                        categories: bootstrap.categories,
                        selectedTechStack:
                            bootstrap.controller.selectedTechStack!,
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
  const _Bootstrap({
    required this.repository,
    required this.controller,
    required this.backendClient,
    required this.categories,
  });

  final QuestionRepository repository;
  final AppController controller;
  final BackendClient backendClient;
  final List<TechCategory> categories;
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}
