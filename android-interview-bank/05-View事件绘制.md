# View / 事件 / 绘制

## Q: View 的绘制流程是什么？

标签：高频 / 基础 / View

复习状态：未掌握

考察点：

- measure、layout、draw。
- MeasureSpec。
- ViewGroup 与子 View 协作。

答案要点：

- View 绘制通常经历 measure、layout、draw 三个阶段。
- measure 决定尺寸，layout 决定位置，draw 负责绘制内容。
- ViewGroup 会测量和布局子 View，子 View 根据父容器传入的 MeasureSpec 计算自身尺寸。
- 自定义 View 要正确处理 wrap_content、padding、onMeasure 和 onDraw。

深挖追问：

- requestLayout 和 invalidate 有什么区别？
- MeasureSpec 三种模式是什么？
- 为什么 onDraw 里不要频繁创建对象？

常见误区：

- 以为 invalidate 会重新 measure。
- 自定义 View 不处理 wrap_content。

## Q: Android 事件分发机制如何工作？

标签：高频 / 易混 / View

复习状态：未掌握

考察点：

- dispatchTouchEvent。
- onInterceptTouchEvent。
- onTouchEvent。

答案要点：

- 事件从 Activity 分发到 Window、DecorView，再到 ViewGroup 和目标 View。
- ViewGroup 可在 onInterceptTouchEvent 中决定是否拦截子 View 事件。
- View 的 onTouchEvent 返回 true 表示消费后续事件。
- DOWN 事件决定后续事件链路，如果 DOWN 未被消费，后续 MOVE/UP 通常不会继续传给该 View。

深挖追问：

- 子 View 如何请求父 View 不拦截？
- 滑动冲突有哪些解决方式？
- ACTION_CANCEL 什么时候出现？

常见误区：

- 混淆分发、拦截、消费。
- 只背流程，不会分析嵌套滑动冲突。

## Q: RecyclerView 的缓存复用机制有哪些层次？

标签：高频 / 进阶 / 性能

复习状态：未掌握

考察点：

- ViewHolder 复用。
- 缓存层级。
- 局部刷新。

答案要点：

- RecyclerView 通过 ViewHolder 复用减少频繁创建 View 的成本。
- 缓存涉及屏幕内 View、临时分离 View、缓存 View、RecycledViewPool 等层次。
- notifyDataSetChanged 会导致粗粒度刷新，DiffUtil、ListAdapter 和 payload 可减少不必要绑定。
- 复杂列表应关注嵌套 RecyclerView、图片加载、预取和 item 布局层级。

深挖追问：

- payload 局部刷新怎么用？
- RecyclerView 嵌套滑动卡顿怎么查？
- RecycledViewPool 在多列表中有什么作用？

常见误区：

- 每次数据变化都全量刷新。
- 在 onBindViewHolder 中做耗时操作。

## Q: 自定义 View 时 onMeasure 应该注意什么？

标签：进阶 / View / 场景题

复习状态：未掌握

考察点：

- MeasureSpec。
- wrap_content。
- 最终尺寸设置。

答案要点：

- onMeasure 必须调用 setMeasuredDimension 设置最终测量尺寸。
- 要根据 MeasureSpec 的 EXACTLY、AT_MOST、UNSPECIFIED 处理父容器约束。
- 自定义 View 应给 wrap_content 提供合理默认尺寸。
- 尺寸计算要考虑 padding、最小尺寸和内容尺寸。

深挖追问：

- 自定义 ViewGroup 如何测量子 View？
- getMeasuredWidth 和 getWidth 有什么区别？
- 为什么测量可能执行多次？

常见误区：

- 直接使用固定尺寸，导致适配失败。
- 忽略 padding 导致内容被裁剪。

## Q: 属性动画和 View 动画有什么区别？

标签：基础 / 高频 / 动画

复习状态：未掌握

考察点：

- 渲染表现。
- 真实属性变化。
- 适用场景。

答案要点：

- View 动画只改变显示效果，不改变 View 的真实属性和点击区域。
- 属性动画会真实修改对象属性，例如 translationX、alpha、scale。
- 属性动画更灵活，可以作用于任意对象属性。
- 动画性能要关注过度绘制、布局触发和对象分配。

深挖追问：

- ObjectAnimator 如何找到属性 setter？
- 硬件加速对动画有什么影响？
- 动画导致点击区域异常可能是什么原因？

常见误区：

- 用 View 动画移动按钮后发现点击区域还在原地，却不知道原因。

