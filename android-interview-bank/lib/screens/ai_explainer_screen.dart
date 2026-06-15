import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/question_card.dart';

enum AiTool {
  qianwen('千问', 'https://www.qianwen.com/'),
  qwen('Qwen Chat', 'https://chat.qwen.ai/'),
  kimi('Kimi', 'https://kimi.moonshot.cn/'),
  yuanbao('元宝', 'https://yuanbao.tencent.com/');

  const AiTool(this.label, this.url);

  final String label;
  final String url;
}

class AiExplainerScreen extends StatefulWidget {
  const AiExplainerScreen({super.key, required this.question});

  final InterviewQuestion question;

  @override
  State<AiExplainerScreen> createState() => _AiExplainerScreenState();
}

class _AiExplainerScreenState extends State<AiExplainerScreen> {
  late final WebViewController _webViewController;
  late final String _prompt = _buildPrompt(widget.question);

  AiTool _selectedTool = AiTool.qianwen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _copyPrompt(showMessage: false);
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(_selectedTool.url));
  }

  Future<void> _copyPrompt({bool showMessage = true}) async {
    await Clipboard.setData(ClipboardData(text: _prompt));
    if (!mounted || !showMessage) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制题目讲解 Prompt，可粘贴到 AI 对话框')),
    );
  }

  void _switchTool(AiTool tool) {
    setState(() {
      _selectedTool = tool;
      _isLoading = true;
    });
    _webViewController.loadRequest(Uri.parse(tool.url));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        elevation: 0,
        title: const Text('AI 讲解'),
        actions: [
          IconButton(
            tooltip: '复制 Prompt',
            onPressed: _copyPrompt,
            icon: const Icon(Icons.copy_all_outlined),
          ),
          PopupMenuButton<AiTool>(
            tooltip: '切换 AI 工具',
            initialValue: _selectedTool,
            onSelected: _switchTool,
            itemBuilder: (context) => [
              for (final tool in AiTool.values)
                PopupMenuItem(value: tool, child: Text(tool.label)),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _PromptPanel(prompt: _prompt, selectedTool: _selectedTool),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController),
                if (_isLoading)
                  const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptPanel extends StatelessWidget {
  const _PromptPanel({required this.prompt, required this.selectedTool});

  final String prompt;
  final AiTool selectedTool;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 18, color: palette.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '已复制到剪贴板，登录 ${selectedTool.label} 后粘贴发送',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppCard(
            padding: const EdgeInsets.all(10),
            child: Text(
              prompt,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

String _buildPrompt(InterviewQuestion question) {
  return '''
我正在准备 Android 面试，请你用清晰、系统、适合面试表达的方式讲解下面这道题。

题目：${question.title}
模块：${question.module}
标签：${question.tags.join('、')}

请按以下结构回答：
1. 先用 3-5 句话解释核心结论。
2. 再分层讲清楚原理、流程、边界条件和项目实践。
3. 补充一个实际项目中的例子。
4. 列出面试时容易答错的点。
5. 最后给我一版 1 分钟口述答案。

我当前题库里的参考要点：
考察点：
${question.checkpoints.map((item) => '- $item').join('\n')}

答案要点：
${question.answerPoints.map((item) => '- $item').join('\n')}

常见误区：
${question.mistakes.map((item) => '- $item').join('\n')}
''';
}
