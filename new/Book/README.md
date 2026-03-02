# kilo (single-file C terminal editor)

这是一个极简终端文本编辑器项目（单文件实现），核心源码在 `kilo.c`。

本仓库里的 `kilo.c` 版本有一个很突出的特点：**严格遵循“禁止前向引用”原则重构**——
文件中基本不使用函数原型声明，而是把函数按依赖关系从底向上排列，保证“调用方出现时，被调用函数已经在前面完整定义”。这对“按文件顺序阅读”非常友好。

> 版本：`KILO_VERSION 0.0.1`

---

## 1. 你会学到什么

- **Raw mode**：用 `termios` 把终端切换到 raw 模式，做到逐键响应。
- **ANSI Escape Sequences**：清屏、移动光标、隐藏/显示光标、颜色控制。
- **行缓冲模型**：把文件拆成行数组 `erow[]`，编辑时只改内存，保存时再拼接。
- **TAB 展开渲染**：`chars`（原始内容）与 `render`（可显示内容）分离。
- **语法高亮**：基于逐字符扫描的 lexer 风格实现（关键字/数字/字符串/注释）。
- **增量 UI 刷新**：用追加缓冲 `abuf` 组装输出，减少 `write()` 次数。
- **交互功能**：保存、退出保护、搜索（带高亮预览）、方向键移动、翻页。

---

## 2. 项目结构

仓库非常小：

- **`kilo.c`**
  - 编辑器的全部实现：数据结构、终端控制、渲染、编辑、搜索、文件 I/O、main。
- **`123`**
  - 与编辑器无关的 HTML 文件（看起来像是误放/样例文件）。学习编辑器实现时可以忽略。

---

## 3. 编译与运行

### 3.1 Linux / macOS / WSL

`kilo.c` 使用了 `termios` / `unistd` / `ioctl` / `getline` 等 POSIX 接口，最推荐在 Linux/macOS 或 WSL 下编译运行。

示例（gcc）：

```bash
gcc -std=c11 -O2 -Wall -Wextra -pedantic -o kilo kilo.c
./kilo test.txt
```

示例（clang）：

```bash
clang -std=c11 -O2 -Wall -Wextra -pedantic -o kilo kilo.c
./kilo test.txt
```

### 3.2 Windows

- **原生 Windows 控制台**默认不支持 `termios`，因此直接用 MSVC/MinGW 编译运行通常会遇到兼容性问题。
- 建议使用：
  - **WSL**（推荐）
  - 或者 MSYS2/MinGW 的 POSIX 环境（仍可能需要额外处理）。

---

## 4. 快捷键

- **`Ctrl-S`**：保存
- **`Ctrl-Q`**：退出
  - 若文件已修改（`E.dirty != 0`），需要连续按 3 次 `Ctrl-Q` 才能强制退出
- **`Ctrl-F`**：搜索
  - 输入字符实时搜索
  - `方向键` 上/下：切换上一个/下一个匹配
  - `Enter`：确认并停留在当前匹配
  - `ESC`：退出搜索并恢复原光标位置
- **`Enter`**：插入换行
- **`Backspace/Delete`**：删除字符（含跨行合并逻辑）
- **方向键**：移动光标
- **PageUp/PageDown**：翻页

---

## 5. 核心数据结构（读代码时先记住）

### 5.1 `struct editorConfig E`（全局状态）

`E` 保存编辑器的“全部运行时状态”，包括：

- 光标：`cx, cy`（屏幕坐标）
- 滚动偏移：`rowoff, coloff`
- 屏幕尺寸：`screenrows, screencols`（其中 `screenrows` 会减去 2 行状态栏）
- 文本：`erow *row` + `numrows`
- 脏标记：`dirty`
- 当前文件名：`filename`
- 状态栏消息：`statusmsg` + `statusmsg_time`
- 语法规则：`syntax`

### 5.2 `typedef struct erow`

每一行包含两套文本：

- **`chars` / `size`**：原始字符（你编辑的真实内容）
- **`render` / `rsize`**：用于显示的渲染字符（TAB 展开为空格）
- **`hl`**：与 `render` 等长的高亮类型数组
- **`hl_oc`**：该行结束时是否处于“多行注释未闭合”的状态（用于跨行传播）

### 5.3 `struct editorSyntax` + `HLDB[]`

高亮数据库（这里仅内置了 C/C++）：

- `filematch`：后缀匹配（`.c`, `.h`, `.cpp`...）
- `keywords`：关键字列表，末尾带 `|` 表示第二类关键字（类型关键字）
- 注释起止符：`//`, `/*`, `*/`
- `flags`：是否高亮字符串/数字

---

## 6. 主流程（从 `main()` 开始跟）

入口在文件底部：

1. `initEditor()`
   - 初始化全局 `E`
   - 读取终端尺寸 `getWindowSize()`
   - 注册 `SIGWINCH`（窗口大小变化）处理 `handleSigWinCh()`
2. `editorSelectSyntaxHighlight(argv[1])`
   - 根据文件名设置 `E.syntax`
3. `editorOpen(argv[1])`
   - `getline()` 逐行读入，调用 `editorInsertRow()`
4. `enableRawMode(STDIN_FILENO)`
   - 切换到 raw 模式
5. while(1)
   - `editorRefreshScreen()`：渲染
   - `editorProcessKeypress()`：读键、处理编辑命令

---

## 6.1 调用链阅读路线图（从入口到各功能）

这一节把“你按键 -> 状态变化 -> 屏幕刷新”的关键调用链串起来，适合对照源码做断点/跟读。

### 6.1.1 启动链路（初始化 -> 加载文件 -> 进入主循环）

```text
main
  -> initEditor
      -> getWindowSize
      -> signal(SIGWINCH, handleSigWinCh)
  -> editorSelectSyntaxHighlight
  -> editorOpen
      -> getline 循环
          -> editorInsertRow
              -> editorUpdateRow
                  -> editorUpdateSyntax
  -> enableRawMode
  -> while(1)
      -> editorRefreshScreen
      -> editorProcessKeypress
```

你可以把启动期的关键状态理解为：

- **`E.screenrows/screencols`**：由 `getWindowSize()` 得到（并减去 2 行状态栏）
- **`E.row[]/E.numrows`**：由 `editorOpen()` 读文件构建
- **`E.syntax`**：由 `editorSelectSyntaxHighlight()` 选择

### 6.1.2 每一帧循环（渲染 + 输入）

```text
while(1)
  -> editorRefreshScreen
  -> editorProcessKeypress
      -> editorReadKey
      -> (按键分发)
```

注意：这个编辑器采用“简单粗暴”的策略——每次循环都重绘整个屏幕（但用 `abuf` 合并输出减少系统调用）。

### 6.1.3 光标移动（方向键/翻页）

```text
editorProcessKeypress
  -> editorMoveCursor
      -> 计算 filerow/filecol = (E.rowoff+E.cy, E.coloff+E.cx)
      -> 更新 (E.cx/E.cy/E.rowoff/E.coloff)
```

这里最重要的是区分：

- **屏幕坐标**：`E.cx/E.cy`
- **文件坐标**：`filecol/fileRow`（要加上 `E.coloff/E.rowoff`）

### 6.1.4 插入字符（普通可打印字符）

```text
editorProcessKeypress
  -> editorInsertChar
      -> editorRowInsertChar
          -> realloc/memmove 修改 row->chars
          -> editorUpdateRow
              -> TAB 展开生成 row->render
              -> editorUpdateSyntax 生成 row->hl
      -> 更新光标与水平滚动 (E.cx/E.coloff)
      -> E.dirty++
```

你可以把这条链路理解为：**模型（chars）变了 -> 派生视图（render/hl）重算 -> 下一帧渲染自然会反映出来**。

### 6.1.5 插入换行（Enter，行分裂）

```text
editorProcessKeypress
  -> editorInsertNewline
      -> editorInsertRow (插入新行)
      -> (必要时) 截断原行 + editorUpdateRow
      -> 更新光标与垂直滚动 (E.cy/E.rowoff)
```

### 6.1.6 删除字符（Backspace/Delete，含跨行合并）

```text
editorProcessKeypress
  -> editorDelChar
      -> (行内删除) editorRowDelChar -> editorUpdateRow
      -> (行首删除) editorRowAppendString + editorDelRow
      -> 更新光标与滚动 (E.cx/E.cy/E.coloff/E.rowoff)
      -> E.dirty++
```

### 6.1.7 屏幕渲染（把 E 的状态变成终端输出）

```text
editorRefreshScreen
  -> abAppend(隐藏光标/回到左上)
  -> for y in screenrows
      -> 取 filerow = E.rowoff + y
      -> 取 row->render/row->hl
      -> editorSyntaxToColor(hl) 输出 ANSI 颜色
  -> 绘制状态栏/消息栏
  -> 计算真实光标列（考虑 TAB 对齐）
  -> abAppend(移动光标/显示光标)
  -> write(STDOUT, ab)
```

### 6.1.8 搜索（Ctrl-F，临时覆盖高亮并可恢复）

```text
editorProcessKeypress
  -> editorFind
      -> editorReadKey (循环读取 query)
      -> strstr(row->render, query)
      -> 保存原 hl -> 临时 memset(HL_MATCH)
      -> 调整 E.cx/E.cy/E.rowoff/E.coloff 让匹配可见
      -> ESC/Enter 时恢复 hl 并退出
```

### 6.1.9 保存（Ctrl-S，把行数组写回文件）

```text
editorProcessKeypress
  -> editorSave
      -> editorRowsToString
      -> open + ftruncate + write
      -> E.dirty = 0
      -> editorSetStatusMessage
```

### 6.1.10 终端尺寸变化（SIGWINCH）

```text
SIGWINCH
  -> handleSigWinCh
      -> getWindowSize
      -> 修正 E.cx/E.cy 防越界
      -> editorRefreshScreen
```

---

## 7. 子系统导览（按阅读顺序）

`kilo.c` 本身就按“依赖从底向上”的顺序组织。你可以按如下模块理解：

### 7.1 底层工具

- `is_separator()`
  - 用于判断关键字边界

### 7.2 Raw 模式与终端尺寸

- `enableRawMode()` / `disableRawMode()` / `editorAtExit()`
- `getCursorPosition()` / `getWindowSize()`

### 7.3 语法高亮

- `editorSyntaxToColor()`：高亮类型 -> ANSI 颜色
- `editorUpdateSyntax()`：逐字符扫描设置 `row->hl`
- `editorSelectSyntaxHighlight()`：选中语法规则

特别点：

- `editorRowHasOpenComment()` 用于跨行多行注释状态传播。

### 7.4 行编辑（模型层）

- 行生命周期：`editorInsertRow()` / `editorDelRow()` / `editorFreeRow()`
- 渲染更新：`editorUpdateRow()`（TAB 展开 + 调 `editorUpdateSyntax()`）
- 字符级操作：
  - `editorRowInsertChar()`
  - `editorRowAppendString()`
  - `editorRowDelChar()`
- 保存辅助：`editorRowsToString()`

### 7.5 文件 I/O

- `editorOpen()`：读取文件到 `E.row[]`
- `editorSave()`：拼接整文件并写回磁盘

### 7.6 屏幕刷新（View 层）

- `struct abuf` + `abAppend()` / `abFree()`：输出缓冲
- `editorRefreshScreen()`：
  - 清屏/绘制编辑区
  - 绘制状态栏（文件名、行数、dirty、当前位置）
  - 绘制消息栏（5 秒失效）
  - 计算渲染光标位置（处理 TAB 对齐）

### 7.7 搜索

- `editorFind()`：
  - 读取查询字符串
  - 用 `strstr(row->render, query)` 做子串匹配
  - 临时把匹配区域 `hl` 覆盖成 `HL_MATCH` 并在退出时恢复

### 7.8 按键处理（Controller 层）

- `editorReadKey()`：读单键 + 解析 ESC 序列（方向键/翻页/Del 等）
- `editorMoveCursor()`：移动光标 + 滚动控制
- `editorInsertChar()` / `editorInsertNewline()` / `editorDelChar()`
- `editorProcessKeypress()`：把按键映射到编辑操作

---

## 8. 推荐阅读路线（学习向）

如果你希望最快建立“全局心智模型”，建议：

1. 从 **`main()`** 看整体循环与初始化顺序
2. 看 **`struct editorConfig`** 和 **`erow`**，明确数据模型
3. 看 **`editorRefreshScreen()`**，理解“屏幕如何被重绘”
4. 看 **`editorReadKey()`** 和 **`editorProcessKeypress()`**，理解“按键如何驱动状态变化”
5. 回到行编辑函数（`editorRowInsertChar` / `editorInsertNewline` / `editorDelChar`）
6. 最后看语法高亮（`editorUpdateSyntax`）和搜索（`editorFind`）

---

## 9. 小提示（读代码时容易卡的点）

- **屏幕坐标 vs 文件坐标**：
  - 屏幕坐标由 `cx, cy` 表示；
  - 文件坐标需要加上滚动偏移：
    - `filerow = E.rowoff + E.cy`
    - `filecol = E.coloff + E.cx`
- **`chars` vs `render`**：
  - 编辑操作主要针对 `chars`
  - 显示与搜索主要针对 `render`
- **多行注释跨行**：
  - `hl_oc` + `editorRowHasOpenComment()` 决定下一行是否从 `in_comment=1` 开始解析

---

## 10. License

仓库未提供 License 文件；如需开源发布，建议补充明确的许可证文本。
