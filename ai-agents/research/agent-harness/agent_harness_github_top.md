# Agent Harness 开发 - GitHub 高星项目调研报告

> 调研时间: 2026-03-23  
> 关键词: AI Agent, Agent Framework, LLM, MCP, Claude Code, Multi-Agent

---

## 一、核心发现：Agent Framework 分类

### 1.1 综合型 Agent 框架 (Tier 1)

| 项目 | Stars | 语言 | 核心定位 |
|------|-------|------|----------|
| **LangChain** | 130,669 | Python | The agent engineering platform |
| **AutoGen** | 56,045 | Python | Microsoft - A programming framework for agentic AI |
| **MetaGPT** | 65,838 | Python | 多 Agent 框架 - First AI Software Company |
| **CrewAI** | 46,917 | Python | 角色扮演式多 Agent 协作框架 |
| **LangGraph** | 27,193 | Python | Build resilient language agents as graphs |
| **Haystack** | 24,587 | MDX | AI orchestration framework |
| **Mastra** | 22,233 | TypeScript | TypeScript AI Agent Framework |

### 1.2 自动编程 Agent

| 项目 | Stars | 说明 |
|------|-------|------|
| **Cline** | 59,252 | IDE 内的自主编程 Agent |
| **Claude Code** | 81,437 | Anthropic 官方 - 终端里的 agentic coding tool |
| **AgentGPT** | 35,869 | 浏览器内组装/配置/部署自主 Agent |
| **agenticSeek** | 25,582 | 本地 Manus AI - 无 API、零成本 |
| **Agent Zero** | 16,288 | Agent Zero AI framework |

### 1.3 自主 Agent 平台

| 项目 | Stars | 说明 |
|------|-------|------|
| **Khoj** | 33,571 | AI 第二大脑 - 自主搜索、研究、自动化 |
| **GPT Researcher** | 25,942 | 自主深度研究 Agent |
| **Dexter** | 18,157 | 自主金融研究 Agent |
| **Eliza** | 17,883 | Autonomous agents for everyone |
| **SuperAGI** | 17,293 | 开源自主 AI Agent 框架 |

---

## 二、Claude Code 生态 (重点)

### 2.1 Claude Code 核心项目

| 项目 | Stars | 说明 |
|------|-------|------|
| **Claude Code** | 81,437 | Anthropic 官方 - 终端 Agentic Coding Tool |
| **system-prompts-and-models-of-ai-tools** | 132,775 | Claude Code/Cursor/Devin 等 AI 工具的系统提示词 |
| **everything-claude-code** | 99,170 | Agent harness 性能优化系统 - Skills, instincts, memory |
| **claude-mem** | 39,588 | Claude Code 插件 - 自动捕获、压缩、注入上下文 |
| **learn-claude-code** | 36,295 | 从 0 到 1 构建类 Claude Code 的 agent harness |
| **awesome-claude-code** | 30,350 | Claude Code Skills/Hooks/Commands 精选列表 |
| **antigravity-awesome-skills** | 26,671 | 1,304+ agentic skills 库 |
| **vibe-kanban** | 23,626 | 让 Claude Code/Codex 效率提升 10X |

### 2.2 Claude Code 安装

```bash
# MacOS/Linux (推荐)
curl -fsSL https://claude.ai/install.sh | bash

# Homebrew
brew install --cask claude-code

# Windows
irm https://claude.ai/install.ps1 | iex
```

### 2.3 Claude Code 核心能力

- 终端内的 agentic coding tool
- 理解代码库
- 执行常规任务
- 解释复杂代码
- Git 工作流处理
- 自然语言命令

---

## 三、12-Factor Agents (核心方法论)

**仓库**: https://github.com/humanlayer/12-factor-agents  
**Stars**: 18,861

> 构建可靠 LLM 应用的 12 条原则

### 核心洞察

> "我尝试过所有 agent 框架...大多数在生产环境中的客户面向 agent 并没有使用框架。大部分成功的'AI Agent'产品主要是确定性代码，LLM 步骤恰到好处地 sprinkled in。"

### 12 原则详解

| Factor | 原则 | 说明 |
|--------|------|------|
| **1** | Natural Language to Tool Calls | 自然语言转工具调用 |
| **2** | Own your prompts | 掌控你的提示词 |
| **3** | Own your context window | 掌控上下文窗口 |
| **4** | Tools are just structured outputs | 工具即结构化输出 |
| **5** | Unify execution state and business state | 统一执行状态和业务状态 |
| **6** | Launch/Pause/Resume with simple APIs | 简单 API 启动/暂停/恢复 |
| **7** | Contact humans with tool calls | 用工具调用联系人类 |
| **8** | Own your control flow | 掌控控制流 |
| **9** | Compact Errors into Context Window | 错误压缩进上下文窗口 |
| **10** | Small, Focused Agents | 小而专注的 Agent |
| **11** | Trigger from anywhere | 从任何地方触发 |
| **12** | Make your agent a stateless reducer | 让 agent 成为无状态 reducer |

### Agent Loop 模式

```python
initial_event = {"message": "..."}
context = [initial_event]

while True:
    next_step = await llm.determine_next_step(context)
    context.append(next_step)

    if next_step.intent === "done":
        return next_step.final_answer

    result = await execute_step(next_step)
    context.append(result)
```

---

## 四、MCP (Model Context Protocol) 生态

### 4.1 MCP 相关高星项目

| 项目 | Stars | 说明 |
|------|-------|------|
| **awesome-mcp-servers** | 83,858 | MCP 服务器集合 |
| **modelcontextprotocol/servers** | 81,824 | MCP 官方服务器 |
| **serena** | 21,939 | 编码 Agent 工具包 (MCP server) |
| **activepieces** | 21,374 | AI Agents & MCPs 自动化平台 (400+ MCP servers) |
| **Figma-Context-MCP** | 13,863 | Figma 布局信息给 AI 编码 Agent |
| **genai-toolbox** | 13,495 | Google - 数据库 MCP 服务器 |
| **mcp-use** | 9,473 | MCP 全栈框架 |
| **Klavis** | 5,674 | MCP 集成平台 |
| **DesktopCommanderMCP** | 5,752 | 终端控制、文件系统搜索、diff 编辑 |

### 4.2 MCP 工具分类

| 类型 | 示例项目 | 用途 |
|------|----------|------|
| **数据库** | genai-toolbox | 数据库访问 |
| **文件系统** | DesktopCommanderMCP | 文件操作 |
| **移动端** | mobile-mcp | iOS/Android 自动化 |
| **浏览器** | browser-use | Web 自动化 |
| **安全** | hexstrike-ai | 网络安全工具 (150+) |
| **开发工具** | XcodeBuildMCP | iOS/macOS 项目构建 |
| **视觉** | Peekaboo | 屏幕截图 + VQA |

### 4.3 MCP Sandbox

**项目**: agent-infra/sandbox (3,159 ⭐)

All-in-One Sandbox for AI Agents:
- Browser
- Shell
- File
- MCP
- VSCode Server

---

## 五、多 Agent 系统

| 项目 | Stars | 说明 |
|------|-------|------|
| **MetaGPT** | 65,838 | 多 Agent 框架 - 软件公司 |
| **CrewAI** | 46,917 | 角色扮演式多 Agent 协作 |
| **TradingAgents** | 37,936 | 多 Agent 金融交易框架 |
| **Open-AutoGLM** | 24,504 | 开放手机 Agent 框架 |
| **MindSearch** | 6,810 | 多 Agent 搜索引擎 (类 Perplexity) |
| **CAMEL** | 16,458 | 第一个多 Agent 框架 |

### MetaGPT 特点

- 多 Agent 协作
- 自然语言编程
- 模拟软件公司角色：产品经理、架构师、工程师、QA

### CrewAI 特点

- 角色扮演式
- 自主协作
- 任务分配和协调

---

## 六、Agent 开发工具链

### 6.1 新兴框架 (2024-2025)

| 项目 | Stars | 说明 |
|------|-------|------|
| **OpenAI Agents Python** | 20,202 | OpenAI 官方 - 轻量多 Agent 框架 |
| **pydantic-ai** | 15,681 | Pydantic 方式的 GenAI Agent 框架 |
| **VoltAgent** | 6,915 | TypeScript AI Agent Framework |
| **PocketFlow** | 10,255 | 100 行 LLM 框架 - Let Agents build Agents |
| **AutoAgent** | 8,685 | 零代码 LLM Agent 框架 |

### 6.2 企业级框架

| 项目 | Stars | 说明 |
|------|-------|------|
| **langchain4j** | 11,237 | Java LLM 集成库 |
| **Parlant** | 17,846 | 客户面向 AI Agent 上下文工程框架 |
| **RagaAI-Catalyst** | 16,113 | Agent 可观测性/监控/评估框架 |

### 6.3 Orchestration 平台

| 项目 | Stars | 说明 |
|------|-------|------|
| **ruflo** | 22,685 | Claude Agent 编排平台 |
| **symphony** | 13,821 | OpenAI - 项目工作转为隔离的自主实现运行 |
| **zeroclaw** | 28,444 | Rust - 快速、小型、完全自主的 AI 个人助手基础设施 |

---

## 七、Agent 安全与评估

| 项目 | Stars | 说明 |
|------|-------|------|
| **agent-scan** | 1,957 | Snyk - AI Agent 安全扫描器 |
| **RagaAI-Catalyst** | 16,113 | Agent 可观测性、监控、评估 |
| **PentestGPT** | 12,194 | LLM 驱动的自动化渗透测试框架 |

---

## 八、资源索引

| 项目 | Stars | 说明 |
|------|-------|------|
| **awesome-ai-agents** | 26,783 | AI 自主 Agent 列表 |
| **acu** | 1,638 | AI Computer Use Agent 资源 |

---

## 九、关键洞察与建议

### 9.1 框架选择建议

| 场景 | 推荐框架 | 理由 |
|------|----------|------|
| **快速原型** | LangChain / LangGraph | 生态最成熟 |
| **多 Agent 协作** | CrewAI / MetaGPT | 专为多 Agent 设计 |
| **生产级可靠性** | 12-Factor Agents 方法论 | 自己掌控核心逻辑 |
| **TypeScript 技术栈** | Mastra / VoltAgent | 原生 TS 支持 |
| **轻量级** | PocketFlow / pydantic-ai | 极简设计 |
| **Claude 集成** | Claude Code + MCP | 官方支持 |

### 9.2 开发流程建议

```
┌─────────────────────────────────────────────────────────────────┐
│                    Agent 开发流程                                │
└─────────────────────────────────────────────────────────────────┘

1. 需求分析
   │  └─ 明确 Agent 自主性边界
   ▼
2. 选择方法论
   │  └─ 参考 12-Factor Agents
   ▼
3. 设计工具集
   │  └─ MCP 工具定义
   ▼
4. 实现核心循环
   │  └─ LLM → Tool Call → Execute → Context
   ▼
5. 添加人机交互
   │  └─ 人工确认、反馈收集
   ▼
6. 可观测性
   │  └─ 日志、追踪、评估
   ▼
7. 安全审计
   │  └─ agent-scan 等工具
   ▼
8. 部署与监控
```

### 9.3 与 OpenClaw 相关的集成点

1. **MCP 协议** - OpenClaw 已支持 MCP
2. **Skills 系统** - 参考 antigravity-awesome-skills
3. **Claude Code 集成** - 通过 sessions_spawn runtime="acp"
4. **12-Factor 方法论** - 指导 OpenClaw Agent 设计

---

## 附录：快速参考链接

### 官方文档
- [Claude Code Docs](https://code.claude.com/docs)
- [12-Factor Agents](https://github.com/humanlayer/12-factor-agents)
- [MCP Specification](https://modelcontextprotocol.io/)

### 核心框架
- [LangChain](https://github.com/langchain-ai/langchain)
- [LangGraph](https://github.com/langchain-ai/langgraph)
- [CrewAI](https://github.com/crewAIInc/crewAI)
- [AutoGen](https://github.com/microsoft/autogen)
- [MetaGPT](https://github.com/FoundationAgents/MetaGPT)

### MCP 生态
- [MCP Servers](https://github.com/modelcontextprotocol/servers)
- [awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers)

### Claude Code 生态
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code)
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code)
- [antigravity-awesome-skills](https://github.com/sickn33/antigravity-awesome-skills)

---

*本报告基于 GitHub API 实时数据整理*
