# 📚 **JUC 并发编程完全指南**

## 第一部分：并发基础与核心思想

### 第1章 并发编程的挑战
#### 1.1 为什么需要并发编程？
在现代多核CPU架构下，串行程序无法充分利用计算资源。并发编程让多个任务**看似同时**执行，提高系统吞吐量和响应速度。

#### 1.2 并发 vs 并行
- **并发**：多个任务交替执行（单核也能实现）
- **并行**：多个任务真正同时执行（需要多核）

#### 1.3 并发编程的三大挑战
1. **原子性问题** - 操作不可被中断
2. **可见性问题** - 一个线程的修改对其他线程可见
3. **有序性问题** - 编译器和处理器的重排序

---

## 第二部分：JUC核心组件详解

### 第2章 原子变量：无锁并发的基础

#### 2.1 什么是原子操作？
原子操作是**不可分割**的操作，要么完全成功，要么完全不执行。

```java
// 非原子操作的问题
int count = 0;
count++; // 实际包含3步：读取 → 修改 → 写入
```

#### 2.2 AtomicXXX 类族
原子类通过 **CAS（Compare-And-Swap）** 实现无锁线程安全：

| 类名 | 用途 | 特点 |
|------|------|------|
| `AtomicInteger` | 整数原子操作 | 最常用，适合计数器 |
| `AtomicLong` | 长整型原子操作 | 大数值场景 |
| `AtomicBoolean` | 布尔值原子操作 | 状态标志 |
| `AtomicReference<T>` | 引用类型原子操作 | 可包装任意对象 |
| `AtomicStampedReference` | 带版本号的引用 | 解决ABA问题 |

#### 2.3 CAS 原理深度解析
```java
// CAS 伪代码实现
public boolean compareAndSwap(int expectedValue, int newValue) {
    int currentValue = getCurrentValue(); // 读取当前值
    
    if (currentValue == expectedValue) {
        setValue(newValue); // 只有值未变时才更新
        return true;
    }
    return false;
}
```

**CAS 三大问题：**
1. **ABA问题** - 值从A→B→A，CAS无法感知变化
2. **自旋开销** - 竞争激烈时CPU消耗大
3. **只能保护一个变量** - 多个变量需要额外同步

### 第3章 显式锁：更灵活的同步机制

#### 3.1 ReentrantLock：可重入锁
```java
public class BankAccount {
    private final ReentrantLock lock = new ReentrantLock();
    private double balance;
    
    public void deposit(double amount) {
        lock.lock(); // 获取锁
        try {
            balance += amount;
        } finally {
            lock.unlock(); // 确保释放
        }
    }
}
```

#### 3.2 锁的特性对比表

| 特性 | synchronized | ReentrantLock |
|------|--------------|---------------|
| 可中断 | ❌ 不支持 | ✅ lockInterruptibly() |
| 超时等待 | ❌ 不支持 | ✅ tryLock(timeout) |
| 公平锁 | ❌ 非公平 | ✅ 可选公平/非公平 |
| 多条件队列 | ❌ 单一 | ✅ 多个Condition |
| 锁绑定 | 方法/代码块 | 任意代码块 |

#### 3.3 读写锁：读多写少的优化
```java
public class Cache<K, V> {
    private final Map<K, V> map = new HashMap<>();
    private final ReadWriteLock lock = new ReentrantReadWriteLock();
    
    public V get(K key) {
        lock.readLock().lock();
        try {
            return map.get(key);
        } finally {
            lock.readLock().unlock();
        }
    }
    
    public void put(K key, V value) {
        lock.writeLock().lock();
        try {
            map.put(key, value);
        } finally {
            lock.writeLock().unlock();
        }
    }
}
```

### 第4章 线程池：高效管理线程生命周期

#### 4.1 为什么需要线程池？
- **资源复用**：避免频繁创建/销毁线程
- **控制并发**：防止系统过载
- **统一管理**：提供监控和统计功能

#### 4.2 ThreadPoolExecutor 七大参数详解

```java
ThreadPoolExecutor executor = new ThreadPoolExecutor(
    // 1. 核心线程数：线程池的基本大小
    2,
    // 2. 最大线程数：线程池允许的最大线程数
    4,
    // 3. 空闲线程存活时间：非核心线程空闲时的存活时间
    60L, TimeUnit.SECONDS,
    // 4. 工作队列：存放待执行任务
    new LinkedBlockingQueue<>(100),
    // 5. 线程工厂：创建新线程
    Executors.defaultThreadFactory(),
    // 6. 拒绝策略：队列满且线程达到最大时的处理策略
    new ThreadPoolExecutor.CallerRunsPolicy()
);
```

#### 4.3 线程池工作流程图解

```
新任务提交
    ↓
检查核心线程池是否已满？
    ├── 未满 → 创建核心线程执行
    ↓
   已满
    ↓
检查工作队列是否已满？
    ├── 未满 → 任务加入队列等待
    ↓
   已满
    ↓
检查线程池是否达到最大线程数？
    ├── 未满 → 创建临时线程执行
    ↓
   已满
    ↓
执行拒绝策略
```

#### 4.4 四种拒绝策略对比

| 策略 | 行为 | 适用场景 |
|------|------|----------|
| AbortPolicy | 抛出RejectedExecutionException | 严格要求任务必须执行 |
| CallerRunsPolicy | 由提交任务的线程自己执行 | 不希望丢失任务 |
| DiscardPolicy | 直接丢弃新任务 | 允许丢失部分任务 |
| DiscardOldestPolicy | 丢弃队列中最老的任务 | 新任务比老任务重要 |

### 第5章 并发集合：线程安全的容器

#### 5.1 ConcurrentHashMap：并发Map的最佳实践

**JDK 8+ 实现原理：**
- 分段锁 → **CAS + synchronized** 优化
- 读操作完全无锁
- 写操作只锁单个桶（Node）

```java
// 统计单词频率
public class WordCounter {
    private final ConcurrentHashMap<String, AtomicInteger> map = 
        new ConcurrentHashMap<>();
    
    public void add(String word) {
        map.computeIfAbsent(word, k -> new AtomicInteger()).incrementAndGet();
    }
}
```

#### 5.2 CopyOnWriteArrayList：读多写少的List

**实现原理：** 写时复制
- 读操作：直接读取，无需加锁
- 写操作：复制整个数组，在新数组上修改，然后替换引用

```java
// 监听器模式
public class EventManager {
    private final CopyOnWriteArrayList<Listener> listeners = 
        new CopyOnWriteArrayList<>();
    
    public void addListener(Listener listener) {
        listeners.add(listener);
    }
    
    public void fireEvent(Event event) {
        // 遍历时线程安全，即使有新的监听器加入
        for (Listener listener : listeners) {
            listener.onEvent(event);
        }
    }
}
```

### 第6章 同步工具类：线程协作的艺术

#### 6.1 CountDownLatch：等待多个任务完成
```java
public class ServiceInitializer {
    private final CountDownLatch latch = new CountDownLatch(3);
    
    public void initialize() throws InterruptedException {
        // 启动三个初始化任务
        new Thread(this::initDatabase).start();
        new Thread(this::initCache).start();
        new Thread(this::initConfig).start();
        
        // 等待所有初始化完成
        latch.await();
        System.out.println("所有服务初始化完成！");
    }
    
    private void initDatabase() {
        // ... 初始化数据库
        latch.countDown();
    }
}
```

#### 6.2 CyclicBarrier：多阶段任务同步
```java
public class DataProcessor {
    private final CyclicBarrier barrier;
    
    public DataProcessor(int parties) {
        barrier = new CyclicBarrier(parties, () -> {
            System.out.println("所有分片处理完成，开始合并结果");
        });
    }
    
    public void processPartition(List<Data> partition) {
        // 处理自己的分片
        process(partition);
        
        // 等待其他线程
        barrier.await();
        
        // 所有线程到达后继续执行
        mergeResults();
    }
}
```

#### 6.3 Semaphore：资源访问控制
```java
public class ConnectionPool {
    private final Semaphore semaphore;
    private final List<Connection> connections;
    
    public ConnectionPool(int size) {
        semaphore = new Semaphore(size);
        connections = createConnections(size);
    }
    
    public Connection getConnection() throws InterruptedException {
        semaphore.acquire(); // 获取许可证
        return getAvailableConnection();
    }
    
    public void releaseConnection(Connection conn) {
        returnConnection(conn);
        semaphore.release(); // 释放许可证
    }
}
```

### 第7章 CompletableFuture：现代异步编程

#### 7.1 从Future到CompletableFuture
传统的Future只能通过get()阻塞获取结果，CompletableFuture提供了回调式编程模型。

```java
// 传统Future
ExecutorService executor = Executors.newFixedThreadPool(2);
Future<Integer> future = executor.submit(() -> {
    Thread.sleep(1000);
    return 42;
});
Integer result = future.get(); // 阻塞！

// CompletableFuture
CompletableFuture.supplyAsync(() -> {
        Thread.sleep(1000);
        return 42;
    })
    .thenApply(r -> r * 2)      // 非阻塞转换
    .thenAccept(System.out::println) // 非阻塞消费
    .exceptionally(ex -> {
        System.err.println("错误: " + ex.getMessage());
        return null;
    });
```

#### 7.2 常用的组合操作
```java
// 组合多个Future
CompletableFuture<String> future1 = fetchUserInfo(userId);
CompletableFuture<String> future2 = fetchUserOrders(userId);

// 两个都完成后执行
future1.thenCombine(future2, (info, orders) -> 
    "用户信息: " + info + ", 订单: " + orders);

// 任意一个完成就执行
CompletableFuture.anyOf(future1, future2)
    .thenAccept(result -> System.out.println("第一个完成的结果: " + result));

// 所有都完成后执行
CompletableFuture.allOf(future1, future2)
    .thenRun(() -> System.out.println("所有任务完成"));
```

---

## 第三部分：底层原理与高级特性

### 第8章 AQS：JUC的基石

#### 8.1 AQS核心设计
**AbstractQueuedSynchronizer** 是所有同步器的基类，核心思想：
- 维护一个 **state** 表示资源状态
- 通过 **CLH队列** 管理等待线程
- 提供 **模板方法模式** 让子类实现

#### 8.2 自定义同步器示例
```java
public class SimpleLock extends AbstractQueuedSynchronizer {
    
    // 尝试获取锁
    @Override
    protected boolean tryAcquire(int acquires) {
        // CAS设置state从0到1
        return compareAndSetState(0, 1);
    }
    
    // 尝试释放锁
    @Override
    protected boolean tryRelease(int releases) {
        setState(0);
        return true;
    }
    
    public void lock() {
        acquire(1);
    }
    
    public void unlock() {
        release(1);
    }
}
```

### 第9章 内存模型与volatile

#### 9.1 Java内存模型（JMM）
JMM定义了线程如何与内存交互，核心概念：
- **主内存**：所有线程共享
- **工作内存**：每个线程私有
- **happens-before**：保证操作的有序性

#### 9.2 volatile的作用
```java
public class Singleton {
    // 双重检查锁定模式
    private static volatile Singleton instance;
    
    public static Singleton getInstance() {
        if (instance == null) {                    // 第一次检查
            synchronized (Singleton.class) {
                if (instance == null) {            // 第二次检查
                    instance = new Singleton();    // 需要volatile防止重排序
                }
            }
        }
        return instance;
    }
}
```

**volatile的三大保证：**
1. **可见性**：写操作立即对其他线程可见
2. **有序性**：禁止指令重排序
3. **不保证原子性**：复合操作仍需同步

---

## 第四部分：最佳实践与避坑指南

### 第10章 synchronized的正确使用

#### 10.1 常见误区速查表

| 场景 | 错误示例 | 问题 | 解决方案 |
|------|----------|------|----------|
| 保护静态变量 | `synchronized void increment()` | 锁实例，但变量是静态的 | 用`static synchronized` |
| 读写不一致 | `synchronized set()` + 无锁`get()` | 读不到最新值 | 读写都加锁或用volatile |
| 泄露内部状态 | 返回内部集合引用 | 外部可绕过锁修改 | 返回副本 |
| 锁粒度不当 | 锁整个方法但只有部分代码需要同步 | 性能差 | 缩小同步范围 |

#### 10.2 线程安全设计原则
1. **封装共享数据**：不要让数据"逃逸"
2. **不变性是安全的**：尽量使用不可变对象
3. **明确所有权**：谁创建、谁修改、谁负责同步
4. **文档化线程安全策略**：明确类的线程安全级别

### 第11章 性能优化技巧

#### 11.1 减少锁竞争
```java
// 优化前：粗粒度锁
public synchronized void process() {
    // 长时间操作
}

// 优化后：细粒度锁 + 锁分段
public void process() {
    // 无锁操作
    preProcess();
    
    synchronized (this) {
        // 最小化临界区
        updateState();
    }
    
    // 无锁操作
    postProcess();
}
```

#### 11.2 选择合适的工具
| 场景 | 推荐工具 | 理由 |
|------|----------|------|
| 高并发计数器 | `LongAdder` | 分段累加，减少竞争 |
| 读多写少缓存 | `ReadWriteLock` | 读读不互斥 |
| 频繁的小对象创建 | 对象池 + `ThreadLocal` | 减少GC压力 |
| 任务调度 | `ScheduledThreadPoolExecutor` | 替代Timer |

---

## 第五部分：实战案例

### 第12章 实现一个简单的连接池
```java
public class SimpleConnectionPool {
    private final BlockingQueue<Connection> pool;
    private final Semaphore available;
    private final List<Connection> allConnections;
    
    public SimpleConnectionPool(int size) {
        pool = new LinkedBlockingQueue<>(size);
        available = new Semaphore(size);
        allConnections = new ArrayList<>(size);
        
        for (int i = 0; i < size; i++) {
            Connection conn = createConnection();
            allConnections.add(conn);
            pool.offer(conn);
        }
    }
    
    public Connection getConnection(long timeout, TimeUnit unit) 
            throws InterruptedException, TimeoutException {
        if (available.tryAcquire(timeout, unit)) {
            Connection conn = pool.poll(2, TimeUnit.SECONDS);
            if (conn != null) {
                return new PooledConnection(conn);
            }
            available.release();
        }
        throw new TimeoutException("获取连接超时");
    }
    
    private class PooledConnection implements Connection {
        private final Connection delegate;
        private volatile boolean closed = false;
        
        public PooledConnection(Connection delegate) {
            this.delegate = delegate;
        }
        
        @Override
        public void close() {
            if (!closed) {
                closed = true;
                pool.offer(delegate);
                available.release();
            }
        }
    }
}
```

### 第13章 高性能缓存实现
```java
public class ConcurrentCache<K, V> {
    private final ConcurrentHashMap<K, FutureTask<V>> cache = 
        new ConcurrentHashMap<>();
    private final ExecutorService executor = 
        Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
    
    public V get(K key, Callable<V> loader) throws Exception {
        while (true) {
            FutureTask<V> future = cache.get(key);
            
            if (future == null) {
                FutureTask<V> newTask = new FutureTask<>(loader);
                future = cache.putIfAbsent(key, newTask);
                
                if (future == null) {
                    future = newTask;
                    executor.execute(newTask);
                }
            }
            
            try {
                return future.get();
            } catch (CancellationException e) {
                cache.remove(key, future);
            } catch (ExecutionException e) {
                cache.remove(key, future);
                throw e;
            }
        }
    }
}
```

---

## 附录：速查表

### A. 选择指南：何时使用什么？

| 需求 | 推荐方案 | 替代方案 |
|------|----------|----------|
| 简单的状态标志 | `AtomicBoolean` | `volatile boolean` |
| 计数器 | `LongAdder` | `AtomicLong` |
| 缓存 | `ConcurrentHashMap` | `Collections.synchronizedMap` |
| 任务队列 | `LinkedBlockingQueue` | `ConcurrentLinkedQueue` |
| 定时任务 | `ScheduledThreadPoolExecutor` | `Timer` |
| 异步编排 | `CompletableFuture` | `Future` + 回调 |

### B. 常见问题诊断

| 症状 | 可能原因 | 解决方案 |
|------|----------|----------|
| CPU占用100% | 死循环、锁竞争、大量自旋 | 减少锁粒度、用阻塞代替自旋 |
| 内存泄漏 | 线程池未关闭、静态集合持有对象 | 使用弱引用、及时清理 |
| 死锁 | 锁顺序不一致、嵌套锁 | 统一锁顺序、使用tryLock |
| 响应慢 | 锁粒度太大、频繁上下文切换 | 减小临界区、调整线程池参数 |

---

## 后记

并发编程是一场平衡的艺术：
- **安全**与**性能**的平衡
- **简单**与**高效**的平衡
- **阻塞**与**非阻塞**的平衡

掌握JUC的核心思想比记住所有API更重要。从理解**可见性、原子性、有序性**开始，逐步深入各种同步工具的使用场景和实现原理，最终形成自己的并发编程思维模型。

记住：**没有最好的并发方案，只有最合适的并发方案。** 根据具体场景选择合适的工具，并在性能测试的指导下不断优化。

---

*这份指南将随着Java并发技术的发展而持续更新。欢迎提出改进建议，共同完善这份JUC完全指南。*