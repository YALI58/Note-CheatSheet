## Pattern 和 Matcher 速查表（简洁版）

### 一、Pattern 类

#### **创建 Pattern**
```java
Pattern p = Pattern.compile("\\d+");                          // 基础编译
Pattern p = Pattern.compile("abc", Pattern.CASE_INSENSITIVE); // 忽略大小写
```

#### **常用标志**
- `CASE_INSENSITIVE` - 忽略大小写
- `MULTILINE` - ^$匹配每行
- `DOTALL` - .匹配换行符

#### **常用方法**
```java
Pattern.matches("\\d+", "123");        // true（静态全匹配）
p.matcher("abc123");                    // 创建Matcher
p.split("a1b2c3");                      // [a, b, c]
p.pattern();                             // 返回正则字符串
```

### 二、Matcher 类

#### **基础匹配**
```java
Matcher m = p.matcher("abc123");
m.matches();      // 完全匹配
m.find();         // 查找下一个
m.lookingAt();    // 从开头匹配
```

#### **获取结果**
```java
m.group();        // 当前匹配串
m.start();        // 起始索引
m.end();          // 结束索引
m.group(1);       // 获取分组1
m.groupCount();   // 分组数量
```

#### **替换操作**
```java
m.replaceAll("*");     // 替换全部
m.replaceFirst("*");   // 替换第一个
```

### 三、常用示例

#### **1. 完全匹配**
```java
// 检查是否为数字
Pattern.matches("\\d+", "123");  // true
```

#### **2. 查找所有匹配**
```java
Matcher m = Pattern.compile("\\d+").matcher("a1b2c3");
while (m.find()) {
    System.out.println(m.group());  // 1, 2, 3
}
```

#### **3. 使用分组**
```java
Matcher m = Pattern.compile("(\\d{4})-(\\d{2})").matcher("2023-12");
if (m.find()) {
    m.group(1);  // 2023
    m.group(2);  // 12
}
```

#### **4. 性能优化（重用Pattern）**
```java
// 不推荐（每次都编译）
for (String s : list) Pattern.matches("\\d+", s);

// 推荐（编译一次）
Pattern p = Pattern.compile("\\d+");
for (String s : list) p.matcher(s).matches();
```

### 四、正则基础语法

| 语法 | 说明 | 示例 |
|------|------|------|
| `\d` | 数字 | `\d+` 匹配1个以上数字 |
| `\w` | 字母、数字、下划线 | `\w+` 匹配单词 |
| `\s` | 空白符 | `\s*` 匹配0个以上空白 |
| `.` | 任意字符 | `.*` 匹配任意内容 |
| `^` | 开头 | `^Hello` 以Hello开头 |
| `$` | 结尾 | `World$` 以World结尾 |
| `[abc]` | a或b或c | `[0-9]` 数字范围 |
| `[^abc]` | 非a、b、c | `[^0-9]` 非数字 |
| `X?` | 0或1次 | `colou?r` 匹配color/colour |
| `X*` | 0或多次 | `ab*c` 匹配ac/abc/abbc |
| `X+` | 1或多次 | `ab+c` 匹配abc/abbc |
| `X{n}` | 恰好n次 | `\d{4}` 4位数字 |
| `(X)` | 捕获组 | `(\\d{4})` 捕获4位数字 |
| `(?:X)` | 非捕获组 | `(?:https?):` 不捕获协议 |
| `(?=X)` | 正向预查 | `\\d+(?=元)` 数字后面跟"元" |
| `(?!X)` | 负向预查 | `\\d+(?!元)` 数字后面不跟"元" |

### 五、快速实战

```java
// 验证邮箱
Pattern.compile("^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$")
       .matcher("test@example.com").matches();

// 提取数字
Pattern.compile("\\d+").matcher("价格100元").find();  // 100

// 替换手机号中间4位
Pattern.compile("(\\d{3})\\d{4}(\\d{4})")
       .matcher("13812345678").replaceAll("$1****$2");  // 138****5678
```

### 六、最佳实践

1. **重用Pattern**避免重复编译
2. **预编译常用正则**为static final
3. **用matches()**检查完全匹配
4. **用find()**查找子串
5. **复杂正则加注释**提高可读性

这样就够用了，需要详细讲解某个部分吗？