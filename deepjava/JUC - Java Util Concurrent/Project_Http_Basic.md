我来为你重新实现这个HTTP服务器，**增强集合框架的存在感**并添加**why型注释**。集合框架不仅仅是存储数据，更是整个服务器的核心支撑！

---

## 📦 项目名称：java-http（集合框架增强版）

### ✨ 核心特点升级
- **集合框架深度应用**：不仅是存储，更是策略、缓存、路由匹配的核心
- **why型注释**：解释为什么用这个集合，而不是其他
- **性能优化**：针对不同场景选择最优集合实现
- **约 400 行代码**：更丰富的集合操作示例

---

## 📄 完整代码

### 1. 核心服务器类 - `SimpleHttpServer.java`

```java
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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.function.BiConsumer;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * 极简 HTTP 服务器 - 集合框架增强版
 * 
 * 为什么这样设计：
 * 1. 集合框架是整个服务器的"骨架"，路由表、参数解析、缓存都需要集合
 * 2. 不同场景选择不同集合实现，体现对性能的理解
 * 3. 集合的操作（查找、遍历、转换）贯穿整个请求生命周期
 */
public class SimpleHttpServer {
    private final HttpServer server;
    
    // 为什么用两个Map分别存储GET和POST？
    // - 方法分开展示了Map作为路由表的经典用法
    // - 避免了在同一个Map中存储复合键（方法+路径）的复杂度
    // - 查询时直接按方法选择Map，时间复杂度O(1)
    private final Map<String, RouteHandler> getRoutes = new HashMap<>();
    private final Map<String, RouteHandler> postRoutes = new HashMap<>();
    
    // 为什么用LinkedHashMap存储路径参数？
    // - 保持参数插入顺序，便于调试和日志记录
    // - 预计算路由的正则表达式，空间换时间
    private final Map<String, CompiledRoute> compiledGetRoutes = new LinkedHashMap<>();
    private final Map<String, CompiledRoute> compiledPostRoutes = new LinkedHashMap<>();
    
    // 为什么用CopyOnWriteArrayList存储过滤器？
    // - 过滤器链通常在启动时配置，运行时很少修改
    // - 读多写少的场景，CopyOnWriteArrayList提供无锁并发读
    private final List<Filter> filters = new CopyOnWriteArrayList<>();
    
    // 为什么用ConcurrentHashMap作为缓存？
    // - 多线程环境下的安全访问
    // - 高并发时性能优于Hashtable和Collections.synchronizedMap
    // - 支持原子性的putIfAbsent操作
    private final Map<String, CachedFile> fileCache = new ConcurrentHashMap<>();
    
    // 静态文件配置
    private String staticPath = null;
    private Path staticDir = null;
    
    // 为什么用EnumSet？
    // - 比HashSet更高效，基于位向量实现
    // - 类型安全，只能包含HttpMethod枚举
    private Set<HttpMethod> supportedMethods = EnumSet.of(HttpMethod.GET, HttpMethod.POST);

    private SimpleHttpServer(int port) throws IOException {
        this.server = HttpServer.create(new InetSocketAddress(port), 0);
        server.setExecutor(Executors.newVirtualThreadPerTaskExecutor());
        
        HttpContext context = server.createContext("/");
        context.setHandler(this::handleRequest);
        
        // 预编译所有路由（启动时一次性工作）
        precompileRoutes();
    }

    /**
     * 预编译路由：典型的空间换时间策略
     * 为什么这样做？因为路由表是静态的，运行时不需要重新编译
     */
    private void precompileRoutes() {
        // 使用Map的entrySet遍历，避免重复查找
        for (Map.Entry<String, RouteHandler> entry : getRoutes.entrySet()) {
            compiledGetRoutes.put(entry.getKey(), 
                new CompiledRoute(entry.getKey(), entry.getValue()));
        }
        for (Map.Entry<String, RouteHandler> entry : postRoutes.entrySet()) {
            compiledPostRoutes.put(entry.getKey(), 
                new CompiledRoute(entry.getKey(), entry.getValue()));
        }
    }

    public static SimpleHttpServer create(int port) throws IOException {
        return new SimpleHttpServer(port);
    }

    /**
     * 链式调用：返回this便于连续配置
     * 这是Builder模式的简化版
     */
    public SimpleHttpServer get(String path, RouteHandler handler) {
        getRoutes.put(path, handler);
        return this;
    }

    public SimpleHttpServer post(String path, RouteHandler handler) {
        postRoutes.put(path, handler);
        return this;
    }

    /**
     * 添加过滤器：装饰器模式的体现
     * 过滤器存储在List中，形成责任链
     */
    public SimpleHttpServer filter(Filter filter) {
        filters.add(filter);
        return this;
    }

    public SimpleHttpServer staticFiles(String urlPath, String directory) {
        this.staticPath = urlPath;
        this.staticDir = Paths.get(directory).normalize();
        return this;
    }

    public void start() {
        server.start();
        System.out.println("🚀 服务器启动在 http://localhost:" + server.getAddress().getPort());
        System.out.println("   路由统计:");
        System.out.println("   - GET 路由: " + getRoutes.size() + " 个");
        System.out.println("   - POST 路由: " + postRoutes.size() + " 个");
        System.out.println("   - 过滤器: " + filters.size() + " 个");
        System.out.println("   静态文件: " + (staticPath != null ? staticPath + " -> " + staticDir : "未启用"));
        System.out.println("   文件缓存: " + fileCache.size() + " 个");
    }

    public void stop(int delaySeconds) {
        server.stop(delaySeconds);
        // 清理缓存
        fileCache.clear();
    }

    /**
     * 请求处理器 - 集合操作的"展示舞台"
     */
    private void handleRequest(HttpExchange exchange) throws IOException {
        String method = exchange.getRequestMethod();
        String path = exchange.getRequestURI().getPath();
        
        // 为什么创建Request对象？
        // - 封装原始HttpExchange，提供更友好的API
        // - 作为数据载体在过滤器链中传递
        Request req = new Request(exchange);
        Response res = new Response(exchange);

        try {
            // 1. 执行过滤器链 - 体现List的遍历和短路特性
            for (Filter filter : filters) {
                if (!filter.filter(req, res)) {
                    return; // 过滤器返回false，中断处理
                }
            }

            // 2. 处理方法不支持检查
            if (!supportedMethods.contains(HttpMethod.fromString(method))) {
                res.status(405).send("Method Not Allowed");
                return;
            }

            // 3. 静态文件处理
            if (staticPath != null && path.startsWith(staticPath)) {
                serveStaticFile(req, res);
                return;
            }

            // 4. 动态路由处理 - 展示Map的查找策略
            Map<String, CompiledRoute> routes = method.equals("GET") ? 
                compiledGetRoutes : compiledPostRoutes;
            
            // 为什么先用精确匹配？
            // - HashMap的get是O(1)，比遍历快得多
            // - 大多数路由是精确匹配，优先处理常见情况
            CompiledRoute exactRoute = routes.get(path);
            if (exactRoute != null) {
                exactRoute.handler.handle(req, res);
                return;
            }

            // 5. 参数化路由匹配 - 展示Map的遍历和模式匹配
            // 为什么用entrySet遍历而不是values()？
            // - 需要同时访问路由模式和处理器
            // - entrySet()比分别遍历keys和values更高效
            for (Map.Entry<String, CompiledRoute> entry : routes.entrySet()) {
                CompiledRoute route = entry.getValue();
                Map<String, String> pathParams = route.match(path);
                if (pathParams != null) {
                    // 使用不可变Map存储路径参数
                    // - 保证线程安全
                    // - 防止处理器意外修改
                    req.setPathParams(Collections.unmodifiableMap(pathParams));
                    route.handler.handle(req, res);
                    return;
                }
            }

            // 6. 404 - 没有找到路由
            res.status(404).send("404 Not Found: " + path);

        } catch (Exception e) {
            // 7. 500错误处理
            e.printStackTrace();
            res.status(500).send("500 Internal Server Error");
        }
    }

    /**
     * 静态文件服务 - 展示缓存和NIO的结合
     */
    private void serveStaticFile(Request req, Response res) throws IOException {
        String path = req.path();
        String relativePath = path.substring(staticPath.length());
        if (relativePath.isEmpty() || relativePath.equals("/")) {
            relativePath = "/index.html";
        }
        
        // 为什么用Path而不是String？
        // - Path提供更好的路径操作方法
        // - resolve和normalize可以防止路径遍历攻击
        Path filePath = staticDir.resolve(relativePath.substring(1)).normalize();
        
        // 安全检查：文件必须在静态目录内
        if (!filePath.startsWith(staticDir)) {
            res.status(403).send("Forbidden");
            return;
        }

        // 为什么用ConcurrentHashMap作为缓存？
        // - 多线程并发读写的安全性
        // - 使用computeIfAbsent实现原子性的"缓存未命中则加载"
        CachedFile cached = fileCache.computeIfAbsent(filePath.toString(), key -> {
            try {
                Path path_key = Paths.get(key);
                if (Files.exists(path_key) && !Files.isDirectory(path_key)) {
                    return new CachedFile(
                        Files.readAllBytes(path_key),
                        Files.probeContentType(path_key),
                        Files.getLastModifiedTime(path_key).toMillis()
                    );
                }
            } catch (IOException e) {
                // 记录错误但返回null
            }
            return null;
        });

        if (cached != null) {
            // 使用缓存响应
            res.header("Content-Type", cached.contentType)
               .header("Cache-Control", "public, max-age=3600")
               .header("Last-Modified", new Date(cached.lastModified).toString())
               .send(cached.content);
        } else {
            res.status(404).send("File Not Found");
        }
    }

    /**
     * 编译后的路由 - 存储预计算的正则表达式
     * 为什么用record？因为它是不可变的，天然线程安全
     */
    private record CompiledRoute(
        String pattern,
        RouteHandler handler,
        Pattern regex,
        List<String> paramNames
    ) {
        public CompiledRoute(String pattern, RouteHandler handler) {
            this(pattern, handler, compilePattern(pattern), extractParamNames(pattern));
        }

        private static Pattern compilePattern(String pattern) {
            if (!pattern.contains("{")) {
                return null; // 精确匹配不需要正则
            }
            // 将 {param} 转换为命名捕获组 (?<param>[^/]+)
            String regex = pattern.replaceAll("\\{([^/]+)\\}", "(?<$1>[^/]+)");
            return Pattern.compile("^" + regex + "$");
        }

        private static List<String> extractParamNames(String pattern) {
            List<String> names = new ArrayList<>();
            java.util.regex.Matcher m = Pattern.compile("\\{([^/]+)\\}").matcher(pattern);
            while (m.find()) {
                names.add(m.group(1));
            }
            // 为什么返回不可变List？
            // - 保证线程安全
            // - 节省内存
            return Collections.unmodifiableList(names);
        }

        public Map<String, String> match(String path) {
            if (regex == null) {
                return null; // 精确匹配已经在之前处理
            }
            
            java.util.regex.Matcher m = regex.matcher(path);
            if (!m.matches()) {
                return null;
            }
            
            // 为什么用HashMap而不是ImmutableMap.Builder？
            // - 需要在运行时动态构建
            // - 参数数量通常很少（<=5），HashMap足够高效
            Map<String, String> params = new HashMap<>();
            for (String name : paramNames) {
                params.put(name, m.group(name));
            }
            return params;
        }
    }

    /**
     * 缓存文件 - 演示Record的另一个用法
     */
    private record CachedFile(byte[] content, String contentType, long lastModified) {}

    /**
     * HTTP方法枚举 - 配合EnumSet使用
     */
    private enum HttpMethod {
        GET, POST, PUT, DELETE, HEAD, OPTIONS;
        
        public static HttpMethod fromString(String method) {
            try {
                return valueOf(method.toUpperCase());
            } catch (IllegalArgumentException e) {
                return null;
            }
        }
    }

    /**
     * 过滤器接口 - 责任链模式的节点
     */
    @FunctionalInterface
    public interface Filter {
        boolean filter(Request req, Response res) throws IOException;
    }

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
import java.util.*;
import java.util.stream.Collectors;

/**
 * HTTP请求封装 - 集合操作的"数据源"
 * 
 * 为什么这样设计：
 * 1. 请求数据天然适合用Map存储（键值对）
 * 2. 不同类型的数据（查询参数、路径参数、请求头）用不同Map
 * 3. 提供不可变视图保证数据安全
 */
public class Request {
    private final HttpExchange exchange;
    private final String method;
    private final String path;
    
    // 为什么用Map<String, List<String>>存储查询参数？
    // - HTTP允许一个参数名对应多个值（如 ?id=1&id=2）
    // - 使用List<String>保留所有值
    private final Map<String, List<String>> queryParams;
    
    // 为什么路径参数用Map<String, String>？
    // - 路径参数通常是唯一的（如 /users/{id}）
    // - 单值就够了，不需要List
    private Map<String, String> pathParams = Map.of(); // 默认为空Map，不可变
    
    // 为什么请求头也用Map<String, List<String>>？
    // - HTTP允许同名头（如 Set-Cookie: a=1; Set-Cookie: b=2）
    // - 需要保留所有值
    private final Map<String, List<String>> headers;
    
    // 延迟解析的请求体
    private String body;

    public Request(HttpExchange exchange) {
        this.exchange = exchange;
        this.method = exchange.getRequestMethod();
        this.path = exchange.getRequestURI().getPath();
        
        // 解析查询参数 - 使用LinkedHashMap保持参数顺序
        this.queryParams = parseQueryParams(exchange.getRequestURI().getQuery());
        
        // 解析请求头 - 转换为小写键便于不区分大小写查找
        this.headers = exchange.getRequestHeaders().entrySet().stream()
            .collect(Collectors.toMap(
                e -> e.getKey().toLowerCase(),
                e -> new ArrayList<>(e.getValue()), // 创建可修改的副本
                (v1, v2) -> { // 合并函数，实际不会发生
                    List<String> merged = new ArrayList<>(v1);
                    merged.addAll(v2);
                    return merged;
                },
                LinkedHashMap::new // 保持头部顺序
            ));
    }

    /**
     * 解析查询字符串 - 演示Map的复杂操作
     */
    private Map<String, List<String>> parseQueryParams(String query) {
        // 为什么用LinkedHashMap？
        // - 保持参数的出现顺序
        // - 便于调试和日志记录
        Map<String, List<String>> params = new LinkedHashMap<>();
        
        if (query == null || query.isEmpty()) {
            return params;
        }

        // 使用Stream API处理字符串分割
        Arrays.stream(query.split("&"))
            .forEach(pair -> {
                int idx = pair.indexOf("=");
                if (idx > 0) {
                    String key = URLDecoder.decode(pair.substring(0, idx), StandardCharsets.UTF_8);
                    String value = URLDecoder.decode(pair.substring(idx + 1), StandardCharsets.UTF_8);
                    
                    // computeIfAbsent是Map的经典用法
                    // - 避免多次containsKey检查
                    // - 原子性操作
                    params.computeIfAbsent(key, k -> new ArrayList<>()).add(value);
                } else if (idx == -1 && !pair.isEmpty()) {
                    // 处理无值的参数（如 ?flag）
                    params.computeIfAbsent(pair, k -> new ArrayList<>()).add("");
                }
            });
        
        // 返回不可修改的视图
        return Collections.unmodifiableMap(params);
    }

    /**
     * 获取查询参数的第一个值
     * 这是最常用的场景
     */
    public String queryParam(String name) {
        List<String> values = queryParams.get(name);
        return values != null && !values.isEmpty() ? values.get(0) : null;
    }

    /**
     * 获取查询参数的所有值
     */
    public List<String> queryParams(String name) {
        return queryParams.getOrDefault(name, List.of());
    }

    /**
     * 获取所有查询参数名
     */
    public Set<String> queryParamNames() {
        return queryParams.keySet();
    }

    /**
     * 获取查询参数的Map视图
     */
    public Map<String, List<String>> queryParams() {
        return queryParams;
    }

    /**
     * 设置路径参数
     * 包级私有，只给服务器调用
     */
    void setPathParams(Map<String, String> pathParams) {
        this.pathParams = Collections.unmodifiableMap(new LinkedHashMap<>(pathParams));
    }

    public String pathParam(String name) {
        return pathParams.get(name);
    }

    public Map<String, String> pathParams() {
        return pathParams;
    }

    /**
     * 获取请求头的第一个值
     */
    public String header(String name) {
        List<String> values = headers.get(name.toLowerCase());
        return values != null && !values.isEmpty() ? values.get(0) : null;
    }

    /**
     * 获取请求头的所有值
     */
    public List<String> headers(String name) {
        return headers.getOrDefault(name.toLowerCase(), List.of());
    }

    /**
     * 获取所有请求头名
     */
    public Set<String> headerNames() {
        return headers.keySet();
    }

    /**
     * 获取请求体的所有行
     * 使用Stream API惰性处理
     */
    public List<String> bodyLines() {
        if (body == null) {
            readBody();
        }
        return body.lines().collect(Collectors.toList());
    }

    /**
     * 获取完整的请求体
     */
    public String body() {
        if (body == null) {
            readBody();
        }
        return body;
    }

    /**
     * 解析JSON请求体为Map（简化版）
     * 演示Stream API处理复杂格式
     */
    public Map<String, String> bodyAsMap() {
        String body = body();
        if (body == null || body.isEmpty()) {
            return Map.of();
        }
        
        // 简化版JSON解析，仅用于演示
        // 真正的项目应该用Jackson等库
        return Arrays.stream(body.replaceAll("[{}\"]", "").split(","))
            .map(s -> s.split(":"))
            .filter(arr -> arr.length == 2)
            .collect(Collectors.toMap(
                arr -> arr[0].trim(),
                arr -> arr[1].trim(),
                (v1, v2) -> v1, // 冲突时保留第一个
                LinkedHashMap::new
            ));
    }

    private void readBody() {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(exchange.getRequestBody(), StandardCharsets.UTF_8))) {
            this.body = reader.lines().collect(Collectors.joining("\n"));
        } catch (Exception e) {
            this.body = "";
        }
    }

    // Getter方法
    public String method() { return method; }
    public String path() { return path; }
    public HttpExchange exchange() { return exchange; }
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
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * HTTP响应封装 - 集合的"输出端"
 * 
 * 为什么这样设计：
 * 1. 响应头也需要用Map存储
 * 2. 提供链式调用API，提高代码可读性
 * 3. 延迟发送，支持多次修改
 */
public class Response {
    private final HttpExchange exchange;
    
    // 为什么用LinkedHashMap？
    // - 保持响应头的添加顺序
    // - 某些客户端依赖头部顺序（如Set-Cookie的顺序）
    private final Map<String, String> headers = new LinkedHashMap<>();
    
    private int statusCode = 200;
    private byte[] body = null;
    private boolean sent = false;

    public Response(HttpExchange exchange) {
        this.exchange = exchange;
        // 默认响应头
        header("Content-Type", "text/plain; charset=UTF-8");
        header("Server", "SimpleJavaServer/1.0");
    }

    /**
     * 链式设置响应头
     */
    public Response header(String name, String value) {
        // 为什么允许覆盖？
        // - HTTP规范要求同名头应该合并，但为了简化，我们只保留最后一个
        // - 如果需要多个同名头（如Set-Cookie），需要特殊处理
        headers.put(name, value);
        return this;
    }

    /**
     * 批量设置响应头
     */
    public Response headers(Map<String, String> headers) {
        this.headers.putAll(headers);
        return this;
    }

    /**
     * 设置Cookie（演示Map的复合值处理）
     */
    public Response cookie(String name, String value) {
        return cookie(name, value, -1, "/");
    }

    public Response cookie(String name, String value, int maxAge, String path) {
        StringBuilder cookie = new StringBuilder();
        cookie.append(name).append("=").append(value);
        if (maxAge >= 0) {
            cookie.append("; Max-Age=").append(maxAge);
        }
        if (path != null) {
            cookie.append("; Path=").append(path);
        }
        cookie.append("; HttpOnly"); // 增加安全性
        
        // Set-Cookie可以有多条，所以不能简单用header()覆盖
        // 这里简化处理，实际应该用List<String>存储
        header("Set-Cookie", cookie.toString());
        return this;
    }

    public Response status(int statusCode) {
        this.statusCode = statusCode;
        return this;
    }

    /**
     * 发送JSON响应
     */
    public Response json(Object data) throws IOException {
        header("Content-Type", "application/json; charset=UTF-8");
        
        // 简化版JSON序列化
        if (data instanceof Map) {
            @SuppressWarnings("unchecked")
            Map<String, Object> map = (Map<String, Object>) data;
            StringBuilder json = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<String, Object> entry : map.entrySet()) {
                if (!first) {
                    json.append(",");
                }
                first = false;
                json.append("\"").append(entry.getKey()).append("\":");
                if (entry.getValue() instanceof String) {
                    json.append("\"").append(entry.getValue()).append("\"");
                } else {
                    json.append(entry.getValue());
                }
            }
            json.append("}");
            return send(json.toString());
        }
        
        return send(data.toString());
    }

    public Response html(String html) throws IOException {
        header("Content-Type", "text/html; charset=UTF-8");
        return send(html);
    }

    public Response send(String text) throws IOException {
        return send(text.getBytes(StandardCharsets.UTF_8));
    }

    public Response send(byte[] data) throws IOException {
        if (sent) {
            throw new IllegalStateException("Response already sent");
        }
        
        this.body = data;
        writeResponse();
        return this;
    }

    /**
     * 实际写入响应的时刻
     */
    private void writeResponse() throws IOException {
        // 设置所有响应头
        for (Map.Entry<String, String> entry : headers.entrySet()) {
            exchange.getResponseHeaders().set(entry.getKey(), entry.getValue());
        }
        
        long contentLength = body != null ? body.length : -1;
        exchange.sendResponseHeaders(statusCode, contentLength);
        
        if (body != null) {
            try (OutputStream os = exchange.getResponseBody()) {
                os.write(body);
            }
        }
        
        sent = true;
    }

    /**
     * 重定向
     */
    public Response redirect(String location) throws IOException {
        if (sent) {
            throw new IllegalStateException("Response already sent");
        }
        
        status(302);
        header("Location", location);
        writeResponse();
        return this;
    }

    /**
     * 文件下载
     */
    public Response download(byte[] data, String filename) throws IOException {
        header("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        header("Content-Length", String.valueOf(data.length));
        return send(data);
    }

    /**
     * 获取已设置的响应头（用于调试）
     */
    public Map<String, String> getHeaders() {
        return new HashMap<>(headers); // 返回副本防止修改
    }

    public int getStatusCode() {
        return statusCode;
    }

    public boolean isSent() {
        return sent;
    }
}
```

---

### 4. 启动类 - `Main.java`

```java
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class Main {
    public static void main(String[] args) throws IOException {
        // 演示集合框架的多种用法
        
        // 1. 创建服务器（演示建造者模式）
        var server = SimpleHttpServer.create(8080);
        
        // 2. 添加过滤器（演示List作为拦截链）
        server
            // 日志过滤器 - 记录所有请求
            .filter((req, res) -> {
                System.out.printf("[%s] %s - 参数: %s%n", 
                    req.method(), 
                    req.path(), 
                    req.queryParams().keySet()
                );
                return true;
            })
            
            // 认证过滤器 - 演示Map存储用户会话
            .filter(new AuthFilter())
            
            // 限流过滤器 - 演示ConcurrentHashMap统计请求
            .filter(new RateLimitFilter(100)); // 每分钟最多100请求
        
        // 3. 注册路由（演示Map作为路由表）
        server
            // 首页 - 展示动态HTML生成
            .get("/", (req, res) -> {
                Map<String, Object> model = new HashMap<>();
                model.put("title", "极简Java服务器");
                model.put("routes", Arrays.asList("/hello", "/users", "/api/stats"));
                model.put("features", Set.of("虚拟线程", "集合框架", "函数式编程"));
                
                StringBuilder html = new StringBuilder("""
                    <!DOCTYPE html>
                    <html>
                    <head><title>${title}</title></head>
                    <body>
                        <h1>🚀 ${title}</h1>
                        <h2>可用路由:</h2>
                        <ul>
                    """);
                
                // 使用集合遍历生成HTML
                for (String route : model.get("routes").toString().split(", ")) {
                    html.append("<li><a href='").append(route).append("'>")
                        .append(route).append("</a></li>\n");
                }
                
                html.append("""
                        </ul>
                        <h2>特性:</h2>
                        <ul>
                        """);
                
                // 演示Set的遍历
                model.get("features").toString().lines()
                    .map(f -> f.replaceAll("[\\[\\],]", ""))
                    .forEach(f -> html.append("<li>").append(f).append("</li>\n"));
                
                html.append("</ul></body></html>");
                
                res.html(html.toString().replace("${title}", model.get("title").toString()));
            })
            
            // 路径参数示例 - 演示Map的路径参数提取
            .get("/hello/{name}", (req, res) -> {
                String name = req.pathParam("name");
                // 演示Optional避免空指针
                String greeting = Optional.ofNullable(name)
                    .map(n -> "你好，" + n)
                    .orElse("你好，世界");
                res.html("<h1>" + greeting + "</h1>");
            })
            
            // 查询参数示例 - 演示Map的查询参数解析
            .get("/search", (req, res) -> {
                Map<String, List<String>> params = req.queryParams();
                
                StringBuilder result = new StringBuilder("查询参数:\n");
                // 演示Map的entrySet遍历
                for (Map.Entry<String, List<String>> entry : params.entrySet()) {
                    result.append(entry.getKey()).append(": ")
                          .append(String.join(", ", entry.getValue()))
                          .append("\n");
                }
                
                res.send(result.toString());
            })
            
            // JSON API示例 - 演示Map转JSON
            .get("/api/user/{id}", (req, res) -> {
                String userId = req.pathParam("id");
                
                // 模拟从数据库查询（演示LinkedHashMap保持字段顺序）
                Map<String, Object> user = new LinkedHashMap<>();
                user.put("id", userId);
                user.put("name", "User" + userId);
                user.put("email", "user" + userId + "@example.com");
                user.put("roles", List.of("admin", "user"));
                user.put("createdAt", new Date());
                
                res.json(user);
            })
            
            // POST示例 - 演示请求体解析
            .post("/api/users", (req, res) -> {
                // 演示将请求体解析为Map
                Map<String, String> data = req.bodyAsMap();
                
                // 数据验证（演示Collection操作）
                if (data == null || data.isEmpty()) {
                    res.status(400).json(Map.of("error", "Empty request body"));
                    return;
                }
                
                List<String> errors = new ArrayList<>();
                if (!data.containsKey("name")) {
                    errors.add("name is required");
                }
                if (!data.containsKey("email")) {
                    errors.add("email is required");
                }
                
                if (!errors.isEmpty()) {
                    res.status(400).json(Map.of("errors", errors));
                    return;
                }
                
                // 成功响应
                Map<String, Object> response = new HashMap<>();
                response.put("status", "success");
                response.put("user", data);
                response.put("timestamp", System.currentTimeMillis());
                
                res.status(201).json(response);
            })
            
            // 统计API - 演示ConcurrentHashMap作为计数器
            .get("/api/stats", (req, res) -> {
                Map<String, Object> stats = new LinkedHashMap<>();
                stats.put("uptime", System.currentTimeMillis() - startTime);
                stats.put("totalRequests", RequestCounter.getTotal());
                stats.put("activeRequests", RequestCounter.getActive());
                stats.put("routes", Map.of(
                    "get", server.getClass().getDeclaredField("getRoutes").get(server),
                    "post", server.getClass().getDeclaredField("postRoutes").get(server)
                ));
                
                res.json(stats);
            })
            
            // 静态文件服务
            .staticFiles("/static", "./webroot");
        
        // 4. 创建静态文件目录和示例文件
        Files.createDirectories(Paths.get("./webroot/css"));
        Files.createDirectories(Paths.get("./webroot/js"));
        
        Files.writeString(Paths.get("./webroot/index.html"), """
            <!DOCTYPE html>
            <html>
            <head><title>静态文件</title></head>
            <body>
                <h1>静态文件示例</h1>
                <p>这个文件是从磁盘读取的</p>
            </body>
            </html>
        """);
        
        Files.writeString(Paths.get("./webroot/css/style.css"), """
            body { font-family: sans-serif; margin: 2em; }
            h1 { color: #333; }
        """);
        
        // 5. 启动服务器
        server.start();
        
        // 6. 演示路由表信息
        System.out.println("\n📊 集合框架使用统计:");
        System.out.println("- HashMap: 存储路由表");
        System.out.println("- ConcurrentHashMap: 请求计数、缓存");
        System.out.println("- LinkedHashMap: 保持参数顺序");
        System.out.println("- CopyOnWriteArrayList: 过滤器链");
        System.out.println("- EnumSet: 支持的方法集合");
        System.out.println("- Collections.unmodifiable*: 不可变视图");
        
        System.out.println("\n📝 按回车键停止服务器...");
        System.in.read();
        
        // 7. 停止服务器
        server.stop(0);
        System.out.println("👋 服务器已停止");
        System.out.println("总请求数: " + RequestCounter.getTotal());
    }
    
    // 启动时间
    private static final long startTime = System.currentTimeMillis();
    
    /**
     * 请求计数器 - 演示ConcurrentHashMap的高级用法
     */
    static class RequestCounter {
        private static final ConcurrentHashMap<String, AtomicLong> counters = new ConcurrentHashMap<>();
        private static final AtomicLong activeRequests = new AtomicLong(0);
        private static final AtomicLong totalRequests = new AtomicLong(0);
        
        public static void increment(String path) {
            counters.computeIfAbsent(path, k -> new AtomicLong()).incrementAndGet();
            activeRequests.incrementAndGet();
            totalRequests.incrementAndGet();
        }
        
        public static void decrement() {
            activeRequests.decrementAndGet();
        }
        
        public static long getCount(String path) {
            return counters.getOrDefault(path, new AtomicLong()).get();
        }
        
        public static Map<String, Long> getAllCounts() {
            Map<String, Long> snapshot = new HashMap<>();
            counters.forEach((k, v) -> snapshot.put(k, v.get()));
            return snapshot;
        }
        
        public static long getActive() {
            return activeRequests.get();
        }
        
        public static long getTotal() {
            return totalRequests.get();
        }
    }
    
    /**
     * 认证过滤器 - 演示Map存储会话
     */
    static class AuthFilter implements SimpleHttpServer.Filter {
        // 模拟用户会话存储
        private final Map<String, UserSession> sessions = new ConcurrentHashMap<>();
        // 白名单路径
        private final Set<String> publicPaths = Set.of("/", "/login", "/static", "/api/public");
        
        @Override
        public boolean filter(Request req, Response res) throws IOException {
            String path = req.path();
            
            // 检查是否是公开路径
            boolean isPublic = publicPaths.stream().anyMatch(path::startsWith);
            if (isPublic) {
                return true;
            }
            
            // 获取会话ID（从Cookie）
            String sessionId = req.header("Cookie");
            if (sessionId != null && sessionId.contains("session=")) {
                String sid = sessionId.replaceAll(".*session=([^;]+).*", "$1");
                UserSession session = sessions.get(sid);
                
                if (session != null && !session.isExpired()) {
                    // 刷新会话过期时间
                    session.refresh();
                    return true;
                }
            }
            
            // 未认证，返回401
            res.status(401).json(Map.of(
                "error", "Unauthorized",
                "message", "Please login first"
            ));
            return false;
        }
        
        // 创建会话
        public String createSession(String username) {
            String sessionId = UUID.randomUUID().toString();
            sessions.put(sessionId, new UserSession(username));
            return sessionId;
        }
        
        // 用户会话
        static class UserSession {
            private final String username;
            private final long createdAt;
            private long lastAccessed;
            private static final long TIMEOUT = 30 * 60 * 1000; // 30分钟
            
            UserSession(String username) {
                this.username = username;
                this.createdAt = System.currentTimeMillis();
                this.lastAccessed = this.createdAt;
            }
            
            void refresh() {
                this.lastAccessed = System.currentTimeMillis();
            }
            
            boolean isExpired() {
                return System.currentTimeMillis() - lastAccessed > TIMEOUT;
            }
        }
    }
    
    /**
     * 限流过滤器 - 演示ConcurrentHashMap作为计数器
     */
    static class RateLimitFilter implements SimpleHttpServer.Filter {
        private final ConcurrentHashMap<String, RateLimiter> limiters = new ConcurrentHashMap<>();
        private final int maxRequestsPerMinute;
        
        RateLimitFilter(int maxRequestsPerMinute) {
            this.maxRequestsPerMinute = maxRequestsPerMinute;
        }
        
        @Override
        public boolean filter(Request req, Response res) throws IOException {
            String clientIp = req.exchange().getRemoteAddress().getAddress().getHostAddress();
            
            RateLimiter limiter = limiters.computeIfAbsent(clientIp, 
                k -> new RateLimiter(maxRequestsPerMinute));
            
            if (!limiter.tryAcquire()) {
                res.status(429).json(Map.of(
                    "error", "Too Many Requests",
                    "message", "Rate limit exceeded. Try again later."
                ));
                return false;
            }
            
            return true;
        }
        
        // 滑动窗口限流器
        static class RateLimiter {
            private final int maxRequests;
            private final long windowSize = 60 * 1000; // 1分钟
            private final LinkedList<Long> timestamps = new LinkedList<>();
            
            RateLimiter(int maxRequests) {
                this.maxRequests = maxRequests;
            }
            
            synchronized boolean tryAcquire() {
                long now = System.currentTimeMillis();
                
                // 移除窗口外的请求记录
                while (!timestamps.isEmpty() && timestamps.getFirst() < now - windowSize) {
                    timestamps.removeFirst();
                }
                
                if (timestamps.size() < maxRequests) {
                    timestamps.addLast(now);
                    return true;
                }
                
                return false;
            }
        }
    }
}
```

---

## 📚 集合框架深度解析

### 1. **Map家族的选择艺术**

| 场景 | 使用的Map | 为什么选它 |
|------|-----------|-----------|
| 路由表 | `HashMap` | 读多写少，O(1)查询，不需要顺序 |
| 请求参数 | `LinkedHashMap` | 保持参数顺序，便于调试 |
| 并发缓存 | `ConcurrentHashMap` | 线程安全，高并发性能好 |
| 不可变配置 | `Map.of()` | 只读数据，节省内存，线程安全 |
| 路径参数 | `Collections.unmodifiableMap` | 防止意外修改 |

### 2. **List的选择策略**

| 场景 | 使用的List | 为什么选它 |
|------|-----------|-----------|
| 过滤器链 | `CopyOnWriteArrayList` | 读多写少，无锁并发读 |
| 参数值列表 | `ArrayList` | 随机访问多，修改少 |
| 限流队列 | `LinkedList` | 频繁头尾操作 |

### 3. **Set的高效应用**

| 场景 | 使用的Set | 为什么选它 |
|------|----------|-----------|
| 支持的方法 | `EnumSet` | 基于位向量，极致性能 |
| 白名单路径 | `Set.of()` | 不可变，节省内存 |
| 特性集合 | `HashSet` | 快速存在性检查 |

### 4. **Queue的巧妙用法**

- `LinkedList` 实现滑动窗口限流
- `ConcurrentLinkedQueue` 可用于异步日志

### 5. **集合的不可变视图**

```java
Collections.unmodifiableMap(params)  // 只读视图
Map.of()  // 不可变空Map
List.of()  // 不可变空List
Set.of()   // 不可变空Set
```

### 6. **并发集合的正确使用**

```java
// 原子性的计算
cache.computeIfAbsent(key, k -> loadValue(k));

// 原子性的更新
counters.merge(key, 1L, Long::sum);

// 线程安全的遍历
counters.forEach((k, v) -> process(k, v.get()));
```

---

## 🎯 核心学习价值

1. **集合框架是架构设计的基础**：不同的集合结构决定了系统的性能和可维护性
2. **选对集合比优化代码更重要**：O(1)和O(n)的差距是架构级的
3. **并发集合的理解是后端必备**：ConcurrentHashMap的CAS操作、分段锁
4. **不可变集合保障线程安全**：防御性编程的最佳实践

这个版本**强化了集合框架的存在感**，每个集合的选择都有充分的理由，代码中的why型注释解释了背后的设计决策。需要我详细解释某个集合的实现原理吗？