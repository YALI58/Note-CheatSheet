## 🚀 Git超简实战速查表（最终版）

---

## 🎯 黄金法则：永远从 `git clone` 开始

```bash
# ✅ 正确姿势（避开99%的坑）
git clone <仓库地址>
cd 项目文件夹
# 开始干活！
```

---

## 📋 每日工作流（80%时间用这些）

### 1️⃣ 开始新功能
```bash
git checkout main      # 先回主分支
git pull               # 拉取最新代码
git checkout -b feature/xxx  # 创建新分支
```

### 2️⃣ 写代码时随时看
```bash
git status        # 看改了哪些文件
git diff          # 看具体改了啥内容
```

### 3️⃣ 提交代码（一天N次）
```bash
git add .              # 添加所有修改
git commit -m "做了什么"  # 提交到本地
git push               # 推送到远程
```

### 4️⃣ 提交前确保最新
```bash
git pull   # 先拉取（有冲突就解决）
git push   # 再推送
```

### 5️⃣ 切换任务
```bash
git checkout main        # 回主分支
git checkout feature/xxx # 回功能分支
git branch              # 看当前在哪个分支
```

---

## 🔧 分支操作大全

```bash
# 查看分支
git branch              # 看本地分支
git branch -r           # 看远程分支
git branch -a           # 看所有分支

# 创建/切换分支
git checkout -b 新分支    # 创建并切换（最常用）
git checkout 分支名       # 切换已有分支
git switch 分支名         # 新版Git切换

# 重命名分支
git branch -m 新名字      # 重命名当前分支
git branch -M 新名字      # 强制重命名（如：master → main）

# 删除分支
git branch -d 分支名      # 删除本地分支（已合并）
git branch -D 分支名      # 强制删除本地分支
git push origin --delete 分支名  # 删除远程分支
```

---

## 🤝 同步与拉取

```bash
# 拉取代码
git pull                    # 拉取并合并（最常用）
git fetch                   # 只拉取不合并
git fetch --prune           # 拉取并清理已删除的远程分支

# 推送代码
git push                    # 推送到当前分支
git push origin 分支名       # 推送到指定分支
git push -u origin 分支名    # 第一次推送，建立关联
```

---

## ⚠️ 特殊场景：历史独立问题

### 为什么会发生？
```bash
# 错误操作（导致历史独立）
mkdir my-project
cd my-project
git init
# 然后想关联一个已有提交的远程仓库...
```

### 解决方案
```bash
# 方案1：推荐（重新clone）
git clone <仓库地址> 新文件夹
# 把自己的代码复制进去

# 方案2：合并独立历史
git remote add origin <地址>
git pull origin main --allow-unrelated-histories
# 解决冲突后
git add .
git commit -m "合并独立历史"
git push
```

---

## 🆘 冲突解决（最简单版）

```bash
# 拉代码时看到 CONFLICT
git pull

# 1. 打开冲突文件，看到：
<<<<<<< HEAD
你的代码
=======
别人的代码
>>>>>>> 远程提交

# 2. 删掉 <<< === >>>，保留想要的内容

# 3. 保存文件后：
git add .
git commit -m "解决冲突"
git push
```

---

## 📦 临时保存（stash）

```bash
# 场景：写一半要切分支修bug
git stash           # 暂存当前修改
git checkout -b hotfix  # 切去修bug

# 修完bug回来
git checkout 原分支
git stash pop       # 恢复修改

# 其他stash命令
git stash list      # 查看暂存列表
git stash clear     # 清空所有暂存
```

---

## 👀 查看历史

```bash
git log --oneline -5     # 最近5次提交（简洁）
git log --oneline --graph --all  # 看分支图
git show 提交ID           # 查看某次提交详情
```

---

## 🔄 撤销操作

```bash
# 还没git add
git restore 文件名        # 撤销工作区修改

# 已经git add，还没commit
git restore --staged 文件名  # 撤销暂存

# 已经commit，还没push
git commit --amend        # 修改最后一次提交
git reset --soft HEAD~1   # 撤销commit，保留修改

# 已经push（危险！）
git reset --hard HEAD~1   # 本地回退
git push --force          # 强制覆盖远程（小心！）
```

---

## 📊 最常用命令速查表

| 场景 | 命令 |
|------|------|
| **首次使用** | `git clone <地址>` |
| **拉取更新** | `git pull` |
| **查看状态** | `git status` |
| **添加文件** | `git add .` |
| **提交** | `git commit -m "信息"` |
| **推送** | `git push` |
| **新建分支** | `git checkout -b 分支名` |
| **切换分支** | `git checkout 分支名` |
| **重命名分支** | `git branch -M 新名字` |
| **暂存修改** | `git stash` → `git stash pop` |
| **看历史** | `git log --oneline` |

---

## 🎯 记住这个循环就够了

```bash
git pull           # 1. 拉取最新
git checkout -b 新功能  # 2. 建新分支
# 写代码...
git add .          # 3. 添加
git commit -m "信息" # 4. 提交
git push           # 5. 推送
```

---

## 💡 一句话总结

> **每天工作流：`pull → checkout -b → add → commit → push`，永远从 `git clone` 开始，就能避开99%的坑！**