# 前端三剑客速查表

## 🏷️ 一、HTML 常用标签速查

### **1.1 结构标签（语义化核心）**
```html
<!-- 页面骨架 -->
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>页面标题</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <!-- 主要结构 -->
    <header>网站头部（logo、导航）</header>
    <nav>导航栏（菜单）</nav>
    <main>主要内容区域</main>
    <aside>侧边栏（广告、相关链接）</aside>
    <footer>页脚（版权、联系方式）</footer>
</body>
</html>
```

### **1.2 内容分区标签**
```html
<!-- 文章内容结构 -->
<article>独立文章内容</article>
<section>内容区块（章节）</section>
<div>通用容器（无语义）</div>
<span>行内容器（无语义）</span>

<!-- 标题层级（h1只能有一个） -->
<h1>主标题（最重要）</h1>
<h2>次级标题</h2>
<h3>三级标题</h3>
<h4>四级标题</h4>
<h5>五级标题</h5>
<h6>六级标题</h6>
```

### **1.3 文本标签**
```html
<p>段落文本</p>
<strong>强调（粗体，语义重要）</strong>
<b>加粗（仅样式）</b>
<em>强调（斜体，语义）</em>
<i>斜体（仅样式/图标）</i>
<u>下划线</u>
<s>删除线</s>
<mark>高亮文本</mark>
<small>小号文本</small>

<!-- 引用 -->
<blockquote>块级引用</blockquote>
<q>行内引用</q>
<cite>引用来源</cite>

<!-- 代码 -->
<code>代码片段</code>
<pre>保留格式文本（多行代码）</pre>
<kbd>键盘输入</kbd>
<samp>程序输出</samp>
```

### **1.4 列表标签**
```html
<!-- 无序列表 -->
<ul>
    <li>列表项1</li>
    <li>列表项2</li>
</ul>

<!-- 有序列表 -->
<ol>
    <li>第一项</li>
    <li>第二项</li>
</ol>

<!-- 定义列表 -->
<dl>
    <dt>术语</dt>
    <dd>描述</dd>
    <dt>HTML</dt>
    <dd>超文本标记语言</dd>
</dl>
```

### **1.5 媒体标签**
```html
<!-- 图片 -->
<img src="image.jpg" alt="图片描述" width="300" height="200">

<!-- 视频 -->
<video controls width="600">
    <source src="video.mp4" type="video/mp4">
    您的浏览器不支持视频标签
</video>

<!-- 音频 -->
<audio controls>
    <source src="audio.mp3" type="audio/mpeg">
</audio>

<!-- 画布 -->
<canvas id="myCanvas" width="400" height="200"></canvas>

<!-- SVG矢量图 -->
<svg width="100" height="100">
    <circle cx="50" cy="50" r="40" fill="red" />
</svg>
```

### **1.6 表单标签**
```html
<form action="/submit" method="POST">
    <!-- 文本输入 -->
    <label for="name">姓名：</label>
    <input type="text" id="name" name="name" placeholder="请输入姓名">
    
    <!-- 邮箱 -->
    <input type="email" placeholder="邮箱">
    
    <!-- 密码 -->
    <input type="password" placeholder="密码">
    
    <!-- 数字 -->
    <input type="number" min="1" max="100" step="1">
    
    <!-- 日期 -->
    <input type="date">
    <input type="datetime-local">
    
    <!-- 单选 -->
    <input type="radio" id="male" name="gender" value="male">
    <label for="male">男</label>
    
    <!-- 多选 -->
    <input type="checkbox" id="agree" name="agree">
    <label for="agree">同意协议</label>
    
    <!-- 下拉 -->
    <select name="city">
        <option value="">请选择</option>
        <option value="beijing">北京</option>
        <option value="shanghai">上海</option>
    </select>
    
    <!-- 多行文本 -->
    <textarea rows="4" cols="50" placeholder="请输入内容"></textarea>
    
    <!-- 按钮 -->
    <button type="submit">提交</button>
    <button type="reset">重置</button>
    <button type="button">普通按钮</button>
    
    <!-- 文件上传 -->
    <input type="file" accept=".jpg,.png">
</form>
```

### **1.7 表格标签**
```html
<table border="1">
    <caption>表格标题</caption>
    <thead>
        <tr>
            <th>姓名</th>
            <th>年龄</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <td>张三</td>
            <td>25</td>
        </tr>
    </tbody>
    <tfoot>
        <tr>
            <td>总计</td>
            <td>1人</td>
        </tr>
    </tfoot>
</table>
```

### **1.8 其他重要标签**
```html
<!-- 链接 -->
<a href="https://example.com" target="_blank">外部链接</a>
<a href="#section1">锚点链接</a>
<a href="mailto:email@example.com">邮件链接</a>
<a href="tel:13800138000">电话链接</a>

<!-- 换行 -->
<br>

<!-- 水平线 -->
<hr>

<!-- 详情折叠 -->
<details>
    <summary>查看更多</summary>
    <p>详细内容在这里...</p>
</details>

<!-- 进度条 -->
<progress value="70" max="100">70%</progress>

<!-- 度量 -->
<meter value="0.6" min="0" max="1">60%</meter>

<!-- 时间 -->
<time datetime="2024-01-15">2024年1月15日</time>
```

---

## 🎨 二、CSS 动画效果速查

### **2.1 基础动画语法**
```css
/* 1. 过渡动画 */
.element {
    transition: all 0.3s ease-in-out;
    /* 简写：property duration timing-function delay */
    transition: width 0.5s ease 0.2s;
    
    /* 分开写 */
    transition-property: transform, opacity;
    transition-duration: 0.5s;
    transition-timing-function: ease;
    transition-delay: 0.1s;
}

/* 2. 关键帧动画 */
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

.element {
    animation: fadeIn 1s ease both;
    /* 简写：name duration timing-function delay iteration-count direction fill-mode */
    
    /* 分开写 */
    animation-name: fadeIn;
    animation-duration: 1s;
    animation-timing-function: ease;
    animation-delay: 0s;
    animation-iteration-count: infinite; /* 循环次数 */
    animation-direction: alternate; /* 方向 */
    animation-fill-mode: both; /* 动画前后状态 */
    animation-play-state: running; /* 运行/暂停 */
}
```

### **2.2 常用动画效果（复制即用）**
```css
/* 淡入 */
.fade-in {
    animation: fadeIn 0.5s ease;
}
@keyframes fadeIn {
    from { opacity: 0; }
    to { opacity: 1; }
}

/* 淡出 */
.fade-out {
    animation: fadeOut 0.5s ease;
}
@keyframes fadeOut {
    from { opacity: 1; }
    to { opacity: 0; }
}

/* 上滑进入 */
.slide-up {
    animation: slideUp 0.5s ease;
}
@keyframes slideUp {
    from { 
        transform: translateY(50px);
        opacity: 0;
    }
    to { 
        transform: translateY(0);
        opacity: 1;
    }
}

/* 下滑进入 */
.slide-down {
    animation: slideDown 0.5s ease;
}
@keyframes slideDown {
    from { 
        transform: translateY(-50px);
        opacity: 0;
    }
    to { 
        transform: translateY(0);
        opacity: 1;
    }
}

/* 左滑进入 */
.slide-left {
    animation: slideLeft 0.5s ease;
}
@keyframes slideLeft {
    from { 
        transform: translateX(50px);
        opacity: 0;
    }
    to { 
        transform: translateX(0);
        opacity: 1;
    }
}

/* 右滑进入 */
.slide-right {
    animation: slideRight 0.5s ease;
}
@keyframes slideRight {
    from { 
        transform: translateX(-50px);
        opacity: 0;
    }
    to { 
        transform: translateX(0);
        opacity: 1;
    }
}

/* 缩放进入 */
.zoom-in {
    animation: zoomIn 0.5s ease;
}
@keyframes zoomIn {
    from { 
        transform: scale(0.8);
        opacity: 0;
    }
    to { 
        transform: scale(1);
        opacity: 1;
    }
}

/* 缩放退出 */
.zoom-out {
    animation: zoomOut 0.5s ease;
}
@keyframes zoomOut {
    from { 
        transform: scale(1);
        opacity: 1;
    }
    to { 
        transform: scale(0.8);
        opacity: 0;
    }
}

/* 弹跳效果 */
.bounce {
    animation: bounce 0.5s ease;
}
@keyframes bounce {
    0%, 100% { transform: translateY(0); }
    50% { transform: translateY(-20px); }
}

/* 旋转进入 */
.rotate-in {
    animation: rotateIn 0.5s ease;
}
@keyframes rotateIn {
    from { 
        transform: rotate(-180deg) scale(0.5);
        opacity: 0;
    }
    to { 
        transform: rotate(0) scale(1);
        opacity: 1;
    }
}

/* 闪烁效果 */
.blink {
    animation: blink 1s infinite;
}
@keyframes blink {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.3; }
}

/* 脉动效果 */
.pulse {
    animation: pulse 2s infinite;
}
@keyframes pulse {
    0% { transform: scale(1); }
    50% { transform: scale(1.05); }
    100% { transform: scale(1); }
}

/* 摇晃效果（错误提示） */
.shake {
    animation: shake 0.5s;
}
@keyframes shake {
    0%, 100% { transform: translateX(0); }
    10%, 30%, 50%, 70%, 90% { transform: translateX(-5px); }
    20%, 40%, 60%, 80% { transform: translateX(5px); }
}

/* 翻转卡片 */
.flip {
    animation: flip 0.6s;
    backface-visibility: hidden;
}
@keyframes flip {
    from { transform: perspective(400px) rotateY(0); }
    to { transform: perspective(400px) rotateY(180deg); }
}

/* 打字机效果 */
.typewriter {
    overflow: hidden;
    border-right: 0.15em solid orange;
    white-space: nowrap;
    animation: typing 3.5s steps(40, end), blink-caret 0.75s step-end infinite;
}
@keyframes typing {
    from { width: 0 }
    to { width: 100% }
}
@keyframes blink-caret {
    from, to { border-color: transparent }
    50% { border-color: orange; }
}

/* 加载动画 */
.loader {
    width: 40px;
    height: 40px;
    border: 4px solid #f3f3f3;
    border-top: 4px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
}
@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* 进度条动画 */
.progress-bar {
    width: 0%;
    height: 4px;
    background: linear-gradient(90deg, #ff7e5f, #feb47b);
    animation: progress 2s ease-in-out forwards;
}
@keyframes progress {
    to { width: 100%; }
}

/* 悬浮效果 */
.hover-lift {
    transition: transform 0.3s ease, box-shadow 0.3s ease;
}
.hover-lift:hover {
    transform: translateY(-5px);
    box-shadow: 0 10px 20px rgba(0,0,0,0.1);
}

/* 按钮点击效果 */
.btn-click:active {
    transform: scale(0.95);
    transition: transform 0.1s;
}
```

### **2.3 实用动画组合**
```css
/* 页面加载动画序列 */
.stagger-item:nth-child(1) { animation-delay: 0.1s; }
.stagger-item:nth-child(2) { animation-delay: 0.2s; }
.stagger-item:nth-child(3) { animation-delay: 0.3s; }

/* 无限循环动画 */
.infinite-rotate {
    animation: rotate 3s linear infinite;
}
@keyframes rotate {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
}

/* 悬停触发子元素动画 */
.parent:hover .child {
    animation: slideUp 0.3s ease;
}

/* 滚动触发动画（需JS配合） */
.animate-on-scroll {
    opacity: 0;
    transform: translateY(30px);
    transition: opacity 0.6s, transform 0.6s;
}
.animate-on-scroll.visible {
    opacity: 1;
    transform: translateY(0);
}
```

### **2.4 CSS变量动画**
```css
/* 使用CSS变量控制动画 */
:root {
    --primary-color: #3498db;
    --animation-speed: 0.3s;
}

.element {
    transition: background-color var(--animation-speed);
}
.element:hover {
    background-color: var(--primary-color);
}

/* 动态改变变量 */
.element {
    animation: colorChange 2s infinite alternate;
}
@keyframes colorChange {
    from { --hue: 0; }
    to { --hue: 360; }
}
.element {
    background: hsl(var(--hue), 100%, 50%);
}
```

---

## ⚡ 三、JavaScript 最常用方法速查

### **3.1 DOM 操作（操作页面元素）**
```javascript
// 获取元素
document.getElementById('id')                 // 通过id
document.querySelector('.class')             // 通过CSS选择器（第一个）
document.querySelectorAll('.class')          // 通过CSS选择器（全部）
document.getElementsByClassName('class')     // 通过类名
document.getElementsByTagName('div')         // 通过标签名

// 修改内容
element.innerHTML = '<span>新内容</span>'    // 设置HTML（注意XSS风险）
element.textContent = '纯文本内容'           // 设置纯文本（安全）
element.innerText = '文本内容'               // 设置文本（考虑样式）

// 修改样式
element.style.color = 'red'                  // 修改单个样式
element.style.cssText = 'color: red; font-size: 16px;' // 批量修改
element.classList.add('new-class')           // 添加类
element.classList.remove('old-class')        // 移除类
element.classList.toggle('active')           // 切换类
element.classList.contains('class')          // 检查类

// 修改属性
element.setAttribute('data-id', '123')       // 设置属性
element.getAttribute('data-id')              // 获取属性
element.removeAttribute('data-id')           // 移除属性
element.hasAttribute('data-id')              // 检查属性

// 创建和添加元素
const newDiv = document.createElement('div') // 创建元素
newDiv.textContent = '新元素'
document.body.appendChild(newDiv)            // 添加到末尾
parent.insertBefore(newDiv, reference)       // 插入到指定位置
element.remove()                             // 移除元素
element.cloneNode(true)                      // 克隆元素（深拷贝）

// 遍历DOM
element.parentElement                        // 父元素
element.children                             // 子元素集合
element.firstElementChild                    // 第一个子元素
element.lastElementChild                     // 最后一个子元素
element.nextElementSibling                   // 下一个兄弟元素
element.previousElementSibling               // 上一个兄弟元素
```

### **3.2 事件处理**
```javascript
// 添加事件监听
element.addEventListener('click', function(event) {
    console.log('点击了', event.target)
}, false)  // false表示冒泡阶段，true表示捕获阶段

// 常用事件类型
'click'         // 点击
'dblclick'      // 双击
'mouseenter'    // 鼠标进入
'mouseleave'    // 鼠标离开
'mousemove'     // 鼠标移动
'mousedown'     // 鼠标按下
'mouseup'       // 鼠标松开
'keydown'       // 键盘按下
'keyup'         // 键盘松开
'keypress'      // 键盘字符输入
'input'         // 输入框输入
'change'        // 值改变（如select）
'submit'        // 表单提交
'focus'         // 获得焦点
'blur'          // 失去焦点
'load'          // 加载完成
'DOMContentLoaded' // DOM加载完成
'resize'        // 窗口大小改变
'scroll'        // 滚动

// 事件对象常用属性
event.target        // 触发事件的元素
event.currentTarget // 绑定事件的元素
event.type          // 事件类型
event.preventDefault()  // 阻止默认行为
event.stopPropagation() // 阻止事件传播
event.key           // 按下的键（键盘事件）
event.clientX       // 鼠标X坐标
event.clientY       // 鼠标Y坐标

// 移除事件
element.removeEventListener('click', handler)
```

### **3.3 数组方法（最常用）**
```javascript
const arr = [1, 2, 3, 4, 5]

// 遍历
arr.forEach(item => console.log(item))           // 遍历（无返回值）
arr.map(item => item * 2)                        // 映射新数组 [2,4,6,8,10]
arr.filter(item => item > 2)                     // 过滤 [3,4,5]
arr.find(item => item > 2)                       // 查找第一个 3
arr.findIndex(item => item > 2)                  // 查找索引 2

// 检查
arr.some(item => item > 4)                       // 是否有满足条件的 true
arr.every(item => item > 0)                      // 是否都满足 true
arr.includes(3)                                  // 是否包含 true

// 转换
arr.reduce((sum, item) => sum + item, 0)         // 累加 15
arr.reduceRight()                                // 从右向左累加

// 排序和反转
arr.sort((a, b) => a - b)                        // 升序排序
arr.reverse()                                    // 反转数组

// 增删改查
arr.push(6)                                      // 末尾添加，返回新长度
arr.pop()                                        // 删除末尾，返回删除的元素
arr.unshift(0)                                   // 开头添加，返回新长度
arr.shift()                                      // 删除开头，返回删除的元素

arr.splice(1, 2, 'a', 'b')                       // 删除并添加：从索引1删除2个，添加'a','b'
arr.slice(1, 3)                                  // 切片：索引1到3（不包含3）

// 连接和转换
arr.concat([6, 7])                               // 连接数组
arr.join(',')                                    // 转为字符串 "1,2,3,4,5"

// 其他
Array.isArray(arr)                               // 是否是数组 true
Array.from(arrayLike)                            // 类数组转真数组
arr.flat()                                       // 扁平化数组
arr.flatMap(x => [x, x*2])                       // 映射后扁平化
```

### **3.4 字符串方法**
```javascript
const str = 'Hello World'

// 查找和检查
str.includes('World')                            // 是否包含 true
str.startsWith('Hello')                          // 是否以...开始 true
str.endsWith('World')                            // 是否以...结束 true
str.indexOf('World')                             // 查找位置 6
str.lastIndexOf('l')                             // 最后出现位置 9
str.charAt(1)                                    // 获取字符 'e'
str.charCodeAt(1)                                // 获取字符编码 101

// 截取和分割
str.slice(0, 5)                                  // 切片 'Hello'
str.substring(0, 5)                              // 子字符串 'Hello'
str.substr(0, 5)                                 // 子串 'Hello'（废弃中）
str.split(' ')                                   // 分割 ['Hello', 'World']

// 修改
str.toLowerCase()                                // 转小写 'hello world'
str.toUpperCase()                                // 转大写 'HELLO WORLD'
str.trim()                                       // 去除两端空格
str.trimStart()                                  // 去除开头空格
str.trimEnd()                                    // 去除结尾空格
str.replace('World', 'JavaScript')               // 替换 'Hello JavaScript'
str.replaceAll('l', 'L')                         // 全部替换 'HeLLo WorLd'

// 重复和填充
str.repeat(2)                                    // 重复 'Hello WorldHello World'
'5'.padStart(3, '0')                             // 前补零 '005'
'5'.padEnd(3, '0')                               // 后补零 '500'
```

### **3.5 对象方法**
```javascript
const obj = { name: '张三', age: 25 }

// 键值操作
Object.keys(obj)                                 // 键数组 ['name', 'age']
Object.values(obj)                               // 值数组 ['张三', 25]
Object.entries(obj)                              // 键值对数组 [['name','张三'],['age',25]]

// 合并和复制
Object.assign({}, obj, { city: '北京' })         // 合并对象
const copy = { ...obj }                          // 展开运算符复制
JSON.parse(JSON.stringify(obj))                  // 深拷贝（简单对象）

// 属性操作
Object.hasOwnProperty('name')                    // 检查自有属性 true
Object.defineProperty(obj, 'gender', { 
    value: '男', 
    writable: true,
    enumerable: true 
})                                              // 定义属性

// 冻结和密封
Object.freeze(obj)                               // 冻结（不能修改）
Object.seal(obj)                                 // 密封（不能增删，可修改）
Object.isFrozen(obj)                             // 是否冻结
Object.isSealed(obj)                             // 是否密封
```

### **3.6 函数方法**
```javascript
// 函数绑定
function greet(name) {
    console.log(`Hello, ${name}!`)
}
const boundGreet = greet.bind(null, '张三')      // 绑定this和参数
boundGreet()                                     // Hello, 张三!

// 函数调用
greet.call(null, '李四')                         // 立即调用，指定this
greet.apply(null, ['王五'])                      // 立即调用，参数为数组

// 箭头函数特性
const add = (a, b) => a + b                     // 简写，没有自己的this
const square = x => x * x                       // 单个参数可省略括号
const returnObj = () => ({ key: 'value' })      // 返回对象需要括号

// 高阶函数
function timer(fn) {
    return function(...args) {
        console.time('执行时间')
        const result = fn(...args)
        console.timeEnd('执行时间')
        return result
    }
}
const timedAdd = timer(add)
```

### **3.7 异步编程（最重要！）**
```javascript
// Promise基本使用
const promise = new Promise((resolve, reject) => {
    setTimeout(() => resolve('成功'), 1000)
})

promise
    .then(result => console.log(result))        // 成功回调
    .catch(error => console.error(error))       // 失败回调
    .finally(() => console.log('完成'))         // 最终执行

// Promise静态方法
Promise.all([promise1, promise2])              // 全部成功
    .then(results => console.log(results))
Promise.race([promise1, promise2])             // 竞速（第一个完成）
Promise.any([promise1, promise2])              // 任意一个成功
Promise.resolve('value')                        // 立即成功
Promise.reject('error')                         // 立即失败

// Async/Await（推荐！）
async function fetchData() {
    try {
        const response = await fetch('url')
        const data = await response.json()
        return data
    } catch (error) {
        console.error('错误:', error)
    }
}

// Fetch API（现代ajax）
fetch('https://api.example.com/data', {
    method: 'GET',                              // 或 'POST', 'PUT', 'DELETE'
    headers: {
        'Content-Type': 'application/json'
    },
    body: JSON.stringify({ key: 'value' })      // POST请求体
})
.then(response => response.json())
.then(data => console.log(data))
.catch(error => console.error(error))
```

### **3.8 实用工具方法**
```javascript
// 数据类型判断
typeof 42                                       // 'number'
typeof 'hello'                                  // 'string'
typeof true                                     // 'boolean'
typeof undefined                                // 'undefined'
typeof null                                     // 'object'（历史遗留）
typeof {}                                       // 'object'
typeof []                                       // 'object'
typeof function(){}                             // 'function'

Array.isArray([])                               // 判断数组 true
isNaN('123')                                    // 判断NaN false
Number.isNaN(NaN)                               // 更准确的判断 true
isFinite(123)                                   // 判断有限数 true

// 数字处理
Math.random()                                   // 0-1随机数
Math.floor(3.7)                                 // 向下取整 3
Math.ceil(3.2)                                  // 向上取整 4
Math.round(3.5)                                 // 四舍五入 4
Math.max(1, 2, 3)                               // 最大值 3
Math.min(1, 2, 3)                               // 最小值 1
Math.abs(-5)                                    // 绝对值 5
Math.sqrt(9)                                    // 平方根 3
Math.pow(2, 3)                                  // 幂运算 8
(5.123).toFixed(2)                              // 保留两位 '5.12'
parseInt('42px')                                // 解析整数 42
parseFloat('3.14px')                            // 解析浮点数 3.14

// 日期时间
const now = new Date()
now.getFullYear()                               // 年 2024
now.getMonth()                                  // 月 0-11
now.getDate()                                   // 日 1-31
now.getDay()                                    // 星期 0-6
now.getHours()                                  // 时 0-23
now.getMinutes()                                // 分 0-59
now.getSeconds()                                // 秒 0-59
now.getTime()                                   // 时间戳（毫秒）
Date.now()                                      // 当前时间戳

now.toLocaleDateString()                        // 本地日期格式
now.toLocaleTimeString()                        // 本地时间格式
now.toISOString()                               // ISO格式 '2024-01-15T10:30:00.000Z'

// 定时器
setTimeout(() => console.log('1秒后执行'), 1000) // 延迟执行
const timerId = setTimeout(...)
clearTimeout(timerId)                           // 清除

setInterval(() => console.log('每1秒执行'), 1000) // 间隔执行
const intervalId = setInterval(...)
clearInterval(intervalId)                       // 清除

// JSON处理
const jsonStr = JSON.stringify(obj)             // 对象转JSON字符串
const obj2 = JSON.parse(jsonStr)                // JSON字符串转对象

// 本地存储
localStorage.setItem('key', 'value')            // 存储（永久）
localStorage.getItem('key')                     // 读取
localStorage.removeItem('key')                  // 移除
localStorage.clear()                            // 清空
sessionStorage.setItem('key', 'value')          // 会话存储（标签页关闭失效）

// 浏览器API
window.location.href                            // 当前URL
window.location.reload()                        // 刷新页面
window.location.assign('new-url.html')          // 跳转
window.history.back()                           // 后退
window.history.forward()                        // 前进
window.scrollTo(0, 100)                         // 滚动到位置
window.innerWidth                               // 视口宽度
window.innerHeight                              // 视口高度

// 错误处理
try {
    // 可能出错的代码
    throw new Error('自定义错误')
} catch (error) {
    console.error('捕获错误:', error.message)
    console.error('堆栈:', error.stack)
} finally {
    console.log('总是执行')
}
```

### **3.9 ES6+ 新特性速查**
```javascript
// 解构赋值
const [a, b] = [1, 2]                           // 数组解构
const { name, age } = person                    // 对象解构
const { name: userName } = person               // 重命名

// 展开和剩余运算符
const arr1 = [1, 2], arr2 = [...arr1, 3, 4]     // 展开数组
const obj1 = { a: 1 }, obj2 = { ...obj1, b: 2 } // 展开对象
function sum(...numbers) {                       // 剩余参数
    return numbers.reduce((a, b) => a + b)
}

// 模板字符串
const name = '张三'
const greeting = `你好，${name}！`               // 插值表达式
const multiLine = `第一行
第二行`                                         // 多行字符串

// 可选链操作符（?.）
const city = user?.address?.city                 // 安全访问嵌套属性
const result = obj.method?.()                    // 安全调用方法

// 空值合并（??）
const value = input ?? '默认值'                  // 只有null/undefined时用默认值

// 逻辑赋值
let x = 1
x ||= 2                                         // x = x || 2
x &&= 3                                         // x = x && 3
x ??= 4                                         // x = x ?? 4

// 动态导入
const module = await import('./module.js')      // 动态导入模块

// BigInt（大整数）
const big = 9007199254740991n                   // BigInt字面量
const bigger = BigInt('9007199254740991')       // BigInt构造函数
```

### **3.10 性能优化技巧**
```javascript
// 防抖（停止操作后执行）
function debounce(fn, delay) {
    let timer
    return function(...args) {
        clearTimeout(timer)
        timer = setTimeout(() => fn.apply(this, args), delay)
    }
}

// 节流（固定时间执行一次）
function throttle(fn, delay) {
    let lastTime = 0
    return function(...args) {
        const now = Date.now()
        if (now - lastTime >= delay) {
            fn.apply(this, args)
            lastTime = now
        }
    }
}

// 使用示例
window.addEventListener('resize', debounce(() => {
    console.log('窗口大小改变')
}, 300))
```

---

## 🎯 四、前端开发黄金法则

### **HTML：**
1. **语义化优先**：用对标签，不用div打天下
2. **可访问性**：alt属性必填，使用aria标签
3. **SEO友好**：合理使用h1-h6，meta标签完整

### **CSS：**
1. **移动优先**：先写移动端样式
2. **BEM命名**：block__element--modifier
3. **动画性能**：使用transform和opacity做动画

### **JavaScript：**
1. **现代语法**：多用const，少用var
2. **异步优先**：Promise > 回调，Async/Await > Promise
3. **代码分割**：动态导入大模块

---

## 💾 保存建议：
1. **打印此表**放在桌面随时查阅
2. **创建代码片段**在编辑器中
3. **每周练习**一个不熟悉的API
4. **实际项目**中遇到问题先查此表

**记住：前端技术更新快，但这些基础API变化不大。掌握它们，你就掌握了80%的日常开发工作！**