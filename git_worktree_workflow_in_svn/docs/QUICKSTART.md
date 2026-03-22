# 快速入门 - 四步工作流

## 工作流程

```
① SVN 更新  →  ② Git 同步  →  ③ 开发合并  →  ④ SVN 提交
```

## 快速命令

### ① SVN 从云仓库更新到本地

```batch
scripts\bat\pull-svn.bat
```

这会自动：
- `svn update` - 拉取远程更新
- `git commit` - 记录到 Git

---

### ② Git 更新本地到 Worktree

```batch
:: 同步所有 Worktree
scripts\bat\sync-all-worktrees.bat

:: 或手动同步单个 Worktree
cd C:\work\project-feature-a
git pull origin main
```

---

### ③ 开发后，Git Worktree 合并提交到本地

```batch
:: 在功能 Worktree 开发
cd C:\work\project-feature-a
:: ... 编码 ...
git add .
git commit -m "完成功能"

:: 合并到主 Worktree
scripts\bat\merge-worktree.bat feature-a
```

---

### ④ SVN 提交

```batch
scripts\bat\push-svn.bat
```

这会自动：
- 显示 SVN 状态
- 提示输入提交信息
- `svn commit` - 提交到 SVN
- `git commit` - 记录到 Git

---

## 完整示例

### 第一次使用：初始化

```batch
:: 创建项目
scripts\bat\setup.bat myproject https://svn.company.com/repo/trunk

:: 创建功能分支
scripts\bat\add-worktree.bat feature/login
```

### 日常工作

```batch
:: ① SVN 更新
scripts\bat\pull-svn.bat

:: ② 同步到 Worktree
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

## 命令速查表

| 步骤 | 命令 | 说明 |
|------|------|------|
| 初始化 | `scripts\bat\setup.bat <项目> <URL>` | 创建项目 |
| 创建分支 | `scripts\bat\add-worktree.bat <分支名>` | 创建 Worktree |
| ① SVN 更新 | `scripts\bat\pull-svn.bat` | 从 SVN 拉取 |
| ② Git 同步 | `scripts\bat\sync-all-worktrees.bat` | 同步所有 Worktree |
| ③ 合并分支 | `scripts\bat\merge-worktree.bat <分支>` | 合并到主目录 |
| ④ SVN 提交 | `scripts\bat\push-svn.bat` | 提交到 SVN |
| 查看列表 | `scripts\bat\list-worktrees.bat` | 列出所有 Worktree |
| 删除分支 | `scripts\bat\remove-worktree.bat <分支>` | 删除 Worktree |

---

## PowerShell 替代方案

```powershell
# ① SVN 更新
.\scripts\powershell\worktree.ps1 pull

# ② Git 同步
.\scripts\powershell\worktree.ps1 sync-all

# ③ 合并分支
.\scripts\powershell\worktree.ps1 merge feature/login

# ④ SVN 提交
.\scripts\powershell\worktree.ps1 push
```

---

## 目录结构

```
C:\repos\
└── project.git\        Git 数据仓库

C:\work\
├── project-svn\        主目录（SVN 操作）
│   └── .svn\          SVN 元数据
│
├── project-feature-a\  功能 A Worktree
└── project-feature-b\  功能 B Worktree
```

---

## 重要提示

⚠️ **SVN 操作只在主目录** (`project-svn`)
⚠️ **其他 Worktree 没有 `.svn` 目录**
⚠️ **提交顺序**: 开发 → 合并 → SVN 提交
