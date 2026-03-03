下面给你一份 **Java NIO （NIO.2） 文件操作速查表**，涵盖日常开发中 90% 的场景。

这份速查表以 `java.nio.file` 包下的 `Paths`、`Path`、`Files` 为核心，配合 `java.nio.file.attribute` 包处理文件属性。

---

### 一、 核心类简介

| 类名 | 作用 |
| :--- | :--- |
| **`Path`** | 路径的现代化表示（替代 `java.io.File`）。 |
| **`Paths`** | 工具类，唯一作用是通过 `Paths.get()` 获取 `Path` 对象。 |
| **`Files`** | **核心工具类**，包含大量静态方法操作文件（读写、复制、移动、删除、获取属性）。 |
| **`FileSystems`** | 获取文件系统，用于获取路径分隔符等。 |

---

### 二、 获取路径

```java
// 推荐：使用 Paths.get()
Path path1 = Paths.get("/home/user/logs/app.log");
Path path2 = Paths.get("C:/data/config/settings.properties"); // Windows

// 拼接路径：自动处理分隔符
Path path3 = Paths.get("/home", "user", "logs", "app.log");

// 相对路径
Path relativePath = Paths.get("logs/app.log");

// 当前目录
Path currentDir = Paths.get(".").toAbsolutePath();

// 从 File 对象转换 (兼容旧代码)
File file = new File("test.txt");
Path pathFromFile = file.toPath();

// Path 转 File
File fileFromPath = pathFromFile.toFile();
```

---

### 三、 文件/目录元数据操作

```java
Path path = Paths.get("/home/user/test.txt");

// 检查存在性
boolean exists = Files.exists(path);
boolean notExists = Files.notExists(path);
boolean isDirectory = Files.isDirectory(path);
boolean isRegularFile = Files.isRegularFile(path); // 是否普通文件
boolean isReadable = Files.isReadable(path);
boolean isWritable = Files.isWritable(path);
boolean isExecutable = Files.isExecutable(path);
boolean isHidden = Files.isHidden(path); // 需要捕获异常

// 获取文件大小 (字节)
long size = Files.size(path);

// 获取最后修改时间
FileTime lastModifiedTime = Files.getLastModifiedTime(path);

// 获取/设置文件权限 (POSIX)
// Set<PosixFilePermission> perms = Files.getPosixFilePermissions(path);
// Files.setPosixFilePermissions(path, perms);

// 获取文件所有者
// UserPrincipal owner = Files.getOwner(path);
```

---

### 四、 目录操作

```java
// 创建单级目录
Path dir = Paths.get("/home/user/newdir");
Files.createDirectory(dir); // 如果父目录不存在，会抛异常

// 创建多级目录 (包含不存在的父目录)
Path multiDir = Paths.get("/home/user/data/logs/2024");
Files.createDirectories(multiDir); // 常用！

// 创建临时目录
Path tmpDir = Files.createTempDirectory("myAppPrefix");

// 遍历目录 (非递归)
try (DirectoryStream<Path> stream = Files.newDirectoryStream(dir)) {
    for (Path entry : stream) {
        System.out.println(entry.getFileName());
    }
}

// 遍历目录 (递归，现代写法，返回 Stream)
// 深度优先，需要关闭 Stream
try (Stream<Path> walk = Files.walk(dir)) {
    walk.filter(Files::isRegularFile) // 只保留文件
        .forEach(System.out::println);
}
```

---

### 五、 文件操作（复制、移动、删除）

```java
Path source = Paths.get("/home/user/source.txt");
Path target = Paths.get("/home/user/target.txt");

// 复制文件
Files.copy(source, target); // 如果 target 已存在，抛异常
Files.copy(source, target, StandardCopyOption.REPLACE_EXISTING); // 覆盖
Files.copy(source, target, StandardCopyOption.COPY_ATTRIBUTES); // 复制属性

// 移动/重命名文件
Files.move(source, target, StandardCopyOption.REPLACE_EXISTING);

// 删除文件
Files.delete(target); // 文件不存在抛异常
boolean deleted = Files.deleteIfExists(target); // 安全删除，返回是否成功

// 创建符号链接/硬链接
Path link = Paths.get("/home/user/link_to_source.txt");
Files.createSymbolicLink(link, source); // 需要权限
// Files.createLink(link, source); // 硬链接
```

---

### 六、 读写文件内容（最常用）

NIO 最大的优势就是简化了读写操作，再也不用写长串的 `while` 循环了。

#### 1. 小文件读写 (直接全部读入内存)

```java
Path path = Paths.get("/home/user/data.txt");

// 读所有字节 (适用于图片、二进制)
byte[] bytes = Files.readAllBytes(path);

// 读所有行 (适用于文本文件)
List<String> lines = Files.readAllLines(path, StandardCharsets.UTF_8);

// 写入字节
Files.write(path, bytes);

// 写入行 (覆盖模式)
List<String> content = Arrays.asList("第一行", "第二行");
Files.write(path, content, StandardCharsets.UTF_8);

// 追加内容
Files.write(path, "追加的内容".getBytes(), StandardOpenOption.APPEND);
Files.write(path, Arrays.asList("追加行"), StandardCharsets.UTF_8,
            StandardOpenOption.CREATE, StandardOpenOption.APPEND);
```

#### 2. 大文件读写 (使用缓冲流)

```java
Path path = Paths.get("/home/user/bigfile.log");

// 写 (使用缓冲)
try (BufferedWriter writer = Files.newBufferedWriter(path, StandardCharsets.UTF_8)) {
    writer.write("Hello");
    writer.newLine();
    writer.write("World");
}

// 读 (使用缓冲，按行读取)
try (BufferedReader reader = Files.newBufferedReader(path, StandardCharsets.UTF_8)) {
    String line;
    while ((line = reader.readLine()) != null) {
        System.out.println(line);
    }
}

// 使用 Stream API 处理大文件 (懒加载，不会一次性读入内存)
try (Stream<String> stream = Files.lines(path, StandardCharsets.UTF_8)) {
    stream.filter(l -> l.contains("ERROR"))
          .limit(10)
          .forEach(System.out::println);
}
```

#### 3. 输入输出流

```java
Path path = Paths.get("/home/user/image.jpg");

// 获取 InputStream (读)
try (InputStream in = Files.newInputStream(path)) {
    // 处理流
}

// 获取 OutputStream (写)
try (OutputStream out = Files.newOutputStream(path)) {
    // 处理流
}
```

---

### 七、 路径操作

```java
Path path = Paths.get("/home/user/docs/../files/report.txt");

// 获取文件名
Path fileName = path.getFileName(); // report.txt

// 获取父路径
Path parent = path.getParent(); // /home/user/docs/../files

// 获取根路径
Path root = path.getRoot(); // /

// 获取名称元素个数
int nameCount = path.getNameCount();

// 获取子路径
Path subPath = path.subpath(0, 2); // home/user

// 规范化路径 (去掉 . 和 ..)
Path normalized = path.normalize(); // /home/user/files/report.txt

// 转换为绝对路径
Path absolutePath = path.toAbsolutePath();

// 解析/合并路径
Path base = Paths.get("/home/user");
Path resolved = base.resolve("docs/report.txt"); // /home/user/docs/report.txt

// 相对化：从 base 到 target 的相对路径
Path target = Paths.get("/home/user/files/data.txt");
Path relative = base.relativize(target); // ../files/data.txt
```

---

### 八、 文件监听（WatchService）

监听目录下的文件变化（创建、修改、删除）。

```java
// 简易示例
WatchService watchService = FileSystems.getDefault().newWatchService();
Path dir = Paths.get("/home/user/watchdir");

// 注册监听事件
dir.register(watchService,
        StandardWatchEventKinds.ENTRY_CREATE,
        StandardWatchEventKinds.ENTRY_MODIFY,
        StandardWatchEventKinds.ENTRY_DELETE);

// 无限循环监听
while (true) {
    WatchKey key = watchService.take(); // 阻塞直到有事件
    for (WatchEvent<?> event : key.pollEvents()) {
        WatchEvent.Kind<?> kind = event.kind();
        Path filename = (Path) event.context();
        System.out.println(kind.name() + ": " + filename);
    }
    boolean valid = key.reset();
    if (!valid) break; // 目录不可用，退出
}
```

---

### 速查总结

| 你想做什么 | 一句话代码示例 |
| :--- | :--- |
| **读全部文本** | `Files.readAllLines(Paths.get("a.txt"))` |
| **写全部文本** | `Files.write(Paths.get("a.txt"), lines)` |
| **按行读大文件** | `Files.lines(path).filter(...)` |
| **复制文件** | `Files.copy(src, dst, REPLACE_EXISTING)` |
| **创建多级目录** | `Files.createDirectories(path)` |
| **遍历目录** | `Files.walk(rootDir).filter(Files::isRegularFile)` |
| **获取文件大小** | `Files.size(path)` |
| **移动/重命名** | `Files.move(src, dst)` |
| **删除文件** | `Files.deleteIfExists(path)` |

**记住：** 遇到文件操作，首先想能不能用 `Files.xxx()` 一行搞定。