

## 本地与远程 历史差别过大，无法拉取如何解决

### 一句话解决方案
直接执行这条命令即可完成拉取和合并：
```bash
git pull https://github.com/YALI58/My-Note-CheatSheet.git main --allow-unrelated-histories
```

### 执行后可能出现的情况
1. **成功**：自动完成合并，直接推送即可
2. **冲突**：需要手动解决冲突（编辑文件 → `git add .` → `git commit -m "解决冲突"`）

### 最后推送代码
```bash
git push https://github.com/YALI58/My-Note-CheatSheet.git main
```

就这么简单，直接执行上面的命令就可以了！




## 快速选择使用本地或远程 版本的命令

在解决冲突时，如果你想**快速决定使用哪一个版本**，可以使用以下命令：

### 🔧 针对单个文件

```bash
# 使用本地版本（保留你的修改，丢弃远程的）
git checkout --ours <文件名>

# 使用远程版本（保留远程的，丢弃你的修改）
git checkout --theirs <文件名>
```

**示例：**
```bash
# 如果你想要保留自己的 Project_JUC.md
git checkout --ours deepjava/Project_JUC.md

# 如果你想要使用远程的 workspace.json
git checkout --theirs deepjava/.obsidian/workspace.json
```

### 📦 针对所有冲突文件

```bash
# 所有冲突文件都使用本地版本
git checkout --ours .

# 所有冲突文件都使用远程版本
git checkout --theirs .
```

### ✅ 使用后的操作

执行完上述命令后，还需要：

```bash
# 1. 标记冲突已解决
git add .

# 2. 提交合并
git commit -m "解决冲突，使用xx版本"

# 3. 推送
git push
```

### 💡 使用场景建议

| 场景 | 推荐命令 | 原因 |
|------|----------|------|
| 你确定自己的修改是正确的 | `--ours` | 保留你的工作 |
| 远程版本更新、更完整 | `--theirs` | 采用远程的最新版本 |
| 配置文件（如 `.obsidian`） | `--theirs` | 通常是另一台设备的配置 |
| 代码文件（如 `.java`、`.md`） | 手动合并 | 可能双方都有重要修改 |

### ⚠️ 注意
- 这些命令**只有在冲突状态（unmerged paths）下才有效**
- 执行后要记得 `git add` 标记解决
- 如果选错了版本，可以用 `git merge --abort` 放弃合并重新来

你现在要处理的是哪两个冲突文件？我可以帮你决定用哪个命令。