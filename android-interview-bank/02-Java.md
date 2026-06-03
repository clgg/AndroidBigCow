# Java

## Q: HashMap 的底层结构是什么？为什么线程不安全？

标签：高频 / 基础 / 易混

复习状态：未掌握

考察点：

- 数组、链表、红黑树结构。
- 哈希冲突处理。
- 并发修改风险。

答案要点：

- HashMap 底层是数组加链表，JDK 8 后链表过长会转为红黑树。
- put 时会根据 key 的 hash 定位桶，桶内通过 equals 判断是否同一个 key。
- 线程不安全的核心原因是内部结构修改没有同步保护，并发 put、resize、链表或树结构调整可能导致数据覆盖、丢失或结构异常。
- 多线程场景应使用 ConcurrentHashMap，或者在外层加同步控制。

深挖追问：

- 为什么容量通常是 2 的幂？
- HashMap 和 ConcurrentHashMap 的扩容有什么区别？
- 红黑树什么时候退化回链表？

常见误区：

- 只说 HashMap 会死循环，不区分 JDK 版本。
- 以为 volatile 能解决 HashMap 的复合操作并发问题。

## Q: volatile 能保证什么？不能保证什么？

标签：高频 / 并发 / 易混

复习状态：未掌握

考察点：

- 可见性。
- 有序性。
- 原子性边界。

答案要点：

- volatile 保证变量写入后对其他线程可见。
- volatile 通过内存屏障限制特定指令重排序。
- volatile 不保证复合操作原子性，例如 `count++` 仍然包含读、改、写三个步骤。
- 状态标记、单例双重检查中的引用发布可以使用 volatile，但计数累加通常需要 AtomicInteger、锁或 LongAdder。

深挖追问：

- volatile 在双重检查锁单例中解决了什么问题？
- happens-before 和 volatile 有什么关系？
- volatile 和 synchronized 如何取舍？

常见误区：

- 把可见性等同于线程安全。
- 认为所有共享变量加 volatile 就足够。

## Q: synchronized 锁的是什么？锁升级过程是什么？

标签：高频 / 进阶 / JVM

复习状态：未掌握

考察点：

- 对象监视器。
- 锁粒度。
- 偏向锁、轻量级锁、重量级锁。

答案要点：

- synchronized 修饰实例方法时锁当前对象，修饰静态方法时锁 Class 对象，修饰代码块时锁括号中的对象。
- JVM 通过对象头 Mark Word 和 Monitor 实现锁。
- 常见锁状态包括无锁、偏向锁、轻量级锁、重量级锁，不同 JDK 版本对偏向锁支持不同。
- 锁升级是为了在不同竞争程度下平衡性能和安全，竞争激烈时会膨胀为重量级锁。

深挖追问：

- synchronized 和 ReentrantLock 有什么区别？
- wait/notify 为什么必须在 synchronized 中调用？
- 锁粗化和锁消除是什么？

常见误区：

- 以为 synchronized 一定很慢。
- 不区分锁对象，导致误判同步范围。

## Q: Java 线程池核心参数有哪些？如何配置？

标签：高频 / 场景题 / 并发

复习状态：未掌握

考察点：

- ThreadPoolExecutor 参数。
- CPU 密集型和 IO 密集型任务区别。
- 队列与拒绝策略。

答案要点：

- 核心参数包括 corePoolSize、maximumPoolSize、keepAliveTime、workQueue、threadFactory、handler。
- CPU 密集型任务线程数通常接近 CPU 核心数，IO 密集型任务可适当增加线程数。
- 队列类型会影响扩容策略，例如无界队列可能导致 maximumPoolSize 不生效，还可能堆积任务造成 OOM。
- 线上应自定义线程名、拒绝策略和监控指标。

深挖追问：

- 为什么不推荐直接使用 Executors.newCachedThreadPool？
- 线程池任务异常如何处理？
- Android 中线程池如何避免 Activity 泄漏？

常见误区：

- 使用无界队列但没有容量保护。
- 所有业务共用一个线程池，导致互相拖垮。

## Q: Java 引用类型有哪些？它们在 Android 内存优化中怎么用？

标签：进阶 / 内存 / 易混

复习状态：未掌握

考察点：

- 强引用、软引用、弱引用、虚引用。
- GC 可达性。
- Android 场景实践。

答案要点：

- 强引用只要可达就不会被回收。
- 软引用在内存不足时可能被回收，但在 Android 图片缓存中不如明确的 LruCache 稳定。
- 弱引用只要发生 GC 且没有强引用就可能被回收，常用于避免长生命周期对象强持有短生命周期对象。
- 虚引用主要用于回收跟踪，业务代码直接使用较少。

深挖追问：

- Handler 内存泄漏为什么常提到 WeakReference？
- LruCache 为什么比 SoftReference 图片缓存更可控？
- 弱引用一定能解决内存泄漏吗？

常见误区：

- 以为用了 WeakReference 就不会有泄漏。
- 混淆软引用和弱引用的回收时机。

