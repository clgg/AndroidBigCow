# Kotlin

## Q: Kotlin 的空安全解决了什么问题？平台类型有什么风险？

标签：高频 / 基础 / 易混

复习状态：未掌握

考察点：

- 可空类型和非空类型。
- Java 互操作。
- NPE 来源。

答案要点：

- Kotlin 用类型系统区分 `String` 和 `String?`，让可空调用在编译期显式处理。
- 安全调用 `?.`、Elvis 操作符 `?:`、非空断言 `!!` 是常见处理方式。
- 平台类型来自 Java，Kotlin 无法确定是否可空，开发者错误假设时仍然可能 NPE。
- 与 Java API 交互时应结合注解、边界校验和封装层降低风险。

深挖追问：

- `lateinit` 和可空变量怎么取舍？
- `!!` 在项目中应该如何管控？
- Java 注解如何影响 Kotlin 可空推断？

常见误区：

- 认为 Kotlin 完全不会出现 NPE。
- 滥用 `!!` 让空安全失去意义。

## Q: data class 自动生成哪些方法？有什么使用边界？

标签：基础 / 高频

复习状态：未掌握

考察点：

- equals、hashCode、toString、copy、componentN。
- 不可变数据建模。
- 浅拷贝。

答案要点：

- data class 会基于主构造函数属性生成 equals、hashCode、toString、copy 和 componentN。
- 适合表达值对象、接口 DTO、UI State。
- copy 是浅拷贝，内部引用对象不会自动深拷贝。
- 只有主构造函数中的属性参与自动生成方法，类体中的属性不参与。

深挖追问：

- data class 作为 HashMap key 时要注意什么？
- copy 修改嵌套集合有什么风险？
- data object 和 object 有什么差异？

常见误区：

- 以为 copy 是深拷贝。
- 忽略可变集合导致状态被意外修改。

## Q: inline、noinline、crossinline 分别解决什么问题？

标签：进阶 / 高频 / Kotlin

复习状态：未掌握

考察点：

- 高阶函数成本。
- lambda 内联。
- 非局部返回。

答案要点：

- inline 会把函数体和可内联 lambda 展开到调用处，减少函数对象分配和调用开销。
- noinline 用于标记某个 lambda 不参与内联，通常因为需要作为对象传递或存储。
- crossinline 禁止 lambda 中非局部 return，常用于 lambda 会在另一个执行上下文中被调用的场景。
- inline 不是越多越好，过度使用可能增加字节码体积。

深挖追问：

- reified 为什么必须配合 inline？
- inline 对性能优化的边界在哪里？
- Kotlin 标准库哪些函数大量使用 inline？

常见误区：

- 认为 inline 一定提升性能。
- 不理解非局部 return 导致控制流判断错误。

## Q: Kotlin 协程和线程是什么关系？

标签：高频 / 协程 / 易混

复习状态：未掌握

考察点：

- 协程不是线程。
- Dispatcher 调度。
- 挂起和恢复。

答案要点：

- 协程是语言和库层面的并发抽象，不等于线程。
- 协程运行需要线程承载，具体在哪些线程执行由 Dispatcher 决定。
- suspend 表示函数可以挂起，不代表一定切线程，也不代表阻塞当前线程。
- 挂起时协程保存状态，等待结果后恢复执行，适合简化异步代码。

深挖追问：

- Dispatchers.Main、IO、Default 怎么选？
- withContext 和 launch 有什么区别？
- 协程取消为什么需要协作？

常见误区：

- 以为 suspend 会自动切到后台线程。
- 把协程当成轻量线程但忽略生命周期。

## Q: Flow、LiveData、StateFlow 有什么区别？

标签：高频 / 架构 / 易混

复习状态：未掌握

考察点：

- 冷流和热流。
- 生命周期感知。
- UI 状态建模。

答案要点：

- Flow 默认是冷流，收集时才执行上游逻辑。
- LiveData 具备生命周期感知，常用于传统 View 系统。
- StateFlow 是热流，始终持有一个当前值，适合表达 UI State。
- 在 Android UI 中收集 Flow/StateFlow 要结合生命周期，例如 repeatOnLifecycle，避免后台无效收集。

深挖追问：

- SharedFlow 和 StateFlow 有什么区别？
- Flow 的背压和异常如何处理？
- 为什么 StateFlow 适合 MVI？

常见误区：

- 把 Flow 当 LiveData 直接在 UI 层永久 collect。
- 用 StateFlow 表示一次性事件。

