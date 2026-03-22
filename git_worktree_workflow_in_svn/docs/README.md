# Git Worktree + SVN 工作流指南

## 目录结构

```
git_worktree_workflow_in_svn/
├── docs/
│   ├── README.md              ← 本文档
│   ├── ARCHITECTURE.md        ← 架构说明
│   └── QUICKSTART.md          ← 快速入门
│
└── scripts/
    ├── bat/                   ← 批处理脚本
    │   ├── setup.bat              初始化项目
    │   ├── add-worktree.bat       创建 Worktree
    │   ├── list-worktrees.bat     列出 Worktree
    │   ├── remove-worktree.bat    删除 Worktree
    │   ├── pull-svn.bat           ① SVN 更新
    │   ├── sync-all-worktrees.bat ② Git 同步
    │   ├── merge-worktree.bat     ③ 合并分支
    │   ├── push-svn.bat           ④ SVN 提交
    │   ├── workflow.bat           一键工作流
    │   ├── svn-sync.bat           SVN 同步（交互式）
    │   └── quick-start.bat        快速入门指南
    │
    └── powershell/            ← PowerShell 脚本（推荐）
        └── worktree.ps1           统一脚本
```

## 工作流程总览

```
┌─────────────────────────────────────────────────────────────┐
│                     SVN 云仓库                               │
│                 (公司代码服务器)                              │
└────────┬──────────────────────────────────▲─────────────────┘
         │                                  │
         │ ① SVN Update                     │ ④ SVN Commit
         │                                  │
         ▼                                  │
┌─────────────────────────────────────────────────────────────┐
│              主 Worktree (project-svn)                      │
│                                                            │
│   含 .svn 目录 - SVN 操作的唯一入口                         │
│                                                            │
│   git commit "sync" ◄──────────┐                           │
└────────┬───────────────────────┼───────────────────────────┘
         │                       │
         │ ② Git Pull/Merge      │ ③ Git Merge (feature → main)
         │                       │
         ▼                       │
┌─────────────────────────────────────────────────────────────┐
│                   Git 本地仓库                               │
│                   (project.git)                             │
└────────┬──────────────────────────────────▲─────────────────┘
         │                                  │
         │ 创建分支                         │ 提交开发
         │                                  │
         ▼                                  │
┌─────────────────────────────────────────────────────────────┐
│                  功能 Worktree                              │
│                                                            │
│   project-feature-a    project-feature-b                   │
│   (独立编译运行)        (独立编译运行)                       │
│                                                            │
└─────────────────────────────────────────────────────────────┘
```

## 四步工作流

### ① SVN 从云仓库更新到本地

```batch
:: 方式一：批处理
scripts\bat\pull-svn.bat

:: 方式二：PowerShell
scripts\powershell\worktree.ps1 pull

:: 方式三：手动
cd C:\work\project-svn
svn update
git add -A
git commit -m "sync: SVN update $(Get-Date -Format 'yyyyMMdd')"
```

### ② Git 更新本地到 Worktree/分支

```batch
:: 方式一：同步所有 Worktree
scripts\bat\sync-all-worktrees.bat

:: 方式二：手动同步单个 Worktree
cd C:\work\project-feature-a
git pull origin main

:: 方式三：PowerShell
scripts\powershell\worktree.ps1 sync-all
```

### ③ 开发后，Git Worktree 合并提交到本地

```batch
:: 在功能 Worktree 提交
cd C:\work\project-feature-a
git add .
git commit -m "完成功能 A 开发"

:: 方式一：批处理合并
scripts\bat\merge-worktree.bat feature-a

:: 方式二：PowerShell
scripts\powershell\worktree.ps1 merge feature-a

:: 方式三：手动合并
cd C:\work\project-svn
git merge feature-a
```

### ④ SVN 提交

```batch
:: 方式一：批处理（推荐）
scripts\bat\push-svn.bat

:: 方式二：PowerShell
scripts\powershell\worktree.ps1 push

:: 方式三：手动
cd C:\work\project-svn
svn commit -m "功能 A 完成"
git add -A
git commit -m "已提交 SVN: 功能 A"
```

---

## 一键工作流

```batch
:: 开始新的一天 (① + ②)
scripts\bat\workflow.bat start

:: 完成功能开发 (③ + ④)
scripts\bat\workflow.bat finish feature-a

:: 完整流程 (① + ② + ③ + ④)
scripts\bat\workflow.bat full feature-a
```

---

## 快速开始

### 第一次使用

```batch
:: 1. 初始化项目
scripts\bat\setup.bat myproject https://svn.company.com/repo/trunk

:: 2. 创建功能分支
scripts\bat\add-worktree.bat feature/login
```

### 日常工作

```batch
:: ① SVN 更新
scripts\bat\pull-svn.bat

:: ② Git 同步
scripts\bat\sync-all-worktrees.bat

:: ③ 开发功能
cd C:\work\myproject-feature-login
:: ... 开发、编译、测试 ...
git add .
git commit -m "完成登录功能"

:: 合并
scripts\bat\merge-worktree.bat feature/login

:: ④ SVN 提交
scripts\bat\push-svn.bat
```

### 清理已完成的分支

```batch
scripts\bat\remove-worktree.bat feature/login
```

---

## 完整工作流示例

### 场景 1：开始新的一天

```batch
:: ========================================
:: ① SVN 更新
:: ========================================
cd C:\work\project-svn
svn update
git add -A
git commit -m "晨间同步: $(Get-Date -Format 'yyyyMMdd-HHmm')"

:: ========================================
:: ② 同步到所有 Worktree
:: ========================================
scripts\bat\sync-all-worktrees.bat

:: ========================================
:: ③ 开始开发
:: ========================================
cd C:\work\project-feature-a
:: ... 开发 ...
git add .
git commit -m "完成今日开发"
```

### 场景 2：完成功能并提交 SVN

```batch
:: ========================================
:: ③ 合并到主 Worktree
:: ========================================
scripts\bat\merge-worktree.bat feature-a

:: ========================================
:: ④ 提交到 SVN
:: ========================================
scripts\bat\push-svn.bat
```

### 场景 3：紧急修复 Bug

```batch
:: ① 快速同步 SVN
scripts\bat\pull-svn.bat

:: ② 创建 hotfix Worktree
scripts\bat\add-worktree.bat hotfix/critical-bug

:: ③ 修复并提交
cd C:\work\project-hotfix-critical-bug
:: 修复代码...
git add .
git commit -m "修复严重 Bug"

:: 合并
scripts\bat\merge-worktree.bat hotfix/critical-bug

:: ④ 提交 SVN
scripts\bat\push-svn.bat

:: 清理
scripts\bat\remove-worktree.bat hotfix/critical-bug
```

---

## 目录结构（实际使用）

```
C:\work\
│
├── project-svn\                    ← ① SVN 更新入口
│   ├── .svn\                       ← SVN 元数据（唯一）
│   ├── .git                        → 指向 C:\repos\project.git
│   └── src\
│
├── project-feature-a\              ← ② ③ 开发 Worktree
│   ├── .git                        → 指向 C:\repos\project.git
│   └── src\
│       └── feature_a.cpp           ← 独立编译测试
│
├── project-feature-b\              ← ② ③ 开发 Worktree
│   ├── .git                        → 指向 C:\repos\project.git
│   └── src\
│       └── feature_b.cpp           ← 独立编译测试
│
└── project-hotfix-xxx\             ← 临时 hotfix
    └── ...

C:\repos\
└── project.git\                    ← Git 数据仓库
    ├── objects\
    ├── refs\
    └── worktrees\
```

---

## 常用命令速查

| 操作 | 批处理 | PowerShell |
|------|--------|------------|
| 初始化 | `scripts\bat\setup.bat <项目> <URL>` | `.\worktree.ps1 init <项目> <URL>` |
| 创建 Worktree | `scripts\bat\add-worktree.bat <分支>` | `.\worktree.ps1 add <分支>` |
| 列出 Worktree | `scripts\bat\list-worktrees.bat` | `.\worktree.ps1 list` |
| 删除 Worktree | `scripts\bat\remove-worktree.bat <分支>` | `.\worktree.ps1 remove <分支>` |
| ① SVN 更新 | `scripts\bat\pull-svn.bat` | `.\worktree.ps1 pull` |
| ② Git 同步 | `scripts\bat\sync-all-worktrees.bat` | `.\worktree.ps1 sync-all` |
| ③ 合并分支 | `scripts\bat\merge-worktree.bat <分支>` | `.\worktree.ps1 merge <分支>` |
| ④ SVN 提交 | `scripts\bat\push-svn.bat` | `.\worktree.ps1 push` |

---

## 注意事项

### ⚠️ SVN 操作

- **只在 `project-svn` 目录操作 SVN**
- 其他 Worktree 没有 `.svn`，不能执行 SVN 命令

### ⚠️ Git 分支

- 每个功能建议一个独立分支
- 完成后合并到主分支，再提交 SVN

### ⚠️ 冲突处理

```batch
:: Git 冲突
git status
:: 编辑冲突文件
git add <file>
git commit

:: SVN 冲突
svn status
:: 编辑冲突文件
svn resolved <file>
svn commit -m "解决冲突"
```

---

## PowerShell 统一脚本（推荐）

```powershell
# 初始化
.\scripts\powershell\worktree.ps1 init myproject https://svn.company.com/repo

# 创建分支
.\scripts\powershell\worktree.ps1 add feature/login

# ① SVN 更新
.\scripts\powershell\worktree.ps1 pull

# ② Git 同步
.\scripts\powershell\worktree.ps1 sync-all

# ③ 开发并合并
cd C:\work\myproject-feature-login
git add .
git commit -m "完成开发"
.\scripts\powershell\worktree.ps1 merge feature/login

# ④ SVN 提交
.\scripts\powershell\worktree.ps1 push

# 清理
.\scripts\powershell\worktree.ps1 remove feature/login
```

---

## 最佳实践

### 分支命名规范

```batch
feature/login          :: 新功能
hotfix/critical-bug    :: 紧急修复
refactor/module-a      :: 重构
experiment/test-idea   :: 实验
```

### 提交信息规范

```batch
:: Git 提交
git commit -m "feat: 实现登录功能"
git commit -m "fix: 修复内存泄漏"
git commit -m "refactor: 重构渲染模块"

:: SVN 提交
svn commit -m "功能: 完成登录模块 #TICKET-123"
svn commit -m "修复: 解决编译警告 #TICKET-124"
```

### 定期清理

```batch
:: 每周清理已完成的分支
git branch --merged main
git branch -d <已合并的分支>
git worktree prune
```
