## 📝 CopyOnWriteArrayList 速查表

### 📌 基本信息
| 项目 | 内容 |
|------|------|
| **所属包** | `java.util.concurrent` |
| **所属领域** | **Java 并发集合** (JUC - Java Util Concurrent) |
| **继承关系** | `ArrayList` → `CopyOnWriteArrayList` |
| **实现接口** | `List`, `RandomAccess`, `Cloneable`, `Serializable` |

---

### 🎯 核心特点
| 特点 | 说明 |
|------|------|
| **线程安全** | ✅ 多线程环境下安全使用 |
| **写时复制** | ✅ 所有修改操作都会复制新数组 |
| **读操作无锁** | ✅ 读取完全不加锁，性能极高 |
| **弱一致性** | ⚠️ 迭代器遍历的是创建时的快照 |
| **内存占用** | ⚠️ 写操作时内存翻倍 |
| **fail-fast** | ❌ 不会抛出 `ConcurrentModificationException` |

---

### 🔧 常用方法
| 操作类型 | 方法 | 时间复杂度 | 说明 |
|---------|------|-----------|------|
| **添加** | `add(E e)` | O(n) | 复制数组，末尾添加 |
| **插入** | `add(int index, E e)` | O(n) | 复制数组，指定位置插入 |
| **获取** | `get(int index)` | O(1) | 直接读取，无锁 |
| **删除** | `remove(int index)` | O(n) | 复制数组，删除元素 |
| **修改** | `set(int index, E e)` | O(n) | 复制数组，替换元素 |
| **大小** | `size()` | O(1) | 直接返回 |
| **迭代** | `iterator()` | O(1) | 返回快照迭代器 |

---

### 💡 工作原理
```mermaid
graph LR
    A[原数组<br/>[A,B,C]] -->|写操作| B[复制新数组<br/>[A,B,C,null]]
    B -->|修改| C[修改后数组<br/>[A,B,C,D]]
    C -->|替换引用| D[原数组指向新数组<br/>list指向[A,B,C,D]]
    A -.->|读操作/迭代器| E[继续使用旧数组]
```

---

### ✅ 适用场景 vs ❌ 不适用场景
| 适用场景 | 不适用场景 |
|---------|-----------|
| ✓ **读多写极少** (读 >> 写) | ✗ **写操作频繁** |
| ✓ **集合规模小** (< 1000元素) | ✗ **集合规模大** (> 10000元素) |
| ✓ **对实时性要求不高** | ✗ **需要强一致性** |
| ✓ **黑名单/白名单** | ✗ **高频日志记录** |
| ✓ **配置信息缓存** | ✗ **实时数据更新** |
| ✓ **监听器列表** | ✗ **高频读写混合** |

---

### 📊 对比其他线程安全List
| 特性 | CopyOnWriteArrayList | Vector | Collections.synchronizedList |
|------|---------------------|--------|------------------------------|
| **锁机制** | 写时复制 + ReentrantLock | synchronized | synchronized |
| **读性能** | ⭐⭐⭐⭐⭐ 极高 | ⭐⭐ 低 | ⭐⭐ 低 |
| **写性能** | ⭐ 极低 (复制数组) | ⭐⭐ 中等 | ⭐⭐ 中等 |
| **内存消耗** | ⭐ 高 (写时双倍) | ⭐⭐⭐ 低 | ⭐⭐⭐ 低 |
| **迭代器** | 快照迭代器 (不抛异常) | fail-fast (抛异常) | fail-fast (抛异常) |
| **适用场景** | 读多写少 | 遗留系统 | 简单同步需求 |

---

### 🔍 源码关键点
```java
// 核心数据结构
private transient volatile Object[] array;  // volatile保证可见性

// 写操作加锁
final transient ReentrantLock lock = new ReentrantLock();

// 读操作 - 无锁
public E get(int index) {
    return get(getArray(), index);  // 直接读取原数组
}

// 写操作 - 加锁复制
public boolean add(E e) {
    final ReentrantLock lock = this.lock;
    lock.lock();
    try {
        Object[] elements = getArray();
        int len = elements.length;
        Object[] newElements = Arrays.copyOf(elements, len + 1);  // 复制
        newElements[len] = e;  // 修改
        setArray(newElements);  // 替换引用
        return true;
    } finally {
        lock.unlock();
    }
}
```

---

### 🎓 所属知识领域
```
Java 知识体系
├── Java 基础
├── Java 集合框架 (Collections Framework)
├── Java 并发编程 (JUC - Java Util Concurrent)
│   ├── 并发集合 (Concurrent Collections)
│   │   ├── CopyOnWriteArrayList     ← 你在这里
│   │   ├── CopyOnWriteArraySet
│   │   ├── ConcurrentHashMap
│   │   ├── BlockingQueue
│   │   └── ...
│   ├── 锁机制 (Locks)
│   ├── 原子类 (Atomic)
│   └── 线程池 (Executor)
└── JVM 内存模型
```

---

### 💡 记忆口诀
> **"读多写少用COW，写时复制内存高，遍历快照不抛异常，并发场景用得着"**

- **COW** = Copy-On-Write
- **JUC** = Java Util Concurrent