# AndroidBigCow 项目分析

分析日期：2026-06-15

## 1. 项目概览

当前仓库主体是 `android-interview-bank`，一个 Flutter 原生离线 Android 面试刷题应用。仓库根目录还有一组 Markdown 题库文件，Flutter App 将结构化题库打包为本地资产 `assets/question_bank.json`，运行时无需网络。

应用定位：

- 面向 Android 客户端工程师的离线面试题练习工具。
- 支持按模块浏览、搜索、标签筛选、随机刷题、收藏、复习状态标记和主题切换。
- 用户进度仅保存在本机，题库内容随 App 内置发布。

## 2. 目录结构

```text
AndroidBigCow/
├── README.md
├── PROJECT_ANALYSIS.md
└── android-interview-bank/
    ├── README.md
    ├── 00-题卡模板.md
    ├── 01-知识点地图.md
    ├── 02-Java.md ... 13-项目实战场景题.md
    ├── assets/
    │   └── question_bank.json
    ├── docs/
    │   ├── unimplemented.md
    │   └── superpowers/
    ├── lib/
    │   ├── main.dart
    │   ├── data/
    │   ├── models/
    │   ├── screens/
    │   ├── state/
    │   ├── theme/
    │   └── widgets/
    ├── test/
    ├── android/
    └── windows/
```

其中：

- `android-interview-bank/*.md`：原始题库和知识点文档。
- `android-interview-bank/assets/question_bank.json`：App 实际加载的结构化题库数据。
- `android-interview-bank/lib`：Flutter 应用代码。
- `android-interview-bank/test`：模型、仓储、状态持久化和基础 Widget 测试。
- `android-interview-bank/docs/unimplemented.md`：未实现能力和后续事项清单。

## 3. 技术栈

运行时：

- Flutter / Dart。
- Material 3 UI。
- `shared_preferences`：本地保存复习进度和主题设置。
- 本地 JSON Asset：保存题库数据。

开发与测试：

- `flutter_lints`。
- `flutter_test`。
- Android 工程使用 Kotlin DSL Gradle 配置。
- Android `namespace` / `applicationId` 当前为 `com.example.android_interview_bank`。

依赖整体很轻，没有网络、数据库、状态管理框架、路由框架或代码生成。

## 4. 功能现状

已实现能力：

- 启动时加载本地题库 JSON 和用户本地进度。
- 首页展示题量、掌握进度、下次复习数、收藏数和模块入口。
- 随机打开一道题。
- 题库页支持：
  - 关键词搜索；
  - 按模块筛选；
  - 多标签组合筛选。
- 题目详情页展示：
  - 题目标题；
  - 标签；
  - 考察点；
  - 答案要点；
  - 深挖追问；
  - 常见误区。
- 题目详情页支持：
  - 收藏 / 取消收藏；
  - 标记为未掌握；
  - 标记为已掌握；
  - 标记为下次复习。
- 复习页集中展示下次复习、未掌握统计和收藏题。
- 设置页支持：
  - 蓝色、紫色、橙色、暗色四套主题；
  - 展示进度 JSON；
  - 重置本地进度。

未实现能力主要包括：

- 账号登录和云同步。
- 在线题库更新。
- 题库导入、题卡新增 / 编辑 / 删除。
- 导出进度到文件、剪贴板或系统分享。
- 间隔重复复习算法。
- 错题 / 难题维度。
- 平板、桌面等大屏布局优化。

## 5. 数据规模与内容

`assets/question_bank.json` 当前包含：

- 58 道题。
- 12 个模块。
- 高频标签 45 次。
- 场景题标签 18 次。
- 易混标签 17 次。

模块题量：

| 模块 | 题量 |
| --- | ---: |
| Android 基础 | 5 |
| Framework / Binder | 5 |
| Gradle / 工程化 | 3 |
| Handler / 线程 / 协程 | 5 |
| Java | 5 |
| Jetpack / 架构 | 5 |
| Kotlin | 5 |
| View / 事件 / 绘制 | 5 |
| 图形渲染 / OpenGL | 5 |
| 性能优化 | 5 |
| 网络 / 存储 / 安全 | 5 |
| 项目实战场景题 | 5 |

题卡结构：

- `id`：题目唯一标识。
- `module`：模块。
- `title`：题目。
- `tags`：标签列表。
- `reviewStatus`：初始复习状态。
- `checkpoints`：考察点。
- `answerPoints`：答案要点。
- `followUps`：深挖追问。
- `mistakes`：常见误区。

## 6. 架构分析

整体架构是轻量本地单体 Flutter App：

```text
main.dart
  └── 加载 QuestionRepository + AppController
      └── AppShell
          ├── HomeScreen
          ├── BankScreen
          ├── ReviewScreen
          └── SettingsScreen
```

核心分层：

- `models/question.dart`：题库领域模型、复习状态枚举、展示聚合对象。
- `models/user_progress.dart`：用户进度模型，按题目 ID 保存收藏和复习状态。
- `data/question_repository.dart`：加载、查询、筛选、随机取题，并将题库数据与用户进度合并。
- `state/app_controller.dart`：本地状态控制器，负责持久化、主题、收藏和复习状态更新。
- `screens/*`：页面级 UI。
- `widgets/*`：题卡、状态标签、通用卡片。
- `theme/app_theme.dart`：主题 Token 和 `ThemeExtension`。

这个结构适合当前 MVP：数据来源单一、状态少、功能边界清晰。随着导入、同步、间隔复习和编辑能力增加，现有 `AppController` 可能会变胖，需要拆分为更明确的服务层。

## 7. 状态与持久化

持久化键：

- `android_interview_bank.progress`
- `android_interview_bank.theme`

当前保存内容：

- 每道题的收藏状态。
- 每道题的手动复习状态。
- 当前主题风格。

优点：

- 题库内容和用户进度分离，后续更新题库不一定覆盖用户进度。
- JSON 结构直观，方便导出或调试。
- 本地存储实现简单，适合离线 MVP。

风险：

- 没有版本号和迁移机制，后续修改进度结构时需要补迁移逻辑。
- `UserProgress.fromJson` 对异常结构容错有限，导入外部进度文件前需要加强校验。
- `QuestionProgress.copyWith` 目前无法显式把 `status` 重置为 `null`，虽然当前业务不需要，但扩展时要注意。

## 8. UI 与交互

UI 特征：

- Material 3。
- 底部四 Tab：题库、刷题、复习、我的。
- 卡片式信息密度较高，适合刷题工具。
- 使用 `IndexedStack` 保留各 Tab 内部状态。
- 主题通过 `AppPalette` 统一管理颜色。

值得优化的点：

- 首页模块卡片当前只有展示，没有直接跳转到对应模块筛选页。
- 复习页计算了未掌握数量，但列表只展示“下次复习”和“收藏题”，没有展示未掌握题列表。
- 设置页“进度导出”只展示 JSON，未支持复制、保存或分享。
- 卡片圆角多为 14/16，整体偏柔和；如果走工具型产品风格，可以适度压缩圆角和垂直间距。
- 大屏和横屏没有专门布局，Windows 工程存在但主要体验仍是手机竖屏。

## 9. 测试现状

现有测试覆盖：

- `question_repository_test.dart`
  - 模块分组顺序。
  - 搜索范围。
  - 模块与标签组合筛选。
  - 进度覆盖题目状态。
- `user_progress_test.dart`
  - 用户进度序列化。
  - 收藏与状态更新。
  - `SharedPreferences` 中进度和主题持久化。
- `widget_test.dart`
  - 主 AppShell 和底部 Tab smoke test。

建议补充：

- 题库 JSON asset 的结构校验测试，避免字段缺失导致启动期崩溃。
- 搜索中文、大小写、空白输入的边界测试。
- 设置页重置确认流程 Widget 测试。
- 详情页收藏 / 状态变更后 UI 刷新测试。
- 复习页各状态集合展示测试。

## 10. 构建与运行

常用命令：

```bash
cd android-interview-bank
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

已有文档记录：`docs/unimplemented.md` 提到 Android debug APK 打包曾因 Gradle wrapper 下载或文件锁等待超时未完成。该问题更像本机 Gradle 下载 / 构建环境阻塞，不是 Dart 代码层面的失败。

## 11. 主要风险

1. 题库数据和 Markdown 源文档缺少自动同步机制。
   当前 App 只读 `question_bank.json`，后续如果继续维护 Markdown 题库，需要明确生成 JSON 的流程，否则容易两边不一致。

2. 应用包名仍是示例值。
   `applicationId = "com.example.android_interview_bank"` 不适合正式分发。

3. 复习模型偏简单。
   目前只有三个手动状态，不包含复习时间、复习次数、正确率、间隔计划等字段。

4. 缺少题库版本和进度迁移。
   一旦题目 ID 调整，用户进度会丢失关联；一旦进度结构升级，也需要兼容旧数据。

5. 导出功能还停留在展示层。
   用户看得到 JSON，但无法便捷复制、保存或分享。

6. 缺少异常态 UI。
   题库 asset 解析失败、SharedPreferences 数据损坏等场景目前没有用户可理解的恢复入口。

## 12. 建议路线

短期优先级：

1. 跑通本机 Android debug APK 构建，确认 Gradle 环境稳定。
2. 将 `applicationId` 和 `namespace` 改为正式包名。
3. 给 `question_bank.json` 增加结构校验测试。
4. 设置页增加“复制进度 JSON”或“导出到文件”。
5. 复习页补齐未掌握题列表。

中期优先级：

1. 建立 Markdown 到 JSON 的生成脚本或校验脚本。
2. 增加题库版本、进度版本和迁移逻辑。
3. 增加间隔复习字段：`lastReviewedAt`、`nextReviewAt`、`reviewCount`。
4. 支持导入本地题库或进度文件。
5. 优化平板 / 桌面布局。

长期方向：

1. 账号系统和云同步。
2. 远程题库增量更新。
3. 题卡编辑、错题本、统计报表。
4. CI 自动执行 format、analyze、test、APK 构建。

## 13. 总结

这是一个边界清晰的 Flutter 离线 MVP：代码量小、依赖少、分层直接，适合快速迭代。当前最有价值的改进不是引入复杂架构，而是补齐工程闭环：构建稳定性、题库数据校验、进度导出、复习队列能力和正式包名。

在功能继续扩展前，建议优先固化“题库源文档 -> JSON asset -> App 测试”的数据链路，避免题库规模扩大后维护成本快速上升。
