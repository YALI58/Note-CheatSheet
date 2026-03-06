## Java Optional 最佳实践与常见陷阱

### 🎯 方法选择速查表

| 你想做什么 | 推荐方法 | 替代方案 |
|------------|----------|----------|
| **取值，有就用，没有给个默认** | `orElse(default)` | 默认值简单时用 |
| **取值，默认值需要计算** | `orElseGet(supplier)` | 避免无谓计算 |
| **取值，没有就报错** | `orElseThrow(ex)` | 明确异常意图 |
| **转换值** | `map(function)` | 配合链式调用 |
| **过滤值** | `filter(predicate)` | 只保留想要的 |
| **有值才做某事** | `ifPresent(consumer)` | 替代 `if (opt.isPresent())` |
| **有值没值都处理** | `ifPresentOrElse(consumer, runnable)` | Java 9+ 替代 if-else |
| **判断是否有值** | `isPresent()`/`isEmpty()` | Java 11 起用 `isEmpty()` 更直观 |
| **绝对确定有值** | `get()` | **不推荐**，除非你能 100% 确定 |

---

### 💡 一句话记住每个方法

| 方法 | 记忆口诀 |
|------|----------|
| `of()` | 确定有值就用我，null 进来就翻脸 |
| `ofNullable()` | 可能有值可能空，我都接着 |
| `empty()` | 我就是个空盒子 |
| `orElse()` | 有值用值，没值用备胎（备胎先准备好） |
| `orElseGet()` | 有值用值，没值现造（需要时才造） |
| `orElseThrow()` | 没值就发脾气（抛异常） |
| `map()` | 有值就变身，没值就躺平 |
| `flatMap()` | 变身完还是盒子？我来拆开 |
| `filter()` | 符合条件的留下，否则滚蛋 |
| `ifPresent()` | 有值就干活，没值就歇着 |
| `ifPresentOrElse()` | 有值没值都得干活 |
| `get()` | 暴力拆盒，没有就崩（别用我） |

---

### 📝 快速参考：链式调用模板

```java
// 标准链式模板
Optional.ofNullable(可能为空的对象)
    .map(对象::获取属性)           // 转换1
    .map(属性::进一步获取)         // 转换2
    .filter(条件)                  // 过滤
    .orElse(默认值);               // 兜底

// 消费模板
Optional.ofNullable(对象)
    .ifPresent(对象 -> {
        // 有值时的处理
    });

// 异常模板
Optional.ofNullable(参数)
    .orElseThrow(() -> new IllegalArgumentException("参数不能为空"));
```

---

### 🚫 常见误区与反模式

#### 误区1：滥用 `get()`
```java
// ❌ 错误
Optional<String> opt = getUserName();
if (opt.isPresent()) {
    String name = opt.get();  // 多此一举
}

// ✅ 正确
opt.ifPresent(name -> System.out.println(name));

// 或者
String name = opt.orElse("默认");
```

#### 误区2：用 Optional 做参数
```java
// ❌ 错误
public void process(Optional<String> name) {  // 不要这样做
    name.ifPresent(n -> ...);
}

// ✅ 正确
public void process(String name) {  // name 可以为 null
    Optional.ofNullable(name).ifPresent(n -> ...);
}

// 或者用重载
public void process() { ... }
public void process(String name) { ... }
```

#### 误区3：用 Optional 做字段类型
```java
// ❌ 错误
public class User {
    private Optional<String> email;  // 不要这样做
}

// ✅ 正确
public class User {
    private String email;  // 可以为 null
}

// 在 getter 中返回 Optional
public Optional<String> getEmail() {
    return Optional.ofNullable(email);
}
```

#### 误区4：忘记 Optional 本身可以为 null
```java
// ❌ 危险
Optional<String> opt = getOptional();  // 可能返回 null
opt.orElse("默认");  // 如果 opt 为 null，抛 NPE

// ✅ 安全
Optional<String> opt = Optional.ofNullable(getOptional());
opt.orElse("默认");
```

---

### 📊 版本特性总结

| 版本 | 新增方法 | 说明 |
|------|----------|------|
| **Java 8** | 基础方法：`of`, `ofNullable`, `empty`, `isPresent`, `get`, `orElse`, `orElseGet`, `orElseThrow`, `map`, `flatMap`, `filter`, `ifPresent` | 基础功能 |
| **Java 9** | `ifPresentOrElse`, `or`, `stream` | 增强消费、流支持 |
| **Java 10** | `orElseThrow()`（无参） | 简化抛异常写法 |
| **Java 11** | `isEmpty()` | 更直观的空值判断 |

---

### 🎮 实战示例

#### 示例1：从对象链中安全取值
```java
// 传统写法（容易 NPE）
String city = null;
if (user != null) {
    Address addr = user.getAddress();
    if (addr != null) {
        city = addr.getCity();
    }
}

// Optional 写法
String city = Optional.ofNullable(user)
    .map(User::getAddress)
    .map(Address::getCity)
    .orElse("未知城市");
```

#### 示例2：集合操作
```java
// 从列表中查找并处理
List<User> users = getUserList();
Optional<User> found = users.stream()
    .filter(u -> "admin".equals(u.getRole()))
    .findFirst();

// 处理结果
found.ifPresentOrElse(
    u -> promoteUser(u),
    () -> createDefaultAdmin()
);
```

#### 示例3：配合 Stream 使用
```java
// 过滤掉空值
List<Optional<String>> optionals = Arrays.asList(
    Optional.of("a"),
    Optional.empty(),
    Optional.of("b")
);

List<String> values = optionals.stream()
    .flatMap(Optional::stream)  // Java 9+ 过滤空值并展开
    .collect(Collectors.toList());  // [a, b]

// Java 8 写法
List<String> values = optionals.stream()
    .filter(Optional::isPresent)
    .map(Optional::get)
    .collect(Collectors.toList());
```

#### 示例4：异常处理
```java
// 转换异常为 Optional
public Optional<Integer> parseInt(String s) {
    try {
        return Optional.of(Integer.parseInt(s));
    } catch (NumberFormatException e) {
        return Optional.empty();
    }
}

// 使用
Optional<Integer> num = parseInt("123")
    .map(x -> x * 2)
    .filter(x -> x > 0);
```

---

### 📝 编码规范建议

1. **返回值使用 Optional，不要用于字段和参数**
2. **避免在序列化类中使用 Optional**
3. **不要用 Optional 做集合元素**
4. **优先使用 orElseGet 而不是 orElse，如果默认值需要计算**
5. **不要对 Optional 本身用 == 判空，用 Optional.ofNullable 包装**

```java
// 规范示例
public class UserService {
    
    // ✅ 返回值用 Optional
    public Optional<User> findById(Long id) {
        User user = userRepo.find(id);
        return Optional.ofNullable(user);
    }
    
    // ✅ 参数用普通类型，内部处理
    public void updateEmail(Long userId, String email) {
        Optional.ofNullable(userId)
            .flatMap(this::findById)
            .ifPresent(user -> user.setEmail(email));
    }
}
```

---

### 🎯 总结

| 场景 | 推荐做法 |
|------|----------|
| **创建 Optional** | `ofNullable` 最安全，`of` 只在确定非空时用 |
| **取值** | `orElse`/`orElseGet`/`orElseThrow`，别用 `get` |
| **转换** | `map`/`flatMap` 链式调用 |
| **过滤** | `filter` 筛选符合条件的值 |
| **消费** | `ifPresent`/`ifPresentOrElse` |
| **判断** | Java 11+ 用 `isEmpty()`，之前用 `!isPresent()` |

**记住核心思想：Optional 是为了让你**：
- **明确表达"可能有值可能没值"的语义**
- **强制调用方处理空值情况**
- **用函数式编程替代繁琐的 if-null 检查**