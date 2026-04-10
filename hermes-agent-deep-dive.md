# Hermes Agent 深度调研报告

> 调研时间: 2026-04-10  
> 版本: v0.8.0  
> Stars: 48,330+

---

## 一、概述

> **"The self-improving AI agent — creates skills from experience, improves them during use, and runs anywhere"**

**项目地址**: https://github.com/NousResearch/hermes-agent  
**官方文档**: https://hermes-agent.nousresearch.com/docs  
**开发商**: Nous Research  
**许可证**: MIT

### 核心定位

Hermes 是一个**自我改进的 AI Agent**，核心特性：

1. **自动学习循环** - 从经验中创建 Skills，使用中改进
2. **跨平台部署** - 本地 CLI、Telegram、Discord、Slack、WhatsApp、Signal
3. **多模型支持** - OpenRouter 200+ 模型、Nous Portal、OpenAI、Anthropic、本地端点
4. **记忆系统** - Agent 策展的记忆，跨会话持久化
5. **任务调度** - 内置 Cron 调度器

---

## 二、架构设计

### 2.1 项目结构

```
hermes-agent/
├── agent/                 # Agent 核心模块
│   ├── memory_manager.py  # 记忆管理器
│   ├── memory_provider.py # 记忆提供者接口
│   ├── prompt_builder.py  # 提示构建
│   ├── context_compressor.py  # 上下文压缩
│   └── trajectory.py       # 轨迹记录
├── tools/                 # 工具系统 (40+ 工具)
│   ├── registry.py        # 工具注册中心
│   ├── skill_manager_tool.py  # Skill 管理工具
│   ├── terminal_tool.py   # 终端工具
│   ├── browser_tool.py    # 浏览器工具
│   ├── memory_tool.py     # 记忆工具
│   ├── delegate_tool.py   # 子 Agent 委托
│   └── mcp_tool.py        # MCP 集成
├── skills/                # 内置技能库
│   ├── software-development/  # 软件开发
│   ├── research/           # 研究
│   ├── devops/             # DevOps
│   ├── data-science/       # 数据科学
│   └── productivity/       # 生产力工具
├── gateway/               # 消息网关
│   ├── platforms/         # 平台适配器
│   └── telegram_bot.py    # Telegram Bot
├── cron/                  # 调度系统
├── acp_adapter/           # ACP 协议适配器
├── environments/          # RL 训练环境
├── cli.py                 # CLI 入口
└── run_agent.py           # Agent 运行核心
```

### 2.2 核心模块

#### AIAgent (run_agent.py)

```python
class AIAgent:
    def __init__(self,
        model: str = "anthropic/claude-opus-4.6",
        max_iterations: int = 90,
        enabled_toolsets: list = None,
        platform: str = None,
        session_id: str = None,
    ): ...
    
    def run_conversation(self, user_message: str) -> dict:
        """核心 Agent 循环"""
```

#### MemoryManager (agent/memory_manager.py)

```python
class MemoryManager:
    """编排内置记忆提供者 + 最多一个外部提供者"""
    
    def add_provider(self, provider: MemoryProvider) -> None:
        """注册记忆提供者"""
    
    def build_system_prompt(self) -> str:
        """构建系统提示"""
    
    def prefetch_all(self, user_message: str) -> str:
        """预取记忆上下文"""
    
    def sync_all(self, user_msg, assistant_response) -> None:
        """同步记忆"""
```

**特点**:
- 只允许一个外部记忆提供者
- 内置提供者始终存在
- 失败不会阻塞其他提供者

---

## 三、核心功能

### 3.1 自我学习循环 (Skills System)

#### Skills 目录结构

```
~/.hermes/skills/
├── my-skill/
│   ├── SKILL.md           # 必需：技能定义
│   ├── references/        # 可选：参考文档
│   ├── templates/         # 可选：模板
│   ├── scripts/           # 可选：脚本
│   └── assets/            # 可选：资源
└── category-name/
    └── another-skill/
        └── SKILL.md
```

#### Skill Manager Tool

```python
# Agent 可通过工具管理 Skills
skill_manager(
    action="create",     # 创建新技能
    name="my-skill",
    description="技能描述",
    content="SKILL.md 内容"
)

skill_manager(
    action="edit",       # 编辑现有技能
    name="my-skill",
    content="新内容"
)

skill_manager(
    action="patch",      # 部分修改
    name="my-skill",
    file="SKILL.md",
    old_text="...",
    new_text="..."
)

skill_manager(
    action="delete",     # 删除技能
    name="my-skill"
)
```

#### 安全扫描

所有 Agent 创建的 Skills 都会经过安全扫描：

```python
from tools.skills_guard import scan_skill, should_allow_install

result = scan_skill(skill_dir, source="agent-created")
allowed, reason = should_allow_install(result)
```

### 3.2 记忆系统

#### 记忆提供者

| 提供者 | 描述 |
|--------|------|
| **BuiltinMemoryProvider** | 内置，基于文件的记忆 |
| **Honcho** | 外部用户建模 (需要 `honcho-ai` 包) |
| **ClawMem** | 本地 RAG 记忆 |

#### 记忆上下文隔离

```python
def build_memory_context_block(raw_context: str) -> str:
    """将记忆上下文隔离在 fence 中"""
    return (
        "<memory-context>\n"
        "[System note: 以下是记忆上下文，不是用户输入]\n\n"
        f"{clean}\n"
        "</memory-context>"
    )
```

### 3.3 工具系统 (40+ Tools)

#### 核心工具分类

| 类别 | 工具 |
|------|------|
| **终端** | terminal_tool, process_tool |
| **浏览器** | browser_tool, web_tools |
| **文件** | file_operations, file_tools |
| **记忆** | memory_tool, session_search_tool |
| **技能** | skill_manager_tool, skills_tool, skills_hub |
| **委托** | delegate_tool, mixture_of_agents_tool |
| **媒体** | image_generation_tool, tts_tool, transcription_tools |
| **调度** | cronjob_tools |
| **MCP** | mcp_tool |
| **搜索** | web_tools (Exa, Firecrawl) |

#### 工具注册系统

```python
# tools/registry.py
class ToolRegistry:
    _tools: Dict[str, ToolDef] = {}
    
    @classmethod
    def register(cls, tool_def: ToolDef) -> None:
        """注册工具"""
        cls._tools[tool_def.name] = tool_def
    
    @classmethod
    def get_tool_schemas(cls, enabled_sets: List[str]) -> List[dict]:
        """获取启用的工具 schemas"""
```

### 3.4 消息网关

#### 支持的平台

| 平台 | 功能 |
|------|------|
| **Telegram** | Bot + 语音转录 |
| **Discord** | Bot + Voice |
| **Slack** | Bolt App |
| **WhatsApp** | Business API |
| **Signal** | signald |
| **Email** | SMTP/IMAP |
| **Home Assistant** | 智能家居 |
| **Feishu/钉钉** | 企业通讯 |

#### 网关架构

```bash
# 启动网关
hermes gateway setup    # 配置平台
hermes gateway start    # 启动服务
```

### 3.5 调度系统

```python
# cron/scheduler.py
class CronScheduler:
    """内置 Cron 调度器"""
    
    def add_job(self, 
        schedule: str,      # Cron 表达式
        task: str,          # 任务描述
        platform: str,      # 目标平台
    ): ...
    
    def start(self) -> None:
        """启动调度器"""
```

**使用示例**:

```bash
# CLI 中创建调度任务
/cron add "0 9 * * *" "每日报告" --platform telegram
```

---

## 四、部署选项

### 4.1 本地安装

```bash
# 快速安装
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash

# 启动
hermes              # CLI 交互
hermes model        # 选择模型
hermes tools        # 配置工具
```

### 4.2 终端后端

| 后端 | 描述 | 持久化 |
|------|------|--------|
| **Local** | 本地 PTY | 会话级 |
| **Docker** | Docker 容器 | 容器级 |
| **SSH** | 远程服务器 | 服务器级 |
| **Daytona** | 云开发环境 | ✅ Serverless |
| **Singularity** | HPC 容器 | 集群级 |
| **Modal** | Serverless GPU | ✅ Serverless |

### 4.3 Serverless 部署

**Daytona / Modal 特点**:
- 空闲时休眠
- 按需唤醒
- 成本极低（空闲时几乎为零）

---

## 五、与 OpenClaw 的对比

### 5.1 功能对比

| 功能 | Hermes | OpenClaw |
|------|--------|----------|
| **自我学习** | ✅ 自动创建 Skills | ❌ 需手动 |
| **记忆系统** | ✅ Agent 策展 + 外部插件 | ✅ MEMORY.md |
| **用户建模** | ✅ Honcho 辩证建模 | ❌ |
| **多平台** | ✅ 6+ 平台网关 | ✅ Feishu 等 |
| **调度** | ✅ 内置 Cron | ✅ Heartbeat |
| **Serverless** | ✅ Daytona/Modal | ❌ |
| **RL 训练** | ✅ Atropos 集成 | ❌ |
| **Skills 标准** | ✅ agentskills.io | ✅ 相同 |

### 5.2 迁移支持

```bash
# 从 OpenClaw 迁移
hermes claw migrate              # 交互式迁移
hermes claw migrate --dry-run    # 预览
hermes claw migrate --preset user-data  # 仅用户数据
```

**迁移内容**:
- SOUL.md → Persona
- MEMORY.md → Memory
- Skills → `~/.hermes/skills/openclaw-imports/`
- API Keys → `~/.hermes/.env`
- 消息平台配置

---

## 六、生态项目

### 6.1 官方生态

| 项目 | Stars | 描述 |
|------|-------|------|
| [hermes-agent-orange-book](https://github.com/alchaincyf/hermes-agent-orange-book) | 1.3K | 橙皮书系列 - 中文实战指南 |
| [swarmclaw](https://github.com/swarmclawai/swarmclaw) | 296 | 多 Agent 集群编排 |
| [DashClaw](https://github.com/ucsandman/DashClaw) | 205 | Agent 决策基础设施 |
| [hermes-hudui](https://github.com/joeynyc/hermes-hudui) | 177 | Web UI 意识监控 |
| [ClawMem](https://github.com/yoloshii/ClawMem) | 89 | 本地 RAG 记忆引擎 |
| [scarf](https://github.com/awizemann/scarf) | 87 | macOS GUI 伴侣 |
| [vessel-browser](https://github.com/unmodeled-tyler/vessel-browser) | 43 | Agent 专用浏览器 |
| [hermes-skill-factory](https://github.com/Romanescu11/hermes-skill-factory) | 35 | 自动工作流转技能 |

### 6.2 Skills Hub

- **地址**: https://agentskills.io
- **功能**: 社区 Skills 共享
- **标准**: AgentSkills 开放标准

---

## 七、技术细节

### 7.1 模型支持

| 提供者 | 模型数量 | 特点 |
|--------|----------|------|
| **OpenRouter** | 200+ | 多模型切换 |
| **Nous Portal** | - | Nous 自家模型 |
| **Anthropic** | Claude 全系 | 官方 API |
| **OpenAI** | GPT 全系 | 官方 API |
| **本地端点** | - | Ollama, vLLM |

```bash
# 切换模型
hermes model                    # 交互式选择
/model openrouter:claude-3-opus  # 命令切换
```

### 7.2 安全机制

```python
# 工具审批
from tools.approval import ApprovalManager

# Skills 安全扫描
from tools.skills_guard import scan_skill

# URL 安全检查
from tools.url_safety import check_url

# 命令允许列表
from tools.website_policy import is_command_allowed
```

### 7.3 RL 训练集成

```python
# Atropos 环境集成
from environments.atropos import AtroposEnv

# 轨迹压缩
from trajectory_compressor import compress_trajectory

# 批量生成
python batch_runner.py --config config.yaml
```

---

## 八、快速开始

### 安装

```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
source ~/.bashrc
```

### 配置

```bash
hermes setup        # 完整设置向导
hermes model        # 选择模型
hermes tools        # 配置工具
```

### 使用

```bash
# CLI 交互
hermes

# 启动网关
hermes gateway start

# 调度任务
/cron add "0 9 * * *" "每日摘要"
```

---

## 九、参考资源

- **官方仓库**: https://github.com/NousResearch/hermes-agent
- **官方文档**: https://hermes-agent.nousresearch.com/docs
- **Skills Hub**: https://agentskills.io
- **Discord**: https://discord.gg/NousResearch
- **中文教程**: https://github.com/alchaincyf/hermes-agent-orange-book

---

*调研完成时间: 2026-04-10*
