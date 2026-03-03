这是为您整理的HTML语法速查手册。这份指南涵盖了从基础结构到HTML5 API的绝大部分知识点，旨在作为一份全面且简洁的参考文档。

---

# HTML 语法速查手册 (全面版)

## 一、 文档基础

### 1.1 文档结构
```html
<!DOCTYPE html>  <!-- 文档类型声明，必须位于第一行 -->
<html lang="zh-CN"> <!-- HTML根元素，设置页面主要语言 -->
<head>
    <meta charset="UTF-8"> <!-- 字符编码，推荐UTF-8 -->
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <!-- 视口设置，用于响应式设计 -->
    <title>页面标题</title> <!-- 浏览器标签页标题 -->
    <link rel="stylesheet" href="style.css"> <!-- 链接外部CSS -->
    <style> /* 内嵌CSS样式 */ </style>
    <script src="script.js" defer></script> <!-- 链接外部JS -->
</head>
<body>
    <!-- 页面可见内容 -->
</body>
</html>
```

### 1.2 语法规则
- **标签**：由尖括号包围的关键词，如 `<div>`。
- **元素**：由开始标签、内容和结束标签组成，如 `<p>内容</p>`。
  - **空元素**：没有内容的元素，如 `<br>`，可自闭合 `<br />`。
- **属性**：为元素提供额外信息，写在开始标签内。格式：`属性名="属性值"`。
  - **布尔属性**：属性值可省略，如 `<input type="checkbox" checked>` 等同于 `checked="checked"`。
- **注释**：`<!-- 注释内容 -->`，浏览器不会渲染。

## 二、 元数据与文档头 (`<head>`)

用于定义文档的元信息，不直接显示在页面内容区。

| 标签 | 描述 | 常用属性/示例 |
| :--- | :--- | :--- |
| `<title>` | **必需**。定义浏览器工具栏的标题。 | `<title>我的网站</title>` |
| `<base>` | 为页面上所有相对链接规定基础 URL。 | `<base href="https://example.com/" target="_blank">` |
| `<link>` | 定义文档与外部资源的关系。 | `rel="stylesheet"` (CSS), `rel="icon"` (网站图标) |
| `<meta>` | 定义关于 HTML 文档的元数据。 | **字符集**: `charset="UTF-8"` <br> **SEO关键词**: `name="keywords" content="HTML, CSS"` <br> **页面描述**: `name="description" content="..."` <br> **作者**: `name="author" content="..."` <br> **视口**: `name="viewport" content="width=device-width"` <br> **刷新/重定向**: `http-equiv="refresh" content="30;url=https://..."` |
| `<style>` | 定义内嵌的 CSS 样式。 | `<style> body { background: #fff; } </style>` |

## 三、 内容分区 (结构化布局)

这些标签用于构建页面的整体框架，定义页眉、页脚、导航等大区块。

| 标签 | 描述 | 作用与语义 |
| :--- | :--- | :--- |
| `<body>` | 文档的主体，所有可见内容均在此标签内。 | 页面的“画布”。 |
| `<header>` | 定义文档或某个区块的页眉。 | 通常包含 Logo、标题、导航等。 |
| `<nav>` | 定义导航链接的集合。 | 用于主导航菜单。 |
| `<main>` | 定义文档的主要内容，**一个页面仅能使用一次**。 | 应排除侧边栏、导航等重复内容。 |
| `<section>` | 定义文档中的一个主题性分区。 | 通常包含一个标题 (`<h1>`-`<h6>`)。 |
| `<article>` | 定义独立的、可复用的内容块。 | 如论坛帖子、新闻文章、用户评论。 |
| `<aside>` | 定义侧边栏，与周边内容略微相关。 | 常用于放置广告、引用、目录。 |
| `<footer>` | 定义文档或某个区块的页脚。 | 通常包含版权信息、联系方式、相关链接。 |
| `<h1>`-`<h6>` | 定义六级标题，`<h1>` 最重要，`<h6>` 最不重要。 | **注意**：不要用标题来加粗文本，按层级合理嵌套。 |
| `<address>` | 定义文档或文章的联系信息（作者、联系方式）。 | 通常由 `<article>` 内的作者信息使用。 |

## 四、 文本内容 (块级元素)

这些标签定义了基本的文本块和内容区域。

| 标签 | 描述 | 示例/备注 |
| :--- | :--- | :--- |
| `<p>` | 定义段落。 | 浏览器会自动在前后添加间距。 |
| `<div>` | 无特殊语义的通用块级容器。 | 用于布局和CSS样式挂钩。 |
| `<hr>` | 主题分割线（水平线）。 | 表示一个段落级别的主题转换。 |
| `<pre>` | 预格式文本。 | 保留空格和换行，常用于展示代码。 |
| `<blockquote>` | 定义长引用。 | `cite` 属性可指定引用的来源URL。 |
| `<ul>` | 无序列表。 | 列表项用 `<li>`。 |
| `<ol>` | 有序列表。 | 列表项用 `<li>`。属性：`type` (1, A, a, I, i), `start`, `reversed`。 |
| `<li>` | 列表项。 | 需放在 `<ul>` 或 `<ol>` 内。 |
| `<dl>` | 描述列表/定义列表。 | 配合 `<dt>` (术语) 和 `<dd>` (描述) 使用。 |

## 五、 文本内联语义 (行内元素)

用于标记段落内部的词、短语或特定格式。

| 标签 | 描述 | 示例/备注 |
| :--- | :--- | :--- |
| `<span>` | 无特殊语义的通用行内容器。 | 用于CSS样式或JS操作。 |
| `<a>` | 定义超链接。 | `href`：链接地址 <br> `target`：`_self` (默认), `_blank` (新标签) <br> `download`：强制下载文件 |
| `<strong>` | 表示内容重要性，通常**加粗**显示。 | 强调语义。 |
| `<b>` | 吸引读者注意，但无重要性强调。仅**加粗**。 | 如摘要中的关键词。 |
| `<em>` | 表示内容强调，通常*斜体*显示。 | 语气上的强调。 |
| `<i>` | 表示与普通文本不同的文本，如技术术语、外语词。 | 通常*斜体*显示，无语义强调。 |
| `<br>` | 换行。 | 用于在诗歌、地址中强制换行。 |
| `<wbr>` | 建议浏览器在此处可换行。 | 用于长单词或URL。 |
| `<small>` | 展示小号字体效果，如免责声明、版权声明。 | 不是用来让字体变小。 |
| `<mark>` | 标记或高亮显示某些文本。 | 通常为黄色背景。 |
| `<del>` | 定义已删除文本。 | 通常为**删除线**。 |
| `<ins>` | 定义插入文本。 | 通常为**下划线**。 |
| `<sup>` | 上标文本。 | 如数学公式 x²。 |
| `<sub>` | 下标文本。 | 如化学式 H₂O。 |
| `<code>` | 定义计算机代码片段。 | 通常显示为等宽字体。 |
| `<kbd>` | 定义键盘输入。 | 如 `Ctrl + S`。 |
| `<time>` | 定义时间或日期。 | `datetime` 属性提供机器可读格式。 |
| `<abbr>` | 定义缩写或首字母缩略词。 | 使用 `title` 属性提供全称。 |

## 六、 图片与多媒体

### 6.1 图片
```html
<!-- 基本图片 -->
<img src="images/logo.png" alt="网站Logo" width="200" height="100">

<!-- 响应式图片 (根据屏幕条件加载不同图片) -->
<picture>
    <source media="(min-width: 800px)" srcset="large.jpg">
    <source media="(min-width: 400px)" srcset="medium.jpg">
    <img src="small.jpg" alt="响应式图片示例"> <!-- 必须保留，作为默认/降级 -->
</picture>

<!-- 带标题的图片 -->
<figure>
    <img src="chart.png" alt="销售数据图">
    <figcaption>图1：2024年度销售趋势</figcaption>
</figure>
```

### 6.2 音频与视频
```html
<!-- 视频 -->
<video controls width="600" poster="preview.jpg">
    <source src="movie.mp4" type="video/mp4">
    <source src="movie.ogg" type="video/ogg">
    您的浏览器不支持 video 标签。 <!-- 降级提示 -->
</video>
<!-- 属性：autoplay(自动播放), muted(静音), loop(循环), controls(显示控件) -->

<!-- 音频 -->
<audio controls>
    <source src="song.mp3" type="audio/mpeg">
    <source src="song.ogg" type="audio/ogg">
    您的浏览器不支持 audio 标签。
</audio>
<!-- 属性：autoplay, muted, loop, controls -->
```

## 七、 超链接与导航

```html
<!-- 基本链接 -->
<a href="https://www.example.com">访问外部网站</a>
<a href="/about.html">相对路径 - 关于我们</a>

<!-- 锚点链接（页面内跳转） -->
<a href="#section2">跳转到第二节</a>
...
<h2 id="section2">第二节</h2>

<!-- 空链接/占位符 -->
<a href="#">暂无链接</a>
<a href="javascript:void(0);">执行JavaScript</a>

<!-- 邮件与电话 -->
<a href="mailto:info@example.com?subject=咨询">发送邮件</a>
<a href="tel:+861234567890">拨打电话</a>
```

## 八、 表格

```html
<table>
    <caption>2024年销售报表</caption> <!-- 表格标题 -->
    <thead> <!-- 表头区域 -->
        <tr>
            <th>季度</th> <!-- 表头单元格，加粗居中 -->
            <th>销售额</th>
        </tr>
    </thead>
    <tbody> <!-- 表格主体区域 -->
        <tr> <!-- 行 -->
            <td>第一季度</td> <!-- 标准单元格 -->
            <td>¥10,000</td>
        </tr>
    </tbody>
    <tfoot> <!-- 表尾区域（如汇总） -->
        <tr>
            <td>总计</td>
            <td>¥45,000</td>
        </tr>
    </tfoot>
</table>

<!-- 单元格合并 -->
<td colspan="2">合并两列</td> <!-- 跨列 -->
<td rowspan="3">合并三行</td>   <!-- 跨行 -->
```

## 九、 表单与输入

表单用于收集用户输入。

### 9.1 表单结构
```html
<form action="/submit-form" method="post" enctype="multipart/form-data">
    <!-- 表单控件放在这里 -->
    <!-- action: 数据提交到的URL -->
    <!-- method: GET(通过URL提交) / POST(通过HTTP body提交) -->
    <!-- enctype: 用于文件上传时必须为 multipart/form-data -->
</form>
```

### 9.2 输入元素 (`<input>`)
`<input>` 是表单中最核心的元素，通过 `type` 属性变化出不同形态。

| Type 值 | 描述 | 示例/备注 |
| :--- | :--- | :--- |
| `text` | 单行文本输入框。 | `size`, `maxlength`, `placeholder` |
| `password` | 密码输入框（字符被遮挡）。 | |
| `email` | 用于输入邮箱，会自动验证格式。 | |
| `number` | 用于输入数字。 | `min`, `max`, `step` |
| `tel` | 用于输入电话号码，不强制验证。 | 移动端会调出数字键盘。 |
| `url` | 用于输入URL，自动验证格式。 | |
| `search` | 搜索框，样式可能与其他框不同。 | |
| `textarea` | **注意：这是单独标签**，用于多行文本。 | `<textarea rows="4" cols="50">` |
| `checkbox` | 复选框（多选）。 | 使用相同 `name` 分组。 |
| `radio` | 单选按钮。 | 使用相同 `name` 分组。 |
| `file` | 文件上传控件。 | 需配合 `enctype="multipart/form-data"` |
| `hidden` | 隐藏字段，不显示但会提交。 | |
| `submit` | 提交按钮。 | `value` 可修改按钮文字。 |
| `reset` | 重置按钮，将表单重置为初始值。 | |
| `button` | 普通按钮，需配合JavaScript。 | |
| `image` | 图片提交按钮。 | 需定义 `src` 和 `alt`。 |
| `color` | 颜色选择器。 | |
| `date` | 日期选择器 (年月日)。 | `min`, `max` |
| `datetime-local` | 本地日期时间。 | |
| `month` | 月份选择器。 | |
| `time` | 时间选择器。 | |
| `week` | 周选择器。 | |
| `range` | 滑块输入。 | `min`, `max`, `step`, `value` |

### 9.3 其他表单元素
```html
<!-- 下拉列表 -->
<select name="city" id="city" multiple> <!-- multiple 可多选 -->
    <optgroup label="中国省份"> <!-- 选项组 -->
        <option value="bj">北京</option>
        <option value="sh" selected>上海</option> <!-- selected 默认选中 -->
    </optgroup>
</select>

<!-- 文本域 (多行文本) -->
<textarea name="message" rows="10" cols="30" placeholder="请输入内容..."></textarea>

<!-- 按钮 (除了 input 的三种type，还有专门的 button 标签) -->
<button type="submit">提交</button> <!-- 更灵活，内部可放图片等 -->
<button type="button" onclick="alert('点击')">点击我</button>

<!-- 字段集与图例 (用于分组) -->
<fieldset>
    <legend>个人信息</legend> <!-- 分组标题 -->
    姓名: <input type="text" name="name"><br>
    年龄: <input type="number" name="age">
</fieldset>
```

### 9.4 表单属性 (用于控件)
- **`name`**：**必须**。用于在提交数据时作为键名。
- **`value`**：控件的默认值。
- **`placeholder`**：输入框的占位提示。
- **`required`**：布尔属性，字段不能为空。
- **`readonly`**：只读，用户不能修改，但数据会提交。
- **`disabled`**：禁用，用户不能交互，数据**不会**提交。
- **`checked`**：用于 `radio` 和 `checkbox`，默认选中。
- **`selected`**：用于 `<option>`，默认选中。
- **`autofocus`**：页面加载时自动获得焦点。
- **`pattern`**：用正则表达式验证输入。如 `pattern="[A-Za-z]{3}"`

## 十、 高级与交互元素 (HTML5特性)

### 10.1 对话与提示
```html
<!-- 详情/摘要折叠块 -->
<details>
    <summary>点击展开查看详情</summary>
    <p>这里是隐藏的详细内容，点击后显示。</p>
</details>

<!-- 对话框 (需配合JS) -->
<dialog id="myDialog">
    <p>这是一个弹窗</p>
    <button onclick="document.getElementById('myDialog').close()">关闭</button>
</dialog>
<button onclick="document.getElementById('myDialog').showModal()">打开弹窗</button>
```

### 10.2 进度与度量
```html
<!-- 任务进度条 (通常用于不确定时间的任务) -->
<progress value="30" max="100">30%</progress>

<!-- 度量衡 (如磁盘使用量) -->
<meter value="0.6" min="0" max="1" low="0.3" high="0.8" optimum="0.5">60%</meter>
```

### 10.3 脚本与画布
```html
<!-- 可伸缩矢量图形 (用于绘制矢量图) -->
<svg width="100" height="100">
    <circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" />
</svg>

<!-- 画布 (用JavaScript动态绘制位图) -->
<canvas id="myCanvas" width="200" height="200"></canvas>
<script>
    var canvas = document.getElementById('myCanvas');
    var ctx = canvas.getContext('2d');
    ctx.fillStyle = 'red';
    ctx.fillRect(10, 10, 150, 75);
</script>
```

## 十一、 全局属性

几乎所有 HTML 元素都有的通用属性。

| 属性 | 描述 |
| :--- | :--- |
| `class` | 定义元素的类名，用于CSS选择器和JavaScript。 |
| `id` | 定义元素的唯一标识符，**在整个文档中必须唯一**。 |
| `style` | 定义元素的内联CSS样式。 |
| `title` | 定义元素的额外信息，通常显示为悬浮提示。 |
| `lang` | 定义元素内容的语言。如 `lang="en"`。 |
| `dir` | 定义文本方向。`ltr` (左到右) 或 `rtl` (右到左)。 |
| `data-*` | 自定义数据属性，用于存储页面或应用的私有数据。如 `<div data-user-id="123">` |
| `hidden` | 布尔属性，表示该元素尚不相关或不再相关，浏览器不渲染。 |
| `tabindex` | 定义元素的键盘Tab键导航顺序。 |
| `contenteditable` | 布尔属性，使元素内容可被用户编辑。 |
| `draggable` | 布尔属性，定义元素是否可拖拽。 |
| `spellcheck` | 布尔属性，定义是否检查拼写/语法。 |

---

这份速查表涵盖了日常开发中95%以上的常用标签和属性。建议根据具体需求查阅更详细的官方文档或专业网站（如 MDN Web Docs）。