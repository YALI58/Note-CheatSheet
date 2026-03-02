# CSS Grid 二维布局利器完全指南

## 🎯 一、Grid 核心概念（一句话说清）

> **Grid = 画格子 + 放东西**
> - 父容器设置 `display: grid`，成为**网格容器**
> - 子元素自动成为**网格项目**，可以放在任意格子中

---

## 📐 二、Grid vs Flexbox 快速对比

| 特性 | Flexbox | CSS Grid |
|------|---------|----------|
| **维度** | 一维（行或列） | 二维（行和列） |
| **控制对象** | 主要控制项目 | 控制容器和项目 |
| **最适合** | 线性布局、组件内部 | 页面整体布局、复杂网格 |
| **记忆口诀** | "排列队伍" | "画表格放东西" |

**简单选择：**
- **Flexbox**：导航、列表、卡片流、居中
- **Grid**：整体页面、复杂网格、报刊布局、仪表盘

---

## 🏗️ 三、网格容器属性速查表

### **1. 定义网格：画几行几列？**
```css
.container {
  display: grid;
  
  /* 定义列（垂直方向） */
  grid-template-columns: 100px 200px 300px;    /* 3列，固定宽度 */
  grid-template-columns: 1fr 2fr 1fr;          /* 3列，比例分配 */
  grid-template-columns: repeat(3, 1fr);       /* 3等宽列 */
  grid-template-columns: repeat(auto-fit, 200px); /* 自动适应，每列200px */
  grid-template-columns: 200px minmax(300px, 1fr); /* 最小300px，最大1fr */
  
  /* 定义行（水平方向） */
  grid-template-rows: 100px auto 200px;        /* 3行，第2行自动高度 */
  grid-template-rows: repeat(2, 150px);        /* 2行，每行150px */
  
  /* 简写：rows / columns */
  grid-template: 
    "header header" 80px
    "sidebar main" 1fr
    "footer footer" 60px / 250px 1fr;          /* 区域模板 */
}
```

### **2. 行列间距：格子间距多大？**
```css
.container {
  /* 行列间距 */
  gap: 20px;              /* 行列都20px */
  gap: 10px 30px;         /* 行间距10px，列间距30px */
  
  /* 旧版写法（兼容性） */
  grid-gap: 20px;
  grid-row-gap: 10px;
  grid-column-gap: 30px;
}
```

### **3. 项目对齐：格子内怎么对齐？**
```css
.container {
  /* 网格内所有项目的对齐 */
  justify-items: stretch;     /* 默认：拉伸填满单元格 */
  justify-items: start;       /* 水平靠左 */
  justify-items: center;      /* 水平居中 */
  justify-items: end;         /* 水平靠右 */
  
  align-items: stretch;       /* 默认：拉伸填满 */
  align-items: start;         /* 垂直顶部 */
  align-items: center;        /* 垂直居中 */
  align-items: end;           /* 垂直底部 */
  
  /* 简写 */
  place-items: center;        /* align-items + justify-items */
}
```

### **4. 内容对齐：整个网格在容器内怎么对齐？**
```css
.container {
  /* 网格整体在容器内的对齐 */
  justify-content: start;     /* 左对齐 */
  justify-content: center;    /* 水平居中 */
  justify-content: end;       /* 右对齐 */
  justify-content: space-between; /* 两端对齐 */
  justify-content: space-around;  /* 周围留白 */
  
  align-content: start;       /* 顶部对齐 */
  align-content: center;      /* 垂直居中 */
  align-content: end;         /* 底部对齐 */
  
  /* 简写 */
  place-content: center;      /* align-content + justify-content */
}
```

### **5. 自动布局：格子不够时自动创建？**
```css
.container {
  /* 自动创建行 */
  grid-auto-rows: 100px;      /* 自动创建的行高100px */
  grid-auto-rows: minmax(100px, auto);
  
  /* 自动创建列 */
  grid-auto-columns: 1fr;
  
  /* 自动放置方向 */
  grid-auto-flow: row;        /* 默认：按行填充 */
  grid-auto-flow: column;     /* 按列填充 */
  grid-auto-flow: row dense;  /* 密集填充（填补空隙） */
}
```

---

## 📍 四、网格项目属性速查表

### **1. 位置：放在哪个格子？**
```css
.item {
  /* 从第几列开始/结束 */
  grid-column-start: 1;        /* 从第1列开始 */
  grid-column-end: 3;          /* 到第3列结束（不包含） */
  grid-column: 1 / 3;          /* 简写：从1到3 */
  grid-column: span 2;         /* 跨越2列 */
  grid-column: 2;              /* 只占第2列 */
  
  /* 从第几行开始/结束 */
  grid-row-start: 1;
  grid-row-end: 3;
  grid-row: 1 / 3;
  grid-row: span 2;
  grid-row: 2;
  
  /* 简写：row-start / column-start / row-end / column-end */
  grid-area: 1 / 1 / 3 / 3;    /* row-start / col-start / row-end / col-end */
}
```

### **2. 命名区域：给格子起名字**
```css
.container {
  grid-template-areas:
    "header header"
    "sidebar main"
    "footer footer";
}

.header { grid-area: header; }
.sidebar { grid-area: sidebar; }
.main { grid-area: main; }
.footer { grid-area: footer; }
```

### **3. 单个项目对齐**
```css
.item {
  /* 单个项目在单元格内的对齐 */
  justify-self: stretch;      /* 继承容器的justify-items */
  justify-self: start;        /* 单元格内水平靠左 */
  justify-self: center;       /* 单元格内水平居中 */
  justify-self: end;          /* 单元格内水平靠右 */
  
  align-self: stretch;        /* 继承容器的align-items */
  align-self: start;          /* 单元格内垂直顶部 */
  align-self: center;         /* 单元格内垂直居中 */
  align-self: end;            /* 单元格内垂直底部 */
  
  /* 简写 */
  place-self: center;         /* align-self + justify-self */
}
```

---

## 🎨 五、Grid 专属单位与函数

### **`fr` 单位：比例分配**
```css
.container {
  grid-template-columns: 1fr 2fr 1fr; 
  /* 总宽度分成4份：第1列占1/4，第2列占2/4，第3列占1/4 */
}
```

### **`repeat()` 函数：重复模式**
```css
.container {
  grid-template-columns: repeat(4, 1fr);          /* 4等宽列 */
  grid-template-columns: repeat(3, 100px 200px);  /* 100px 200px 重复3次 */
  grid-template-columns: repeat(auto-fill, 150px);/* 自动填满150px宽的列 */
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); /* 响应式 */
}
```

### **`minmax()` 函数：范围限制**
```css
.container {
  grid-template-columns: 200px minmax(300px, 1fr);
  /* 第1列固定200px，第2列最小300px，最大占满剩余空间 */
}
```

### **`fit-content()` 函数：适应内容**
```css
.container {
  grid-template-columns: fit-content(200px) 1fr;
  /* 第1列根据内容宽度，但不超过200px */
}
```

---

## 🔧 六、12个实用网格布局模式（复制即用）

### **模式1：经典12列网格系统**
```css
.grid-12 {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: 20px;
}

.col-1 { grid-column: span 1; }
.col-2 { grid-column: span 2; }
.col-3 { grid-column: span 3; }
.col-4 { grid-column: span 4; }
.col-6 { grid-column: span 6; }
.col-12 { grid-column: span 12; }
```

### **模式2：圣杯布局（命名区域版）**
```css
.holy-grail {
  display: grid;
  grid-template-areas:
    "header header header"
    "nav main aside"
    "footer footer footer";
  grid-template-columns: 200px 1fr 200px;
  grid-template-rows: 80px 1fr 60px;
  min-height: 100vh;
  gap: 10px;
}

header { grid-area: header; }
nav { grid-area: nav; }
main { grid-area: main; }
aside { grid-area: aside; }
footer { grid-area: footer; }
```

### **模式3：响应式卡片网格**
```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 20px;
  padding: 20px;
}

/* 280px最小，自动适应列数 */
```

### **模式4：报刊杂志布局**
```css
.magazine {
  display: grid;
  grid-template-columns: 2fr 1fr 1fr;
  grid-template-rows: 300px 200px 150px;
  gap: 15px;
}

.featured {
  grid-column: 1 / 2;
  grid-row: 1 / 3;
}

.side-article {
  grid-column: 2 / 4;
  grid-row: 1 / 2;
}
```

### **模式5：仪表盘布局**
```css
.dashboard {
  display: grid;
  grid-template-columns: 250px 1fr 1fr;
  grid-template-rows: 80px 300px 200px 150px;
  gap: 15px;
  height: 100vh;
}

.sidebar {
  grid-column: 1;
  grid-row: 1 / -1;  /* 从第1行到最后一行 */
}

.header {
  grid-column: 2 / -1;
  grid-row: 1;
}

.chart-large {
  grid-column: 2 / 4;
  grid-row: 2;
}

.chart-small {
  grid-column: span 1;
  grid-row: 3;
}
```

### **模式6：图片画廊（等高网格）**
```css
.gallery {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  grid-auto-rows: 200px;
  gap: 10px;
}

.gallery-item {
  width: 100%;
  height: 100%;
  object-fit: cover;  /* 保持比例填充 */
}
```

### **模式7：表单布局（标签+输入框）**
```css
.form-grid {
  display: grid;
  grid-template-columns: 120px 1fr;
  gap: 15px;
  align-items: center;
}

label {
  text-align: right;
}

input, select {
  width: 100%;
}
```

### **模式8：三栏等高布局**
```css
.three-columns {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 30px;
  align-items: stretch;  /* 等高 */
}

.column {
  /* 自动等高 */
}
```

### **模式9：不对称布局**
```css
.asymmetric {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr 1fr;
  gap: 20px;
}

.wide {
  grid-column: span 2;
}

.tall {
  grid-row: span 2;
}
```

### **模式10：页脚始终在底部**
```css
.page {
  display: grid;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}

.header { grid-row: 1; }
.content { grid-row: 2; }
.footer { grid-row: 3; }
```

### **模式11：瀑布流布局**
```css
.masonry {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  grid-auto-rows: 20px;  /* 基础行高 */
  gap: 10px;
}

.masonry-item {
  grid-row-end: span var(--row-span);  /* 通过CSS变量控制高度 */
}

/* HTML中设置：
<div class="masonry-item" style="--row-span: 8"></div>
*/
```

### **模式12：居中卡片（自适应）**
```css
.center-card {
  display: grid;
  place-items: center;      /* 水平和垂直都居中 */
  min-height: 100vh;
}

.card {
  width: min(90%, 500px);   /* 最大500px，最小90%宽度 */
  padding: 2rem;
}
```

---

## 🎮 七、Grid 游戏化学习

### **推荐练习游戏：**
- **[CSS Grid Garden](https://cssgridgarden.com/)**：28个关卡，种胡萝卜
- **[Grid Critters](https://gridcritters.com/)**：付费但极好的互动教程

### **记住这5个核心属性就够用：**
1. **`display: grid`** - 开启Grid
2. **`grid-template-columns`** - 定义列
3. **`grid-template-rows`** - 定义行
4. **`gap`** - 格子间距
5. **`grid-column` / `grid-row`** - 项目位置

---

## 📱 八、Grid 响应式设计模式

### **移动端优先的响应式网格**
```css
.container {
  display: grid;
  gap: 20px;
  
  /* 移动端：1列 */
  grid-template-columns: 1fr;
  
  /* 平板：2列 */
  @media (min-width: 768px) {
    grid-template-columns: repeat(2, 1fr);
  }
  
  /* 桌面：4列 */
  @media (min-width: 1024px) {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

### **使用 auto-fit/fill 自动响应**
```css
/* 自动适应，最小200px，最多1fr */
.container {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}
```

### **响应式区域布局**
```css
.layout {
  display: grid;
  grid-template-areas:
    "header"
    "main"
    "sidebar"
    "footer";
  
  @media (min-width: 768px) {
    grid-template-areas:
      "header header"
      "sidebar main"
      "footer footer";
    grid-template-columns: 250px 1fr;
  }
}
```

---

## 🚨 九、常见错误与解决

### **错误1：fr单位计算混乱**
```css
/* ❌ 错误：混合固定值和fr可能导致意外 */
.container {
  grid-template-columns: 200px 1fr 1fr;
  /* 200px先被减去，剩余空间被1fr 1fr平分 */
}

/* ✅ 明确计算：使用calc或minmax */
.container {
  grid-template-columns: 200px minmax(0, 1fr) minmax(0, 1fr);
}
```

### **错误2：隐式网格大小失控**
```css
/* ❌ 错误：自动创建的行/列可能太大 */
.container {
  grid-auto-rows: auto;  /* 可能非常高 */
}

/* ✅ 控制隐式网格大小 */
.container {
  grid-auto-rows: 100px;
  /* 或 */
  grid-auto-rows: minmax(100px, auto);
}
```

### **错误3：项目超出网格**
```css
/* ❌ 错误：项目指定不存在的行列 */
.item {
  grid-column: 1 / 10;  /* 如果只有5列 */
}

/* ✅ 使用span或动态值 */
.item {
  grid-column: 1 / -1;  /* 从第1列到最后一列 */
  /* 或 */
  grid-column: span 2;  /* 跨越2列 */
}
```

### **错误4：gap导致溢出**
```css
/* ❌ 错误：gap会增加总尺寸 */
.container {
  width: 100%;
  grid-template-columns: repeat(3, 33.33%);
  gap: 20px;  /* 总宽度超过100%！ */
}

/* ✅ 使用fr单位或calc */
.container {
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}
```

---

## 🔍 十、Grid 调试技巧

### **浏览器DevTools可视化：**
1. 选中grid容器
2. 点击元素旁边的 `grid` 图标
3. 显示网格线编号和区域
4. 可以临时修改所有grid属性

### **显示网格线：**
```css
.container {
  /* 添加辅助线查看网格结构 */
  background-image: 
    linear-gradient(to right, rgba(255,0,0,0.1) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(255,0,0,0.1) 1px, transparent 1px);
  background-size: calc(100% / 12) calc(100% / 8); /* 12列8行 */
}
```

### **使用Firefox Grid Inspector：**
Firefox的开发者工具有最好的Grid调试器，可以显示所有网格线和区域名称。

---

## 💡 十一、Grid 最佳实践

### **1. 命名网格线（提高可读性）**
```css
.container {
  grid-template-columns: 
    [sidebar-start] 250px 
    [sidebar-end content-start] 1fr 
    [content-end];
  grid-template-rows: 
    [header-start] 80px 
    [header-end main-start] 1fr 
    [main-end footer-start] 60px 
    [footer-end];
}

.sidebar {
  grid-column: sidebar-start / sidebar-end;
}
```

### **2. 使用子网格（CSS Grid Level 2）**
```css
/* 子网格继承父网格线 */
.container {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
}

.nested {
  display: grid;
  grid-template-columns: subgrid;  /* 继承12列 */
  grid-column: 1 / -1;
}
```

### **3. 结合Flexbox使用**
```css
/* Grid管理整体，Flexbox管理内部 */
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 20px;
}

.card {
  display: flex;
  flex-direction: column;
}

.card-content {
  flex: 1;  /* 推按钮到底部 */
}
```

---

## 🎯 十二、Grid 速记口诀

### **【三句真言】**
1. **父grid，子自动** - 父设为grid，子就成网格项
2. **先画格，后放物** - 先定义行列，再放项目
3. **行数字，列字母** - 记：行(row)是数字，列(column)是字母开头

### **【五个最常用】**
```css
/* 最常用的5个模式 */
.grid-basic {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 20px;
}

.grid-center {
  display: grid;
  place-items: center;
}

.grid-areas {
  display: grid;
  grid-template-areas: "header header" "sidebar main";
}

.grid-span {
  grid-column: span 2;
  grid-row: span 2;
}

.grid-place {
  grid-column: 1 / -1;  /* 占满整行 */
}
```

### **【选择记忆】**
```css
/* 记不住全部？记这些就够了： */

/* 1. 定义网格 */
display: grid;
grid-template-columns: repeat(3, 1fr);  /* 3等宽列 */
gap: 20px;                              /* 间距 */

/* 2. 放置项目 */
.item {
  grid-column: 2 / 4;    /* 从第2列到第4列 */
  grid-row: 1;           /* 在第1行 */
}

/* 3. 对齐项目 */
place-items: center;     /* 单元格内居中 */
place-content: center;   /* 整个网格居中 */
```

---

## 📚 十三、下一步学习建议

1. **先掌握12个模式** - 覆盖95%日常需求
2. **玩CSS Grid Garden** - 巩固基础
3. **实际项目应用** - 用Grid重构一个现有页面
4. **学习高级特性** - 子网格、网格线命名
5. **了解浏览器支持** - Grid现在有98%+支持率

## 🏆 十四、Grid 布局哲学

**Grid的核心思想：**
1. **声明式布局**：告诉浏览器"我想要这样的布局"，而不是"如何实现这个布局"
2. **二维思维**：同时考虑行和列，而不是分别处理
3. **内容与布局分离**：HTML管内容，CSS管布局

**记住：Grid是现代CSS布局的终极武器。一旦掌握，你会感叹："以前那些hack都是什么鬼！"**

---

**保存这份指南，当你需要Grid布局时，回来查阅对应的模式。实践是最好的学习方法，动手写起来吧！**