# Claude Code 架构组件编写规范提示词

> 用于生成 Claude Code 的 Command、Agent (Subagent)、Skill 组件

---

## 一、概述

Claude Code 支持三种核心扩展组件：

| 组件 | 文件位置 | 作用 | 上下文 |
|------|----------|------|--------|
| **Command** | `.claude/commands/<name>.md` | 用户调用的斜杠命令，工作流入口 | 注入当前上下文 |
| **Agent** | `.claude/agents/<name>.md` | 独立的自主执行单元，隔离上下文 | 全新隔离上下文 |
| **Skill** | `.claude/skills/<name>/SKILL.md` | 可复用的知识/工作流模块 | 注入当前上下文 |

---

## 二、Command 编写规范

### 2.1 文件结构

```
.claude/commands/
└── my-command.md    # 单文件即可
```

### 2.2 YAML Frontmatter 字段

```yaml
---
name: my-command                    # 可选，默认为文件名
description: 命令描述，用于自动发现和补全菜单  # 推荐
argument-hint: [参数提示]            # 可选，如 [issue-number]
disable-model-invocation: false     # 可选，禁止自动调用
user-invocable: true                # 可选，false 则隐藏 from / 菜单
paths: "src/**/*.ts"                # 可选，限制激活的文件路径 glob
allowed-tools: "Read,Write,Edit"    # 可选，免确认的工具
model: sonnet                       # 可选，haiku/sonnet/opus
effort: high                        # 可选，low/medium/high/max
context: fork                       # 可选，在隔离子代理中运行
agent: general-purpose              # 可选，context:fork 时的代理类型
hooks: {}                           # 可选，生命周期钩子
---

# 命令内容

这里写命令的具体指令...
```

### 2.3 完整模板

```markdown
---
name: code-review
description: 执行代码审查，检查代码质量、安全性和最佳实践
argument-hint: [file-path]
allowed-tools: Read, Grep, Glob
model: sonnet
---

# Code Review Command

你是一个专业的代码审查助手。

## 工作流程

1. **获取目标文件**
   - 使用 Glob 和 Read 读取指定文件
   - 如果未指定文件，检查 git diff 获取变更

2. **审查维度**
   - 代码质量和可读性
   - 安全漏洞（SQL注入、XSS等）
   - 性能问题
   - 最佳实践违反

3. **输出格式**

```markdown
## 代码审查报告

### 文件: [filename]

#### 发现的问题

| 级别 | 行号 | 问题 | 建议 |
|------|------|------|------|
| 🔴 严重 | 42 | SQL注入风险 | 使用参数化查询 |

#### 优点
- ...

#### 总体评分: B+
```

## 注意事项

- 始终提供具体的行号和修改建议
- 区分严重性级别
- 给出可操作的建议
```

---

## 三、Agent (Subagent) 编写规范

### 3.1 文件结构

```
.claude/agents/
└── my-agent.md    # 单文件即可
```

### 3.2 YAML Frontmatter 字段

```yaml
---
name: my-agent                     # 必需，小写字母和连字符
description: 何时调用此代理的描述       # 必需，使用 PROACTIVELY 表示自动调用
tools: Read,Write,Edit,Bash        # 可选，工具白名单，省略则继承全部
disallowedTools: WebFetch          # 可选，工具黑名单
model: sonnet                      # 可选，haiku/sonnet/opus/inherit
permissionMode: acceptEdits        # 可选，default/acceptEdits/auto/bypassPermissions
maxTurns: 10                       # 可选，最大代理轮次
skills:                            # 可选，预加载的技能列表
  - skill-name-1
  - skill-name-2
mcpServers:                        # 可选，MCP 服务器配置
  - server-name
hooks: {}                          # 可选，生命周期钩子
memory: project                    # 可选，user/project/local
background: false                  # 可选，是否后台运行
effort: high                       # 可选，low/medium/high/max
isolation: worktree                # 可选，"worktree" 在临时 git worktree 中运行
initialPrompt: ""                  # 可选，自动提交的首条用户消息
color: green                       # 可选，显示颜色 red/blue/green/yellow/purple/orange/pink/cyan
---
```

### 3.3 内置代理类型

| Agent | Model | Tools | 描述 |
|-------|-------|-------|------|
| `general-purpose` | inherit | All | 复杂多步任务，默认类型 |
| `Explore` | haiku | Read-only | 快速代码库搜索和探索 |
| `Plan` | inherit | Read-only | 预规划研究，设计实现方案 |
| `statusline-setup` | sonnet | Read, Edit | 配置状态栏 |
| `claude-code-guide` | haiku | Glob,Grep,Read,WebFetch,WebSearch | 回答 Claude Code 功能问题 |

### 3.4 完整模板

```markdown
---
name: api-tester
description: PROACTIVELY 使用此代理测试 API 端点。当用户需要测试 REST API、验证响应格式或执行接口测试时自动激活。
tools: WebFetch, Read, Write, Bash
model: sonnet
color: blue
maxTurns: 15
permissionMode: acceptEdits
memory: project
skills:
  - http-client
---

# API Tester Agent

你是一个专业的 API 测试代理。

## 你的任务

执行 API 测试工作流：

1. **准备测试环境**
   - 读取 API 配置文件
   - 确认测试端点

2. **执行测试**
   - 发送请求并捕获响应
   - 验证状态码和响应格式
   - 检查响应时间

3. **生成报告**
   - 记录所有测试结果
   - 标记失败的测试
   - 提供修复建议

## 输出格式

```markdown
## API 测试报告

| 端点 | 方法 | 状态码 | 响应时间 | 结果 |
|------|------|--------|----------|------|
| /api/users | GET | 200 | 45ms | ✅ |

### 失败详情
...
```

## 记忆

将测试结果保存到 memory 以供后续分析。
```

---

## 四、Skill 编写规范

### 4.1 文件结构

```
.claude/skills/
└── my-skill/
    ├── SKILL.md           # 必需，技能主文件
    ├── scripts/           # 可选，可执行脚本
    │   └── helper.sh
    ├── references/        # 可选，参考文档
    │   └── guide.md
    └── assets/            # 可选，资源文件
        └── template.json
```

### 4.2 YAML Frontmatter 字段

```yaml
---
name: my-skill                      # 可选，默认为目录名
description: 技能描述，决定何时触发    # 推荐，描述性要"pushy"一些
argument-hint: [参数提示]            # 可选
disable-model-invocation: false     # 可选
user-invocable: true                # 可选，false 则隐藏 from / 菜单
allowed-tools: ""                   # 可选
model: sonnet                       # 可选
effort: high                        # 可选
context: fork                       # 可选
agent: general-purpose              # 可选
hooks: {}                           # 可选
paths: "src/**/*.cpp"               # 可选，自动激活的文件 glob 模式
shell: bash                         # 可选，bash/powershell
---
```

### 4.3 渐进式披露原则

Skills 使用三级加载系统：

| 层级 | 内容 | 大小限制 |
|------|------|----------|
| **Metadata** | name + description | ~100 词，始终在上下文 |
| **SKILL.md body** | 技能主体内容 | <500 行理想 |
| **Bundled resources** | scripts/references/assets | 无限制，按需加载 |

### 4.4 完整模板

```markdown
---
name: cpp-codegen
description: 生成符合 C++ Core Guidelines 的高质量 C++ 代码。当用户编写 C++ 代码、创建类、实现函数、或需要 C++ 最佳实践指导时使用此技能。即使未明确要求，只要涉及 C++ 开发就应激活。
paths: "**/*.cpp,**/*.h,**/*.hpp"
---

# C++ Code Generation Skill

生成符合现代 C++ 标准的高质量代码。

## 何时使用

- 编写新的 C++ 代码
- 重构现有 C++ 代码
- 代码审查
- 实现 C++ 设计模式

## 核心原则

### 1. RAII - 资源获取即初始化

```cpp
// ✅ GOOD: 使用智能指针
auto widget = std::make_unique<Widget>();

// ❌ BAD: 裸指针
Widget* widget = new Widget();
```

### 2. 不可变优先

```cpp
// ✅ GOOD: 默认 const
const int max_retries = 3;
const std::string name = "widget";

// ❌ BAD: 可变变量
int max_retries = 3;
```

### 3. 类型安全

```cpp
// ✅ GOOD: 强类型枚举
enum class Color { red, green, blue };

// ❌ BAD: 弱类型枚举
enum Color { RED, GREEN, BLUE };
```

## 输出规范

生成的代码必须：

1. **符合 C++20 标准**
2. **使用 constexpr** 编译期计算
3. **包含适当的错误处理**
4. **提供完整的注释**

## 参考文件

对于复杂的模板和模式，参阅：
- `references/patterns.md` - 设计模式示例
- `references/modern-cpp.md` - C++20 特性指南

## 示例

**输入**: 创建一个线程安全的队列

**输出**:

```cpp
#include <mutex>
#include <condition_variable>
#include <queue>

template<typename T>
class ThreadSafeQueue {
public:
    void push(T value) {
        std::lock_guard<std::mutex> lock(mutex_);
        queue_.push(std::move(value));
        cv_.notify_one();
    }

    T pop() {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this] { return !queue_.empty(); });
        T value = std::move(queue_.front());
        queue_.pop();
        return value;
    }

    bool empty() const {
        std::lock_guard<std::mutex> lock(mutex_);
        return queue_.empty();
    }

private:
    mutable std::mutex mutex_;
    std::condition_variable cv_;
    std::queue<T> queue_;
};
```
```

---

## 五、Command → Agent → Skill 编排模式

### 5.1 架构流程

```
┌─────────────────────────────────────────────────────────────┐
│                     User Input                               │
│                  /weather-orchestrator                       │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      COMMAND                                 │
│              工作流入口，编排任务                              │
│                                                              │
│  1. 解析用户输入                                              │
│  2. 调用 Agent 执行具体任务                                    │
│  3. 调用 Skill 生成输出                                       │
└─────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│     AGENT       │ │     AGENT       │ │     SKILL       │
│  隔离上下文执行  │ │  隔离上下文执行  │ │  注入知识模块   │
│                 │ │                 │ │                 │
│  - 独立 memory  │ │  - 独立 memory  │ │  - 可复用       │
│  - 独立 tools   │ │  - 独立 tools   │ │  - 可预加载     │
│  - 预加载 skill │ │                 │ │                 │
└─────────────────┘ └─────────────────┘ └─────────────────┘
```

### 5.2 编排示例

**Command (orchestrator)**:
```markdown
---
name: weather-orchestrator
description: 获取天气数据并生成可视化报告
---

# Weather Orchestrator

协调天气数据获取和报告生成：

1. **调用 Agent 获取数据**
   - 使用 Task tool 调用 `weather-agent`
   - 传入位置参数

2. **调用 Skill 生成报告**
   - 使用 Skill `weather-svg-creator`
   - 传入温度数据

3. **返回结果给用户**
```

**Agent (worker)**:
```markdown
---
name: weather-agent
description: PROACTIVELY 获取天气数据
tools: WebFetch, Read, Write
model: sonnet
skills:
  - weather-fetcher
---

# Weather Agent

使用预加载的 weather-fetcher skill 获取天气数据...

返回温度值和单位。
```

**Skill (knowledge)**:
```markdown
---
name: weather-fetcher
description: 从 Open-Meteo API 获取天气数据
---

# Weather Fetcher Skill

提供获取天气数据的指令...

## API 调用
...
```

---

## 六、最佳实践

### 6.1 通用原则

1. **描述要"pushy"** - description 是主要触发机制，要明确说明何时使用
2. **保持简洁** - SKILL.md 理想 <500 行，复杂内容放 references/
3. **渐进式披露** - 三级加载：元数据 → 主体 → 资源
4. **提供示例** - 包含输入/输出示例
5. **避免惊喜** - 内容意图清晰，不含恶意代码

### 6.2 选择指南

| 需求 | 选择 |
|------|------|
| 用户通过 `/` 调用的工作流 | Command |
| 需要隔离执行的后台任务 | Agent |
| 可复用的知识/工作流模块 | Skill |
| 复杂多步骤流程 | Command → Agent → Skill |

### 6.3 文件组织

```
.claude/
├── commands/
│   ├── plan.md
│   ├── review.md
│   └── deploy.md
├── agents/
│   ├── tester.md
│   ├── explorer.md
│   └── planner.md
├── skills/
│   ├── cpp-codegen/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── api-testing/
│   │   ├── SKILL.md
│   │   └── scripts/
│   └── code-review/
│       └── SKILL.md
└── settings.json
```

---

## 七、参考资源

- [Claude Code 官方文档](https://code.claude.com/docs)
- [anthropics/skills 仓库](https://github.com/anthropics/skills)
- [claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
