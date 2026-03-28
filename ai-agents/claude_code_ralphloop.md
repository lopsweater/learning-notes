# Claude Code RalphLoop 调研报告

## 概述

**RalphLoop** 是一个由 Claude Code 驱动的 AI 自主开发循环系统。只需描述需求，AI 就能自动完成从代码编写、测试、PR 创建到合并的完整开发流程。

| 属性 | 值 |
|------|-----|
| **名称** | RalphLoop |
| **GitHub** | https://github.com/FlowCoder-cyh/RalphLoop |
| **语言** | Shell |
| **许可证** | MIT |
| **核心** | Claude Code 自动化 |

---

## 核心功能

### 1. 全自动开发流程

```
需求描述 → AI 生成任务列表 → 自动循环：
  └─ 创建分支 → 编写代码 → 测试 → PR → CI → 合并
```

### 2. TDD 强制

- **RED**: 先写失败的测试
- **GREEN**: 最小实现
- **lint → build → test**: 完整测试套件
- **commit → push → PR**: 自动提交

### 3. 智能恢复

- **Crash 恢复**: 从 git log 自动恢复
- **冲突解决**: PR 自动 rebase
- **Regression**: E2E 失败自动生成修复任务

---

## 安装

### 前置要求

| 工具 | 安装命令 |
|------|---------|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` |
| **GitHub CLI** | Windows: `winget install GitHub.cli` / Mac: `brew install gh` |
| **Git** | 已预装 |
| **Git Bash** | Windows: Git 安装时包含 |

### 安装步骤

```bash
# 1. 克隆仓库
git clone https://github.com/FlowCoder-cyh/RalphLoop.git

# 2. 运行安装脚本
cd RalphLoop
bash install.sh
```

### 卸载

```bash
bash uninstall.sh
```

---

## 使用方法

### 1. 初始化项目

```
/wi:init
```

AI 会询问：
- 项目名称
- 项目类型
- GitHub 账户（推荐组织账户）

### 2. 编写需求文档

```
/wi:prd
```

AI 会询问要做什么，并整理成 PRD 文档。

> 不确定如何描述？先运行 `/wi:guide`

### 3. 配置基础设施

```
/wi:env
```

AI 分析 PRD，自动配置：
- Supabase MCP 数据库
- Vercel 部署
- GitHub Secrets

### 4. 开始开发

```
/wi:start
```

AI 自动：
- 生成任务列表
- 创建 Smoke 测试
- 设置 Ruleset
- 启动自动开发循环

### 5. 查看进度

```
/wi:status
```

终端实时显示：
```
--- Iteration 5/94 ---
WI #8/78: WI-008-feat People DB Schema
进度: 7/78 (8%)
  ⠹ 2m 30s | feature/WI-008-feat-people-db-schema | 文件: 5个
```

### 6. 记录决策

```
/wi:note 使用 Supabase Auth 代替 NextAuth
```

---

## 命令汇总

| 命令 | 功能 |
|------|------|
| `/wi:init` | 项目环境设置 |
| `/wi:prd` | 编写需求文档 |
| `/wi:env` | 基础设施配置 |
| `/wi:start` | 启动开发循环 |
| `/wi:status` | 查看进度 |
| `/wi:guide` | PRD 编写指南 |
| `/wi:note` | 记录决策 |

---

## 系统架构

### 目录结构

```
RalphLoop/
├── install.sh              # 安装脚本
├── uninstall.sh            # 卸载脚本
├── rules/                  # Claude Code 全局规则
│   ├── wi-global.md        # 提交/分支/PR 规则
│   ├── wi-ralph-loop.md    # Ralph Loop 执行规则
│   └── wi-utf8.md          # UTF-8 编码规则
├── skills/wi/              # Claude Code 技能（命令）
│   ├── init.md             # /wi:init
│   ├── prd.md              # /wi:prd
│   ├── env.md              # /wi:env
│   ├── start.md            # /wi:start
│   ├── status.md           # /wi:status
│   ├── guide.md            # /wi:guide
│   └── note.md             # /wi:note
└── templates/              # 项目模板
    ├── ralph.sh            # Ralph Loop 引擎
    ├── .ralph/
    │   ├── PROMPT.md       # AI 指令
    │   ├── hooks/          # Git hooks
    │   └── scripts/        # 辅助脚本
    ├── .claude/rules/
    │   └── ralph-operations.md
    ├── .github/workflows/  # CI/CD
    ├── .ralphrc            # 配置
    └── CLAUDE.md           # 项目信息
```

### 工作流程

```
bash ralph.sh
    │
    ├─ 同步 main 分支
    ├─ 恢复已完成任务
    ├─ 清理过期任务
    ├─ 解决冲突 PR
    ├─ 注入回归修复
    │
    ├─ 选择下一个任务
    ├─ 调用 Claude (TDD)
    │   ├─ 创建分支 (worktree)
    │   ├─ RED: 写失败测试
    │   ├─ GREEN: 最小实现
    │   ├─ lint → build → test
    │   ├─ 提交 → 推送 → PR
    │   └─ 加入合并队列
    │
    ├─ 记录完成
    ├─ CI 通过 → 自动合并
    ├─ E2E 测试 → 失败自动修复
    └─ 循环下一个任务
```

---

## 核心设计原则

| 原则 | 说明 |
|------|------|
| **fix_plan.md 只读** | 循环中禁止修改 |
| **TDD 强制** | 测试先行，减少探索 |
| **禁止 mock** | DB 连接时强制 Prisma CRUD |
| **E2E 分离** | 仅交互式编写 |
| **1 次迭代 = 1 个任务** | 每次只处理一个工作项 |
| **并行 worktree** | 自动决定并行/串行 |
| **合并队列** | 组织账户自动 rebase + CI |
| **会话复用** | `--resume` 复用上下文 |
| **崩溃恢复** | git log 自动恢复 |
| **熔断器** | 3 次无进展自动停止 |

---

## 配置选项

### `.ralphrc`

```bash
MAX_ITERATIONS=50       # 最大迭代次数
MAX_TURNS=40            # 每个任务最大轮次
PARALLEL_COUNT=1        # 并行 worker 数量
RATE_LIMIT_PER_HOUR=80  # API 调用限制
COOLDOWN_SEC=5          # 迭代间隔
NO_PROGRESS_LIMIT=3     # 无进展容忍次数
CONTEXT_THRESHOLD=150000 # 会话重置阈值
GITHUB_ACCOUNT_TYPE=""  # "org" 或 "personal"
GITHUB_ORG=""           # 组织名或用户名
```

---

## 提交规则

### 格式

```
WI-NNN-[type] 任务描述

类型: feat, fix, docs, style, refactor, test, chore, perf, ci, revert
编号: fix_plan.md 中的序号 (001, 002, ...)
```

### 示例

```
WI-001-feat 用户认证添加
WI-015-fix 登录令牌过期处理
```

---

## 分支规则

```
feat:     feature/WI-NNN-feat-任务名
fix:      fix/WI-NNN-fix-任务名
chore:    chore/WI-NNN-chore-任务名
docs:     docs/WI-NNN-docs-任务名
refactor: refactor/WI-NNN-refactor-任务名
```

---

## 适用场景

### ✅ 适合

- 有想法但开发困难
- 想自动化重复工作
- 想系统化使用 Claude Code
- 需要快速原型开发

### ❌ 不适合

- 需要精确控制的复杂系统
- 安全关键型应用
- 需要人工审核的敏感操作

---

## 支持平台

| 平台 | 状态 | 备注 |
|------|------|------|
| Windows (Git Bash) | ✅ 支持 | |
| macOS | ✅ 支持 | 推荐 tmux |
| Linux | ✅ 支持 | |
| WSL | ✅ 支持 | 自动检测 Windows 路径 |

---

## 与游戏引擎开发的结合建议

### 可能的应用

1. **自动化测试生成**
   - 使用 RalphLoop 为引擎模块生成单元测试
   - 自动化 CI/CD 流程

2. **代码重构**
   - 批量重命名、格式化
   - 自动化代码迁移

3. **文档生成**
   - 从代码自动生成 API 文档
   - 更新 README 和 CHANGELOG

### 注意事项

1. **RHI 核心保护**
   - 在 `.ralph/guardrails.md` 中添加保护规则
   - 禁止修改核心接口

2. **代码审查**
   - 所有 PR 需要人工审核
   - 设置严格的 CI 检查

3. **渐进式采用**
   - 先在非核心模块测试
   - 验证后再扩展范围

---

## 相关资源

- **GitHub**: https://github.com/FlowCoder-cyh/RalphLoop
- **Claude Code**: https://claude.com/claude-code
- **关键词**: Claude Code automation, AI coding agent, autonomous development

---

## 更新日期

2026-03-23
