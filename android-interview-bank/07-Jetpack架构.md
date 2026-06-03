# Jetpack / 架构

## Q: ViewModel 解决了什么问题？不能做什么？

标签：高频 / 架构 / 易混

复习状态：未掌握

考察点：

- 生命周期感知。
- 配置变更。
- 状态持有。

答案要点：

- ViewModel 用于持有和管理 UI 相关状态，能在配置变更时保留。
- ViewModel 不应该持有 Activity、View、Context 等短生命周期对象。
- ViewModel 的清理点是 onCleared，但进程被杀时不保证业务收尾逻辑执行。
- 需要恢复进程死亡后的状态时，应结合 SavedStateHandle 或持久化。

深挖追问：

- ViewModelStoreOwner 是什么？
- AndroidViewModel 是否推荐？
- ViewModel 中启动协程应该用哪个 Scope？

常见误区：

- 把 ViewModel 当全局单例。
- 在 ViewModel 中直接操作 View。

## Q: LiveData 和 StateFlow 在 UI 层如何选择？

标签：高频 / 架构 / 易混

复习状态：未掌握

考察点：

- 生命周期。
- 状态表达。
- 协程生态。

答案要点：

- LiveData 生命周期感知能力内置，适合传统 XML/View 项目。
- StateFlow 属于 Kotlin Flow 生态，始终有当前值，适合协程和单向数据流。
- StateFlow 在 UI 层收集时要配合 repeatOnLifecycle。
- 一次性事件不适合直接用 StateFlow 表达，可考虑 Channel、SharedFlow 或事件包装，取决于场景。

深挖追问：

- LiveData 的粘性表现是什么？
- StateFlow 为什么需要初始值？
- SharedFlow replay 参数如何影响事件？

常见误区：

- 用 StateFlow 直接发 Toast、导航等一次性事件。
- 永久 collect 导致后台仍然消费数据。

## Q: MVVM 的职责边界应该如何划分？

标签：高频 / 架构 / 场景题

复习状态：未掌握

考察点：

- UI、状态、业务逻辑分离。
- Repository。
- 可测试性。

答案要点：

- View 负责渲染状态和转发用户事件。
- ViewModel 负责组织 UI 状态、调用用例或仓库、处理 UI 逻辑。
- Repository 负责协调数据来源，例如网络、数据库、缓存。
- 复杂业务可引入 UseCase，避免 ViewModel 变成业务大杂烩。

深挖追问：

- ViewModel 能不能直接调用 Retrofit？
- Repository 是否一定需要？
- MVI 和 MVVM 的差异是什么？

常见误区：

- 把所有逻辑都塞进 ViewModel。
- Repository 只是简单转发 DAO/API，没有实际抽象价值。

## Q: Room 相比直接 SQLite 有什么优势和限制？

标签：Jetpack / 存储 / 高频

复习状态：未掌握

考察点：

- 编译期校验。
- DAO。
- 迁移。

答案要点：

- Room 在 SQLite 之上提供注解建模、DAO 抽象和编译期 SQL 校验。
- 支持 Flow、LiveData 等响应式查询能力。
- 数据库版本升级必须设计 Migration，否则可能丢数据或崩溃。
- 复杂 SQL、批量写入和大表查询仍然需要关注索引、事务和性能。

深挖追问：

- Room Migration 如何测试？
- suspend DAO 方法运行在哪个线程？
- 什么时候需要事务？

常见误区：

- 以为用了 Room 就不需要懂 SQL。
- fallbackToDestructiveMigration 在线上随意使用。

## Q: Compose 中重组是什么？如何避免不必要重组？

标签：Compose / 进阶 / 性能

复习状态：未掌握

考察点：

- 声明式 UI。
- State 驱动。
- 稳定性。

答案要点：

- Compose 根据状态变化重新执行相关 Composable，这个过程叫重组。
- 重组不是重建整个界面，Compose 会尽量跳过稳定且未变化的部分。
- 应使用 remember、derivedStateOf、key、稳定数据结构等方式减少无效重组。
- 副作用逻辑应放在 LaunchedEffect、DisposableEffect、SideEffect 等 API 中。

深挖追问：

- remember 和 rememberSaveable 有什么区别？
- 什么是稳定类型？
- LazyColumn key 为什么重要？

常见误区：

- 在 Composable 中直接执行网络请求。
- 把重组等同于性能问题本身。

