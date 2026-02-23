# 🏗️ 实战项目：**智能股票行情分析系统**

## 📈 项目概述

我将设计一个**模拟股票实时行情分析系统**，这个项目会全面运用JUC的核心类。你会学到：

1. **Atomic类**：股票价格实时更新
2. **ConcurrentHashMap**：管理股票数据
3. **线程池**：并行计算技术指标
4. **同步工具**：控制数据流和任务协调
5. **锁机制**：保证数据一致性
6. **并发集合**：高效数据存储

---

## 📁 项目结构

```
StockAnalysisSystem/
├── src/
│   ├── StockMarket.java           # 主程序入口
│   ├── model/
│   │   ├── Stock.java            # 股票实体类
│   │   └── Quote.java            # 行情报价类
│   ├── core/
│   │   ├── MarketDataStream.java # 模拟行情数据流
│   │   ├── StockRegistry.java    # 股票注册中心
│   │   ├── IndicatorCalculator.java # 技术指标计算
│   │   └── AlertSystem.java      # 价格预警系统
│   └── utils/
│       ├── ThreadPoolFactory.java # 线程池工厂
│       └── ConcurrentUtils.java   # 并发工具类
└── README.md
```

---

## 🚀 完整代码实现

### 1. **Stock.java** - 股票实体类（使用Atomic类）
```java
package model;

import java.util.concurrent.atomic.*;

/**
 * 股票实体类 - 演示Atomic类的使用
 * 核心特点：所有价格字段都使用原子类，保证多线程更新安全
 */
public class Stock {
    private final String symbol;          // 股票代码，如 "AAPL"
    private final String name;            // 股票名称
    
    // 🔥 AtomicInteger: 用于整数计数器（交易量、计数等）
    private final AtomicInteger volume = new AtomicInteger(0);       // 当日成交量
    
    // 🔥 AtomicLong: 用于大整数计数器（适合高频率更新）
    private final AtomicLong totalTrades = new AtomicLong(0);        // 总交易次数
    
    // 🔥 AtomicReference<Double>: 用于引用类型（价格数据）
    // Double是引用类型，需要用AtomicReference包装
    private final AtomicReference<Double> currentPrice = new AtomicReference<>(0.0);      // 当前价格
    private final AtomicReference<Double> highPrice = new AtomicReference<>(0.0);         // 当日最高价
    private final AtomicReference<Double> lowPrice = new AtomicReference<>(Double.MAX_VALUE); // 当日最低价
    
    // 🔥 AtomicBoolean: 用于状态标志
    private final AtomicBoolean isTrading = new AtomicBoolean(true);  // 是否在交易中
    
    public Stock(String symbol, String name, double initialPrice) {
        this.symbol = symbol;
        this.name = name;
        this.currentPrice.set(initialPrice);
        this.highPrice.set(initialPrice);
        this.lowPrice.set(initialPrice);
    }
    
    /**
     * 更新股票价格 - 演示AtomicReference的CAS操作
     * 
     * @param newPrice 新的价格
     * @param tradeVolume 本次交易的成交量
     * @return 是否更新成功（这里总是成功，实际可能加入业务判断）
     */
    public boolean updatePrice(double newPrice, int tradeVolume) {
        // 1. 使用原子方式更新当前价格
        currentPrice.set(newPrice);  // set()是原子操作
        
        // 2. 使用CAS方式更新最高价（更复杂的原子操作）
        updateHighPrice(newPrice);
        
        // 3. 使用CAS方式更新最低价
        updateLowPrice(newPrice);
        
        // 4. 使用addAndGet原子增加成交量
        volume.addAndGet(tradeVolume);
        
        // 5. 使用incrementAndGet原子增加交易次数
        totalTrades.incrementAndGet();
        
        return true;
    }
    
    /**
     * CAS更新最高价 - 演示compareAndSet的使用
     * 
     * 场景：多个线程同时更新，只有新价格比当前最高价高时才更新
     * 使用循环CAS保证原子性和正确性
     */
    private void updateHighPrice(double newPrice) {
        while (true) {
            Double currentHigh = highPrice.get();  // 获取当前最高价
            if (newPrice <= currentHigh) {
                break;  // 新价格不比当前高，不需要更新
            }
            
            // 🔥 compareAndSet(expect, update)
            // 参数1 expect: 期望的当前值（我们认为的当前值）
            // 参数2 update: 要设置的新值
            // 返回值: 如果当前值等于expect，则设置为update并返回true；否则返回false
            if (highPrice.compareAndSet(currentHigh, newPrice)) {
                // CAS成功，更新完成
                System.out.println(symbol + " 更新最高价: " + currentHigh + " -> " + newPrice);
                break;
            }
            // CAS失败，说明其他线程已经修改了highPrice，重新循环尝试
        }
    }
    
    /**
     * CAS更新最低价
     */
    private void updateLowPrice(double newPrice) {
        while (true) {
            Double currentLow = lowPrice.get();
            if (newPrice >= currentLow) {
                break;
            }
            if (lowPrice.compareAndSet(currentLow, newPrice)) {
                System.out.println(symbol + " 更新最低价: " + currentLow + " -> " + newPrice);
                break;
            }
        }
    }
    
    /**
     * 获取当前价格（原子读）
     */
    public double getCurrentPrice() {
        return currentPrice.get();  // get()是原子操作
    }
    
    /**
     * 获取并重置成交量 - 演示getAndSet的使用
     * 
     * @return 重置前的成交量
     * 
     * 🔥 getAndSet(newValue) 方法：
     * 1. 原子地获取当前值
     * 2. 原子地设置为新值
     * 3. 返回获取到的旧值
     * 
     * 场景：每日收盘时获取当日成交量，然后重置为0
     */
    public int getAndResetVolume() {
        return volume.getAndSet(0);  // 获取当前值，然后设置为0
    }
    
    /**
     * 尝试暂停交易 - 演示AtomicBoolean的CAS操作
     * 
     * @return 是否成功暂停（从交易中变为暂停）
     */
    public boolean tryPauseTrading() {
        // 🔥 compareAndSet(expect, update)
        // 期望当前是true（正在交易），设置为false（暂停）
        return isTrading.compareAndSet(true, false);
    }
    
    /**
     * 恢复交易
     */
    public boolean resumeTrading() {
        return isTrading.compareAndSet(false, true);
    }
    
    /**
     * 获取股票快照（线程安全的方法）
     */
    public StockSnapshot getSnapshot() {
        return new StockSnapshot(
            symbol,
            name,
            currentPrice.get(),
            highPrice.get(),
            lowPrice.get(),
            volume.get(),
            totalTrades.get(),
            isTrading.get()
        );
    }
    
    // 快照类，用于数据传递
    public static class StockSnapshot {
        public final String symbol;
        public final String name;
        public final double currentPrice;
        public final double highPrice;
        public final double lowPrice;
        public final int volume;
        public final long totalTrades;
        public final boolean isTrading;
        
        public StockSnapshot(String symbol, String name, double currentPrice,
                           double highPrice, double lowPrice, int volume,
                           long totalTrades, boolean isTrading) {
            this.symbol = symbol;
            this.name = name;
            this.currentPrice = currentPrice;
            this.highPrice = highPrice;
            this.lowPrice = lowPrice;
            this.volume = volume;
            this.totalTrades = totalTrades;
            this.isTrading = isTrading;
        }
    }
    
    // Getters
    public String getSymbol() { return symbol; }
    public String getName() { return name; }
    public boolean isTrading() { return isTrading.get(); }
}
```

### 2. **StockRegistry.java** - 股票注册中心（使用ConcurrentHashMap）
```java
package core;

import model.Stock;
import java.util.*;
import java.util.concurrent.*;

/**
 * 股票注册中心 - 演示ConcurrentHashMap的高级用法
 * 管理所有股票信息，提供线程安全的CRUD操作
 */
public class StockRegistry {
    
    // 🔥 ConcurrentHashMap: 线程安全的哈希表
    // Key: 股票代码, Value: Stock对象
    private final ConcurrentHashMap<String, Stock> stockMap = new ConcurrentHashMap<>();
    
    // 🔥 CopyOnWriteArrayList: 读多写少的线程安全列表
    // 存储股票代码列表，频繁遍历，很少修改
    private final CopyOnWriteArrayList<String> stockSymbols = new CopyOnWriteArrayList<>();
    
    // 🔥 ConcurrentLinkedQueue: 无界线程安全队列
    // 用于记录价格更新日志（生产消费模型）
    private final ConcurrentLinkedQueue<PriceUpdateLog> updateLogQueue = new ConcurrentLinkedQueue<>();
    
    // 🔥 LongAdder: 高性能计数器
    private final LongAdder totalUpdates = new LongAdder();  // 总更新次数
    
    /**
     * 注册新股票 - 演示putIfAbsent的使用
     * 
     * 🔥 putIfAbsent(key, value) 方法：
     * 1. 如果key不存在，则放入key-value，返回null
     * 2. 如果key已存在，不覆盖，返回已存在的value
     * 
     * 场景：防止重复注册同一只股票
     */
    public boolean registerStock(Stock stock) {
        String symbol = stock.getSymbol();
        
        // 使用putIfAbsent保证股票代码唯一性
        Stock existing = stockMap.putIfAbsent(symbol, stock);
        
        if (existing == null) {
            // 注册成功，添加到代码列表
            stockSymbols.add(symbol);
            System.out.println("注册股票成功: " + symbol + " - " + stock.getName());
            return true;
        } else {
            System.out.println("股票已存在: " + symbol);
            return false;
        }
    }
    
    /**
     * 批量更新股票价格 - 演示forEach的并行处理
     * 
     * @param updates Map<股票代码, 新价格>
     */
    public void batchUpdatePrices(Map<String, Double> updates) {
        // 🔥 forEach 并行遍历
        // parallelismThreshold: 并行阈值，当元素数量超过这个值时使用并行处理
        // action: 对每个元素执行的操作 (key, value) -> {}
        updates.forEach((symbol, newPrice) -> {
            Stock stock = stockMap.get(symbol);
            if (stock != null && stock.isTrading()) {
                // 模拟交易量（1-100手）
                int volume = ThreadLocalRandom.current().nextInt(1, 101);
                stock.updatePrice(newPrice, volume);
                
                // 记录更新日志
                updateLogQueue.offer(new PriceUpdateLog(symbol, newPrice, volume));
                totalUpdates.increment();
            }
        });
    }
    
    /**
     * 获取股票信息 - 演示computeIfAbsent的使用
     * 
     * 🔥 computeIfAbsent(key, mappingFunction) 方法：
     * 1. 如果key存在，返回对应的value
     * 2. 如果key不存在，使用mappingFunction计算value，放入map，返回计算的值
     * 
     * 场景：延迟加载/缓存模式
     */
    public Stock getOrCreateStock(String symbol) {
        return stockMap.computeIfAbsent(symbol, sym -> {
            // 只有当股票不存在时，才会执行这个函数
            System.out.println("自动创建股票: " + sym);
            
            // 生成随机初始价格（50-200）
            double initialPrice = 50 + ThreadLocalRandom.current().nextDouble(150);
            
            // 生成随机股票名称
            String name = "自动生成-" + sym;
            
            Stock newStock = new Stock(sym, name, initialPrice);
            stockSymbols.add(sym);
            return newStock;
        });
    }
    
    /**
     * 获取价格最高的N只股票 - 演示并行流处理
     */
    public List<Stock.StockSnapshot> getTopStocksByPrice(int n) {
        return stockMap.values().parallelStream()  // 🔥 并行流
                .filter(Stock::isTrading)
                .map(Stock::getSnapshot)
                .sorted((s1, s2) -> Double.compare(s2.currentPrice, s1.currentPrice))
                .limit(n)
                .collect(Collectors.toList());
    }
    
    /**
     * 统计交易信息 - 演示reduce操作
     */
    public TradingStatistics getTradingStatistics() {
        // 🔥 reduce 并行归约操作
        // parallelismThreshold: 并行阈值
        // transformer: 转换函数，将每个元素转换为要累加的值
        // reducer: 归约函数，将两个值合并为一个
        
        double totalMarketValue = stockMap.reduce(2, 
            (symbol, stock) -> stock.getCurrentPrice() * 1000000,  // 假设每只股票有100万股
            Double::sum
        );
        
        int activeStocks = (int) stockMap.reduceValues(2, 
            stock -> stock.isTrading() ? 1L : 0L,
            Long::sum
        );
        
        return new TradingStatistics(
            stockMap.size(),
            activeStocks,
            totalMarketValue,
            totalUpdates.sum()
        );
    }
    
    /**
     * 清空更新日志队列 - 演示drainTo的使用
     */
    public List<PriceUpdateLog> drainUpdateLogs() {
        List<PriceUpdateLog> logs = new ArrayList<>();
        // 🔥 drainTo(collection): 将队列中所有元素转移到指定集合
        // 这是原子操作，适合批量处理
        updateLogQueue.drainTo(logs);
        return logs;
    }
    
    /**
     * 搜索股票 - 演示search操作
     * 
     * 🔥 search(parallelismThreshold, searchFunction) 方法：
     * 并行搜索，返回第一个匹配的元素
     */
    public Stock searchStockByCondition(String keyword) {
        return stockMap.search(2, (symbol, stock) -> {
            if (stock.getName().contains(keyword) || symbol.contains(keyword)) {
                return stock;
            }
            return null;  // 返回null表示不匹配
        });
    }
    
    // 内部类：价格更新日志
    public static class PriceUpdateLog {
        public final String symbol;
        public final double price;
        public final int volume;
        public final long timestamp;
        
        public PriceUpdateLog(String symbol, double price, int volume) {
            this.symbol = symbol;
            this.price = price;
            this.volume = volume;
            this.timestamp = System.currentTimeMillis();
        }
    }
    
    // 内部类：交易统计
    public static class TradingStatistics {
        public final int totalStocks;
        public final int activeStocks;
        public final double totalMarketValue;
        public final long totalUpdates;
        
        public TradingStatistics(int totalStocks, int activeStocks, 
                               double totalMarketValue, long totalUpdates) {
            this.totalStocks = totalStocks;
            this.activeStocks = activeStocks;
            this.totalMarketValue = totalMarketValue;
            this.totalUpdates = totalUpdates;
        }
    }
}
```

### 3. **ThreadPoolFactory.java** - 线程池工厂（完整配置）
```java
package utils;

import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 线程池工厂 - 演示ThreadPoolExecutor的完整配置
 * 创建不同类型的线程池，适应不同场景
 */
public class ThreadPoolFactory {
    
    /**
     * 创建CPU密集型任务线程池
     * 
     * 🔥 参数详解：
     * corePoolSize: 核心线程数 = CPU核心数
     *   保持活跃的最小线程数，即使空闲也不会回收（除非allowCoreThreadTimeOut=true）
     * 
     * maximumPoolSize: 最大线程数 = CPU核心数 + 1
     *   允许创建的最大线程数，当队列满了且核心线程都在忙时，会创建新线程直到达到这个数
     * 
     * keepAliveTime: 空闲线程存活时间 = 30秒
     *   超过核心线程数的空闲线程，空闲多久后被回收
     * 
     * unit: 时间单位 = TimeUnit.SECONDS
     * 
     * workQueue: 工作队列 = LinkedBlockingQueue
     *   存放待执行任务的队列，这里使用无界队列（注意内存风险）
     * 
     * threadFactory: 线程工厂 = 自定义工厂
     *   用于创建新线程，可以设置线程名、优先级等
     * 
     * handler: 拒绝策略 = CallerRunsPolicy
     *   当队列满且线程数达到maximumPoolSize时，如何处理新任务
     *   CallerRunsPolicy: 让提交任务的线程自己执行
     */
    public static ThreadPoolExecutor createCpuIntensivePool() {
        int corePoolSize = Runtime.getRuntime().availableProcessors();
        int maxPoolSize = corePoolSize + 1;
        
        return new ThreadPoolExecutor(
            corePoolSize,              // 核心线程数
            maxPoolSize,               // 最大线程数
            30L, TimeUnit.SECONDS,     // 空闲线程存活时间
            new LinkedBlockingQueue<>(), // 工作队列（无界）
            new NamedThreadFactory("CPU-Worker"), // 线程工厂
            new ThreadPoolExecutor.CallerRunsPolicy() // 拒绝策略
        );
    }
    
    /**
     * 创建IO密集型任务线程池
     * 
     * 特点：核心线程数较多，因为线程大部分时间在等待IO
     */
    public static ThreadPoolExecutor createIoIntensivePool() {
        int corePoolSize = Runtime.getRuntime().availableProcessors() * 2;
        int maxPoolSize = corePoolSize * 2;
        
        return new ThreadPoolExecutor(
            corePoolSize,
            maxPoolSize,
            60L, TimeUnit.SECONDS,      // IO任务可能长时间等待，存活时间较长
            new LinkedBlockingQueue<>(1000), // 有界队列，防止内存溢出
            new NamedThreadFactory("IO-Worker"),
            new ThreadPoolExecutor.AbortPolicy() // 直接拒绝，避免任务堆积
        );
    }
    
    /**
     * 创建定时任务线程池
     */
    public static ScheduledExecutorService createScheduledPool() {
        return new ScheduledThreadPoolExecutor(
            2,  // 核心线程数
            new NamedThreadFactory("Scheduled-Worker"),
            new ThreadPoolExecutor.AbortPolicy()
        );
    }
    
    /**
     * 创建计算任务线程池（用于技术指标计算）
     */
    public static ThreadPoolExecutor createCalculationPool() {
        return new ThreadPoolExecutor(
            4, 8,                       // 适中的线程数
            10L, TimeUnit.SECONDS,
            new ArrayBlockingQueue<>(500), // 数组阻塞队列，固定大小
            new NamedThreadFactory("Calc-Worker"),
            new ThreadPoolExecutor.DiscardOldestPolicy() // 丢弃最老的任务
        );
    }
    
    /**
     * 自定义线程工厂 - 演示ThreadFactory的使用
     * 可以统一设置线程名称、优先级、守护线程等属性
     */
    private static class NamedThreadFactory implements ThreadFactory {
        private final AtomicInteger threadNumber = new AtomicInteger(1);
        private final String namePrefix;
        
        NamedThreadFactory(String poolName) {
            namePrefix = poolName + "-";
        }
        
        @Override
        public Thread newThread(Runnable r) {
            Thread t = new Thread(r, namePrefix + threadNumber.getAndIncrement());
            
            // 设置线程属性
            if (t.isDaemon()) {
                t.setDaemon(false);  // 设为用户线程
            }
            if (t.getPriority() != Thread.NORM_PRIORITY) {
                t.setPriority(Thread.NORM_PRIORITY);  // 正常优先级
            }
            
            // 设置未捕获异常处理器
            t.setUncaughtExceptionHandler((thread, throwable) -> {
                System.err.println("线程 " + thread.getName() + " 发生异常: " + throwable.getMessage());
                throwable.printStackTrace();
            });
            
            return t;
        }
    }
    
    /**
     * 监控线程池状态的方法
     */
    public static void monitorThreadPool(ThreadPoolExecutor executor, String poolName) {
        ScheduledExecutorService monitor = Executors.newSingleThreadScheduledExecutor();
        
        monitor.scheduleAtFixedRate(() -> {
            System.out.println("\n=== 线程池监控 [" + poolName + "] ===");
            System.out.println("核心线程数: " + executor.getCorePoolSize());
            System.out.println("最大线程数: " + executor.getMaximumPoolSize());
            System.out.println("活跃线程数: " + executor.getActiveCount());
            System.out.println("队列大小: " + executor.getQueue().size());
            System.out.println("已完成任务数: " + executor.getCompletedTaskCount());
            System.out.println("总任务数: " + executor.getTaskCount());
            System.out.println("池大小: " + executor.getPoolSize());
            System.out.println("=======================\n");
        }, 0, 5, TimeUnit.SECONDS);  // 每5秒监控一次
    }
}
```

### 4. **IndicatorCalculator.java** - 技术指标计算（使用CompletableFuture）
```java


package core;

import model.Stock;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 技术指标计算器 - 演示CompletableFuture和并行计算
 * 计算各种股票技术指标
 */
public class IndicatorCalculator {
    
    private final ThreadPoolExecutor calculationPool;
    private final ConcurrentHashMap<String, List<Double>> priceHistory;
    
    // 🔥 CountDownLatch: 倒计时门闩，用于等待多个任务完成
    // 场景：批量计算指标，等待所有计算完成
    private CountDownLatch currentBatchLatch;
    
    // 🔥 AtomicInteger: 用于并发计数
    private final AtomicInteger calculationsInProgress = new AtomicInteger(0);
    
    public IndicatorCalculator() {
        this.calculationPool = ThreadPoolFactory.createCalculationPool();
        this.priceHistory = new ConcurrentHashMap<>();
    }
    
    /**
     * 批量计算移动平均线 - 演示CompletableFuture.allOf()
     * 
     * 🔥 CompletableFuture：Java 8引入的异步编程API
     * 比传统的Future更强大，支持链式调用、组合等
     */
    public Map<String, Double> calculateMovingAverages(
            Map<String, Stock> stocks, 
            int period) {
        
        // 存储计算结果
        ConcurrentHashMap<String, Double> results = new ConcurrentHashMap<>();
        
        // 创建CompletableFuture列表
        List<CompletableFuture<Void>> futures = new ArrayList<>();
        
        for (Map.Entry<String, Stock> entry : stocks.entrySet()) {
            String symbol = entry.getKey();
            Stock stock = entry.getValue();
            
            // 🔥 supplyAsync: 异步执行有返回值的任务
            CompletableFuture<Double> future = CompletableFuture.supplyAsync(() -> {
                calculationsInProgress.incrementAndGet();
                try {
                    return calculateMA(symbol, stock.getCurrentPrice(), period);
                } finally {
                    calculationsInProgress.decrementAndGet();
                }
            }, calculationPool);
            
            // 🔥 thenAccept: 任务完成后处理结果（消费结果）
            CompletableFuture<Void> resultFuture = future.thenAccept(maValue -> {
                results.put(symbol, maValue);
                System.out.println("计算完成: " + symbol + " MA(" + period + ") = " + maValue);
            });
            
            // 🔥 exceptionally: 异常处理
            resultFuture.exceptionally(ex -> {
                System.err.println("计算MA失败: " + symbol + " - " + ex.getMessage());
                return null;
            });
            
            futures.add(resultFuture);
        }
        
        // 🔥 allOf: 等待所有future完成
        CompletableFuture<Void> allFutures = CompletableFuture.allOf(
            futures.toArray(new CompletableFuture[0])
        );
        
        try {
            // 等待所有计算完成，最多30秒
            allFutures.get(30, TimeUnit.SECONDS);
        } catch (Exception e) {
            System.err.println("批量计算超时或异常: " + e.getMessage());
            // 取消未完成的任务
            futures.forEach(future -> future.cancel(true));
        }
        
        return results;
    }
    
    /**
     * 并行计算多个技术指标 - 演示thenCombine
     * 
     * 🔥 thenCombine: 组合两个独立的CompletableFuture
     * 当两个future都完成后，使用BiFunction合并结果
     */
    public Map<String, TechnicalIndicators> calculateMultipleIndicators(
            String symbol, double currentPrice) {
        
        // 并行计算三个指标
        CompletableFuture<Double> maFuture = CompletableFuture.supplyAsync(
            () -> calculateMA(symbol, currentPrice, 10),
            calculationPool
        );
        
        CompletableFuture<Double> rsiFuture = CompletableFuture.supplyAsync(
            () -> calculateRSI(symbol, currentPrice),
            calculationPool
        );
        
        CompletableFuture<Double> bollingerFuture = CompletableFuture.supplyAsync(
            () -> calculateBollingerBands(symbol, currentPrice),
            calculationPool
        );
        
        // 🔥 thenCombine: 等待两个future都完成，然后合并结果
        CompletableFuture<TechnicalIndicators> combinedFuture = maFuture
            .thenCombine(rsiFuture, (ma, rsi) -> new TechnicalIndicators(ma, rsi, 0.0))
            .thenCombine(bollingerFuture, (indicators, bollinger) -> {
                indicators.bollingerBands = bollinger;
                return indicators;
            });
        
        try {
            // 等待所有计算完成
            TechnicalIndicators indicators = combinedFuture.get(10, TimeUnit.SECONDS);
            
            Map<String, TechnicalIndicators> result = new HashMap<>();
            result.put(symbol, indicators);
            return result;
            
        } catch (Exception e) {
            System.err.println("计算指标失败: " + symbol + " - " + e.getMessage());
            return Collections.emptyMap();
        }
    }
    
    /**
     * 使用CountDownLatch控制批量计算
     */
    public void batchCalculateWithLatch(List<String> symbols) {
        // 🔥 CountDownLatch初始化：需要等待的任务数量
        currentBatchLatch = new CountDownLatch(symbols.size());
        
        for (String symbol : symbols) {
            calculationPool.execute(() -> {
                try {
                    // 模拟计算
                    Thread.sleep(ThreadLocalRandom.current().nextInt(100, 500));
                    System.out.println("计算完成: " + symbol + 
                                     " (剩余: " + currentBatchLatch.getCount() + ")");
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                } finally {
                    // 🔥 countDown: 每个任务完成时调用，计数器减1
                    currentBatchLatch.countDown();
                }
            });
        }
        
        try {
            // 🔥 await: 等待计数器减到0
            // 🔥 await(timeout, unit): 限时等待，避免永久阻塞
            boolean completed = currentBatchLatch.await(30, TimeUnit.SECONDS);
            
            if (completed) {
                System.out.println("批量计算全部完成!");
            } else {
                System.out.println("批量计算超时，剩余: " + currentBatchLatch.getCount());
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println("批量计算被中断");
        }
    }
    
    /**
     * 使用CyclicBarrier分阶段计算
     * 
     * 🔥 CyclicBarrier: 循环栅栏
     * 让一组线程互相等待，全部到达栅栏后一起继续执行
     * 可以重复使用（与CountDownLatch的区别）
     */
    public void phasedCalculationWithBarrier(List<String> symbols) {
        // 🔥 CyclicBarrier初始化：
        // 参数1: parties - 需要等待的线程数量
        // 参数2: barrierAction - 所有线程到达后执行的动作（可选）
        CyclicBarrier barrier = new CyclicBarrier(symbols.size(), () -> {
            System.out.println("\n=== 所有线程完成阶段1，开始阶段2 ===");
        });
        
        for (String symbol : symbols) {
            new Thread(() -> {
                try {
                    // 阶段1：数据准备
                    System.out.println(Thread.currentThread().getName() + 
                                     " 准备数据: " + symbol);
                    Thread.sleep(100);
                    
                    // 🔥 await: 等待其他线程到达栅栏
                    barrier.await();
                    
                    // 阶段2：计算
                    System.out.println(Thread.currentThread().getName() + 
                                     " 计算指标: " + symbol);
                    Thread.sleep(200);
                    
                    // 这里可以设置第二个栅栏进行更多阶段
                    
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }, "Calc-Thread-" + symbol).start();
        }
    }
    
    // 模拟计算各种技术指标的方法
    private double calculateMA(String symbol, double currentPrice, int period) {
        // 获取历史价格
        List<Double> history = priceHistory.computeIfAbsent(symbol, 
            k -> generateRandomHistory(50));
        
        // 添加新价格
        history.add(currentPrice);
        if (history.size() > 100) {
            history.remove(0); // 保持固定长度
        }
        
        // 计算移动平均
        int start = Math.max(0, history.size() - period);
        double sum = 0;
        for (int i = start; i < history.size(); i++) {
            sum += history.get(i);
        }
        
        return sum / Math.min(period, history.size() - start);
    }
    
    private double calculateRSI(String symbol, double currentPrice) {
        // 简化实现
        return 50 + ThreadLocalRandom.current().nextDouble(50);
    }
    
    private double calculateBollingerBands(String symbol, double currentPrice) {
        // 简化实现
        return currentPrice * (0.9 + ThreadLocalRandom.current().nextDouble(0.2));
    }
    
    private List<Double> generateRandomHistory(int size) {
        List<Double> history = new ArrayList<>();
        double basePrice = 100 + ThreadLocalRandom.current().nextDouble(900);
        
        for (int i = 0; i < size; i++) {
            // 随机波动
            double change = (ThreadLocalRandom.current().nextDouble() - 0.5) * 20;
            history.add(basePrice + change);
            basePrice = history.get(history.size() - 1);
        }
        
        return history;
    }
    
    // 技术指标结果类
    public static class TechnicalIndicators {
        public double movingAverage;
        public double rsi;
        public double bollingerBands;
        
        public TechnicalIndicators(double ma, double rsi, double bb) {
            this.movingAverage = ma;
            this.rsi = rsi;
            this.bollingerBands = bb;
        }
    }


```

### 5. **AlertSystem.java** - 预警系统（使用锁和条件变量）
```java
package core;

import model.Stock;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.locks.*;

/**
 * 股票价格预警系统 - 演示ReentrantLock和Condition的使用
 * 监控股票价格，触发预警条件时通知
 */
public class AlertSystem {
    
    // 🔥 ReentrantLock: 可重入锁，替代synchronized
    // true: 公平锁（按等待时间分配锁，性能较低但公平）
    private final ReentrantLock lock = new ReentrantLock(true);
    
    // 🔥 Condition: 条件变量，与锁绑定
    // 用于线程间精确通信，可以唤醒特定条件的线程
    private final Condition priceCondition = lock.newCondition();
    private final Condition volumeCondition = lock.newCondition();
    
    // 预警规则存储
    private final ConcurrentHashMap<String, List<AlertRule>> alertRules = 
        new ConcurrentHashMap<>();
    
    // 预警触发记录
    private final ConcurrentLinkedQueue<AlertEvent> alertEvents = 
        new ConcurrentLinkedQueue<>();
    
    // 🔥 ReadWriteLock: 读写锁，读读共享，读写互斥
    // 适合读多写少的场景
    private final ReadWriteLog alertLogLock = new ReadWriteLog();
    
    // 🔥 Semaphore: 信号量，控制并发访问数量
    // 限制同时处理预警的数量，防止系统过载
    private final Semaphore alertProcessingSemaphore = new Semaphore(5);
    
    /**
     * 添加预警规则 - 演示锁的使用
     */
    public void addAlertRule(String symbol, AlertRule rule) {
        // 🔥 lock(): 获取锁（会阻塞直到获取成功）
        lock.lock();
        try {
            List<AlertRule> rules = alertRules.computeIfAbsent(symbol, 
                k -> new CopyOnWriteArrayList<>());
            rules.add(rule);
            System.out.println("添加预警规则: " + symbol + " - " + rule);
            
            // 🔥 signalAll(): 唤醒所有等待priceCondition的线程
            priceCondition.signalAll();
            
        } finally {
            // 🔥 unlock(): 必须在finally中释放锁，防止死锁
            lock.unlock();
        }
    }
    
    /**
     * 监控股票价格 - 演示Condition.await()的使用
     */
    public void monitorStock(String symbol, Stock stock) {
        new Thread(() -> {
            while (!Thread.currentThread().isInterrupted()) {
                lock.lock();
                try {
                    List<AlertRule> rules = alertRules.get(symbol);
                    if (rules == null || rules.isEmpty()) {
                        // 🔥 await(): 等待，释放锁，直到被signal/signalAll唤醒
                        // 被唤醒后会重新获取锁
                        priceCondition.await();
                        continue;
                    }
                    
                    double currentPrice = stock.getCurrentPrice();
                    
                    for (AlertRule rule : rules) {
                        if (rule.check(currentPrice)) {
                            // 触发预警
                            triggerAlert(symbol, rule, currentPrice);
                        }
                    }
                    
                    // 🔥 await(timeout, unit): 限时等待
                    // 避免永久等待，定期检查
                    priceCondition.await(1, TimeUnit.SECONDS);
                    
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                    break;
                } finally {
                    lock.unlock();
                }
            }
        }, "Monitor-" + symbol).start();
    }
    
    /**
     * 触发预警 - 演示信号量和读写锁的使用
     */
    private void triggerAlert(String symbol, AlertRule rule, double price) {
        // 尝试获取信号量许可
        if (!alertProcessingSemaphore.tryAcquire()) {
            System.out.println("预警处理繁忙，丢弃预警: " + symbol);
            return;
        }
        
        try {
            // 使用读锁获取日志（多个线程可以同时读）
            alertLogLock.readLock().lock();
            try {
                // 检查是否最近已触发相同预警（防重复）
                if (isDuplicateAlert(symbol, rule, price)) {
                    return;
                }
            } finally {
                alertLogLock.readLock().unlock();
            }
            
            // 使用写锁记录预警（写锁独占）
            alertLogLock.writeLock().lock();
            try {
                AlertEvent event = new AlertEvent(symbol, rule, price, System.currentTimeMillis());
                alertEvents.offer(event);
                System.out.println("🚨 触发预警: " + event);
                
                // 模拟预警处理
                processAlert(event);
                
            } finally {
                alertLogLock.writeLock().unlock();
            }
            
        } finally {
            // 释放信号量许可
            alertProcessingSemaphore.release();
        }
    }
    
    /**
     * 使用tryLock尝试获取锁 - 演示非阻塞锁获取
     */
    public boolean tryAddRuleWithTimeout(String symbol, AlertRule rule) {
        // 🔥 tryLock(): 尝试获取锁，立即返回结果
        if (lock.tryLock()) {
            try {
                addAlertRule(symbol, rule);
                return true;
            } finally {
                lock.unlock();
            }
        }
        
        // 🔥 tryLock(timeout, unit): 限时尝试获取锁
        try {
            if (lock.tryLock(100, TimeUnit.MILLISECONDS)) {
                try {
                    addAlertRule(symbol, rule);
                    return true;
                } finally {
                    lock.unlock();
                }
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
        
        System.out.println("添加规则失败: 获取锁超时");
        return false;
    }
    
    /**
     * 使用Condition.signal()精确唤醒 - 演示与signalAll的区别
     */
    public void notifySpecificMonitor(String symbol) {
        lock.lock();
        try {
            // 🔥 signal(): 只唤醒一个等待线程（随机）
            // 比signalAll()更高效，避免"惊群效应"
            priceCondition.signal();
            
            System.out.println("通知特定监控器: " + symbol);
            
        } finally {
            lock.unlock();
        }
    }
    
    /**
     * 获取预警统计 - 演示StampedLock乐观读
     */
    public AlertStatistics getAlertStatistics() {
        // 🔥 StampedLock: JDK8引入，比ReadWriteLock性能更好
        // 支持乐观读（不阻塞），适合读多写少
        StampedLock stampedLock = new StampedLock();
        
        long stamp = stampedLock.tryOptimisticRead(); // 尝试乐观读
        int totalAlerts = alertEvents.size();
        int activeRules = countActiveRules();
        
        // 🔥 validate(stamp): 验证乐观读期间是否有写操作
        if (!stampedLock.validate(stamp)) {
            // 有写操作，升级为悲观读
            stamp = stampedLock.readLock();
            try {
                totalAlerts = alertEvents.size();
                activeRules = countActiveRules();
            } finally {
                stampedLock.unlockRead(stamp);
            }
        }
        
        return new AlertStatistics(totalAlerts, activeRules, 
                                 alertProcessingSemaphore.availablePermits());
    }
    
    private boolean isDuplicateAlert(String symbol, AlertRule rule, double price) {
        // 简化实现：检查最近10秒内是否有相同预警
        long now = System.currentTimeMillis();
        return alertEvents.stream()
                .filter(e -> e.symbol.equals(symbol) && e.rule.equals(rule))
                .anyMatch(e -> now - e.timestamp < 10000);
    }
    
    private void processAlert(AlertEvent event) {
        // 模拟预警处理
        try {
            Thread.sleep(50);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }
    
    private int countActiveRules() {
        return alertRules.values().stream()
                .mapToInt(List::size)
                .sum();
    }
    
    // 预警规则类
    public static class AlertRule {
        public enum Type { PRICE_ABOVE, PRICE_BELOW, PERCENT_CHANGE }
        
        public final Type type;
        public final double threshold;
        public final double percent;
        
        public AlertRule(Type type, double threshold) {
            this.type = type;
            this.threshold = threshold;
            this.percent = 0;
        }
        
        public boolean check(double price) {
            switch (type) {
                case PRICE_ABOVE: return price > threshold;
                case PRICE_BELOW: return price < threshold;
                default: return false;
            }
        }
        
        @Override
        public String toString() {
            return type + "@" + threshold;
        }
    }
    
    // 预警事件类
    public static class AlertEvent {
        public final String symbol;
        public final AlertRule rule;
        public final double price;
        public final long timestamp;
        
        public AlertEvent(String symbol, AlertRule rule, double price, long timestamp) {
            this.symbol = symbol;
            this.rule = rule;
            this.price = price;
            this.timestamp = timestamp;
        }
        
        @Override
        public String toString() {
            return String.format("[%s] %s 价格: %.2f 触发规则: %s", 
                new Date(timestamp), symbol, price, rule);
        }
    }
    
    // 预警统计类
    public static class AlertStatistics {
        public final int totalAlerts;
        public final int activeRules;
        public final int availableProcessors;
        
        public AlertStatistics(int totalAlerts, int activeRules, int availableProcessors) {
            this.totalAlerts = totalAlerts;
            this.activeRules = activeRules;
            this.availableProcessors = availableProcessors;
        }
    }
    
    // 读写锁包装类
    private static class ReadWriteLog {
        private final ReentrantReadWriteLock rwLock = new ReentrantReadWriteLock(true);
        
        public Lock readLock() {
            return rwLock.readLock();
        }
        
        public Lock writeLock() {
            return rwLock.writeLock();
        }
    }
}
```




### 6. **StockMarket.java** - 主程序入口
```java
import core.*;
import model.Stock;
import utils.ThreadPoolFactory;
import java.util.*;
import java.util.concurrent.*;

/**
 * 股票行情分析系统主程序
 * 集成所有JUC组件，演示完整的工作流程
 */
public class StockMarket {
    
    private final StockRegistry stockRegistry;
    private final IndicatorCalculator indicatorCalculator;
    private final AlertSystem alertSystem;
    
    // 使用不同的线程池处理不同类型的任务
    private final ThreadPoolExecutor dataStreamPool;
    private final ScheduledExecutorService scheduledPool;
    
    // 🔥 Phaser: 比CyclicBarrier更灵活的同步器
    // 支持动态注册/注销参与线程，支持多阶段
    private final Phaser marketPhaser = new Phaser(1); // 主线程注册
    
    public StockMarket() {
        this.stockRegistry = new StockRegistry();
        this.indicatorCalculator = new IndicatorCalculator();
        this.alertSystem = new AlertSystem();
        
        this.dataStreamPool = ThreadPoolFactory.createIoIntensivePool();
        this.scheduledPool = ThreadPoolFactory.createScheduledPool();
        
        // 监控线程池
        ThreadPoolFactory.monitorThreadPool(dataStreamPool, "数据流线程池");
    }
    
    /**
     * 初始化市场数据
     */
    public void initializeMarket() {
        System.out.println("=== 初始化股票市场 ===");
        
        // 注册一些常见股票
        Stock[] stocks = {
            new Stock("AAPL", "Apple Inc.", 150.25),
            new Stock("GOOGL", "Alphabet Inc.", 2750.50),
            new Stock("MSFT", "Microsoft Corp", 305.75),
            new Stock("AMZN", "Amazon.com Inc.", 3300.00),
            new Stock("TSLA", "Tesla Inc.", 850.30),
            new Stock("NVDA", "NVIDIA Corp", 220.45),
            new Stock("JPM", "JPMorgan Chase", 155.60),
            new Stock("BABA", "Alibaba Group", 210.80)
        };
        
        for (Stock stock : stocks) {
            stockRegistry.registerStock(stock);
            
            // 为每只股票启动监控
            alertSystem.monitorStock(stock.getSymbol(), stock);
        }
        
        // 添加预警规则
        alertSystem.addAlertRule("AAPL", 
            new AlertSystem.AlertRule(AlertSystem.AlertRule.Type.PRICE_ABOVE, 160.0));
        alertSystem.addAlertRule("TSLA", 
            new AlertSystem.AlertRule(AlertSystem.AlertRule.Type.PRICE_BELOW, 800.0));
    }
    
    /**
     * 启动模拟数据流
     */
    public void startDataStream() {
        System.out.println("\n=== 启动模拟数据流 ===");
        
        // 使用ScheduledExecutorService定时生成数据
        scheduledPool.scheduleAtFixedRate(() -> {
            // 动态注册到Phaser
            marketPhaser.register();
            
            dataStreamPool.execute(() -> {
                try {
                    generateMarketData();
                } finally {
                    // 到达并注销
                    marketPhaser.arriveAndDeregister();
                }
            });
        }, 0, 500, TimeUnit.MILLISECONDS); // 每500ms生成一次数据
    }
    
    /**
     * 生成模拟市场数据
     */
    private void generateMarketData() {
        Map<String, Double> priceUpdates = new HashMap<>();
        Random random = new Random();
        
        // 模拟价格波动
        stockRegistry.getStockSymbols().forEach(symbol -> {
            double change = (random.nextDouble() - 0.5) * 5; // ±2.5
            Stock stock = stockRegistry.getOrCreateStock(symbol);
            double currentPrice = stock.getCurrentPrice();
            double newPrice = Math.max(1.0, currentPrice + change);
            
            priceUpdates.put(symbol, newPrice);
        });
        
        // 批量更新价格
        stockRegistry.batchUpdatePrices(priceUpdates);
        
        // 每10次更新计算一次技术指标
        if (random.nextInt(10) == 0) {
            calculateIndicators();
        }
        
        // 显示市场状态
        if (random.nextInt(20) == 0) {
            showMarketStatus();
        }
    }
    
    /**
     * 计算技术指标
     */
    private void calculateIndicators() {
        System.out.println("\n=== 计算技术指标 ===");
        
        // 使用CompletableFuture并行计算
        List<String> symbols = new ArrayList<>(stockRegistry.getStockSymbols());
        
        // 分批计算，避免一次计算太多
        int batchSize = 4;
        for (int i = 0; i < symbols.size(); i += batchSize) {
            int end = Math.min(i + batchSize, symbols.size());
            List<String> batch = symbols.subList(i, end);
            
            indicatorCalculator.batchCalculateWithLatch(batch);
        }
    }
    
    /**
     * 显示市场状态
     */
    private void showMarketStatus() {
        System.out.println("\n=== 市场状态 ===");
        
        // 获取top 3股票
        List<Stock.StockSnapshot> topStocks = stockRegistry.getTopStocksByPrice(3);
        System.out.println("价格最高的3只股票:");
        topStocks.forEach(s -> System.out.printf("  %s: %.2f (成交量: %,d)%n", 
            s.symbol, s.currentPrice, s.volume));
        
        // 获取交易统计
        StockRegistry.TradingStatistics stats = stockRegistry.getTradingStatistics();
        System.out.printf("市场概况: %d只股票, %d只交易中, 总市值: %,.2f, 总更新: %,d%n",
            stats.totalStocks, stats.activeStocks, stats.totalMarketValue, stats.totalUpdates);
        
        // 获取预警统计
        AlertSystem.AlertStatistics alertStats = alertSystem.getAlertStatistics();
        System.out.printf("预警统计: 总预警数: %,d, 活跃规则: %d%n",
            alertStats.totalAlerts, alertStats.activeRules);
    }
    
    /**
     * 运行一段时间后关闭
     */
    public void runForDuration(int seconds) throws InterruptedException {
        System.out.println("\n=== 运行 " + seconds + " 秒 ===");
        
        // 等待所有数据生成任务完成
        marketPhaser.arriveAndAwaitAdvance();
        
        // 主线程等待指定时间
        Thread.sleep(seconds * 1000L);
        
        // 优雅关闭
        shutdown();
    }
    
    /**
     * 优雅关闭所有资源
     */
    public void shutdown() {
        System.out.println("\n=== 关闭系统 ===");
        
        // 1. 停止接受新任务
        dataStreamPool.shutdown();
        scheduledPool.shutdown();
        
        // 2. 等待正在执行的任务完成
        try {
            if (!dataStreamPool.awaitTermination(10, TimeUnit.SECONDS)) {
                System.out.println("数据流线程池超时，强制关闭");
                dataStreamPool.shutdownNow();
            }
            
            if (!scheduledPool.awaitTermination(5, TimeUnit.SECONDS)) {
                scheduledPool.shutdownNow();
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            dataStreamPool.shutdownNow();
            scheduledPool.shutdownNow();
        }
        
        // 3. 输出最终统计
        showFinalStatistics();
        
        System.out.println("系统关闭完成");
    }
    
    /**
     * 显示最终统计
     */
    private void showFinalStatistics() {
        System.out.println("\n=== 最终统计 ===");
        
        StockRegistry.TradingStatistics stats = stockRegistry.getTradingStatistics();
        System.out.println("总股票数: " + stats.totalStocks);
        System.out.println("总更新次数: " + stats.totalUpdates);
        System.out.println("总市值: " + String.format("%,.2f", stats.totalMarketValue));
        
        // 获取所有更新日志
        List<StockRegistry.PriceUpdateLog> logs = stockRegistry.drainUpdateLogs();
        System.out.println("价格更新日志数: " + logs.size());
        
        if (!logs.isEmpty()) {
            System.out.println("最后一条更新: " + 
                logs.get(logs.size() - 1).symbol + " @ " + 
                logs.get(logs.size() - 1).price);
        }
    }
    
    /**
     * 主方法
     */
    public static void main(String[] args) {
        StockMarket market = new StockMarket();
        
        try {
            // 1. 初始化
            market.initializeMarket();
            
            // 2. 启动数据流
            market.startDataStream();
            
            // 3. 运行30秒
            market.runForDuration(30);
            
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            System.err.println("主程序被中断");
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

---

## 📚 学习路径建议

### 第一周：理解基础
1. **运行项目**：跑起来看效果
2. **阅读注释**：重点看`AtomicInteger`、`ConcurrentHashMap`的注释
3. **修改参数**：改线程池参数看效果变化

### 第二周：动手修改
1. **添加新功能**：比如增加股票搜索功能
2. **优化性能**：调整各种并发参数
3. **添加日志**：记录更多运行时信息

### 第三周：创新扩展
1. **实现新功能**：添加K线图计算
2. **集成外部系统**：连接模拟交易API
3. **设计新模式**：实现观察者模式监控

### 第四周：深度优化
1. **性能测试**：用JMH测试各组件性能
2. **问题排查**：模拟高并发问题并解决
3. **架构优化**：重新设计更优的架构

---

## 🎯 重点学习目标

1. **理解每个JUC类的适用场景**
2. **掌握方法参数的含义和用法**
3. **学会组合使用多个并发工具**
4. **能够设计线程安全的系统**
5. **能够诊断和解决并发问题**

这个项目涵盖了JUC 80%的常用功能，通过实际编码，你会在3-4周内建立起完整的并发编程思维。**记住：只看不练假把式，一定要动手敲代码！**