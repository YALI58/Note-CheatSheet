抱歉，是我理解错了，我们换个新的。

这次给你找的是一个 **极简的 HTTP 服务器**——`java-http`。它完全符合你想要的现代感：**零依赖、基于 Java 21 虚拟线程、核心代码轻量**，而且同样能覆盖面向对象、集合、异常处理、NIO 等学习价值，只不过场景从“命令行工具”换成了“网络编程” 。

---

## 📦 项目名称：java-http（精简示例版）

> 注意：`java-http` 本身是一个功能完整的生产级库 。但为了**控制在 1000 行以内**并保持**自包含**，我为你**重新实现了一个精简版本**，只保留最核心的功能，让你能一口气读懂整个服务器的原理。

### ✨ 核心特点
- **纯 Java 21 + 虚拟线程**：体验 Project Loom 带来的简洁并发模型
- **零第三方依赖**：只用 JDK 原生 API
- **约 300 行代码**：完整实现一个能处理静态文件和简单路由的 HTTP 服务器
- **现代 Java 风格**：Record、Pattern Matching、try-with-resources 全部用上


## 📄 完整代码

### 1. 核心服务器类 - `SimpleHttpServer.java`

```java
import com.sun.net.httpserver.Filter;
import com.sun.net.httpserver.HttpContext;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;

import java.io.*;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.Executors;
import java.util.function.BiConsumer;

/**
 * 极简 HTTP 服务器（基于虚拟线程）
 * 演示：网络编程、NIO.2 文件操作、函数式接口、虚拟线程、异常处理
 * 
 * 使用示例：
 * SimpleHttpServer.create(8080)
 *     .get("/", (req, res) -> res.send("Hello World"))
 *     .get("/hello/{name}", (req, res) -> 
 *         res.send("Hello, " + req.pathParam("name")))
 *     .staticFiles("/static", "./webroot")
 *     .start();
 */
public class SimpleHttpServer {
    private final HttpServer server;
    private final Map<String, RouteHandler> getRoutes = new HashMap<>();
    private final Map<String, RouteHandler> postRoutes = new HashMap<>();
    private String staticPath = null;
    private String staticDir = null;

    private SimpleHttpServer(int port) throws IOException {
        // 创建 HttpServer，绑定端口
        this.server = HttpServer.create(new InetSocketAddress(port), 0);
        
        // 设置虚拟线程执行器（Java 21+）
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        
        // 创建根上下文，所有请求都经过这里
        HttpContext context = server.createContext("/");
        context.setHandler(this::handleRequest);
    }

    /**
     * 静态工厂方法
     */
    public static SimpleHttpServer create(int port) throws IOException {
        return new SimpleHttpServer(port);
    }

    /**
     * 注册 GET 路由
     */
    public SimpleHttpServer get(String path, RouteHandler handler) {
        getRoutes.put(path, handler);
        return this;
    }

    /**
     * 注册 POST 路由
     */
    public SimpleHttpServer post(String path, RouteHandler handler) {
        postRoutes.put(path, handler);
        return this;
    }

    /**
     * 设置静态文件目录
     */
    public SimpleHttpServer staticFiles(String urlPath, String directory) {
        this.staticPath = urlPath;
        this.staticDir = directory;
        return this;
    }

    /**
     * 启动服务器
     */
    public void start() {
        server.start();
        System.out.println("🚀 服务器启动在 http://localhost:" + server.getAddress().getPort());
        System.out.println("   静态文件: " + (staticPath != null ? staticPath + " -> " + staticDir : "未启用"));
        System.out.println("   注册的路由: " + (getRoutes.size() + postRoutes.size()) + " 个");
    }

    /**
     * 停止服务器
     */
    public void stop(int delaySeconds) {
        server.stop(delaySeconds);
    }

    /**
     * 统一请求处理器
     */
    private void handleRequest(HttpExchange exchange) throws IOException {
        String method = exchange.getRequestMethod();
        String path = exchange.getRequestURI().getPath();

        try {
            // 1. 处理静态文件
            if (staticPath != null && path.startsWith(staticPath)) {
                serveStaticFile(exchange, path);
                return;
            }

            // 2. 查找动态路由
            Map<String, RouteHandler> routes = method.equals("GET") ? getRoutes : postRoutes;
            RouteMatch match = findRoute(routes, path);

            if (match != null) {
                // 创建请求和响应对象
                Request req = new Request(exchange, match.pathParams);
                Response res = new Response(exchange);
                
                // 执行路由处理器
                match.handler.handle(req, res);
            } else {
                // 404
                String response = "404 - Not Found: " + path;
                exchange.sendResponseHeaders(404, response.getBytes().length);
                try (OutputStream os = exchange.getResponseBody()) {
                    os.write(response.getBytes());
                }
            }
        } catch (Exception e) {
            // 500
            e.printStackTrace();
            String response = "500 - Internal Server Error: " + e.getMessage();
            exchange.sendResponseHeaders(500, response.getBytes().length);
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(response.getBytes());
            }
        } finally {
            exchange.close();
        }
    }

    /**
     * 路由匹配（支持路径参数 /users/{id}）
     * 演示：正则表达式、Map 使用
     */
    private RouteMatch findRoute(Map<String, RouteHandler> routes, String path) {
        // 先尝试完全匹配
        RouteHandler exact = routes.get(path);
        if (exact != null) {
            return new RouteMatch(exact, Map.of());
        }

        // 再尝试模式匹配
        for (Map.Entry<String, RouteHandler> entry : routes.entrySet()) {
            String routePath = entry.getKey();
            if (routePath.contains("{")) {
                // 简单模式匹配：把 {param} 转换成正则 ([^/]+)
                String pattern = routePath.replaceAll("\\{[^/]+\\}", "([^/]+)");
                if (path.matches(pattern)) {
                    // 提取路径参数
                    String[] routeParts = routePath.split("/");
                    String[] pathParts = path.split("/");
                    Map<String, String> params = new HashMap<>();
                    
                    for (int i = 0; i < routeParts.length; i++) {
                        if (routeParts[i].startsWith("{") && routeParts[i].endsWith("}")) {
                            String paramName = routeParts[i].substring(1, routeParts[i].length() - 1);
                            String paramValue = i < pathParts.length ? pathParts[i] : "";
                            params.put(paramName, paramValue);
                        }
                    }
                    return new RouteMatch(entry.getValue(), params);
                }
            }
        }
        return null;
    }

    /**
     * 提供静态文件
     * 演示：NIO.2 文件操作、MIME 类型、流传输
     */
    private void serveStaticFile(HttpExchange exchange, String path) throws IOException {
        // 移除静态路径前缀，得到相对路径
        String relativePath = path.substring(staticPath.length());
        if (relativePath.isEmpty() || relativePath.equals("/")) {
            relativePath = "/index.html";
        }
        
        // 构建文件系统路径，防止路径遍历攻击
        Path filePath = Paths.get(staticDir, relativePath).normalize();
        if (!filePath.startsWith(Paths.get(staticDir).normalize())) {
            exchange.sendResponseHeaders(403, -1); // Forbidden
            return;
        }

        if (Files.exists(filePath) && !Files.isDirectory(filePath)) {
            // 设置 Content-Type
            String contentType = Files.probeContentType(filePath);
            if (contentType != null) {
                exchange.getResponseHeaders().set("Content-Type", contentType);
            }
            
            // 发送文件
            exchange.sendResponseHeaders(200, Files.size(filePath));
            try (OutputStream os = exchange.getResponseBody();
                 InputStream is = Files.newInputStream(filePath)) {
                is.transferTo(os);
            }
        } else {
            exchange.sendResponseHeaders(404, -1);
        }
    }

    /**
     * 路由匹配结果
     */
    private record RouteMatch(RouteHandler handler, Map<String, String> pathParams) {}

    /**
     * 路由处理器函数式接口
     */
    @FunctionalInterface
    public interface RouteHandler {
        void handle(Request req, Response res) throws Exception;
    }
}
```

---

### 2. 请求封装 - `Request.java`

```java
import com.sun.net.httpserver.HttpExchange;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * HTTP 请求封装
 * 演示：Record、不可变对象、流式处理
 */
public record Request(
    String method,
    String path,
    Map<String, String> queryParams,
    Map<String, String> pathParams,
    Map<String, String> headers,
    String body
) {
    public Request(HttpExchange exchange, Map<String, String> pathParams) {
        this(
            exchange.getRequestMethod(),
            exchange.getRequestURI().getPath(),
            parseQueryParams(exchange.getRequestURI().getQuery()),
            pathParams != null ? pathParams : Map.of(),
            parseHeaders(exchange),
            readBody(exchange)
        );
    }

    /**
     * 获取查询参数
     */
    public String queryParam(String name) {
        return queryParams.get(name);
    }

    /**
     * 获取路径参数（如 /users/{id} 中的 id）
     */
    public String pathParam(String name) {
        return pathParams.get(name);
    }

    /**
     * 获取请求头
     */
    public String header(String name) {
        return headers.get(name.toLowerCase());
    }

    /**
     * 解析查询字符串为 Map
     */
    private static Map<String, String> parseQueryParams(String query) {
        Map<String, String> params = new HashMap<>();
        if (query == null || query.isEmpty()) {
            return params;
        }

        for (String pair : query.split("&")) {
            int idx = pair.indexOf("=");
            if (idx > 0) {
                String key = URLDecoder.decode(pair.substring(0, idx), StandardCharsets.UTF_8);
                String value = URLDecoder.decode(pair.substring(idx + 1), StandardCharsets.UTF_8);
                params.put(key, value);
            }
        }
        return params;
    }

    /**
     * 解析请求头为 Map
     */
    private static Map<String, String> parseHeaders(HttpExchange exchange) {
        return exchange.getRequestHeaders().entrySet().stream()
            .collect(Collectors.toMap(
                e -> e.getKey().toLowerCase(),
                e -> String.join(", ", e.getValue())
            ));
    }

    /**
     * 读取请求体
     */
    private static String readBody(HttpExchange exchange) {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(exchange.getRequestBody(), StandardCharsets.UTF_8))) {
            return reader.lines().collect(Collectors.joining("\n"));
        } catch (Exception e) {
            return "";
        }
    }
}
```

---

### 3. 响应封装 - `Response.java`

```java
import com.sun.net.httpserver.HttpExchange;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * HTTP 响应封装
 * 演示：Builder 模式、链式调用
 */
public class Response {
    private final HttpExchange exchange;
    private final Map<String, String> headers = new HashMap<>();
    private int statusCode = 200;

    public Response(HttpExchange exchange) {
        this.exchange = exchange;
        // 默认响应头
        header("Content-Type", "text/plain; charset=UTF-8");
    }

    /**
     * 设置响应头
     */
    public Response header(String name, String value) {
        headers.put(name, value);
        return this;
    }

    /**
     * 设置状态码
     */
    public Response status(int statusCode) {
        this.statusCode = statusCode;
        return this;
    }

    /**
     * 发送 JSON 响应
     */
    public Response json(String json) throws IOException {
        header("Content-Type", "application/json; charset=UTF-8");
        return send(json);
    }

    /**
     * 发送 HTML 响应
     */
    public Response html(String html) throws IOException {
        header("Content-Type", "text/html; charset=UTF-8");
        return send(html);
    }

    /**
     * 发送文本响应
     */
    public Response send(String text) throws IOException {
        byte[] bytes = text.getBytes(StandardCharsets.UTF_8);
        
        // 设置响应头
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            exchange.getResponseHeaders().set(entry.getKey(), entry.getValue());
        }
        
        // 发送响应
        exchange.sendResponseHeaders(statusCode, bytes.length);
        try (OutputStream os = exchange.getResponseBody()) {
            os.write(bytes);
        }
        return this;
    }

    /**
     * 重定向
     */
    public Response redirect(String location) throws IOException {
        exchange.getResponseHeaders().set("Location", location);
        exchange.sendResponseHeaders(302, -1);
        return this;
    }
}
```

---

### 4. 启动类 - `Main.java`

```java
import java.io.IOException;

public class Main {
    public static void main(String[] args) throws IOException {
        // 创建服务器
        var server = SimpleHttpServer.create(8080);
        
        // 注册路由
        server
            // 首页
            .get("/", (req, res) -> 
                res.html("""
                    <!DOCTYPE html>
                    <html>
                    <head><title>极简 Java 服务器</title></head>
                    <body>
                        <h1>🚀 极简 Java HTTP 服务器</h1>
                        <p>基于虚拟线程，核心代码约 300 行</p>
                        <ul>
                            <li><a href="/hello/世界">路径参数示例</a></li>
                            <li><a href="/search?q=java&page=1">查询参数示例</a></li>
                            <li><a href="/static/test.txt">静态文件示例</a></li>
                            <li><a href="/api/time">JSON 响应示例</a></li>
                        </ul>
                    </body>
                    </html>
                    """
                )
            )
            
            // 路径参数示例
            .get("/hello/{name}", (req, res) -> 
                res.html("<h1>你好，" + req.pathParam("name") + "！</h1>")
            )
            
            // 查询参数示例
            .get("/search", (req, res) -> 
                res.send("搜索: " + req.queryParam("q") + 
                        ", 页码: " + req.queryParam("page"))
            )
            
            // JSON 响应示例
            .get("/api/time", (req, res) -> 
                res.json("{\"time\": \"" + new java.util.Date() + "\"}")
            )
            
            // POST 示例
            .post("/api/echo", (req, res) -> 
                res.json("{\"received\": \"" + req.body() + "\"}")
            )
            
            // 静态文件服务（创建 ./webroot/ 目录并放入文件）
            .staticFiles("/static", "./webroot");
        
        // 启动
        server.start();
        
        System.out.println("\n📝 按回车键停止服务器...");
        System.in.read();
        server.stop(0);
        System.out.println("👋 服务器已停止");
    }
}
```

---

### 5. 静态文件示例（可选）

创建 `./webroot/test.txt`：
```
这是一个静态文件示例。
由极简 HTTP 服务器提供。
```

---

## 📚 学习要点

### 1. **现代文件 IO（NIO.2）**
- `Files.exists()`, `Files.size()`, `Files.probeContentType()` 
- `Files.newInputStream()` 流式传输大文件
- `Path.normalize()` 防止路径遍历攻击

### 2. **Java 21 虚拟线程**
- `Executors.newVirtualThreadPerTaskExecutor()` 一行开启虚拟线程 
- 理解传统线程模型 vs 虚拟线程的差异

### 3. **函数式编程**
- `@FunctionalInterface` 定义路由处理器
- Lambda 表达式注册路由
- Stream API 处理请求头

### 4. **集合框架**
- `HashMap` 存储路由表
- `Map.of()` 不可变集合
- `record` 作为轻量级 DTO

### 5. **异常处理**
- 集中式 try-catch 处理 500 错误
- 资源自动关闭（try-with-resources）
- 自定义错误页面

### 6. **网络编程基础**
- HTTP 协议状态码（200, 302, 404, 403, 500）
- 请求/响应生命周期
- MIME 类型

---

## 🚀 如何运行

### 方式一：命令行
```bash
# 创建目录
mkdir -p SimpleHttpServer/src
cd SimpleHttpServer/src

# 将上述四个文件保存到当前目录

# 编译
javac --enable-preview --release 21 *.java

# 运行
java --enable-preview Main
```

### 方式二：IDE（IntelliJ IDEA）
1. 创建新项目，Java 21
2. 复制四个文件到 src 目录
3. 运行 `Main.main()`

---

## 💡 扩展练习

理解了核心代码后，可以尝试添加：

1. **中间件支持**：在路由执行前后添加日志、鉴权
2. **Session 管理**：用 `ConcurrentHashMap` 存储会话
3. **文件上传**：处理 `multipart/form-data`
4. **WebSocket**：升级连接处理
5. **HTTPS**：配置 SSLContext

---

这个项目比 TODO 更贴近后端开发的真实场景，同时保持了代码的简洁性。需要我解释某部分实现，或者帮你扩展某个功能吗？