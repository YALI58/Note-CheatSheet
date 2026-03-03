## Java并发编程完全速查表（已补充）

### 一、线程基础速查

| 组件 | 作用 | 核心方法 | 示例代码 |
|------|------|----------|----------|
| **`Thread`** | 线程工人 | `start()`、`join()`、`sleep()` | `new Thread(() -> {}).start()` |
| **`Runnable`** | 无返回值任务 | `void run()` | `Runnable r = () -> System.out.println("task")` |
| **`Callable<V>`** | 有返回值任务 | `V call() throws Exception` | `Callable<Integer> c = () -> 42` |
| **`Future<V>`** | 异步结果 | `get()`、`isDone()`、`cancel()` | `Future<Integer> f = executor.submit(callable)` |

**💡 关键关系：`Runnable` 是 `Thread` 构造方法的参数**
```java
// Runnable 作为 Thread 构造方法的参数
Runnable task = () -> System.out.println("任务内容");
Thread thread = new Thread(task);  // ⭐ Runnable 作为参数传入
thread.start();

// Thread 类的相关构造方法
Thread(Runnable target)
Thread(Runnable target, String name)
Thread(ThreadGroup group, Runnable target)
```

---

### 二、线程池速查

#### 1. 创建方式对比

| 方式 | 代码 | 特点 | 风险 |
|------|------|------|------|
| **❌ Executors** | `Executors.newFixedThreadPool(10)` | 便捷但不安全 | 无界队列OOM |
| **✅ ThreadPoolExecutor** | `new ThreadPoolExecutor(...)` | 手动控制，推荐 | 无，需合理配置 |

#### 2. ThreadPoolExecutor 核心参数

```java
new ThreadPoolExecutor(
    int corePoolSize,      // 核心线程数（常驻）
    int maximumPoolSize,   // 最大线程数
    long keepAliveTime,    // 空闲线程存活时间
    TimeUnit unit,         // 时间单位
    BlockingQueue<Runnable> workQueue,     // 任务队列 ⭐
    ThreadFactory threadFactory,            // 线程工厂 ⭐
    RejectedExecutionHandler handler        // 拒绝策略 ⭐
)
```

#### 3. 线程池工作流程

```
提交任务 →
    ├─ 核心线程未满 → 创建核心线程执行
    ├─ 核心线程满 → 放入阻塞队列
    ├─ 队列满 → 创建非核心线程执行
    └─ 最大线程满 + 队列满 → 触发拒绝策略
```

---

### 三、阻塞队列速查 ⭐

| 队列类 | 特性 | 锁机制 | 是否有界 | 使用场景 |
|--------|------|--------|----------|----------|
| **`ArrayBlockingQueue`** | 数组实现 | **单锁** | ✅ 必须指定 | 有界、公平可选 |
| **`LinkedBlockingQueue`** | 链表实现 | **双锁** | ⚠️ 默认无界 | 吞吐量大 |
| **`SynchronousQueue`** | 不存元素 | CAS | 容量0 | 直接传递 |
| **`PriorityBlockingQueue`** | 优先级 | 单锁 | ⚠️ 无界 | 优先级任务 |
| **`DelayQueue`** | 延迟执行 | 单锁 | ⚠️ 无界 | 定时任务 |

**💡 关键记忆**：
- `LinkedBlockingQueue()` → **无界**（容量 `Integer.MAX_VALUE`）→ **可能OOM**
- `LinkedBlockingQueue(100)` → **有界** → **推荐**

---

### 四、线程工厂速查 ⭐

#### 1. 接口定义
```java
@FunctionalInterface
public interface ThreadFactory {
    Thread newThread(Runnable r);  // 唯一方法，参数也是 Runnable
}
```

#### 2. 自定义实现模板

```java
public class CustomThreadFactory implements ThreadFactory {
    private final String namePrefix;
    private final AtomicInteger threadNumber = new AtomicInteger(1);
    private final boolean daemon;
    private final int priority;
    private final Thread.UncaughtExceptionHandler handler;

    public CustomThreadFactory(String namePrefix) {
        this(namePrefix, false, Thread.NORM_PRIORITY, null);
    }

    public CustomThreadFactory(String namePrefix, boolean daemon, 
                              int priority, Thread.UncaughtExceptionHandler handler) {
        this.namePrefix = namePrefix;
        this.daemon = daemon;
        this.priority = priority;
        this.handler = handler;
    }

    @Override
    public Thread newThread(Runnable r) {  // ⭐ 参数是 Runnable
        Thread thread = new Thread(r, namePrefix + "-" + threadNumber.getAndIncrement());
        thread.setDaemon(daemon);
        thread.setPriority(priority);
        if (handler != null) thread.setUncaughtExceptionHandler(handler);
        return thread;
    }
}
```

#### 3. 使用示例
```java
// 创建线程工厂
ThreadFactory factory = new CustomThreadFactory("order-worker", false, 
                                               Thread.NORM_PRIORITY, 
                                               (t, e) -> log.error("线程异常", e));

// 在线程池中使用
ExecutorService executor = new ThreadPoolExecutor(
    5, 10, 60L, TimeUnit.SECONDS,
    new LinkedBlockingQueue<>(100),
    factory,  // ⭐ 传入工厂
    new ThreadPoolExecutor.AbortPolicy()
);
```

#### 4. Guava 快捷方式
```java
ThreadFactory factory = new ThreadFactoryBuilder()
    .setNameFormat("my-pool-%d")
    .setDaemon(false)
    .setPriority(Thread.NORM_PRIORITY)
    .setUncaughtExceptionHandler((t, e) -> log.error("线程异常", e))
    .build();
```

---

### 五、拒绝策略速查

| 策略 | 行为 | 使用场景 |
|------|------|----------|
| **`AbortPolicy`** | **抛异常**（默认） | 关键任务，失败需感知 |
| **`DiscardPolicy`** | 静默丢弃 | 不重要的任务 |
| **`DiscardOldestPolicy`** | 丢弃队列最旧，重试提交 | 旧任务可牺牲 |
| **`CallerRunsPolicy`** | 提交者线程自己执行 | 降级、慢速处理 |

---

### 六、并发工具速查

| 工具类 | 作用 | 核心方法 | 类似概念 |
|--------|------|----------|----------|
| **`CountDownLatch`** | 等待N个线程完成 | `countDown()`、`await()` | 门闩，一次性 |
| **`CyclicBarrier`** | N个线程互相等待 | `await()` | 栅栏，可循环 |
| **`Semaphore`** | 控制并发数 | `acquire()`、`release()` | 许可证 |
| **`Phaser`** | 分阶段同步 | `arrive()`、`awaitAdvance()` | 增强版屏障 |
| **`Exchanger`** | 线程间交换数据 | `exchange()` | 双向传输 |

---

### 七、原子类速查

| 类 | 作用 | 常用方法 |
|------|------|----------|
| **`AtomicInteger`** | 线程安全整数 | `getAndIncrement()`、`compareAndSet()` |
| **`AtomicLong`** | 线程安全长整型 | 同上 |
| **`AtomicBoolean`** | 线程安全布尔 | `compareAndSet()` |
| **`AtomicReference<V>`** | 线程安全对象 | `getAndSet()` |
| **`LongAdder`** | 高并发计数器 | `increment()`、`sum()` |

**💡 选择建议**：高并发计数用 `LongAdder`，一般场景用 `AtomicLong`

---

### 八、锁机制速查

| 锁类型 | 示例 | 特点 | 适用场景 |
|--------|------|------|----------|
| **`synchronized`** | `synchronized(obj){}` | JVM内置，自动释放 | 简单同步 |
| **`ReentrantLock`** | `lock.lock()` | API级别，可中断 | 高级同步需求 |
| **`ReentrantReadWriteLock`** | `readLock()`/`writeLock()` | 读写分离 | 读多写少 |
| **`StampedLock`** | `tryOptimisticRead()` | 乐观读 | 极高并发读 |

---

### 九、最佳实践速查（阿里巴巴规约）

| 规则 | 正确做法 | 错误做法 |
|------|----------|----------|
| **1. 线程池创建** | `new ThreadPoolExecutor(...)` | `Executors.newFixedThreadPool()` |
| **2. 阻塞队列** | `new LinkedBlockingQueue<>(100)` | `new LinkedBlockingQueue<>()` |
| **3. 线程名称** | 使用自定义ThreadFactory | 默认 `Thread-0` |
| **4. 异常处理** | 设置UncaughtExceptionHandler | 忽略线程异常 |
| **5. 线程关闭** | `shutdown()` + `awaitTermination()` | 不关闭 |
| **6. ThreadLocal** | 使用后 `remove()` | 不清理导致内存泄漏 |
| **7. 高并发计数** | `LongAdder` | `AtomicLong` |

---

### 十、完整示例：最佳实践组合

```java
public class BestPracticeExample {
    public static void main(String[] args) {
        // 1. 创建有界队列
        BlockingQueue<Runnable> queue = new LinkedBlockingQueue<>(100);
        
        // 2. 创建线程工厂（有意义名称 + 异常处理）
        ThreadFactory factory = new ThreadFactoryBuilder()
            .setNameFormat("biz-worker-%d")
            .setUncaughtExceptionHandler((t, e) -> {
                System.err.println("线程 " + t.getName() + " 异常: " + e);
            })
            .build();
        
        // 3. 手动创建线程池（核心参数明确）
        ThreadPoolExecutor executor = new ThreadPoolExecutor(
            5,                          // corePoolSize
            10,                         // maximumPoolSize
            60L, TimeUnit.SECONDS,       // keepAliveTime
            queue,                       // 有界队列 ⭐
            factory,                     // 自定义工厂 ⭐
            new ThreadPoolExecutor.CallerRunsPolicy() // 拒绝策略
        );
        
        // 4. 提交任务（Runnable 作为参数）
        executor.submit(() -> {  // ⭐ Lambda表达式本质是Runnable
            System.out.println("任务由 " + Thread.currentThread().getName() + " 执行");
        });
        
        // 5. 优雅关闭
        executor.shutdown();
        try {
            if (!executor.awaitTermination(60, TimeUnit.SECONDS)) {
                executor.shutdownNow();
            }
        } catch (InterruptedException e) {
            executor.shutdownNow();
        }
    }
}
```

---

### 十一、Runnable 作为参数的完整脉络 ⭐

```java
// 1. Thread 构造方法接收 Runnable
Thread(Runnable target)

// 2. ThreadFactory 的 newThread 方法接收 Runnable
ThreadFactory.newThread(Runnable r)

// 3. Executor 的 execute 方法接收 Runnable
Executor.execute(Runnable command)

// 4. 线程池的 submit 方法接收 Runnable
ExecutorService.submit(Runnable task)

// 5. 无处不在的 Runnable 参数
new Thread(() -> {})                    // Lambda → Runnable
executor.submit(() -> {})                // Lambda → Runnable
factory.newThread(() -> {})               // Lambda → Runnable
new ThreadPoolExecutor(..., queue)        // queue 的元素类型是 Runnable
```

**💡 核心总结**：Runnable 就像并发编程中的"通用货币"，所有需要执行的任务都以 Runnable 的形式传递，从最底层的 Thread 到上层的线程池，Runnable 始终是那个**被传递的参数**。

---

### 快速记忆口诀

```
线程基础要记牢，Runnable是参数
Thread构造传任务，ThreadFactory也一样
线程池，手动建，Executors有风险
阻塞队列要有界，无界队列内存险
线程工厂命名好，出了问题不难找
拒绝策略要选对，CallerRuns能保底
核心参数记心间，core,max和队列
线程用完要关闭，shutdown后等一等
```

这份速查表已经完整包含了Java并发编程的核心知识点，并特别强调了 **"Runnable是Thread构造方法的参数"** 这一关键关系。你可以保存下来，在实际开发中随时查阅！