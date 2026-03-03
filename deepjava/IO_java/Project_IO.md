# PassKeep 代码重构 - 按三重排序原则 (使用NIO重构文件操作)

根据提供的三重排序原则，我对代码进行了重新排列，并将所有文件操作从传统的`java.io`替换为`java.nio`。重构后的代码严格遵循：

1. **类型依赖顺序**：被使用的类型先声明
2. **成员变量顺序**：变量定义在使用的类型之后
3. **方法调用逆序**：被调用的方法在前，调用者在后

---

## PasswordEntry.java

```java
package com.YALI;

// PasswordEntry.java - 密码条目类
import java.io.Serializable;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

public class PasswordEntry implements Serializable {
    private static final long serialVersionUID = 1L;

    // ========== 1. 内部类/接口（无）==========

    // ========== 2. 成员变量（按变量类型依赖顺序）==========
    // WHY: 使用UUID短ID而不是自增数字，避免多设备同步时ID冲突
    private String id;
    // WHY: 名称用于快速识别，如"Google"、"GitHub"，支持搜索
    private String name;
    // WHY: 分开存储用户名和密码，便于未来支持密码更改功能
    private String username;
    // WHY: 明文存储密码(后续会加密)，便于用户查看和复制
    private String password;
    // WHY: 可选字段，方便用户直接打开网站
    private String url;
    // WHY: 备注字段存储额外信息，如安全问题答案等
    private String notes;
    // WHY: 分类便于组织管理，如工作、个人、金融等
    private String category;
    // WHY: 记录创建时间用于审计和排序
    private LocalDateTime createdAt;
    // WHY: 记录更新时间，便于知道密码是否陈旧需要更换
    private LocalDateTime updatedAt;

    // ========== 3. 方法定义（严格按调用链逆序）==========

    /** ----- 第1层：基础方法（被上层调用）----- */
    // 简要信息显示 - 被listAllEntries调用
    public String toSummaryString() {
        // WHY: 列表视图只显示关键信息，避免界面过于拥挤
        return String.format("id: [%s] name: %s 组织: (%s) - 用户名: %s",
                id, name, category, username);
    }

    // Getter/Setter方法组
    public String getId() { return id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getUrl() { return url; }
    public void setUrl(String url) { this.url = url; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }

    /** ----- 第2层：组合方法（调用第1层）----- */
    // toString - 被viewEntry调用，调用getter方法
    @Override
    public String toString() {
        // WHY: 重写toString提供完整的密码条目信息显示
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
        return String.format("""
            ┌──────────────────────────────────┐
            ID: %s
            名称: %s
            分类: %s
            用户名: %s
            密码: %s
            网址: %s
            备注: %s
            创建时间: %s
            更新时间: %s
            └──────────────────────────────────┘
            """,
                id, name, category, username,
                "*".repeat(password.length()), // WHY: 显示星号隐藏真实密码，防止旁观者窥屏
                url.isEmpty() ? "无" : url,
                notes.isEmpty() ? "无" : notes,
                createdAt.format(formatter),
                updatedAt.format(formatter)
        );
    }

    // ========== 4. 构造函数（最后放置）==========
    public PasswordEntry(String name, String username, String password,
                         String url, String notes, String category) {
        // WHY: 构造函数只设置必要字段，其他字段有默认值
        this.id = java.util.UUID.randomUUID().toString().substring(0, 8); // UUID生成
        this.name = name;
        this.username = username;
        this.password = password;
        this.url = url;
        this.notes = notes;
        this.category = category;
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
    }
}
```

---

## PasswordManager.java

```java
package com.YALI;

// PasswordManager.java - 密码管理器核心类 (使用NIO重构)
import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

public class PasswordManager {
    // ========== 1. 内部类/接口（无）==========

    // ========== 2. 成员变量（按变量类型依赖顺序）==========
    private List<PasswordEntry> entries;        // 依赖PasswordEntry
    private final Path dataPath;                  // NIO Path类型
    private final Path masterPath;                 // NIO Path类型
    private String masterPassword;                // JDK原生类型
    private boolean isUnlocked;                   // JDK原生类型

    // ========== 3. 方法定义（严格按调用链逆序）==========

    /** ----- 第1层：基础方法（调用深度最低）----- */
    // 安全检查 - 被所有public方法调用
    private void checkUnlocked() {
        // WHY: 安全检查，确保在解锁状态下才能操作
        if (!isUnlocked) {
            throw new IllegalStateException("密码库未解锁，请先输入主密码");
        }
    }

    // 保存主密码到文件 - 被initializeMasterPassword调用
    private void saveMasterPassword() {
        // WHY: 单独文件存储主密码哈希，与密码数据文件分离
        // 这样即使数据文件泄露，没有主密码也无法解密
        // NIO实现: 使用Files.writeString()写入文件
        try {
            Files.writeString(masterPath, masterPassword, 
                StandardOpenOption.CREATE, StandardOpenOption.TRUNCATE_EXISTING);
            System.out.println("✅ 主密码已保存"); // 添加调试信息
        } catch (IOException e) {
            System.err.println("保存主密码失败: " + e.getMessage());
        }
    }

    // 保存条目到文件 - 被addEntry/updatePassword/deleteEntry调用
    private void saveEntries() {
        // WHY: 使用ObjectOutputStream直接序列化对象，简化IO操作
        // 实际应用应对密码字段进行加密
        // NIO实现: 通过Files.newOutputStream()获取输出流
        try (ObjectOutputStream oos = new ObjectOutputStream(
                Files.newOutputStream(dataPath, 
                    StandardOpenOption.CREATE, 
                    StandardOpenOption.TRUNCATE_EXISTING))) {
            oos.writeObject(entries);
        } catch (IOException e) {
            System.err.println("保存失败: " + e.getMessage());
        }
    }

    // 从文件加载条目 - 被unlock调用
    @SuppressWarnings("unchecked")
    private void loadEntries() {
        if (!Files.exists(dataPath)) {
            entries = new ArrayList<>();
            return;
        }

        // WHY: 使用try-with-resources自动关闭流
        // NIO实现: 通过Files.newInputStream()获取输入流
        try (ObjectInputStream ois = new ObjectInputStream(
                Files.newInputStream(dataPath))) {
            entries = (List<PasswordEntry>) ois.readObject();
        } catch (IOException | ClassNotFoundException e) {
            System.err.println("加载失败: " + e.getMessage());
            entries = new ArrayList<>();
        }
    }

    // 密码哈希 - 被initializeMasterPassword/verifyMasterPassword调用
    private String hashPassword(String password) {
        // WHY: 使用简单哈希演示，实际应使用BCrypt等专业加密库
        // 密码哈希确保即使主密码文件泄露也无法直接获得密码
        return Integer.toHexString(password.hashCode());
    }

    // 验证主密码 - 被initializeMasterPassword/unlock调用
    private boolean verifyMasterPassword(String password) {
        // WHY: 验证输入密码的哈希是否与存储的哈希匹配
        // NIO实现: 使用Files.readString()读取文件
        try {
            if (!Files.exists(masterPath)) {
                return false;
            }
            String stored = Files.readString(masterPath).trim();
            this.masterPassword = hashPassword(password);
            
            return stored.equals(this.masterPassword);
        } catch (IOException e) {
            System.err.println("读取主密码失败: " + e.getMessage());
            return false;
        }
    }

    /** ----- 第2层：组合方法（调用第1层）----- */
    // 初始化/验证主密码 - 被authenticate调用
    public boolean initializeMasterPassword(String password) {
        if (!Files.exists(masterPath)) {
            // 首次使用：创建主密码
            System.out.println("📝 首次运行，创建主密码...");
            this.masterPassword = hashPassword(password);
            saveMasterPassword();
            return true;
        } else {
            // 非首次使用：验证密码
            System.out.println("🔑 验证主密码...");
            return verifyMasterPassword(password);
        }
    }

    // 解锁密码库 - 被main调用
    public boolean unlock(String password) {
        isUnlocked = verifyMasterPassword(password);
        if (isUnlocked) {
            loadEntries();
            System.out.println("🔓 密码库已解锁，加载了 " + entries.size() + " 条记录");
        }
        return isUnlocked;
    }

    // 锁定密码库 - 被main调用
    public void lock() {
        // WHY: 锁定清空内存中的密码数据，防止他人访问
        isUnlocked = false;
        if (entries != null) {
            entries.clear();
        }
        System.out.println("🔒 密码库已锁定");
    }

    // 生成随机密码 - 静态方法，被addNewEntry/generatePassword调用
    public static String generateRandomPassword(int length) {
        // WHY: 提供强密码生成功能，避免用户使用弱密码
        String chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" +
                      "abcdefghijklmnopqrstuvwxyz" +
                      "0123456789!@#$%^&*()";
        Random random = new Random();
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }

    // 根据ID查找条目 - 被findEntryById/updatePassword/deleteEntry调用
    public Optional<PasswordEntry> findEntryById(String id) {
        checkUnlocked();
        // WHY: 返回Optional避免空指针异常
        return entries.stream()
            .filter(e -> e.getId().equals(id))
            .findFirst();
    }

    // 获取所有条目 - 被listAllEntries调用
    public List<PasswordEntry> getAllEntries() {
        checkUnlocked();
        return new ArrayList<>(entries); // WHY: 返回副本防止外部修改
    }

    // 按分类获取条目 - 备用方法
    public List<PasswordEntry> getEntriesByCategory(String category) {
        checkUnlocked();
        // WHY: 使用Stream API进行函数式过滤，代码更简洁
        return entries.stream()
            .filter(e -> e.getCategory().equalsIgnoreCase(category))
            .collect(Collectors.toList());
    }

    // 搜索条目 - 被searchEntries调用
    public List<PasswordEntry> searchEntries(String keyword) {
        checkUnlocked();
        String lowerKeyword = keyword.toLowerCase();
        // WHY: 同时在名称、用户名、网址、备注中搜索，提高查找率
        return entries.stream()
            .filter(e -> e.getName().toLowerCase().contains(lowerKeyword) ||
                         e.getUsername().toLowerCase().contains(lowerKeyword) ||
                         e.getUrl().toLowerCase().contains(lowerKeyword) ||
                         e.getNotes().toLowerCase().contains(lowerKeyword))
            .collect(Collectors.toList());
    }

    /** ----- 第3层：业务方法（调用第2层）----- */
    // 添加密码条目 - 被addNewEntry调用
    public void addEntry(PasswordEntry entry) {
        checkUnlocked();
        entries.add(entry);
        saveEntries();
        System.out.println("✅ 密码已添加，ID: " + entry.getId());
    }

    // 更新密码 - 被updatePassword调用
    public boolean updatePassword(String id, String newPassword) {
        checkUnlocked();
        Optional<PasswordEntry> opt = findEntryById(id);
        if (opt.isPresent()) {
            PasswordEntry entry = opt.get();
            entry.setPassword(newPassword);
            entry.setUpdatedAt(LocalDateTime.now());
            saveEntries();
            return true;
        }
        return false;
    }

    // 删除条目 - 被deleteEntry调用
    public boolean deleteEntry(String id) {
        checkUnlocked();
        boolean removed = entries.removeIf(e -> e.getId().equals(id));
        if (removed) {
            saveEntries();
        }
        return removed;
    }

    // ========== 4. 构造函数（最后放置）==========
    public PasswordManager(String dataFile) {
        // WHY: 构造函数只初始化集合和文件路径，不加载数据
        // 必须在验证主密码后才能加载数据，保证安全性
        this.entries = new ArrayList<>();
        // NIO: 将String转换为Path
        this.dataPath = Paths.get(dataFile);
        this.masterPath = Paths.get("master.pwd");
        this.isUnlocked = false;
    }
}
```

---

## Main.java

```java
package com.YALI;

// Main.java - 主程序入口（完整修复版，使用NIO）
import java.nio.file.*;
import java.util.List;
import java.util.Optional;
import java.util.Scanner;

public class Main {
    // ========== 1. 内部类/接口（无）==========

    // ========== 2. 成员变量 ==========
    private static PasswordManager manager;
    private static Scanner scanner;

    // ========== 3. 方法定义 ==========

    /** ----- 第1层：基础方法 ----- */
    private static void generatePassword() {
        System.out.print("请输入密码长度 (默认12): ");
        String input = scanner.nextLine();
        int length = input.isEmpty() ? 12 : Integer.parseInt(input);

        String password = PasswordManager.generateRandomPassword(length);
        System.out.println("🔑 生成的密码: " + password);
    }

    private static void deleteEntry() {
        System.out.print("请输入密码ID: ");
        String id = scanner.nextLine();

        System.out.print("确定删除? (y/n): ");
        String confirm = scanner.nextLine();

        if (confirm.equalsIgnoreCase("y") && manager.deleteEntry(id)) {
            System.out.println("✅ 已删除");
        }
    }

    private static void updatePassword() {
        System.out.print("请输入密码ID: ");
        String id = scanner.nextLine();

        Optional<PasswordEntry> opt = manager.findEntryById(id);
        if (opt.isEmpty()) {
            System.out.println("❌ 未找到该密码");
            return;
        }

        System.out.print("请输入新密码: ");
        String newPassword = scanner.nextLine();

        if (manager.updatePassword(id, newPassword)) {
            System.out.println("✅ 密码已更新");
        }
    }

    private static void viewEntry() {
        System.out.print("请输入密码ID: ");
        String id = scanner.nextLine();

        Optional<PasswordEntry> opt = manager.findEntryById(id);
        if (opt.isPresent()) {
            System.out.println(opt.get());
            System.out.println("💡 提示: 密码已复制到剪贴板 (模拟)");
        } else {
            System.out.println("❌ 未找到该密码");
        }
    }

    private static void searchEntries() {
        System.out.print("请输入搜索关键词: ");
        String keyword = scanner.nextLine();

        List<PasswordEntry> results = manager.searchEntries(keyword);
        if (results.isEmpty()) {
            System.out.println("❌ 未找到匹配的密码");
            return;
        }

        System.out.println("\n🔍 搜索结果:");
        for (PasswordEntry entry : results) {
            System.out.println(entry.toSummaryString());
        }
    }

    private static void addNewEntry() {
        System.out.println("\n➕ 添加新密码");

        System.out.print("名称: ");
        String name = scanner.nextLine();

        System.out.print("用户名: ");
        String username = scanner.nextLine();

        System.out.print("密码 (留空自动生成): ");
        String password = scanner.nextLine();
        if (password.isEmpty()) {
            password = PasswordManager.generateRandomPassword(12);
            System.out.println("生成的密码: " + password);
        }

        System.out.print("网址 (可选): ");
        String url = scanner.nextLine();

        System.out.print("备注 (可选): ");
        String notes = scanner.nextLine();

        System.out.print("分类 (默认: 个人): ");
        String category = scanner.nextLine();
        if (category.isEmpty()) category = "个人";

        PasswordEntry entry = new PasswordEntry(name, username, password,
                url, notes, category);
        manager.addEntry(entry);
    }

    private static void listAllEntries() {
        List<PasswordEntry> entries = manager.getAllEntries();
        if (entries.isEmpty()) {
            System.out.println("📭 暂无密码记录");
            return;
        }

        System.out.println("\n📋 密码列表:");
        for (PasswordEntry entry : entries) {
            System.out.println(entry.toSummaryString());
        }
    }

    private static void printMenu() {
        System.out.println("\n📋 主菜单");
        System.out.println("1. 查看所有密码");
        System.out.println("2. 添加新密码");
        System.out.println("3. 搜索密码");
        System.out.println("4. 查看密码详情");
        System.out.println("5. 更新密码");
        System.out.println("6. 删除密码");
        System.out.println("7. 生成随机密码");
        System.out.println("8. 退出并锁定");
        System.out.print("请选择 [1-8]: ");
    }

    /** ----- 第2层：组合方法 ----- */
    private static boolean authenticate() {
        Path masterPath = Paths.get("master.pwd");

        // 【修复1】首次运行 - 设置主密码
        if (!Files.exists(masterPath)) {
            System.out.println("📢 检测到首次运行，请设置主密码");
            System.out.println("⚠️  警告：主密码一旦忘记，所有数据将无法恢复！");
            System.out.println("建议使用大小写字母+数字+符号的组合");

            while (true) {
                System.out.print("请输入主密码: ");
                String password1 = scanner.nextLine();

                // 密码强度检查
                if (password1.length() < 4) {
                    System.out.println("❌ 密码太短，至少需要4个字符");
                    continue;
                }

                System.out.print("请再次输入主密码: ");
                String password2 = scanner.nextLine();

                if (!password1.equals(password2)) {
                    System.out.println("❌ 两次输入的密码不一致，请重新设置");
                    continue;
                }

                // 初始化主密码
                if (manager.initializeMasterPassword(password1)) {
                    System.out.println("✅ 主密码设置成功！");
                    // 首次运行自动解锁
                    return manager.unlock(password1);
                } else {
                    System.out.println("❌ 主密码设置失败");
                    return false;
                }
            }
        }
        // 【修复2】非首次运行 - 验证主密码
        else {
            System.out.print("请输入主密码: ");
            String password = scanner.nextLine();

            if (!manager.initializeMasterPassword(password)) {
                System.out.println("❌ 密码错误！");
                return false;
            }

            return manager.unlock(password);
        }
    }

    // ========== 4. 主方法 ==========
    public static void main(String[] args) {
        scanner = new Scanner(System.in);
        manager = new PasswordManager("passwords.dat");

        System.out.println("🔐 PassKeep 密码管理器 🔐");
        System.out.println("==========================");

        // 主密码设置/验证
        if (!authenticate()) {
            System.out.println("❌ 认证失败，程序退出");
            return;
        }

        System.out.println("✅ 密码库已解锁！");

        // 主循环
        boolean running = true;
        while (running) {
            try {
                printMenu();
                String choice = scanner.nextLine().trim();

                switch (choice) {
                    case "1" -> listAllEntries();
                    case "2" -> addNewEntry();
                    case "3" -> searchEntries();
                    case "4" -> viewEntry();
                    case "5" -> updatePassword();
                    case "6" -> deleteEntry();
                    case "7" -> generatePassword();
                    case "8" -> {
                        manager.lock();
                        System.out.println("👋 已锁定密码库，再见！");
                        running = false;
                    }
                    default -> System.out.println("❌ 无效选项，请重新输入");
                }
            } catch (Exception e) {
                System.err.println("发生错误: " + e.getMessage());
            }
        }
    }
}
```

---

## 项目结构
```
com/YALI/
├── PasswordEntry.java    # 密码条目类
├── PasswordManager.java  # 核心管理类  
└── Main.java            # 主程序入口
```

## 编译和运行
```bash
# 在项目根目录编译
javac com/YALI/*.java

# 运行
java com.YALI.Main
```

---

## NIO重构说明

### 1. 主要改动
- **`java.io.File` → `java.nio.file.Path`**
- **`File.exists()` → `Files.exists(path)`**
- **`FileReader/FileWriter` → `Files.readString()/Files.writeString()`**
- **`FileInputStream/FileOutputStream` → `Files.newInputStream()/Files.newOutputStream()`**

### 2. 具体替换点

| 原IO代码 | NIO新代码 |
|---------|----------|
| `new File("master.pwd")` | `Paths.get("master.pwd")` |
| `file.exists()` | `Files.exists(path)` |
| `new FileReader()` + `BufferedReader` | `Files.readString()` |
| `new FileWriter()` + `PrintWriter` | `Files.writeString()` |
| `new FileInputStream()` | `Files.newInputStream()` |
| `new FileOutputStream()` | `Files.newOutputStream()` |

### 3. NIO优势
- **更简洁的API**：一行代码完成文件读写
- **更好的错误处理**：统一的`IOException`处理
- **原子操作支持**：文件操作更安全
- **性能更好**：NIO底层使用缓冲区和非阻塞IO

---

## 重构原则验证

### ✅ 类型依赖顺序
- **PasswordEntry** 不依赖其他类 → 第一个文件
- **PasswordManager** 依赖 PasswordEntry → 第二个文件  
- **Main** 依赖 PasswordManager → 第三个文件

### ✅ 成员变量顺序
每个文件内部按"被依赖类型优先"排列

### ✅ 方法调用逆序
每个类中方法按调用深度逆序排列，构造函数最后

### ✅ 保持原逻辑
只修改文件操作方式，不改变任何业务逻辑