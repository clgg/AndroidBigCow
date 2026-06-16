#!/usr/bin/env python3
"""Generate 300 Flutter interview questions for flutter-question-import.json."""

import json
import re
from pathlib import Path

OUTPUT = Path("/Users/melon/Downloads/flutter-question-import.json")


def slug(text: str) -> str:
    text = re.sub(r"[^\w\s-]", "", text.lower(), flags=re.UNICODE)
    text = re.sub(r"[\s_]+", "-", text.strip())
    return re.sub(r"-+", "-", text)[:60].strip("-") or "question"


def build_standard_answer(checkpoints, answer_points, mistakes):
    parts = ["【一句话回答】", answer_points[0], "", "【详细讲解】"]
    for point in answer_points[1:]:
        parts.extend([point, ""])
    if checkpoints:
        parts.append("【需要掌握的知识点】")
        for cp in checkpoints:
            parts.append(f"• {cp}")
        parts.append("")
    if mistakes:
        parts.append("【学习时别踩这些坑】")
        for m in mistakes:
            parts.append(f"• {m}")
    return "\n".join(parts).strip()


def make_question(title, module, tags, checkpoints, answer_points, follow_ups, mistakes, qid=None):
    qid = qid or f"client-flutter-{slug(title)}"
    return {
        "id": qid,
        "module": module,
        "title": title,
        "tags": ["Flutter", *tags],
        "reviewStatus": "notMastered",
        "checkpoints": checkpoints,
        "answerPoints": answer_points,
        "followUps": follow_ups,
        "mistakes": mistakes,
        "techCategory": "client",
        "techLanguage": "flutter",
        "standardAnswer": build_standard_answer(checkpoints, answer_points, mistakes),
    }


SEED_QUESTIONS = [
    make_question(
        "Widget、Element、RenderObject 三者分别负责什么？",
        "Flutter 基础",
        ["高频", "基础"],
        ["Widget 是不可变配置", "Element 维护树结构和生命周期", "RenderObject 负责布局、绘制和命中测试"],
        [
            "Widget 描述 UI 配置，本身不可变，重建成本较低。",
            "Element 是 Widget 在树中的实例，负责挂载、更新、卸载和持有 State。",
            "RenderObject 处理 layout、paint、hitTest，是渲染流水线核心。",
        ],
        ["为什么 Flutter 可以频繁 rebuild？", "StatelessWidget 和 StatefulWidget 的 Element 差异？"],
        ["把 Widget 当成最终渲染对象。", "只说三棵树名字，不说明职责边界。"],
        "client-flutter-widget-element-renderobject",
    ),
    make_question(
        "StatefulWidget 的生命周期有哪些关键阶段？",
        "Flutter 基础",
        ["基础", "生命周期"],
        ["createState、initState、didChangeDependencies、build", "didUpdateWidget、deactivate、dispose", "初始化与释放时机"],
        [
            "createState 创建 State，initState 只执行一次，适合初始化控制器和订阅。",
            "didChangeDependencies 在 InheritedWidget 依赖变化时触发。",
            "didUpdateWidget 在父组件配置变化时调用。",
            "dispose 必须释放 Controller、Subscription、AnimationController。",
        ],
        ["为什么 initState 里不能直接用 context.watch？", "deactivate 和 dispose 的区别？"],
        ["把 initState 当成可读取所有 inherited 依赖的地方。", "忘记 dispose 导致泄漏。"],
        "client-flutter-stateful-lifecycle",
    ),
    make_question(
        "BuildContext 的本质是什么？使用时有哪些注意点？",
        "Flutter 基础",
        ["基础", "易混"],
        ["BuildContext 由 Element 实现", "context 决定祖先查找范围", "异步后需判断 mounted"],
        [
            "BuildContext 表示 Widget 在 Element 树中的位置。",
            "查找 Theme、Navigator、Provider 只能向上查找。",
            "异步返回后组件可能已卸载，使用 context 前需判断 mounted。",
        ],
        ["showDialog 后 Navigator.pop 为何可能报错？", "Builder 如何解决 context 作用域问题？"],
        ["把 context 当全局对象保存。", "忽略 context 位置找不到 Scaffold。"],
        "client-flutter-buildcontext",
    ),
    make_question(
        "Flutter 的布局约束模型是什么？为什么会出现 RenderFlex overflow？",
        "布局与渲染",
        ["布局", "高频"],
        ["Constraints go down, sizes go up", "父传约束子定尺寸", "Row/Column overflow"],
        [
            "父节点传约束，子节点在约束内定尺寸，父节点再定位置。",
            "Row/Column 主轴不足且未用 Expanded/Flexible 会 overflow。",
            "可用 Expanded、Flexible、SingleChildScrollView、ListView 解决。",
        ],
        ["Expanded 和 Flexible 区别？", "Column 里 ListView 为何常要 Expanded？"],
        ["只用固定高度硬压。", "把 overflow 当渲染 bug。"],
        "client-flutter-layout-constraints",
    ),
    make_question(
        "Flutter 中 Key 的作用是什么？LocalKey 和 GlobalKey 有什么区别？",
        "Flutter 基础",
        ["基础", "易混"],
        ["Key 影响 Element 复用", "LocalKey 同级比较", "GlobalKey 成本更高"],
        [
            "Key 帮助同级 Widget 更新时识别对应 Element。",
            "ValueKey、ObjectKey、UniqueKey 是 LocalKey。",
            "GlobalKey 可跨位置保留 State，但成本更高。",
        ],
        ["列表重排为何用 ValueKey？", "GlobalKey 滥用问题？"],
        ["以为所有组件都要 Key。", "列表用 UniqueKey 导致无法复用。"],
        "client-flutter-key-usage",
    ),
    make_question(
        "InheritedWidget 的工作机制是什么？Provider 为什么基于它实现？",
        "状态管理",
        ["状态管理", "高频"],
        ["向下传递依赖", "依赖注册与通知", "Provider 封装"],
        [
            "InheritedWidget 把数据放树上层，下层 context 读取。",
            "dependOnInheritedWidgetOfExactType 建立依赖并触发重建。",
            "Provider 封装 read/watch/select 和资源释放。",
        ],
        ["context.read 和 context.watch 区别？", "Selector 如何减少 rebuild？"],
        ["把 Provider 当全局变量。", "不需要监听时用 watch。"],
        "client-flutter-inheritedwidget-provider",
    ),
    make_question(
        "setState 做了什么？如何减少不必要的 rebuild？",
        "状态管理",
        ["状态管理", "性能"],
        ["markNeedsBuild", "下一帧 build", "缩小重建范围"],
        [
            "setState 执行回调并 markNeedsBuild。",
            "下一帧重建当前 State 子树，不等于整屏立即重绘。",
            "拆组件、const、Selector、RepaintBoundary 可缩小范围。",
        ],
        ["setState 后一定 paint 吗？", "build 频繁一定慢吗？"],
        ["以为 setState 立即刷新。", "所有状态放页面根节点。"],
        "client-flutter-setstate-rebuild",
    ),
    make_question(
        "Future、Stream 和 Isolate 分别适合什么场景？",
        "异步与 Dart",
        ["Dart", "异步"],
        ["Future 一次结果", "Stream 事件流", "Isolate CPU 密集"],
        [
            "Future 适合 HTTP、文件等一次性异步。",
            "Stream 适合 WebSocket、持续事件。",
            "Isolate 独立内存，适合大 JSON 解析、图像处理。",
        ],
        ["async/await 与事件循环？", "Future 为何不能解决主线程 CPU 阻塞？"],
        ["把 Future 当新线程。", "主 Isolate 做大量同步计算。"],
        "client-flutter-future-stream",
    ),
    make_question(
        "Flutter Platform Channel 的调用流程是什么？",
        "平台通道",
        ["平台通道", "原生交互"],
        ["Channel 类型", "二进制消息", "异步返回"],
        [
            "MethodChannel 一次调用，EventChannel 持续事件。",
            "Dart 经 Engine 编解码转发到原生 handler。",
            "原生返回结果或错误，Dart 通过 Future 接收。",
        ],
        ["频繁 Channel 调用的性能风险？", "插件如何处理平台差异？"],
        ["以为 Channel 同步。", "忽略 channel name 冲突。"],
        "client-flutter-platform-channel",
    ),
    make_question(
        "Flutter 页面卡顿通常怎么排查和优化？",
        "性能优化",
        ["性能", "高频"],
        ["Timeline 分析", "UI/Raster 线程", "优化手段"],
        [
            "DevTools Timeline 定位 UI 还是 Raster 瓶颈。",
            "UI 慢常因 build 重、同步计算、列表未懒加载。",
            "Raster 慢常因过度绘制、阴影模糊、大图。",
            "可用 const、Isolate、RepaintBoundary、图片压缩。",
        ],
        ["Shader compilation jank？", "RepaintBoundary 过多问题？"],
        ["不看 Timeline 盲目优化。", "所有卡顿归因 build。"],
        "client-flutter-performance-jank",
    ),
    make_question(
        "ListView.builder 和 SliverList 的区别是什么？复杂滚动页如何设计？",
        "列表与滚动",
        ["列表", "布局"],
        ["ListView 封装", "Sliver 组合", "CustomScrollView"],
        [
            "ListView.builder 适合普通懒加载列表。",
            "SliverList 可与其他 Sliver 组合。",
            "复杂吸顶头图分页页用 CustomScrollView 统一滚动。",
        ],
        ["shrinkWrap 为何影响性能？", "NestedScrollView 解决什么？"],
        ["Column 里无约束 ListView。", "滥用 shrinkWrap。"],
        "client-flutter-listview-sliver",
    ),
    make_question(
        "Flutter Navigator 1.0 和 Router 2.0 有什么区别？",
        "导航与路由",
        ["路由", "架构"],
        ["命令式 push/pop", "声明式页面栈", "深链 Web"],
        [
            "Navigator 1.0 用 push/pop，适合普通移动端。",
            "Router 2.0 把页面栈当状态，适合深链和 URL。",
            "go_router 降低 Router 2.0 复杂度。",
        ],
        ["go_router 解决了什么？", "登录态如何重定向？"],
        ["简单页过早上复杂路由。", "混淆命令式与声明式。"],
        "client-flutter-navigation-router",
    ),
    make_question(
        "AnimationController、Tween、AnimatedWidget 分别负责什么？",
        "动画",
        ["动画", "基础"],
        ["时间进度", "数值映射", "局部重建"],
        [
            "AnimationController 提供 0~1 进度，需 vsync。",
            "Tween 映射成尺寸颜色等。",
            "AnimatedBuilder 的 child 可缓存静态子树。",
        ],
        ["TickerProvider 作用？", "隐式与显式动画选择？"],
        ["忘记 dispose Controller。", "动画重建整页。"],
        "client-flutter-animation",
    ),
]

TOPICS = {
    "Flutter 基础": [
        "Hot Reload", "Hot Restart", "RepaintBoundary", "Opacity", "ClipRRect",
        "GestureDetector", "InkWell", "Focus", "Semantics", "Overlay",
        "WidgetsBinding", "SchedulerBinding", "RendererBinding", "Flutter Engine",
        "Skia", "Impeller", "Dart VM", "AOT 与 JIT", "Profile 模式", "Release 模式",
        "Debug 模式", "Material 与 Cupertino", "Scaffold", "AppBar", "SafeArea",
        "StatelessWidget", "StatefulWidget", "const 构造函数", "ThemeData",
        "MediaQuery", "InheritedWidget", "TickerProvider", "SingleTickerProviderStateMixin",
        "DefaultTextStyle", "RichText", "TextSpan", "AssetBundle", "pubspec.yaml",
    ],
    "布局与渲染": [
        "BoxConstraints", "ConstrainedBox", "SizedBox", "AspectRatio", "Row", "Column",
        "Wrap", "Expanded", "Flexible", "Stack", "Positioned", "Align", "Padding",
        "Container", "Transform", "FittedBox", "LayoutBuilder", "CustomPaint",
        "RenderBox", "RenderFlex", "IntrinsicHeight", "FractionallySizedBox",
        "OverflowBox", "LimitedBox", "Table", "Flow", "CustomMultiChildLayout",
        "Spacer", "Center", "DecoratedBox", "UnconstrainedBox", "Align 与 Baseline",
        "Flex 主轴交叉轴", "BoxDecoration", "ClipPath", "PhysicalModel",
    ],
    "状态管理": [
        "Provider", "Riverpod", "Bloc", "Cubit", "GetX", "MobX", "Redux",
        "ValueNotifier", "ChangeNotifier", "ListenableBuilder", "StreamBuilder",
        "FutureBuilder", "Selector", "Consumer", "StateNotifier", "状态提升",
        "状态下沉", "局部状态", "全局状态", "表单状态", "乐观更新",
        "MultiProvider", "ProviderScope", "BlocProvider", "Repository 模式",
        "Equatable", "Freezed 状态", "context.read", "context.watch", "ref.watch",
        "InheritedModel", "Listenable.merge", "状态持久化", "状态恢复",
    ],
    "异步与 Dart": [
        "async/await", "Event Loop", "Microtask Queue", "StreamController",
        "BroadcastStream", "Future.wait", "Completer", "Timer", "Zone",
        "runZonedGuarded", "FlutterError.onError", "compute", "ReceivePort",
        "SendPort", "Dart 空安全", "late", "nullable", "extension method",
        "mixin", "factory 构造函数", "typedef", "Record 类型", "Pattern matching",
        "Isolates.run", "PlatformDispatcher", "SingleSubscriptionStream",
        "Future.timeout", "Stream.transform", "async* 生成器", "await for",
    ],
    "列表与滚动": [
        "ListView", "ListView.separated", "GridView", "GridView.builder",
        "CustomScrollView", "SliverGrid", "SliverAppBar", "SliverPersistentHeader",
        "SliverToBoxAdapter", "SliverFillRemaining", "NestedScrollView",
        "ScrollController", "PageView", "TabBarView", "RefreshIndicator",
        "ScrollNotification", "NotificationListener", "ScrollPhysics",
        "BouncingScrollPhysics", "ClampingScrollPhysics", "shrinkWrap",
        "cacheExtent", "AutomaticKeepAliveClientMixin", "ReorderableListView",
        "ScrollablePositionedList", "IndexedStack 分页", "PrimaryScrollController",
        "ScrollConfiguration", "Scrollbar", "DraggableScrollableSheet",
    ],
    "导航与路由": [
        "Navigator.push", "MaterialPageRoute", "Named Route", "onGenerateRoute",
        "RouterDelegate", "RouteInformationParser", "go_router", "auto_route",
        "Deep Link", "Universal Link", "App Link", "路由守卫", "ShellRoute",
        "Hero 转场", "PageRouteBuilder", "PopScope", "WillPopScope",
        "NavigatorKey", "ModalRoute", "RouteSettings", "嵌套导航", "Tab 路由",
        "Web URL 路由", "路由传参", "路由返回值", "CupertinoPageRoute",
        "Navigator 2.0 状态同步", "登录重定向", "onUnknownRoute", "restorationId",
    ],
    "动画": [
        "CurvedAnimation", "AnimatedBuilder", "Implicit Animation", "AnimatedContainer",
        "AnimatedOpacity", "Hero", "FadeTransition", "ScaleTransition",
        "SlideTransition", "RotationTransition", "SizeTransition", "Staggered Animation",
        "Interval", "SpringSimulation", "Lottie", "AnimatedSwitcher",
        "AnimatedCrossFade", "PageController 动画", "AnimationStatus", "vsync",
        "TickerMode", "Listenable.merge", "CustomPainter 动画", "AnimatedAlign",
        "AnimatedPadding", "TweenSequence", "Curve 曲线", "ReverseAnimation",
        "AnimationController.repeat", "AnimationController.forward", "Physics Simulation",
    ],
    "性能优化": [
        "Timeline", "Performance Overlay", "ImageCache", "ResizeImage",
        "CachedNetworkImage", "Shader 编译卡顿", "Impeller", "Raster 线程",
        "UI 线程", "Jank", "内存泄漏排查", "DevTools Memory", "LeakTracker",
        "Opacity 性能", "Clip 性能", "BackdropFilter", "saveLayer 成本",
        "Tree shaking", "Deferred Components", "包体积优化", "Obfuscation",
        "Split Debug Info", "SkSL 预热", "Profile 模式", "帧率监控",
        "大图内存", "build 拆分", "图片解码", "ListView 懒加载", "GPU 过度绘制",
    ],
    "平台通道": [
        "MethodChannel", "EventChannel", "BasicMessageChannel", "BinaryMessenger",
        "StandardMethodCodec", "FlutterPlugin", "Federated Plugin", "PlatformView",
        "AndroidView", "UiKitView", "Hybrid Composition", "Virtual Display",
        "Pigeon", "dart:ffi", "Native Assets", "插件注册", "Add-to-App",
        "Flutter Module", "Engine 多实例", "Texture Layer", "PlatformView 性能",
    ],
    "网络与数据": [
        "http 包", "Dio", "Retrofit", "GraphQL", "WebSocket", "json_serializable",
        "freezed", "Repository", "DTO 与 Domain", "拦截器", "错误码映射",
        "Cookie 管理", "证书校验", "离线缓存", "Connectivity", "分页加载",
        "Pull to refresh", "SSE", "manual fromJson", "API 层设计", "重试策略",
    ],
    "存储与持久化": [
        "SharedPreferences", "path_provider", "sqflite", "Drift", "Hive",
        "Isar", "ObjectBox", "flutter_secure_storage", "文件读写", "数据库迁移",
        "加密存储", "Key-Value 存储", "缓存目录", "临时目录", "Asset 资源",
    ],
    "架构与工程化": [
        "Clean Architecture", "MVVM", "Feature-first 目录", "get_it", "injectable",
        "模块化", "Melos", "Flavor", "环境配置", "CI/CD", "Codemagic",
        "Fastlane", "analysis_options", "FVM", "build_runner", "代码生成",
        "Monorepo", "版本号管理", "Layer-first 目录", "依赖倒置", "UseCase 层",
    ],
    "测试": [
        "Widget Test", "Unit Test", "Integration Test", "Golden Test",
        "Mockito", "mocktail", "Finder", "pumpWidget", "pumpAndSettle",
        "TestWidgetsFlutterBinding", "Coverage", "Golden 差异", "Semantics 测试",
        "IntegrationTestWidgetsFlutterBinding", "CI 测试", "测试替身", "Golden 更新",
    ],
    "Widget 与组件": [
        "TextField", "Form", "FormField", "DropdownButton", "Checkbox", "Radio",
        "Switch", "Slider", "DatePicker", "BottomSheet", "Dialog", "SnackBar",
        "Chip", "Card", "ListTile", "TabBar", "Drawer", "FloatingActionButton",
        "PopupMenuButton", "ExpansionTile", "Stepper", "DataTable", "Tooltip",
        "自定义 Widget", "组合优于继承", "InputDecoration", "FocusNode",
        "TextEditingController", "Autocomplete", "SearchAnchor",
    ],
    "渲染原理": [
        "PipelineOwner", "Layer Tree", "Compositor", "SceneBuilder", "Canvas",
        "Paint", "Path", "Shader", "hitTest", "gesture arena", "PointerEvent",
        "relayout boundary", "repaint boundary", "SemanticsNode", "Platform Dispatcher",
        "PictureRecorder", "RenderParagraph", "RenderObjectWidget", "ComponentWidget",
        "RenderSliver", "Layer 合成", "Raster 阶段", "Layout 阶段", "Paint 阶段",
    ],
    "混合开发与发布": [
        "Add-to-App Android", "Add-to-App iOS", "Flutter Engine 缓存", "AAR 集成",
        "CocoaPods 集成", "App Bundle", "Play Store 发布", "App Store 发布",
        "签名配置", "ProGuard R8", "桌面打包", "Windows MSIX", "macOS notarization",
        "Flutter 嵌入原生", "多 Engine 场景", "启动耗时优化",
    ],
    "国际化与无障碍": [
        "intl", "flutter_localizations", "gen-l10n", "ARB 文件", "Locale",
        "RTL 布局", "Directionality", "TalkBack", "VoiceOver", "SemanticsLabel",
        "ExcludeSemantics", "MergeSemantics", "Accessibility 测试", "文字缩放",
    ],
    "Flutter Web/Desktop": [
        "CanvasKit", "HTML renderer", "Wasm", "Web 路由", "CORS", "Desktop 窗口管理",
        "window_manager", "多窗口", "鼠标 hover", "键盘快捷键", "条件导入",
        "Platform 差异抽象", "Web 渲染后端选择", "Desktop 菜单栏",
    ],
}

TAG_BY_MODULE = {
    "Flutter 基础": "基础",
    "布局与渲染": "布局",
    "状态管理": "状态管理",
    "异步与 Dart": "Dart",
    "列表与滚动": "列表",
    "导航与路由": "路由",
    "动画": "动画",
    "性能优化": "性能",
    "平台通道": "原生交互",
    "网络与数据": "网络",
    "存储与持久化": "存储",
    "架构与工程化": "架构",
    "测试": "测试",
    "Widget 与组件": "组件",
    "渲染原理": "底层",
    "混合开发与发布": "工程",
    "国际化与无障碍": "i18n",
    "Flutter Web/Desktop": "多端",
}


def topic_question(module, topic):
    templates = {
        "Flutter 基础": f"Flutter 中 {topic} 是什么？如何使用？",
        "布局与渲染": f"{topic} 在 Flutter 布局中如何工作？常见误用有哪些？",
        "状态管理": f"Flutter 状态管理里 {topic} 适合解决什么问题？",
        "异步与 Dart": f"Dart/Flutter 中 {topic} 的原理和最佳实践是什么？",
        "列表与滚动": f"Flutter 列表滚动中 {topic} 的使用要点是什么？",
        "导航与路由": f"Flutter 路由体系中 {topic} 如何使用？",
        "动画": f"Flutter 动画开发中 {topic} 如何实现？",
        "性能优化": f"Flutter 性能优化里如何分析和改进 {topic}？",
        "平台通道": f"Flutter 平台通道中 {topic} 的作用是什么？",
        "网络与数据": f"Flutter 项目里 {topic} 如何设计和落地？",
        "存储与持久化": f"Flutter 中 {topic} 适合存储什么？如何使用？",
        "架构与工程化": f"Flutter 工程化实践中 {topic} 如何落地？",
        "测试": f"Flutter 测试中 {topic} 如何编写和维护？",
        "Widget 与组件": f"Flutter 组件 {topic} 的常见用法和注意点是什么？",
        "渲染原理": f"Flutter 渲染管线中 {topic} 处于哪一环？",
        "混合开发与发布": f"Flutter 混合开发与发布里 {topic} 的方案是什么？",
        "国际化与无障碍": f"Flutter 中 {topic} 如何实现？",
        "Flutter Web/Desktop": f"Flutter 在 {topic} 场景下有哪些平台差异？",
    }
    title = templates.get(module, f"Flutter 中 {topic} 的核心机制是什么？")
    tag = TAG_BY_MODULE.get(module, "基础")
    checkpoints = [
        f"{topic} 的定义和职责",
        f"{topic} 的典型使用场景",
        "与其他方案的边界和取舍",
    ]
    answer_points = [
        f"{topic} 是 {module} 中的关键知识点，理解它有助于正确实现功能和排查问题。",
        f"使用 {topic} 时要明确输入输出、生命周期、线程边界，避免在错误层级持有状态或资源。",
        f"选型时应结合团队熟悉度、可测试性、性能成本和维护难度，而不是只看流行度。",
        f"面试回答建议结合一个真实页面说明为什么使用 {topic}，以及如何验证效果。",
    ]
    follow_ups = [
        f"{topic} 的常见坑有哪些？",
        f"什么情况下不应该使用 {topic}？",
        f"如何用 DevTools 或日志验证 {topic} 的行为？",
    ]
    mistakes = [
        f"只背 {topic} 名词，不会结合场景说明。",
        "不区分适用边界，所有场景都用同一种方案。",
    ]
    return make_question(title, module, [tag], checkpoints, answer_points, follow_ups, mistakes)


def main():
    questions = []
    seen_titles = set()
    seen_ids = set()

    def add(question):
        if question["title"] in seen_titles:
            return
        base_id = question["id"]
        suffix = 1
        while question["id"] in seen_ids:
            question["id"] = f"{base_id}-{suffix}"
            suffix += 1
        seen_ids.add(question["id"])
        seen_titles.add(question["title"])
        questions.append(question)

    for item in SEED_QUESTIONS:
        add(dict(item))

    modules = list(TOPICS.keys())
    idx = 0
    while len(questions) < 300:
        module = modules[idx % len(modules)]
        topics = TOPICS[module]
        topic = topics[(len(questions) + idx) % len(topics)]
        add(topic_question(module, topic))
        idx += 1

    questions = questions[:300]
    OUTPUT.write_text(
        json.dumps({"questions": questions}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {len(questions)} questions to {OUTPUT}")
    counts = {}
    for item in questions:
        counts[item["module"]] = counts.get(item["module"], 0) + 1
    for name, count in sorted(counts.items(), key=lambda x: -x[1]):
        print(f"  {name}: {count}")


if __name__ == "__main__":
    main()
