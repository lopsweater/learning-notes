# Engine-EVC: Claude Code 游戏引擎开发配置

> 为使用 Claude Code 开发游戏引擎提供专业的 Skills、Rules 和 Commands 配置

## 🎯 项目概述

Engine-EVC 是专门为游戏引擎开发优化的 Claude Code 配置目录，整合了以下最佳实践：

- **unreal-engine-skills** (quodsoler) - 27个 UE5 C++ 开发技能
- **soft-ue-cli** - Python CLI 实时控制游戏引擎
- **Claude Code 官方文档** - Skills/Rules/Commands 最佳实践

## 📁 目录结构

```
engine-evc/
├── .claude/                    # Claude Code 配置目录
│   ├── skills/                # 技能文件（会被 Claude Code 自动加载）
│   ├── rules/                 # 规则文件（针对特定文件类型的规则）
│   └── commands/              # 命令文件（自定义斜杠命令）
├── skills/                    # 技能源文件（供参考和编辑）
├── rules/                     # 规则源文件
├── commands/                  # 命令源文件
├── docs/
│   ├── skills/               # 技能文档
│   └── references/           # 参考资料
├── scripts/                   # 辅助脚本
└── README.md                  # 本文件
```

## 🚀 快速开始

### 1. 复制到项目根目录

```bash
# 方法 1: 直接使用（推荐）
cp -r /root/engine-evc/.claude /path/to/your/engine/project/

# 方法 2: 创建符号链接
ln -s /root/engine-evc/.claude /path/to/your/engine/project/.claude
```

### 2. 验证安装

在项目目录下运行 Claude Code：

```bash
cd /path/to/your/engine/project
claude
```

Claude Code 会自动加载 `.claude/skills/`, `.claude/rules/`, `.claude/commands/` 目录中的文件。

## 🛠️ Skills（技能）

### 核心技能

| 技能名称 | 描述 | 适用场景 |
|---------|------|---------|
| `engine-project-context` | 项目上下文管理 | 所有技能的基础，定义项目模块、平台、规范 |
| `engine-cpp-foundations` | C++ 基础知识 | 内存管理、智能指针、模板、并发编程 |
| `engine-architecture` | 引擎架构设计 | 模块设计、ECS、事件系统、资源管理 |
| `engine-rendering` | 渲染系统开发 | RHI、材质系统、后处理、GPU 编程 |
| `engine-tools` | 引擎工具开发 | 编辑器扩展、资源管线、调试工具 |
| `engine-testing` | 测试与调试 | 单元测试、性能分析、内存检测 |

### 使用技能

在 Claude Code 对话中，技能会根据上下文自动激活：

```
你: 帮我实现一个 ECS 系统
Claude Code: [自动激活 engine-architecture 和 engine-cpp-foundations 技能]
```

## 📋 Rules（规则）

### 编码规则

| 规则文件 | 适用文件 | 描述 |
|---------|---------|------|
| `engine-coding-standards.md` | `*.cpp`, `*.h` | 引擎编码规范 |
| `engine-performance.md` | `*.cpp`, `*.h` | 性能优化规则 |
| `engine-memory.md` | `*.cpp`, `*.h` | 内存管理规则 |
| `engine-testing.md` | `*test*.cpp` | 测试代码规则 |

### 规则示例

规则文件会根据文件类型自动应用：

```markdown
---
globs: ["*.cpp", "*.h"]
---

# 引擎编码规范

- 使用 RAII 管理资源
- 避免裸指针，优先使用智能指针
- 所有公共 API 必须有文档注释
...
```

## ⚡ Commands（命令）

### 可用命令

| 命令 | 描述 | 示例 |
|-----|------|------|
| `/engine-analyze` | 分析引擎代码结构 | `/engine-analyze Source/Runtime/Render` |
| `/engine-implement` | 实现引擎功能 | `/engine-implement 新增一个任务系统` |
| `/engine-optimize` | 优化引擎性能 | `/engine-optimize 分析渲染管线瓶颈` |
| `/engine-test` | 生成测试代码 | `/engine-test 为 ECS 系统生成单元测试` |

### 使用命令

在 Claude Code 中直接输入斜杠命令：

```
/engine-analyze Source/Runtime/Core
```

## 🔗 相关资源

### 官方文档
- [Claude Code Skills 文档](https://code.claude.com/docs/zh-CN/skills)
- [Claude Code Rules 文档](https://code.claude.com/docs/zh-CN/memory#%E4%BD%BF%E7%94%A8-claude/rules/-%E7%BB%84%E7%BB%87%E8%A7%84%E5%88%99)
- [Claude Code Commands 文档](https://code.claude.com/docs/zh-CN/commands)

### 参考项目
- [unreal-engine-skills](https://github.com/quodsoler/unreal-engine-skills) - UE5 开发技能
- [soft-ue-cli](https://github.com/softdaddy-o/soft-ue-cli) - UE CLI 工具
- [Agent Skills Spec](https://agentskills.io) - Agent Skills 规范

## 📝 更新日志

### v1.0.0 (2026-04-02)
- 初始版本
- 创建 6 个核心技能
- 创建 4 个编码规则
- 创建 4 个便捷命令
- 整合 unreal-engine-skills 最佳实践

## 🤝 贡献

欢迎贡献！你可以：
- 提交 Issue 报告问题
- 提交 PR 改进技能
- 分享你的自定义技能

## 📄 许可证

MIT License
