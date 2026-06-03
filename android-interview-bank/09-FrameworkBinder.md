# Framework / Binder

## Q: Android 系统启动的大致流程是什么？

标签：底层 / Framework / 高频

复习状态：未掌握

考察点：

- init。
- Zygote。
- SystemServer。

答案要点：

- 设备启动后 init 进程解析 init 脚本并启动关键服务。
- Zygote 进程预加载类和资源，后续应用进程通常由 Zygote fork 出来。
- SystemServer 启动 AMS、WMS、PMS 等核心系统服务。
- Launcher 启动后，用户点击图标再通过系统服务完成应用进程和 Activity 启动。

深挖追问：

- Zygote 预加载有什么意义？
- SystemServer 崩溃会怎样？
- 应用进程为什么由 Zygote fork？

常见误区：

- 只知道 Zygote，不知道 SystemServer 负责系统服务。

## Q: Binder 为什么是 Android 主要 IPC 机制？

标签：底层 / 高频 / Binder

复习状态：未掌握

考察点：

- 跨进程通信。
- Binder 驱动。
- 引用和权限。

答案要点：

- Binder 是 Android 中核心 IPC 机制，支持客户端调用服务端对象接口。
- Binder 涉及用户空间的代理/桩对象、ServiceManager 和内核 Binder 驱动。
- 相比传统 IPC，Binder 在 Android 中统一了承载系统服务调用、对象引用和权限校验。
- AIDL 是基于 Binder 的接口描述方式，用于生成跨进程调用代码。

深挖追问：

- Binder 一次拷贝是什么意思？
- ServiceManager 做什么？
- Binder 线程池为什么重要？

常见误区：

- 把 AIDL 等同于 Binder 本身。
- 只说性能好，不知道调用链路。

## Q: AMS 在 Activity 启动中负责什么？

标签：Framework / AMS / 高频

复习状态：未掌握

考察点：

- Activity 启动调度。
- 进程管理。
- 任务栈。

答案要点：

- AMS/ActivityTaskManager 负责校验启动请求、解析目标 Activity、管理任务栈和进程状态。
- 如果目标进程不存在，会请求 Zygote fork 应用进程。
- 应用进程启动后通过 ActivityThread 与系统完成绑定，并执行 Activity 生命周期。
- Activity 启动涉及跨进程调用，客户端、系统服务和应用主线程协作完成。

深挖追问：

- ActivityThread 是线程吗？
- Instrumentation 在启动中有什么作用？
- launchMode 在 Framework 层如何影响栈？

常见误区：

- 认为 Activity 是自己 new 出来的。
- 不区分 AMS 和应用进程中的 ActivityThread。

## Q: WMS 和 SurfaceFlinger 分别负责什么？

标签：底层 / 图形 / Framework

复习状态：未掌握

考察点：

- 窗口管理。
- Surface 合成。
- 显示链路。

答案要点：

- WMS 负责窗口层级、窗口属性、焦点、布局和与输入相关的窗口信息。
- SurfaceFlinger 负责接收各窗口对应的 Surface Buffer，并合成最终显示画面。
- 应用侧绘制内容写入 Buffer，系统侧通过 SurfaceFlinger 合成到屏幕。
- WMS 关心窗口组织，SurfaceFlinger 关心图层合成，两者通过 Surface/Layer 关联。

深挖追问：

- 一个 Activity 对应几个 Window？
- SurfaceView 为什么适合视频或相机预览？
- 输入事件和窗口焦点有什么关系？

常见误区：

- 把窗口管理和图像合成混为一谈。

## Q: PMS 在应用安装和权限中做什么？

标签：Framework / PMS / 底层

复习状态：未掌握

考察点：

- APK 解析。
- 签名。
- 权限。

答案要点：

- PMS 负责扫描和解析 APK，读取 Manifest，管理包信息、组件信息、签名和权限。
- 安装时会校验签名、版本、权限声明和兼容性。
- 系统查询组件、权限判断、Intent 解析等都依赖 PMS 提供的数据。
- Android 版本升级后，包可见性、权限和安装限制都有更多约束。

深挖追问：

- 签名校验失败会怎样？
- queries 标签解决什么问题？
- 动态权限和安装权限分别由谁管理？

常见误区：

- 只把 PMS 理解为安装 APK。

