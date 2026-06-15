import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';

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
  late final String _prompt = widget.question.title;

  AiTool _selectedTool = AiTool.qianwen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _copyPrompt(showMessage: true);
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
      const SnackBar(content: Text('已复制题目，可粘贴到 AI 对话框')),
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
            tooltip: '复制题目',
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
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Align(
              alignment: Alignment.topCenter,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
