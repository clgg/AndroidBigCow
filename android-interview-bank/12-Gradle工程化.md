# Gradle / 工程化

## Q: Gradle 构建生命周期包括哪些阶段？

标签：工程化 / 基础 / 高频

复习状态：未掌握

考察点：

- Initialization。
- Configuration。
- Execution。

答案要点：

- Initialization 阶段确定参与构建的项目。
- Configuration 阶段配置项目和 Task 图。
- Execution 阶段执行被选中的 Task。
- 构建性能优化重点之一是减少配置阶段成本，使用懒配置和配置缓存。

深挖追问：

- Task 注册和 Task 创建有什么区别？
- configuration cache 对插件有什么要求？
- buildSrc 和 convention plugin 如何选择？

常见误区：

- 在配置阶段执行耗时 IO。

## Q: productFlavor 和 buildType 有什么区别？

标签：Android / Gradle / 高频

复习状态：未掌握

考察点：

- Variant。
- 渠道。
- 调试和发布配置。

答案要点：

- buildType 表达构建类型，例如 debug、release，常用于混淆、签名、调试开关。
- productFlavor 表达产品维度，例如渠道、地区、环境。
- buildType 和 flavor 组合生成 Variant。
- 大量 flavor 会增加构建矩阵复杂度，要控制维度和依赖差异。

深挖追问：

- flavorDimension 是什么？
- manifestPlaceholders 如何使用？
- 不同环境 API 地址应该放哪里？

常见误区：

- 用 flavor 承担所有环境配置，导致构建变慢且维护困难。

## Q: Android 项目模块化有什么收益和代价？

标签：工程化 / 架构 / 场景题

复习状态：未掌握

考察点：

- 编译隔离。
- 依赖边界。
- 团队协作。

答案要点：

- 模块化能改善代码边界、提升并行开发能力，并在合理设计下改善增量编译。
- 常见拆分方式包括基础库、业务模块、功能模块、动态特性模块。
- 代价是依赖治理、版本管理、路由通信、资源命名和构建配置复杂度上升。
- 模块化应服务于业务边界和团队协作，不应为了拆而拆。

深挖追问：

- 模块之间如何通信？
- 如何避免公共模块膨胀？
- 组件化和插件化有什么区别？

常见误区：

- 认为模块越多越好。
- 依赖方向混乱导致循环依赖。

