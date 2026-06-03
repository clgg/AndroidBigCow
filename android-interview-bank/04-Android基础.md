# Android 基础

## Q: Activity 生命周期有哪些关键回调？异常重建时如何恢复状态？

标签：高频 / 基础 / 易混

复习状态：未掌握

考察点：

- 生命周期回调顺序。
- 配置变更。
- 状态保存。

答案要点：

- 常见回调包括 onCreate、onStart、onResume、onPause、onStop、onDestroy。
- 横竖屏切换、语言变化、系统回收后恢复等场景可能触发重建。
- 临时 UI 状态可用 onSaveInstanceState 保存，业务状态更适合 ViewModel 或持久化。
- onPause 应快速完成，耗时操作应避免阻塞生命周期切换。

深挖追问：

- onSaveInstanceState 一定会调用吗？
- Activity 被系统回收后 Intent 数据还在吗？
- Fragment 生命周期和 View 生命周期有什么区别？

常见误区：

- 把 onDestroy 当成必定调用的清理点。
- 所有状态都塞进 Bundle，忽略大小限制。

## Q: Android 四大组件分别解决什么问题？

标签：基础 / 高频

复习状态：未掌握

考察点：

- 组件职责。
- 生命周期和进程边界。
- Manifest 声明。

答案要点：

- Activity 负责提供用户界面和交互入口。
- Service 负责后台任务或跨进程服务能力，不等于自动运行在子线程。
- BroadcastReceiver 负责接收广播事件，执行时间应短。
- ContentProvider 负责跨进程结构化数据共享，也参与应用启动初始化链路。

深挖追问：

- Service 和 IntentService、JobIntentService、WorkManager 有什么区别？
- 静态广播和动态广播有什么区别？
- ContentProvider 为什么可能影响启动速度？

常见误区：

- 认为 Service 默认在后台线程。
- 忽略 Android 版本对后台执行和广播的限制。

## Q: Activity 启动模式有哪些？任务栈如何影响页面行为？

标签：高频 / 易混 / 场景题

复习状态：未掌握

考察点：

- standard、singleTop、singleTask、singleInstance。
- Task 和 Back Stack。
- Intent flag。

答案要点：

- standard 每次启动创建新实例。
- singleTop 在栈顶复用，否则创建新实例。
- singleTask 在任务栈中复用已有实例，并清理其上的页面。
- singleInstance 独占任务栈，新版本中更推荐结合具体场景谨慎使用。
- Intent flags 也会影响任务栈行为，例如 FLAG_ACTIVITY_NEW_TASK、CLEAR_TOP。

深挖追问：

- onNewIntent 什么时候调用？
- Deep Link 打开页面如何设计任务栈？
- 通知点击返回栈如何构建？

常见误区：

- 背启动模式定义但不会分析实际返回路径。
- 忽略 Manifest 和 Intent flag 共同作用。

## Q: Service、前台服务、WorkManager 如何取舍？

标签：高频 / 场景题 / Android

复习状态：未掌握

考察点：

- 后台执行限制。
- 用户可感知任务。
- 可靠任务调度。

答案要点：

- 普通 Service 适合与组件绑定或短期后台逻辑，但受后台限制影响。
- 前台服务适合用户可感知且需要持续运行的任务，例如导航、播放、录音，需要展示通知。
- WorkManager 适合可延迟、需要可靠执行的任务，能结合约束条件和重试策略。
- 长时间后台任务要考虑系统限制、电量、权限和用户体验。

深挖追问：

- WorkManager 一定会立即执行吗？
- 前台服务类型限制是什么？
- App 被杀后任务还能不能继续？

常见误区：

- 用 Service 处理所有后台任务。
- 认为 WorkManager 适合实时任务。

## Q: Android 运行时权限的核心流程是什么？

标签：基础 / 高频 / 安全

复习状态：未掌握

考察点：

- 普通权限和危险权限。
- 运行时申请。
- 版本差异。

答案要点：

- 普通权限安装时授予，危险权限需要运行时申请。
- 申请前应解释使用场景，申请后处理允许、拒绝、永久拒绝。
- Android 版本持续加强隐私限制，例如存储、位置、通知、蓝牙、媒体权限都有差异。
- 权限申请应和业务动作绑定，避免启动时批量索取。

深挖追问：

- shouldShowRequestPermissionRationale 如何使用？
- Android 13 通知权限有什么变化？
- 分区存储对文件访问有什么影响？

常见误区：

- 只判断一次权限，不处理用户后续关闭权限。
- 把权限申请写成和业务无关的全局流程。

