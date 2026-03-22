# 架构说明

## 架构图

```
┌─────────────────────────────────────────────────────────────┐
│                    SVN 远程仓库                              │
│              (公司服务器，你只能检出)                         │
└────────┬──────────────────────────────────▲─────────────────┘
         │                                  │
         │ svn checkout/update              │ svn commit
         │                                  │
         ▼                                  │
┌─────────────────────────────────────────────────────────────┐
│              主 Worktree (project-svn)                      │
│                                                            │
│   ┌──────────┐  ┌──────────┐                              │
│   │  .svn/   │  │  .git    │                              │
│   │ SVN 元数据│  │ Git 引用 │                              │
│   └──────────┘  └──────────┘                              │
│                                                            │
│   SVN 和 Git 在这里共存！                                   │
└─────────────────────────────────────────────────────────────┘
         │                                  ▲
         │ git worktree add                 │ git commit
         │                                  │
         ▼                                  │
┌─────────────────────────────────────────────────────────────┐
│                Git 本地裸仓库 (project.git)                  │
│                                                            │
│   纯本地仓库，没有远程！                                     │
│   只存储 Git 对象数据，不包含工作文件                         │
└─────────────────────────────────────────────────────────────┘
```

## 关键理解

### 1. Git 本地仓库是如何创建的？

```batch
:: 创建裸仓库（只有数据，没有工作文件）
mkdir C:\repos\project.git
git init --bare

:: 这创建了一个纯本地的 Git 仓库
:: 没有任何远程配置，只是存储版本数据
```

### 2. SVN 和 Git 如何共存？

```batch
:: 创建主 Worktree
git worktree add C:\work\project-svn

:: 在这个目录中，同时存在：
:: - .svn/ 目录 → SVN 可以操作
:: - .git 文件  → 指向 Git 仓库

:: SVN 操作
svn update        ✓ 有效
svn commit        ✓ 有效

:: Git 操作
git add .         ✓ 有效
git commit        ✓ 有效
```

### 3. 提交流程详解

```
┌─────────────────────────────────────────────────────────────┐
│  步骤 ①: SVN 更新到本地                                      │
└─────────────────────────────────────────────────────────────┘

主 Worktree (project-svn):
  svn update          → 从 SVN 服务器拉取最新代码
  git add -A          → 将变更添加到 Git
  git commit          → 记录到 Git 本地仓库

结果：SVN 和 Git 都有了最新代码的记录

┌─────────────────────────────────────────────────────────────┐
│  步骤 ②: Git 同步到 Worktree                                 │
└─────────────────────────────────────────────────────────────┘

Git 本地仓库 → 功能 Worktree:
  git pull origin main
  或
  git merge main

结果：功能 Worktree 获得了 SVN 的最新代码

┌─────────────────────────────────────────────────────────────┐
│  步骤 ③: 在 Worktree 开发并合并                              │
└─────────────────────────────────────────────────────────────┘

功能 Worktree:
  git add .
  git commit          → 提交到 Git 本地仓库

主 Worktree:
  git merge feature   → 从 Git 本地仓库合并代码

结果：主 Worktree 的工作目录有了新代码

┌─────────────────────────────────────────────────────────────┐
│  步骤 ④: SVN 提交                                            │
└─────────────────────────────────────────────────────────────┘

主 Worktree:
  svn commit          → 提交到 SVN 服务器

结果：SVN 服务器收到新代码
```

## 核心原理

### Git 本地仓库

```batch
:: 查看配置
cd C:\repos\project.git
git remote -v

:: 输出：（空）
:: 这是一个纯本地仓库，没有远程
```

### Git Worktree 机制

```batch
:: 主 Worktree 的 .git 文件内容
cat C:\work\project-svn\.git

:: 输出：
gitdir: C:\repos\project.git\worktrees\project-svn

:: 这表示：
:: - 工作文件在 C:\work\project-svn
:: - Git 数据在 C:\repos\project.git
:: - 它们通过 .git 文件关联
```

### SVN 和 Git 共存

```batch
cd C:\work\project-svn

:: SVN 可以操作（因为有 .svn 目录）
svn status
svn update
svn commit

:: Git 也可以操作（因为有 .git 引用）
git status
git add .
git commit

:: 它们互不干扰！
```

## 完整示例

```batch
:: ========================================
:: 初始化（一次性）
:: ========================================

:: 1. 创建 Git 本地仓库
mkdir C:\repos\myproject.git
cd C:\repos\myproject.git
git init --bare

:: 2. 创建主 Worktree
git worktree add C:\work\myproject-svn

:: 3. 在主 Worktree 检出 SVN
cd C:\work\myproject-svn
svn checkout https://svn.company.com/repo/trunk .

:: 4. 创建初始 Git 提交
git add .
git commit -m "Init from SVN"

:: 5. 创建功能 Worktree
cd C:\repos\myproject.git
git worktree add C:\work\myproject-feature-a -b feature-a

:: ========================================
:: 日常工作
:: ========================================

:: ① SVN 更新
cd C:\work\myproject-svn
svn update                    :: 从 SVN 服务器拉取
git add -A && git commit      :: 记录到 Git 本地

:: ② Git 同步到功能分支
cd C:\work\myproject-feature-a
git merge main                :: 从 Git 本地仓库同步

:: ③ 开发并合并
:: ... 开发代码 ...
git add . && git commit       :: 提交到 Git 本地

cd C:\work\myproject-svn
git merge feature-a           :: 合并到主 Worktree

:: ④ SVN 提交
svn commit -m "完成功能"       :: 提交到 SVN 服务器
```

## 关键要点

| 概念 | 说明 |
|------|------|
| **Git 本地仓库** | 纯本地存储，没有远程，用于版本管理和 Worktree 共享 |
| **SVN 远程仓库** | 公司代码服务器，只能通过 `svn` 命令操作 |
| **主 Worktree** | 唯一包含 `.svn` 的目录，SVN 操作入口 |
| **功能 Worktree** | 只有 Git，没有 SVN，用于独立开发 |
| **Git 提交** | 只记录到本地 Git 仓库，不影响 SVN |
| **SVN 提交** | 从主 Worktree 提交到 SVN 服务器 |

## 为什么这样设计？

1. **Git 没有远程**：你不需要创建远程 Git 仓库，只是用它来管理本地版本
2. **SVN 保持原有流程**：SVN 的检出、更新、提交流程完全不变
3. **Worktree 提供并行能力**：多个目录可以同时开发不同功能
4. **版本追踪**：Git 记录每次 SVN 同步，方便回滚和对比

## 数据流向

```
SVN 远程仓库
    ↓ svn update
主 Worktree (.svn + .git)
    ↓ git commit
Git 本地仓库
    ↓ git worktree add
┌───┴───┬───────┬───────┐
│       │       │       │
↓       ↓       ↓       ↓
WT-1   WT-2   WT-3   WT-4
功能A   功能B   测试    实验
    ↓ git merge
主 Worktree
    ↓ svn commit
SVN 远程仓库
```

## 简单说

**Git 只是本地工具，SVN 还是你的远程仓库。**

Git Worktree 让你可以在多个目录同时开发，SVN 仍然是唯一的远程代码仓库。
