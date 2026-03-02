# Tinyhttpd：从零读懂一个最小 HTTP 服务器
 
 本书以仓库 `Tinyhttpd-master` 为对象，带你用“读源码”的方式理解一个极简 HTTP/1.0 服务器：
 
 - 它如何建立监听 socket
 - 它如何读取并解析 HTTP 请求
 - 它如何把 URL 映射到本地文件
 - 它如何服务静态文件
 - 它如何通过 `fork + pipe + exec` 执行 CGI
 - 它如何用线程把“一个连接一个处理单元”跑起来
 
 代码量很小，但覆盖了网络编程与进程/线程、管道、环境变量等经典系统编程知识点。
 
 ---
 
 ## 目录
 
 - 第 1 章：导读——我们要读懂什么
 - 第 2 章：快速上手——跑起来再读
 - 第 3 章：整体架构——文件、模块与职责
 - 第 4 章：一次请求的生命线——从 `accept()` 到 `close()`
 - 第 5 章：静态文件路径——`serve_file()` 这条线
 - 第 6 章：CGI 路径——`execute_cgi()` 这条线
 - 第 7 章：并发模型——线程与资源回收
 - 第 8 章：示例资源——`htdocs/` 如何配合演示
 - 附录 A：函数参考（逐函数详解）
 
 ---
 
 # 第 1 章：导读——我们要读懂什么
 
 这份 tinyhttpd 是一个教学性质的“最小可用 Web Server”。它不追求完整的 HTTP 标准实现，而是把关键链路讲清楚：
 
 - **连接层**：`socket` / `bind` / `listen` / `accept`
 - **协议层**：按行读取请求头，解析请求行 `METHOD URL VERSION`
 - **资源层**：把 URL 映射到 `htdocs/` 下的文件
 - **执行层**：
   - 静态文件：输出 headers + 文件内容
   - CGI：通过管道把 HTTP 请求体喂给 CGI，把 CGI 输出转回浏览器
 
 你读完这份代码，至少能回答这些问题：
 
 - 为什么要写 `Content-Length`？不写会发生什么？
 - CGI 为什么需要设置环境变量？
 - 为什么 `GET` 带参数会被当成 CGI？
 - 线程版本与单线程版本差异是什么？
 
 ---
 
 # 第 2 章：快速上手——跑起来再读
 
 ## 2.1 项目文件一览
 
 - `httpd.c`：核心服务器
 - `simpleclient.c`：独立的 TCP client 示例（**不是**用来请求 HTTP 页面）
 - `htdocs/`：网页与 CGI 演示
   - `index.html`：主页，表单提交到 `color.cgi`
   - `color.cgi`：Perl CGI，根据参数设置背景色
   - `check.cgi`：Perl CGI，打印所有 CGI 参数
 
 ## 2.2 运行效果（你应该看到什么）
 
 服务器启动后会输出类似：
 
 - `httpd running on port 4000`
 
 浏览器访问：
 
 - `http://127.0.0.1:4000/`
 
 应返回 `htdocs/index.html`。
 
 ## 2.3 Windows 下的构建提示
 
 这份代码使用 POSIX 头文件（例如 `sys/socket.h`、`unistd.h`、`fork()`、`pipe()`），因此：
 
 - **MSVC（Visual Studio）不能直接编译**（需要改成 Winsock + `CreateProcess`/`CreatePipe` 等）。
 - 推荐使用以下任一种“类 Unix”环境来编译：
   - **WSL**（Ubuntu 等）
   - **MSYS2/MinGW-w64**（取决于其对 `fork()` 等的支持情况）
 
 本仓库 `Makefile` 使用 `gcc`。如果你告诉我你用的是 WSL 还是 MSYS2，我可以把“可执行步骤”补到这里，做到可复制粘贴。
 
 ---
 
 # 第 3 章：整体架构——文件、模块与职责
 
 ## 3.1 `httpd.c` 的分层心智模型
 
 读 `httpd.c` 时，建议你把函数按角色分组，而不是按出现顺序死读：
 
 - **错误响应**
   - `bad_request()`：400
   - `not_found()`：404
   - `unimplemented()`：501
   - `cannot_execute()`：500
 - **I/O 辅助**
   - `get_line()`：从 socket 读取一行，处理 `\r\n`
   - `cat()`：把文件内容写到 socket
 - **静态文件路径**
   - `headers()`：输出响应头
   - `serve_file()`：丢弃请求头，读文件并返回
 - **CGI 路径**
   - `execute_cgi()`：pipe + fork + exec + 环境变量
 - **服务器入口**
   - `startup()`：socket/bind/listen
   - `accept_request()`：解析请求、路由到静态或 CGI
   - `main()`：accept 循环 + 线程创建
 
 ## 3.2 “禁止向前引用”在本项目里的含义
 
 为了便于阅读与维护，当前 `httpd.c` 已按“禁止向前引用”原则重排：
 
 - **不在文件顶部用函数原型“兜底”**
 - **被调用者在上，调用者在下**
 - 最后才是 `main()`
 
 这样做的好处是：你顺着文件往下读时，遇到一个函数调用，通常你已经读过被调用函数的实现。
 
 ---
 
 # 第 4 章：一次请求的生命线——从 `accept()` 到 `close()`
 
 本章只讲“主线”，先不纠结每一行代码。
 
 ## 4.1 主循环：`main()`
 
 `main()` 做三件事：
 
 - 调用 `startup(&port)` 建立监听 socket
 - 循环 `accept()` 接入客户端连接
 - 为每个连接创建线程，线程入口为 `accept_request()`
 
 你可以把它理解成：
 
 - **main 是调度器**
 - **accept_request 是请求处理器**
 
 ## 4.2 请求处理器：`accept_request()` 的“路由”逻辑
 
 `accept_request()` 的工作像一个非常小的路由器：
 
 - 读请求行（方法与 URL）
 - 把 URL 映射成 `htdocs/...` 本地路径
 - 决定走哪条路径：
   - 静态：`serve_file()`
   - CGI：`execute_cgi()`
 - 最后 `close(client)` 关闭连接（HTTP/1.0 风格）
 
 你读代码时重点观察：
 
 - **哪些条件会触发 CGI**
 - **为什么要丢弃剩余请求头**
 
 ---
 
 # 第 5 章：静态文件路径——`serve_file()` 这条线
 
 静态路径相对直观，可以当作你理解整体协议 I/O 的“热身”。
 
 ## 5.1 静态响应的最小组成
 
 一个最小 HTTP 响应通常包含：
 
 - 状态行：`HTTP/1.0 200 OK`
 - 若干头部（比如 `Content-Type`）
 - 空行
 - body（文件内容）
 
 在 tinyhttpd 中对应：
 
 - `headers(client, filename)`：输出状态行与头部
 - `cat(client, resource)`：输出文件内容
 
 ## 5.2 为什么 `serve_file()` 要先“丢弃请求头”
 
 在 `accept_request()` 读完请求行后，socket 里通常还留着请求头（例如 `Host`、`User-Agent`）。
 
 tinyhttpd 的静态路径并不需要这些头，所以 `serve_file()` 用 `get_line()` 读到空行（`"\n"`）为止，把它们丢弃。
 
 ---
 
 # 第 6 章：CGI 路径——`execute_cgi()` 这条线
 
 CGI 是这份代码最值得读的部分，因为它把系统调用串成了一条“数据管道”。
 
 ## 6.1 CGI 在 tinyhttpd 里是什么
 
 在 tinyhttpd 中，CGI 本质上是：
 
 - 一个可执行文件（这里是 Perl 脚本）
 - 通过环境变量拿到请求元信息（方法、参数、长度）
 - 从标准输入读取请求体（POST）
 - 向标准输出写入响应内容（HTML）
 
 ## 6.2 两根管道：把 HTTP socket 变成 CGI 的 stdin/stdout
 
 `execute_cgi()` 建了两根管道：
 
 - `cgi_input`：父进程写 -> 子进程读（作为 CGI 的 `STDIN`）
 - `cgi_output`：子进程写 -> 父进程读（作为 CGI 的 `STDOUT`）
 
 于是父进程就能：
 
 - 把 POST body 写给 CGI
 - 把 CGI 输出再写回浏览器
 
 ## 6.3 为什么 POST 必须要 `Content-Length`
 
 POST 的 body 在 HTTP/1.0 下没有 chunked 编码时，服务器需要 `Content-Length` 才知道要从 socket 读取多少字节。
 
 因此 tinyhttpd 在找不到 `Content-Length` 时直接 `bad_request()`。
 
 ---
 
 # 第 7 章：并发模型——线程与资源回收
 
 目前 `main()` 使用 `pthread_create()` 为每个连接创建一个线程。
 
 你需要知道两点：
 
 - 这是教学用的简单模型：实现容易，但高并发下线程开销大。
 - 代码里没有 `pthread_detach()`/`pthread_join()`，严格意义上可能产生线程资源回收问题。
 
 如果你打算把它用于更严肃的实验：
 
 - 可以考虑改为 `pthread_detach(newthread)`
 - 或者引入线程池
 
 ---
 
 # 第 8 章：示例资源——`htdocs/` 如何配合演示
 
 ## 8.1 `index.html`
 
 页面里有一个表单：
 
 - `ACTION="color.cgi"`
 - `METHOD="POST"`
 
 输入一个颜色（例如 `chartreuse`），提交后会触发 CGI。
 
 ## 8.2 `color.cgi`
 
 - 读取参数 `color`
 - 输出 HTML，并把背景设为该颜色
 
 ## 8.3 `check.cgi`
 
 - 列出 CGI 收到的所有参数
 - 适合用来验证 GET/POST 参数解析是否符合预期
 
 ---
 
 # 附录 A：函数参考（逐函数详解）
 
 本附录按“功能分组”的方式，逐函数说明用途、参数/返回值、关键流程、错误处理与调用关系。
 
 ## A.1 宏与常量
 
 - `ISspace(x)`：包装 `isspace`，用于把 `char` 安全提升为 `int` 后再判断空白字符。
 - `SERVER_STRING`：响应头中 `Server:` 字段。
 - `STDIN/STDOUT/STDERR`：用于 `dup2()` 重定向 CGI 子进程标准输入输出。
 
 ---
 
 ## A.2 错误响应与退出
 
 ### `void bad_request(int client)`
 
 - **功能**
   - 返回 `400 Bad Request`。
   - 典型触发：POST 缺少 `Content-Length`。
 - **参数**
   - `client`：客户端 socket。
 - **关键流程**
   - 多次 `send()` 输出状态行、头部、空行、错误描述。
 - **调用关系**
   - 被 `execute_cgi()` 调用。
 
 ### `void cannot_execute(int client)`
 
 - **功能**
   - 返回 `500 Internal Server Error`（CGI 执行失败）。
 - **参数**
   - `client`：客户端 socket。
 - **调用关系**
   - 被 `execute_cgi()` 调用（pipe/fork 失败等）。
 
 ### `void not_found(int client)`
 
 - **功能**
   - 返回 `404 Not Found`。
 - **参数**
   - `client`：客户端 socket。
 - **调用关系**
   - 被 `accept_request()`（`stat` 失败）或 `serve_file()`（`fopen` 失败）调用。
 
 ### `void unimplemented(int client)`
 
 - **功能**
   - 返回 `501 Method Not Implemented`。
 - **参数**
   - `client`：客户端 socket。
 - **调用关系**
   - 被 `accept_request()` 调用。
 
 ### `void error_die(const char *sc)`
 
 - **功能**
   - `perror(sc)` 后 `exit(1)`，用于致命系统调用错误。
 - **参数**
   - `sc`：错误上下文。
 - **调用关系**
   - 被 `startup()`、`main()` 调用。
 
 ---
 
 ## A.3 Socket 与文本 I/O
 
 ### `int get_line(int sock, char *buf, int size)`
 
 - **功能**
   - 从 socket 读取一行，兼容 `\n`/`\r`/`\r\n`，统一为 `\n` 结尾。
 - **参数**
   - `sock`：socket。
   - `buf`：缓冲区。
   - `size`：缓冲区大小。
 - **返回值**
   - 写入字节数（不含 `\0`）。
 - **关键流程**
   - `recv()` 单字节读取；遇 `\r` 时用 `MSG_PEEK` 看下一个字节。
 - **调用关系**
   - 被 `accept_request()`、`serve_file()`、`execute_cgi()` 调用。
 
 ---
 
 ## A.4 静态文件路径
 
 ### `void headers(int client, const char *filename)`
 
 - **功能**
   - 输出 `200 OK` 响应头（当前 `Content-Type` 固定为 `text/html`）。
 - **参数**
   - `client`：客户端 socket。
   - `filename`：当前未用。
 - **调用关系**
   - 被 `serve_file()` 调用。
 
 ### `void cat(int client, FILE *resource)`
 
 - **功能**
   - 将文件内容写回 socket（逐行 `fgets` + `send`）。
 - **参数**
   - `client`：客户端 socket。
   - `resource`：文件指针。
 - **调用关系**
   - 被 `serve_file()` 调用。
 
 ### `void serve_file(int client, const char *filename)`
 
 - **功能**
   - 丢弃请求头、打开文件、输出 headers、输出文件内容。
 - **参数**
   - `client`：客户端 socket。
   - `filename`：本地文件路径。
 - **调用关系**
   - 被 `accept_request()` 调用。
 
 ---
 
 ## A.5 CGI 路径
 
 ### `void execute_cgi(int client, const char *path, const char *method, const char *query_string)`
 
 - **功能**
   - 执行 CGI，设置环境变量，把 POST body 写入 CGI stdin，把 CGI stdout 回写给客户端。
 - **参数**
   - `client`：客户端 socket。
   - `path`：CGI 路径。
   - `method`：`GET`/`POST`。
   - `query_string`：GET 参数。
 - **关键流程**
   - 读取/丢弃请求头；POST 提取 `Content-Length`。
   - `pipe()` 两根管道；`fork()`。
   - 子进程 `dup2()` 重定向 + `putenv()` 设置变量 + `execl()`。
   - 父进程把 POST body 写入管道，把 CGI 输出转发到 socket。
 - **调用关系**
   - 被 `accept_request()` 调用。
 
 ---
 
 ## A.6 服务器入口与请求调度
 
 ### `int startup(u_short *port)`
 
 - **功能**
   - `socket/bind/listen` 建立监听 socket。
 - **参数**
   - `port`：端口指针。
 - **返回值**
   - 监听 socket。
 - **调用关系**
   - 被 `main()` 调用。
 
 ### `void accept_request(void *arg)`
 
 - **功能**
   - 解析请求行与 URL，映射到 `htdocs/`，在静态与 CGI 之间分流。
 - **参数**
   - `arg`：线程入口参数（本实现用 `(intptr_t)` 传递 `client_sock`）。
 - **调用关系**
   - 被 `main()` 创建线程调用。
 
 ### `int main(void)`
 
 - **功能**
   - `startup()` 后循环 `accept()`，为每个连接创建线程处理。
 
 ---
 
 # 附录 B：`simpleclient.c` 说明
 
 `simpleclient.c` 是一个独立的 TCP client 示例：连接 `127.0.0.1:9734`，写 1 字节再读 1 字节并打印。
 
 - 它与 `httpd.c` 的默认端口 `4000` 不一致。
 - 它不是用来测试 HTTP 的，而是展示最小 socket client 的写法。
