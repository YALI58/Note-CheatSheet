# 📊 Java并发工具速查表

## 一、AtomicInteger - 原子计数器

| 项目       | 内容                   |
| -------- | -------------------- |
| **是什么**  | 线程安全的整数计数器           |
| **为什么用** | 解决并发环境下`i++`计数不准确的问题 |
| **生活类比** | 奶茶店的专业计数器，多人同时按也不会乱  |

### 核心方法
```java
AtomicInteger count = new AtomicInteger(0);

count.incrementAndGet();  // +1并返回新值 (++count)
count.getAndIncrement();  // 返回旧值再+1 (count++)
count.decrementAndGet();  // -1并返回新值
count.addAndGet(5);       // +5并返回新值
count.get();              // 获取当前值
count.set(10);            // 设置为10
count.compareAndSet(期望值, 新值);  // 只有等于期望值才更新
```

### 代码模板
```java
public class Counter {
    private AtomicInteger count = new AtomicInteger(0);
    
    public void increment() {
        int newValue = count.incrementAndGet();
        System.out.println("当前值: " + newValue);
    }
    
    public int getCount() {
        return count.get();
    }
}
```

---

## 二、CountDownLatch - 倒计时门闩

| 项目 | 内容 |
|------|------|
| **是什么** | 一个线程等待其他N个线程完成后再执行的同步器 |
| **为什么用** | 主线程需要等待多个子任务都完成才能继续 |
| **生活类比** | 等所有顾客的奶茶都做好，才一起叫号取餐 |
| **特点** | ⚠️ 一次性使用，计数器归零后不能重置 |

### 核心方法
```java
CountDownLatch latch = new CountDownLatch(3);  // 初始化计数器=3

latch.countDown();  // 计数器减1（每个任务完成时调用）
latch.await();      // 等待计数器变为0（可中断）
latch.await(30, TimeUnit.SECONDS);  // 限时等待，超时返回false
latch.getCount();   // 获取当前剩余计数
```

### 代码模板
```java
public class BatchProcessor {
    public void processBatch(List<String> tasks) {
        CountDownLatch latch = new CountDownLatch(tasks.size());
        
        for (String task : tasks) {
            new Thread(() -> {
                try {
                    // 执行任务
                    System.out.println("处理: " + task);
                    Thread.sleep(1000);
                } catch (Exception e) {
                    e.printStackTrace();
                } finally {
                    latch.countDown();  // 必须在finally中调用！
                }
            }).start();
        }
        
        try {
            // 等待所有任务完成（最多等10秒）
            if (latch.await(10, TimeUnit.SECONDS)) {
                System.out.println("全部完成！");
            } else {
                System.out.println("超时，剩余: " + latch.getCount());
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

---

## 三、CyclicBarrier - 循环栅栏

| 项目 | 内容 |
|------|------|
| **是什么** | 让一组线程互相等待，全部到达后再一起继续执行 |
| **为什么用** | 分阶段计算，每个阶段都需要所有线程同步 |
| **生活类比** | 旅游团互相等，人齐了才去下一个景点 |
| **特点** | ✅ 可循环使用，计数器会自动重置 |

### 核心方法
```java
// 构造函数
CyclicBarrier barrier = new CyclicBarrier(3);  // 等待3个线程
CyclicBarrier barrier2 = new CyclicBarrier(3, () -> {
    System.out.println("所有人都到了，执行回调");
});

barrier.await();              // 等待其他人
barrier.await(5, TimeUnit.SECONDS);  // 限时等待
barrier.reset();              // 手动重置栅栏
barrier.getParties();         // 获取需要的线程数
barrier.getNumberWaiting();   // 获取当前等待的线程数
```

### 代码模板
```java
public class PhasedTask {
    public void runPhasedTasks() {
        CyclicBarrier barrier = new CyclicBarrier(3, () -> {
            System.out.println("=== 阶段完成，开始下一阶段 ===");
        });
        
        for (int i = 0; i < 3; i++) {
            new Thread(() -> {
                try {
                    // 阶段1
                    System.out.println(Thread.currentThread().getName() + " 执行阶段1");
                    Thread.sleep(1000);
                    barrier.await();  // 等待其他人完成阶段1
                    
                    // 阶段2
                    System.out.println(Thread.currentThread().getName() + " 执行阶段2");
                    Thread.sleep(1000);
                    barrier.await();  // 等待其他人完成阶段2
                    
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
}
```

---

## 四、CompletableFuture - 异步任务编排

| 项目 | 内容 |
|------|------|
| **是什么** | Java 8引入的异步编程API，支持链式调用和任务组合 |
| **为什么用** | 解决Future阻塞问题，实现复杂的异步流程控制 |
| **生活类比** | 点外卖：接单→做餐→配送→送达，每一步完成后自动下一步 |

### 核心方法速查

#### 1. 创建异步任务
```java
// 无返回值
CompletableFuture.runAsync(() -> {
    System.out.println("执行任务");
});

// 有返回值
CompletableFuture.supplyAsync(() -> {
    return "结果";
});

// 指定线程池
CompletableFuture.supplyAsync(() -> "结果", threadPool);
```

#### 2. 结果处理
```java
// 转换结果（有返回值）
thenApply(result -> result + "处理后")

// 消费结果（无返回值）
thenAccept(result -> System.out.println(result))

// 执行Runnable（不关心结果）
thenRun(() -> System.out.println("完成"))

// 同时消费结果和异常
whenComplete((result, ex) -> {
    if (ex != null) System.out.println("异常");
    else System.out.println(result);
})
```

#### 3. 组合多个Future
```java
// 等待所有完成
CompletableFuture.allOf(f1, f2, f3).thenRun(() -> {})

// 等待任意一个完成
CompletableFuture.anyOf(f1, f2, f3).thenAccept(result -> {})

// 合并两个的结果
f1.thenCombine(f2, (r1, r2) -> r1 + r2)

// 一个完成后执行另一个（依赖关系）
f1.thenCompose(result -> CompletableFuture.supplyAsync(() -> result + "再处理"))
```

#### 4. 异常处理
```java
// 异常时返回默认值
exceptionally(ex -> "默认值")

// 无论成功失败都执行
handle((result, ex) -> {
    if (ex != null) return "错误";
    else return result;
})
```

### 代码模板
```java
public class AsyncProcessor {
    private ExecutorService pool = Executors.newFixedThreadPool(10);
    
    public CompletableFuture<String> process(String input) {
        return CompletableFuture.supplyAsync(() -> {
            // 第一阶段
            return step1(input);
        }, pool).thenApply(result1 -> {
            // 第二阶段（依赖第一阶段）
            return step2(result1);
        }).thenApply(result2 -> {
            // 第三阶段
            return step3(result2);
        }).exceptionally(ex -> {
            // 异常处理
            System.err.println("出错: " + ex.getMessage());
            return "默认值";
        });
    }
    
    // 并行执行多个任务
    public CompletableFuture<Map<String, String>> parallelProcess() {
        CompletableFuture<String> f1 = CompletableFuture.supplyAsync(() -> task1());
        CompletableFuture<String> f2 = CompletableFuture.supplyAsync(() -> task2());
        CompletableFuture<String> f3 = CompletableFuture.supplyAsync(() -> task3());
        
        return CompletableFuture.allOf(f1, f2, f3)
            .thenApply(v -> {
                Map<String, String> results = new HashMap<>();
                try {
                    results.put("task1", f1.get());
                    results.put("task2", f2.get());
                    results.put("task3", f3.get());
                } catch (Exception e) {
                    e.printStackTrace();
                }
                return results;
            });
    }
}
```

---

## 五、对比总结表

| 特性 | AtomicInteger | CountDownLatch | CyclicBarrier | CompletableFuture |
|------|--------------|----------------|---------------|-------------------|
| **用途** | 并发计数 | 等待多个任务 | 多阶段同步 | 复杂异步编排 |
| **是否可重用** | ✅ 是 | ❌ 否 | ✅ 是 | 每个实例独立 |
| **等待方向** | - | 单向等待 | 互相等待 | 任意组合 |
| **复杂度** | ⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **学习曲线** | 平缓 | 平缓 | 中等 | 陡峭 |
| **常用方法** | incrementAndGet() | countDown()/await() | await() | thenApply()/thenCombine() |

---

## 六、选择指南

```java
if (只需要并发计数) {
    // 使用 AtomicInteger
    new AtomicInteger(0);
    
} else if (只需要等待所有子任务完成) {
    // 使用 CountDownLatch
    new CountDownLatch(taskCount);
    
} else if (需要多阶段同步，且可循环使用) {
    // 使用 CyclicBarrier
    new CyclicBarrier(threadCount);
    
} else if (需要复杂的异步流程控制) {
    // 使用 CompletableFuture
    CompletableFuture.supplyAsync(() -> {});
}
```

## 七、常见陷阱

### CountDownLatch
- ❌ 忘记在finally中调用countDown() → 导致死等
- ❌ 初始化计数器设为0 → await()直接通过
- ✅ 必须设置超时时间，防止永久阻塞

### CyclicBarrier
- ❌ 线程数少于parties → 永远等不到
- ❌ 忘记处理BrokenBarrierException
- ✅ 考虑使用限时await()

### CompletableFuture
- ❌ 忘记指定线程池 → 使用公共ForkJoinPool
- ❌ 不处理异常 → 异常被吞掉
- ✅ 总是链式调用exceptionally()

---

**速查口诀**：
- AtomicInteger：计数就用它，并发不会差
- CountDownLatch：等任务完成，countDown要记清
- CyclicBarrier：分阶段等，循环可用
- CompletableFuture：异步编排，链式调用真方便







# 2.0
# Java 同步器（Synchronizer）详解

## 📚 什么是同步器？

**同步器**是Java并发编程中用于**协调多个线程之间的协作**的工具类。它们解决的核心问题是：**当多个线程需要相互等待、通信或协同完成某项任务时，如何确保它们能够有序、高效地工作**。

### 生活中的类比

想象一下**接力赛**：
- **CountDownLatch** = 发令枪：所有运动员等待枪响才能起跑
- **CyclicBarrier** = 接力区：所有运动员到达接力区才能交接棒
- **Semaphore** = 赛道限制：最多允许8条赛道同时使用
- **Phaser** = 多阶段比赛：预赛→半决赛→决赛，每个阶段运动员动态变化

## 🎯 五种核心同步器对比

| 同步器 | 核心机制 | 能否重置 | 参与者是否动态 | 主要用途 |
|--------|----------|----------|----------------|----------|
| **CountDownLatch** | 计数器减到0唤醒 | ❌ 不能 | ❌ 固定 | 等待一组事件发生 |
| **CyclicBarrier** | 线程到达屏障后等待 | ✅ 能 | ❌ 固定 | 多线程分阶段计算 |
| **Semaphore** | 许可证数量控制 | ✅ 能 | ✅ 动态 | 限流、资源池控制 |
| **Phaser** | 分阶段同步 | ✅ 能 | ✅ 动态 | 复杂多阶段任务 |
| **Exchanger** | 两两数据交换 | ✅ 能 | 固定2个 | 双线程数据交换 |

---

## 1️⃣ CountDownLatch（倒计时门闩）

### 工作原理
- 初始化时设置一个计数器
- 每个线程完成任务后调用`countDown()`使计数器减1
- 等待的线程调用`await()`阻塞，直到计数器变为0

### 代码示例

```java
public class CountDownLatchExample {
    
    /**
     * 场景：外卖配送系统
     * 需要等待所有骑手取餐完成，才能开始配送
     */
    public static void deliverySystem() throws InterruptedException {
        int riderCount = 3;
        CountDownLatch latch = new CountDownLatch(riderCount);
        
        System.out.println("餐厅开始备餐...");
        
        // 3个骑手同时取餐
        for (int i = 1; i <= riderCount; i++) {
            int riderId = i;
            new Thread(() -> {
                try {
                    System.out.println("骑手" + riderId + "正在取餐...");
                    Thread.sleep((long) (Math.random() * 3000)); // 模拟取餐时间
                    System.out.println("骑手" + riderId + "取餐完成");
                    
                    latch.countDown(); // 重要：计数器减1
                    
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }).start();
        }
        
        // 主线程等待所有骑手完成取餐
        System.out.println("配送中心等待所有骑手取餐...");
        latch.await(); // 阻塞直到计数器为0
        System.out.println("所有骑手已取餐，开始批量配送！");
    }
    
    public static void main(String[] args) throws InterruptedException {
        deliverySystem();
    }
}
```

### 输出结果
```
餐厅开始备餐...
配送中心等待所有骑手取餐...
骑手1正在取餐...
骑手2正在取餐...
骑手3正在取餐...
骑手2取餐完成
骑手1取餐完成
骑手3取餐完成
所有骑手已取餐，开始批量配送！
```

### 关键点
- **一次性使用**：计数器归零后不能重置
- **主从模式**：常用于一个线程等待多个线程
- **典型场景**：并行计算后汇总、服务启动等待依赖

---

## 2️⃣ CyclicBarrier（循环屏障）

### 工作原理
- 设置一个屏障点，指定需要等待的线程数
- 每个线程到达屏障时调用`await()`阻塞
- 当最后一个线程到达时，所有线程被唤醒
- 可以设置屏障触发的回调函数

### 代码示例

```java
public class CyclicBarrierExample {
    
    /**
     * 场景：团队旅游
     * 所有成员必须到达景点门口才能一起进入
     * 参观完一个景点后，继续前往下一个
     */
    public static void tourSystem() {
        int memberCount = 4;
        
        // 屏障触发时执行的回调（导游）
        Runnable tourGuide = () -> {
            System.out.println("========== 导游：全体集合完毕，开始参观！==========");
        };
        
        CyclicBarrier barrier = new CyclicBarrier(memberCount, tourGuide);
        
        // 创建4个游客线程
        for (int i = 1; i <= memberCount; i++) {
            int memberId = i;
            new Thread(() -> {
                try {
                    // 第一站：正门
                    Thread.sleep((long) (Math.random() * 2000));
                    System.out.println("游客" + memberId + "到达正门");
                    barrier.await(); // 等待其他游客
                    
                    // 第二站：展览馆
                    Thread.sleep((long) (Math.random() * 2000));
                    System.out.println("游客" + memberId + "到达展览馆");
                    barrier.await();
                    
                    // 第三站：纪念品店
                    Thread.sleep((long) (Math.random() * 2000));
                    System.out.println("游客" + memberId + "到达纪念品店");
                    barrier.await();
                    
                    System.out.println("游客" + memberId + "完成所有景点");
                    
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }).start();
        }
    }
    
    public static void main(String[] args) {
        tourSystem();
    }
}
```

### 输出结果
```
游客3到达正门
游客1到达正门
游客2到达正门
游客4到达正门
========== 导游：全体集合完毕，开始参观！==========
游客2到达展览馆
游客1到达展览馆
游客3到达展览馆
游客4到达展览馆
========== 导游：全体集合完毕，开始参观！==========
游客1到达纪念品店
游客4到达纪念品店
游客2到达纪念品店
游客3到达纪念品店
========== 导游：全体集合完毕，开始参观！==========
游客2完成所有景点
游客1完成所有景点
游客4完成所有景点
游客3完成所有景点
```

### 关键点
- **可循环使用**：计数器可重置，适合多阶段任务
- **相互等待**：所有线程到达后才能继续
- **典型场景**：分阶段计算、游戏大厅等待玩家

---

## 3️⃣ Semaphore（信号量）

### 工作原理
- 维护一组许可证（permits）
- 线程通过`acquire()`获取许可证，如果没有则阻塞
- 线程通过`release()`释放许可证
- 可以控制同时访问资源的线程数

### 代码示例

```java
public class SemaphoreExample {
    
    /**
     * 场景：停车场管理系统
     * 只有5个车位，超过的车辆必须等待
     */
    static class ParkingLot {
        private final Semaphore parkingSpaces;
        
        public ParkingLot(int spaces) {
            this.parkingSpaces = new Semaphore(spaces, true); // 公平模式
        }
        
        public void enter(String carNumber) {
            try {
                System.out.println(carNumber + " 等待车位...");
                parkingSpaces.acquire(); // 获取许可证
                
                System.out.println(carNumber + " 进入停车场，剩余车位：" + 
                    parkingSpaces.availablePermits());
                
                // 模拟停车时间
                Thread.sleep((long) (Math.random() * 5000));
                
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                // 离开停车场
                System.out.println(carNumber + " 离开停车场");
                parkingSpaces.release(); // 释放许可证
            }
        }
    }
    
    public static void main(String[] args) {
        ParkingLot parkingLot = new ParkingLot(3); // 3个车位
        
        // 模拟10辆车进入停车场
        for (int i = 1; i <= 10; i++) {
            String carNumber = "京A" + String.format("%03d", i);
            new Thread(() -> parkingLot.enter(carNumber)).start();
            
            // 车辆到达间隔
            try {
                Thread.sleep(500);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```

### 输出结果
```
京A001 等待车位...
京A001 进入停车场，剩余车位：2
京A002 等待车位...
京A002 进入停车场，剩余车位：1
京A003 等待车位...
京A003 进入停车场，剩余车位：0
京A004 等待车位...
京A001 离开停车场
京A004 进入停车场，剩余车位：0
京A002 离开停车场
京A005 进入停车场，剩余车位：0
...
```

### 关键点
- **限流作用**：控制并发访问数
- **公平/非公平**：可设置是否按等待顺序分配
- **典型场景**：数据库连接池、API限流

---

## 4️⃣ Phaser（阶段器）

### 工作原理
- 支持**多阶段**同步，每个阶段可以动态注册/注销参与者
- 每个阶段所有参与者到达后自动进入下一阶段
- 可以获取当前阶段数、参与者数

### 代码示例

```java
public class PhaserExample {
    
    /**
     * 场景：软件开发迭代
     * 需求分析 -> 开发 -> 测试 -> 发布
     * 每个阶段人数可以变化
     */
    static class SoftwareDevelopment extends Phaser {
        @Override
        protected boolean onAdvance(int phase, int registeredParties) {
            // 每个阶段完成时的回调
            switch (phase) {
                case 0:
                    System.out.println("========== 需求分析阶段完成，进入开发阶段 ==========");
                    return false; // 返回false表示继续下一个阶段
                case 1:
                    System.out.println("========== 开发阶段完成，进入测试阶段 ==========");
                    return false;
                case 2:
                    System.out.println("========== 测试阶段完成，进入发布阶段 ==========");
                    return false;
                case 3:
                    System.out.println("========== 项目成功发布！=========");
                    return true; // 返回true表示终止phaser
                default:
                    return true;
            }
        }
    }
    
    public static void main(String[] args) {
        SoftwareDevelopment phaser = new SoftwareDevelopment();
        phaser.register(); // 主线程注册
        
        System.out.println("项目启动，当前阶段：" + phaser.getPhase());
        
        // 需求分析阶段：产品经理+架构师
        new Thread(new Worker("产品经理", phaser)).start();
        new Thread(new Worker("架构师", phaser)).start();
        
        // 等待需求分析完成
        phaser.arriveAndAwaitAdvance();
        
        // 开发阶段：增加开发人员
        phaser.register(); // 增加测试人员
        new Thread(new Worker("后端开发", phaser)).start();
        new Thread(new Worker("前端开发", phaser)).start();
        
        phaser.arriveAndAwaitAdvance();
        
        // 测试阶段：增加测试人员，架构师退出
        phaser.register(); // 增加测试
        new Thread(new Worker("测试工程师", phaser)).start();
        
        phaser.arriveAndAwaitAdvance();
        
        // 发布阶段
        System.out.println("准备发布...");
        phaser.arriveAndAwaitAdvance();
        
        phaser.arriveAndDeregister(); // 主线程退出
    }
    
    static class Worker implements Runnable {
        private final String name;
        private final Phaser phaser;
        
        public Worker(String name, Phaser phaser) {
            this.name = name;
            this.phaser = phaser;
            phaser.register(); // 动态注册到phaser
        }
        
        @Override
        public void run() {
            try {
                // 需求分析阶段
                System.out.println(name + " 开始需求分析...");
                Thread.sleep((long) (Math.random() * 2000));
                System.out.println(name + " 完成需求分析");
                phaser.arriveAndAwaitAdvance(); // 到达并等待
                
                // 开发阶段
                System.out.println(name + " 开始开发...");
                Thread.sleep((long) (Math.random() * 3000));
                System.out.println(name + " 完成开发");
                phaser.arriveAndAwaitAdvance();
                
                // 测试阶段
                System.out.println(name + " 开始测试...");
                Thread.sleep((long) (Math.random() * 2000));
                System.out.println(name + " 完成测试");
                phaser.arriveAndAwaitAdvance();
                
                // 发布阶段
                System.out.println(name + " 参与发布");
                phaser.arriveAndAwaitAdvance();
                
                // 任务完成，注销
                phaser.arriveAndDeregister();
                
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }
    }
}
```

### 关键点
- **动态注册/注销**：`register()`和`arriveAndDeregister()`
- **多阶段管理**：自动管理阶段推进
- **典型场景**：复杂业务流程、多阶段并行计算

---

## 5️⃣ Exchanger（交换器）

### 工作原理
- 用于两个线程之间交换数据
- 第一个线程调用`exchange()`后阻塞
- 第二个线程调用`exchange()`时，两者交换数据

### 代码示例

```java
public class ExchangerExample {
    
    /**
     * 场景：生产-消费缓冲区交换
     * 生产者填满缓冲区后，与消费者的空缓冲区交换
     */
    public static void main(String[] args) {
        Exchanger<List<Integer>> exchanger = new Exchanger<>();
        
        // 生产者线程
        new Thread(() -> {
            List<Integer> buffer = new ArrayList<>();
            for (int i = 1; i <= 10; i++) {
                buffer.add(i);
                System.out.println("生产者生产: " + i);
                
                if (buffer.size() == 3) { // 缓冲区满
                    try {
                        System.out.println("生产者等待交换缓冲区...");
                        buffer = exchanger.exchange(buffer); // 交换缓冲区
                        System.out.println("生产者获得空缓冲区");
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
            }
        }).start();
        
        // 消费者线程
        new Thread(() -> {
            List<Integer> buffer = new ArrayList<>();
            for (int i = 1; i <= 10; i++) {
                if (buffer.isEmpty()) {
                    try {
                        System.out.println("消费者等待交换缓冲区...");
                        buffer = exchanger.exchange(buffer); // 交换缓冲区
                        System.out.println("消费者获得满缓冲区");
                    } catch (InterruptedException e) {
                        e.printStackTrace();
                    }
                }
                
                if (!buffer.isEmpty()) {
                    Integer data = buffer.remove(0);
                    System.out.println("消费者消费: " + data);
                }
            }
        }).start();
    }
}
```

### 输出结果
```
生产者生产: 1
生产者生产: 2
生产者生产: 3
生产者等待交换缓冲区...
消费者等待交换缓冲区...
消费者获得满缓冲区
生产者获得空缓冲区
消费者消费: 1
消费者消费: 2
消费者消费: 3
生产者生产: 4
...
```

### 关键点
- **双线程专用**：只能用于两个线程
- **同步交换**：双方都到达才能交换
- **典型场景**：流水线作业、数据同步处理

---

## 📊 实战选择指南

### 如何选择合适的同步器？

| 需求 | 推荐同步器 | 原因 |
|------|------------|------|
| 等待一组任务完成后继续 | CountDownLatch | 一次性等待，简单直接 |
| 多线程分阶段执行 | CyclicBarrier | 可重置，支持回调 |
| 控制并发访问数量 | Semaphore | 灵活限流，可动态调整 |
| 复杂多阶段，人数变化 | Phaser | 动态注册/注销，阶段管理 |
| 双线程数据交换 | Exchanger | 专门为此设计 |

### 组合使用示例

```java
public class CombinedSynchronizers {
    
    /**
     * 场景：批量数据处理系统
     * 1. Semaphore限流，同时最多处理5个批次
     * 2. CountDownLatch等待所有数据加载完成
     * 3. CyclicBarrier分阶段处理
     */
    public void processData() {
        Semaphore limiter = new Semaphore(5);
        CountDownLatch loader = new CountDownLatch(10);
        CyclicBarrier barrier = new CyclicBarrier(5, 
            () -> System.out.println("批次处理完成"));
        
        // 实现复杂的数据处理流程
    }
}
```

## 💡 核心总结

1. **同步器本质是协调工具**：不处理业务逻辑，只处理线程协作
2. **选择合适的同步器**：根据业务场景选择合适的工具
3. **注意异常处理**：始终在finally中释放资源
4. **避免死锁**：合理设置超时，避免无限等待
5. **理解底层原理**：基于AQS(AbstractQueuedSynchronizer)实现

# Java 同步器（Synchronizer）速查表

## 📊 一图看懂五大同步器

| 同步器 | 图标 | 核心机制 | 一句话记忆 |
|--------|------|----------|------------|
| **CountDownLatch** | ⏳ | 计数器减到0放行 | **"人等事"**：一个线程等N个事件完成 |
| **CyclicBarrier** | 🚧 | 人到齐了再出发 | **"人等人"**：N个线程互相等待 |
| **Semaphore** | 🎫 | 许可证数量控制 | **"限人流"**：控制同时访问的线程数 |
| **Phaser** | 🏃 | 分阶段动态注册 | **"分段跑"**：多阶段任务，人数可变 |
| **Exchanger** | 🤝 | 两两交换数据 | **"换情报"**：两个线程交换数据 |

---

## 🎯 核心API速查

### 1️⃣ CountDownLatch
```java
// 创建
CountDownLatch latch = new CountDownLatch(3);  // 计数器初始值3

// 等待线程
latch.await();                    // 阻塞直到0
latch.await(5, TimeUnit.SECONDS); // 超时等待

// 工作线程
latch.countDown();  // 计数器减1（必须在finally中调用）
```

### 2️⃣ CyclicBarrier
```java
// 创建
CyclicBarrier barrier = new CyclicBarrier(3);  // 3个线程互相等
CyclicBarrier barrier2 = new CyclicBarrier(3, () -> {
    System.out.println("人到齐了！");  // 屏障触发时的回调
});

// 使用
barrier.await();                    // 等待其他线程
barrier.await(5, TimeUnit.SECONDS); // 超时等待
barrier.reset();                     // 重置屏障（注意异常处理）
```

### 3️⃣ Semaphore
```java
// 创建
Semaphore semaphore = new Semaphore(5);      // 5个许可证，非公平
Semaphore semaphore2 = new Semaphore(5, true); // 公平模式

// 使用
semaphore.acquire();      // 获取1个许可证（可中断）
semaphore.acquire(2);     // 获取2个许可证
semaphore.tryAcquire();   // 尝试获取，失败立即返回
semaphore.release();      // 释放1个许可证
semaphore.release(2);     // 释放2个许可证

// 监控
int available = semaphore.availablePermits();  // 当前可用许可证
int queueLength = semaphore.getQueueLength();  // 等待线程数
```

### 4️⃣ Phaser
```java
// 创建
Phaser phaser = new Phaser();           // 初始注册数0
Phaser phaser2 = new Phaser(3);         // 初始注册数3

// 注册/注销
phaser.register();                       // 注册一个参与者
int phase = phaser.bulkRegister(5);      // 批量注册5个

// 到达同步
phaser.arrive();                         // 到达，不等待
phaser.arriveAndAwaitAdvance();          // 到达并等待
phaser.arriveAndDeregister();            // 到达并注销

// 查询
int phase = phaser.getPhase();            // 当前阶段数
int registered = phaser.getRegisteredParties(); // 已注册人数
int arrived = phaser.getArrivedParties(); // 已到达人数
int unarrived = phaser.getUnarrivedParties(); // 未到达人数
```

### 5️⃣ Exchanger
```java
// 创建
Exchanger<String> exchanger = new Exchanger<>();  // 泛型指定交换类型

// 使用
String received = exchanger.exchange(myData);      // 交换数据
String received2 = exchanger.exchange(myData, 5, TimeUnit.SECONDS); // 超时交换
```

---

## 📋 快速对比表

| 特性 | CountDownLatch | CyclicBarrier | Semaphore | Phaser | Exchanger |
|------|---------------|---------------|-----------|--------|-----------|
| **能否重置** | ❌ 不能 | ✅ 能 | ✅ 能 | ✅ 能 | ✅ 能 |
| **参与者动态** | ❌ 固定 | ❌ 固定 | ✅ 动态 | ✅ 动态 | 固定2个 |
| **等待方向** | 单向等待 | 互相等待 | 获取许可 | 互相等待 | 互相等待 |
| **回调函数** | ❌ 无 | ✅ 有 | ❌ 无 | ✅ 有 | ❌ 无 |
| **超时支持** | ✅ 支持 | ✅ 支持 | ✅ 支持 | ✅ 支持 | ✅ 支持 |
| **中断支持** | ✅ 支持 | ✅ 支持 | ✅ 支持 | ✅ 支持 | ✅ 支持 |
| **公平模式** | ❌ 不支持 | ❌ 不支持 | ✅ 支持 | ❌ 不支持 | ❌ 不支持 |

---

## 🎨 代码模板速查

### 场景1：主线程等待子任务完成
```java
// CountDownLatch模板
public void waitForTasks() {
    int taskCount = 5;
    CountDownLatch latch = new CountDownLatch(taskCount);
    
    for (int i = 0; i < taskCount; i++) {
        new Thread(() -> {
            try {
                // 执行业务
                doWork();
            } finally {
                latch.countDown();  // 必须放在finally
            }
        }).start();
    }
    
    latch.await();  // 等待所有任务完成
    System.out.println("所有任务完成");
}
```

### 场景2：多线程分阶段执行
```java
// CyclicBarrier模板
public void phasedExecution() {
    int threadCount = 3;
    CyclicBarrier barrier = new CyclicBarrier(threadCount, 
        () -> System.out.println("阶段完成"));
    
    for (int i = 0; i < threadCount; i++) {
        new Thread(() -> {
            try {
                // 阶段1
                phase1();
                barrier.await();
                
                // 阶段2
                phase2();
                barrier.await();
                
                // 阶段3
                phase3();
            } catch (Exception e) {
                // 处理BrokenBarrierException
            }
        }).start();
    }
}
```

### 场景3：限流控制
```java
// Semaphore模板
public class RateLimiter {
    private final Semaphore semaphore;
    
    public RateLimiter(int maxConcurrent) {
        this.semaphore = new Semaphore(maxConcurrent);
    }
    
    public void execute(Runnable task) {
        try {
            semaphore.acquire();
            try {
                task.run();
            } finally {
                semaphore.release();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
}
```

### 场景4：动态多阶段任务
```java
// Phaser模板
public void dynamicPhasedTasks() {
    Phaser phaser = new Phaser(1);  // 主线程注册
    
    // 动态添加参与者
    for (int i = 0; i < 3; i++) {
        new Thread(() -> {
            phaser.register();
            try {
                while (!phaser.isTerminated()) {
                    // 执行业务
                    doWork();
                    phaser.arriveAndAwaitAdvance();  // 等待阶段完成
                }
            } finally {
                phaser.arriveAndDeregister();  // 退出
            }
        }).start();
    }
    
    // 控制阶段推进
    for (int phase = 0; phase < 5; phase++) {
        System.out.println("开始阶段 " + phase);
        phaser.arriveAndAwaitAdvance();  // 进入下一阶段
    }
    
    phaser.arriveAndDeregister();  // 主线程退出
}
```

### 场景5：双线程数据交换
```java
// Exchanger模板
public void dataExchange() {
    Exchanger<Data> exchanger = new Exchanger<>();
    
    // 线程1
    new Thread(() -> {
        try {
            Data data1 = produceData();
            Data data2 = exchanger.exchange(data1);
            processData(data2);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();
    
    // 线程2
    new Thread(() -> {
        try {
            Data data1 = produceData();
            Data data2 = exchanger.exchange(data1);
            processData(data2);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }).start();
}
```

---

## ⚠️ 常见陷阱与最佳实践

| 陷阱 | 错误示例 | 正确做法 |
|------|----------|----------|
| **忘记countDown()** | `if(ok) return;` 直接返回 | 始终在finally中调用 |
| **屏障破坏** | 未处理BrokenBarrierException | 捕获异常并重置 |
| **许可证泄漏** | acquire后异常退出 | try-finally保证release |
| **Phaser死锁** | 注册数和到达数不匹配 | 确保arrive和register配对 |
| **超时设置** | 无限期等待 | 始终设置合理超时 |

```java
// 正确模板
public void safeCountDown() {
    CountDownLatch latch = new CountDownLatch(1);
    try {
        // 业务逻辑
    } finally {
        latch.countDown();  // 确保执行
    }
}

// 屏障保护
public void safeBarrier() {
    CyclicBarrier barrier = new CyclicBarrier(3);
    try {
        barrier.await(5, TimeUnit.SECONDS);
    } catch (TimeoutException e) {
        barrier.reset();  // 超时后重置
    } catch (BrokenBarrierException e) {
        barrier.reset();  // 屏障损坏后重置
    }
}
```

---

## 🔍 性能对比

| 同步器 | 适用并发量 | 性能特点 | 瓶颈 |
|--------|------------|----------|------|
| **CountDownLatch** | 任意 | 简单高效 | 一次性使用 |
| **CyclicBarrier** | < 1000 | 回调可能成瓶颈 | 所有线程互相等待 |
| **Semaphore** | 任意 | CAS操作高效 | 公平模式性能下降 |
| **Phaser** | 任意 | 比CyclicBarrier更灵活 | 动态注册有开销 |
| **Exchanger** | 2 | 极简高效 | 只能用于2线程 |

---

## 📚 记忆口诀

**"计循信相阶"**（记寻写信接？）

- **计** - CountDown**Latch**（计数器）
- **循** - **Cyclic**Barrier（可循环）
- **信** - **Semaphore**（信号量）
- **相** - E**xchanger**（相互交换）
- **阶** - **Phaser**（分阶段）

或者：
**"发令枪、接力棒、停车场、分段跑、换情报"**

---

这个速查表涵盖了：
- ✅ 五大同步器核心概念
- ✅ API快速参考
- ✅ 代码模板
- ✅ 陷阱与最佳实践
- ✅ 性能对比
- ✅ 记忆口诀






