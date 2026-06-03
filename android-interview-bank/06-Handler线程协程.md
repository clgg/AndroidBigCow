# Handler / 线程 / 协程

## Q: Handler、Looper、MessageQueue 之间是什么关系？

标签：高频 / 基础 / 易混

复习状态：未掌握

考察点：

- 消息循环。
- 线程绑定。
- 主线程通信。

答案要点：

- Looper 负责在线程中开启消息循环。
- MessageQueue 负责存放 Message。
- Handler 负责发送消息和处理消息，并和创建它的线程 Looper 绑定。
- 主线程默认已经创建 Looper，普通子线程需要手动 Looper.prepare 和 Looper.loop，或使用 HandlerThread。

深挖追问：

- Looper.loop 为什么不会让主线程退出？
- Handler 为什么能切回主线程？
- MessageQueue 没消息时线程在做什么？

常见误区：

- 以为 Handler 自己创建线程。
- 不理解 Handler 绑定的是 Looper 所在线程。

## Q: Handler 为什么可能导致内存泄漏？

标签：高频 / 易混 / 内存

复习状态：未掌握

考察点：

- 延迟消息。
- 引用链。
- 生命周期清理。

答案要点：

- 非静态内部类 Handler 会隐式持有外部 Activity。
- MessageQueue 中未处理的 Message 持有 Handler，Handler 又持有 Activity，可能导致 Activity 无法回收。
- postDelayed 或长时间延迟消息更容易暴露问题。
- 解决方式包括静态内部类加 WeakReference、onDestroy 移除消息、使用生命周期感知组件。

深挖追问：

- Handler 本身是不是泄漏根因？
- removeCallbacksAndMessages(null) 有什么风险？
- HandlerThread 退出时要注意什么？

常见误区：

- 认为用了 WeakReference 就完全安全。
- 忘记清理队列中的业务回调。

## Q: Thread、HandlerThread、线程池分别适合什么场景？

标签：场景题 / 并发 / Android

复习状态：未掌握

考察点：

- 线程复用。
- 消息调度。
- 任务类型。

答案要点：

- Thread 适合简单短期任务，但频繁创建销毁成本高。
- HandlerThread 是带 Looper 的单线程，适合串行处理需要消息队列的后台任务。
- 线程池适合大量异步任务，通过复用线程控制并发和资源。
- Android 中要避免线程生命周期超过组件生命周期导致泄漏。

深挖追问：

- HandlerThread 如何安全退出？
- 线程池队列堆积怎么监控？
- 多个业务共用线程池有什么风险？

常见误区：

- 所有异步任务都直接 new Thread。
- HandlerThread 使用完不 quit。

## Q: ANR 是什么？常见触发原因有哪些？

标签：高频 / 性能 / 场景题

复习状态：未掌握

考察点：

- 主线程阻塞。
- 系统超时。
- 诊断方法。

答案要点：

- ANR 是应用在规定时间内没有响应系统输入、广播、服务等事件。
- 常见原因包括主线程 IO、锁等待、死循环、Binder 调用阻塞、广播或服务执行超时。
- 排查要看 traces、主线程堆栈、锁竞争、系统负载和业务日志。
- 预防核心是主线程只做 UI 和轻量逻辑，耗时任务放到合适线程并设置超时。

深挖追问：

- Input ANR 和 Broadcast ANR 有什么区别？
- 如何分析 traces.txt？
- Binder 调用为什么可能导致 ANR？

常见误区：

- 只把 ANR 归因于主线程做网络请求。
- 不看现场堆栈，直接猜原因。

## Q: 协程取消为什么需要协作？

标签：协程 / 进阶 / 易混

复习状态：未掌握

考察点：

- Job 状态。
- 挂起点。
- isActive。

答案要点：

- 协程取消本质上是修改 Job 状态，并不会强行杀死正在执行的代码。
- 挂起函数通常会检查取消状态并抛出 CancellationException。
- CPU 密集循环需要主动检查 isActive、yield 或 ensureActive。
- finally 中释放资源时要注意挂起清理逻辑可用 NonCancellable 包裹。

深挖追问：

- CancellationException 应不应该被吞掉？
- viewModelScope 什么时候取消？
- withTimeout 底层如何体现取消？

常见误区：

- 认为 cancel 会立即终止任意代码。
- catch Exception 时误吞 CancellationException。

