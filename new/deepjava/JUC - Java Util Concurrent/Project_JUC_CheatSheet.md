```java

Stock实体类

AtomicInterger
AtomicLong
AtomicReference<T>
AtomicBoolean

CAS 交换
Atomicxxx.compareAndSet(A,B)
Atomicxxx的value与A进行比较，如果相等则与B进行交换，新值为B，过程是原子性的

交换逻辑使用循环:
当多个线程同时尝试更新highPrice时，只有一个线程的CAS操作会成功，其他线程的CAS会失败。失败的线程需要：  重新获取最新的highPrice值,重新尝试CAS更新

所有的get()都是原子性的
快照类，用于数据交换，不可变对象，线程安全

```

```java

CoucurrentHashMap,线程安全的HashMap
CopyOnWriteArrayList,读多写少的场景
ConcurrentLinkedQueue,无锁队列，适合生产者-消费者模式
LongAdder,高并发计数器
CoucurrentHashMap的putIfAbsent() 保证唯一性，防止重复注册

* 学习重点：ConcurrentHashMap的高级用法  
* - putIfAbsent：原子性的"不存在则添加"  
* - computeIfAbsent：延迟加载/缓存模式  
* - forEach：并行遍历  
* - reduce：并行归约  
* - search：并行搜索
  foreach 示例： 
  forEach(parallelismThreshold, action)  参数说明：  
  - parallelismThreshold：并行阈值（元素数超过此值才并行）  
  - action：对每个元素执行的操作  

```


```java
ThreadPoolFactory

* 学习重点：ThreadPoolExecutor的完整配置  
*  
* 核心参数详解：  
* 1. corePoolSize：核心线程数（一直存活）  
* 2. maximumPoolSize：最大线程数  
* 3. keepAliveTime：空闲线程存活时间  
* 4. workQueue：工作队列  
* 5. threadFactory：线程工厂  
* 6. handler：拒绝策略
  // 获取电脑的可使用的进程数量
  Runtime.getRuntime().availableProcessors(); 
  
  LinkedBlockingQueue<>(?) 填上问号就是有界队列(防止OOM)，不填上就是无界队列(有内存风险)
  
  ThreadPoolExecutor
  return new ThreadPoolExecutor(  
        corePoolSize,              // 核心线程数  
        maxPoolSize,               // 最大线程数  
        30L,                       // 空闲线程存活时间  
        TimeUnit.SECONDS,          // 时间单位  
        new LinkedBlockingQueue<>(), // 无界队列（注意内存风险）  
        new NamedThreadFactory("CPU-Worker"), // 线程工厂  
        new ThreadPoolExecutor.CallerRunsPolicy() // 拒绝策略：调用者执行  
);
  
ThreadFactory里有个newThread(Runnable r) 重写这个方法，ThreadPoolExecutor里会调用到ThreadFactory的newThread(this)方法
  
public class ThreadPoolExecutor {
    private final ThreadFactory threadFactory;
    
    // 线程池内部的工作者
    private class Worker implements Runnable {
        final Thread thread;
        
        Worker(Runnable firstTask) {
            // 看！这里自动调用了你的 newThread() 方法
            this.thread = getThreadFactory().newThread(this);
        }
    }
}
```



```java

AlertSystem CheatSheet:

```
# 🔥 Java并发锁机制速查表

## 📌 ReentrantLock系列

| 代码示例 | 技术点 | 说明 | 使用场景 |
|---------|-------|------|---------|
| `lock = new ReentrantLock(true)` | **公平锁** | `true`=公平锁(按等待时间),`false`=非公平锁(默认) | 避免线程饥饿，但性能较低 |
| `lock.lock()` | **阻塞获取锁** | 线程阻塞直到获取锁 | 必须保证锁最终被释放 |
| `lock.unlock()` | **释放锁** | 必须在finally块中释放 | 防止死锁 |
| `lock.tryLock()` | **非阻塞尝试** | 立即返回是否获取成功 | 不想无限等待的场景 |
| `lock.tryLock(100, ms)` | **限时等待锁** | 指定时间内等待锁 | 避免长时间阻塞 |
| `lock.newCondition()` | **创建条件变量** | 每个Condition对应一个等待队列 | 需要精确唤醒特定线程 |

## 📌 Condition条件变量

| 代码示例 | 技术点 | 说明 | 使用场景 |
|---------|-------|------|---------|
| `priceCondition.await()` | **等待** | 释放锁并等待，被唤醒后重新获取锁 | 等待条件满足 |
| `priceCondition.await(1, s)` | **限时等待** | 超时后自动唤醒 | 定期检查，避免永久等待 |
| `priceCondition.signal()` | **唤醒单个** | 随机唤醒一个等待线程 | 精确控制，避免惊群效应 |
| `priceCondition.signalAll()` | **唤醒全部** | 唤醒所有等待线程 | 状态变化影响所有等待线程 |

## 📌 ReadWriteLock读写锁

| 代码示例 | 技术点 | 说明 | 使用场景 |
|---------|-------|------|---------|
| `readLock().lock()` | **读锁** | 多个线程可同时持有 | 读多写少，数据不频繁变更 |
| `writeLock().lock()` | **写锁** | 独占锁，阻塞所有读写 | 需要修改共享数据时 |
| `readLock().unlock()` | **释放读锁** | - | - |
| `writeLock().unlock()` | **释放写锁** | - | - |

## 📌 StampedLock（JDK8+）

| 代码示例 | 技术点 | 说明 | 使用场景 |
|---------|-------|------|---------|
| `stampedLock.tryOptimisticRead()` | **乐观读** | 不加锁，返回stamp | 读操作多，写操作极少 |
| `stampedLock.validate(stamp)` | **验证版本** | 检查乐观读期间是否有写操作 | 乐观读后验证数据有效性 |
| `stampedLock.readLock()` | **悲观读** | 传统读锁 | validate失败后降级使用 |
| `stampedLock.unlockRead(stamp)` | **释放读锁** | - | - |

## 📌 Semaphore信号量

| 代码示例 | 技术点 | 说明 | 使用场景 |
|---------|-------|------|---------|
| `new Semaphore(5)` | **创建信号量** | 初始化5个许可 | 限流、资源池控制 |
| `semaphore.tryAcquire()` | **尝试获取** | 立即返回是否获取许可 | 快速失败，不等待 |
| `semaphore.acquire()` | **阻塞获取** | 无许可时阻塞 | 必须获取许可才能执行 |
| `semaphore.release()` | **释放许可** | 归还许可 | 必须在finally中确保释放 |

## 📌 并发集合

| 集合类 | 特性 | 说明 |
|--------|------|------|
| `ConcurrentHashMap` | 分段锁/无锁 | 高并发Map，线程安全 |
| `ConcurrentLinkedQueue` | CAS无锁队列 | 高性能线程安全队列 |
| `CopyOnWriteArrayList` | 写时复制 | 读多写极少，最终一致性 |


```java
// 标准锁使用模板
lock.lock();
try {
    // 业务逻辑
} finally {
    lock.unlock();  // 必须释放
}

// 条件等待模板
lock.lock();
try {
    while (!conditionMet()) {  // 防止虚假唤醒
        condition.await();
    }
    // 执行操作
} finally {
    lock.unlock();
}

// 读写锁使用
readLock.lock();  // 读锁可共享
try {
    // 读取数据
} finally {
    readLock.unlock();
}
```

