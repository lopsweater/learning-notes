# AI Agent 开发范式调研报告

> 更新日期: 2026-03-23

---

## 一、Agent 开发演进历程

### 1.1 从 DAG 到 Agent

```
传统软件 → DAG 编排器 (Airflow/Prefect) → Agent
  ↓              ↓                          ↓
流程图         有向无环图              动态决策图
```

**核心转变**: 从硬编码流程 → LLM 实时决策

### 1.2 Agent 循环模型

```python
# Agent 核心循环
initial_event = {"message": "用户输入"}
context = [initial_event]

while True:
    # 1. LLM 决定下一步
    next_step = await llm.determine_next_step(context)
    context.append(next_step)
    
    # 2. 判断是否完成
    if next_step.intent == "done":
        return next_step.final_answer
    
    # 3. 执行工具
    result = await execute_step(next_step)
    context.append(result)
```

---

## 二、主流 Agent 框架对比

### 2.1 框架概览

| 框架 | Stars | 语言 | 特点 | 适用场景 |
|------|-------|------|------|---------|
| **LangChain** | 130K | Python/JS | 生态最全，组件丰富 | 通用 LLM 应用 |
| **MetaGPT** | 66K | Python | 多 Agent 协作，软件公司 | 复杂软件开发 |
| **AutoGen** | 56K | Python | 微软出品，多 Agent | 企业级应用 |
| **CrewAI** | 47K | Python | 角色扮演，协作式 | 团队协作场景 |
| **LangGraph** | 27K | Python | 图结构，状态管理 | 状态复杂的工作流 |
| **OpenAI Agents SDK** | 20K | Python | 轻量级，官方支持 | OpenAI 生态 |
| **RalphLoop** | - | Shell | Claude Code 自动化 | 自动开发循环 |

### 2.2 框架分类

#### 🏗️ 编排型框架

**LangGraph**
- 图结构编排
- 状态持久化
- Human-in-the-loop
- 适合复杂状态管理

```python
from langgraph.graph import StateGraph, END

def agent_node(state):
    # Agent 逻辑
    return state

workflow = StateGraph(AgentState)
workflow.add_node("agent", agent_node)
workflow.add_edge("agent", END)
```

#### 👥 多 Agent 协作型

**AutoGen**
- Agent 对话
- 自动化工作流
- 代码执行
- 适合团队协作

```python
from autogen import AssistantAgent, UserProxyAgent

assistant = AssistantAgent("assistant")
user = UserProxyAgent("user")

user.initiate_chat(assistant, message="帮我写一个排序算法")
```

**CrewAI**
- 角色定义
- 任务分配
- 协作模式
- 适合角色扮演

```python
from crewai import Agent, Task, Crew

researcher = Agent(role="研究员", goal="收集信息")
writer = Agent(role="写作者", goal="撰写内容")

crew = Crew(agents=[researcher, writer], tasks=[...])
crew.kickoff()
```

#### 🔧 轻量级框架

**OpenAI Agents SDK (原 Swarm)**
- 轻量级
- Handoff 机制
- 工具调用
- 适合快速原型

```python
from agents import Agent, Runner

agent_a = Agent(name="Agent A", instructions="...")
agent_b = Agent(name="Agent B", instructions="...")

runner = Runner()
result = runner.run(agent_a, messages=[...])
```

---

## 三、12-Factor Agents 开发原则

> 来源: https://github.com/humanlayer/12-factor-agents

### 核心原则

| # | 原则 | 说明 |
|---|------|------|
| 1 | **自然语言转工具调用** | LLM 输出结构化 JSON 调用工具 |
| 2 | **掌控你的提示词** | 不要依赖框架默认 prompt |
| 3 | **掌控上下文窗口** | 主动管理上下文，而非被动填充 |
| 4 | **工具即结构化输出** | 工具调用本质是结构化输出 |
| 5 | **统一执行状态和业务状态** | 合并状态管理 |
| 6 | **简单 API 启动/暂停/恢复** | 支持长时间运行 |
| 7 | **通过工具联系人类** | Human-in-the-loop 作为工具 |
| 8 | **掌控控制流** | 不要让 LLM 完全控制流程 |
| 9 | **压缩错误到上下文** | 错误信息智能压缩 |
| 10 | **小而专注的 Agent** | 单一职责原则 |
| 11 | **从任何地方触发** | 支持多种触发方式 |
| 12 | **无状态 Reducer** | Agent 作为纯函数 |

### 关键洞察

> **好的 Agent 不是 "给 prompt + 工具包 + 循环"，而是主要由软件组成，在关键点插入 LLM。**

---

## 四、Agent 架构模式

### 4.1 单 Agent 模式

```
用户输入 → Agent → 工具执行 → 输出
           ↑         ↓
           └─ 循环 ──┘
```

**适用**: 简单任务，单一职责

### 4.2 多 Agent 协作模式

```
         ┌─ Agent A ─┐
用户 → 协调器 ─┼─ Agent B ─┼─ 结果聚合 → 输出
         └─ Agent C ─┘
```

**适用**: 复杂任务，需要分工

#### 协作方式

| 模式 | 说明 | 示例 |
|------|------|------|
| **串联** | 顺序执行 | 研究 → 写作 → 审核 |
| **并联** | 并行执行 | 多个研究员同时研究 |
| **层级** | 管理者-执行者 | 项目经理分配任务给开发者 |
| **对等** | 平等对话 | 两个专家讨论 |

### 4.3 图结构模式 (LangGraph)

```
     ┌─ Node A ─┐
Start ─┤         ├─ End
     └─ Node B ─┘
```

**特点**:
- 状态持久化
- 断点恢复
- 分支合并
- 循环结构

### 4.4 Handoff 模式 (OpenAI Agents SDK)

```
Agent A (接待) → Agent B (专家) → Agent C (审核) → 完成
```

**特点**:
- 轻量级切换
- 无全局状态
- 简单直观

---

## 五、Agent 核心能力

### 5.1 工具调用 (Tool Calling)

```python
# 工具定义
@tool
def search(query: str) -> str:
    """搜索互联网"""
    return search_engine(query)

@tool
def send_email(to: str, subject: str, body: str) -> str:
    """发送邮件"""
    return email_client.send(to, subject, body)

# Agent 使用工具
agent = Agent(
    name="助手",
    tools=[search, send_email]
)
```

### 5.2 记忆管理

| 类型 | 说明 | 实现 |
|------|------|------|
| **短期记忆** | 当前对话上下文 | Context Window |
| **长期记忆** | 跨会话持久化 | Vector DB |
| **工作记忆** | 任务执行状态 | State Graph |

### 5.3 Human-in-the-Loop

```python
# 审核节点
def human_review(state):
    # 等待人工确认
    approval = wait_for_human_input()
    if approval:
        return "approved"
    return "rejected"

workflow.add_node("review", human_review)
```

### 5.4 错误处理

```python
async def execute_with_retry(tool, max_retries=3):
    for i in range(max_retries):
        try:
            result = await tool.execute()
            return result
        except Exception as e:
            if i == max_retries - 1:
                # 压缩错误到上下文
                compacted_error = compact_error(e)
                context.append(compacted_error)
            else:
                # 重试
                await asyncio.sleep(2 ** i)
```

---

## 六、生产级 Agent 设计

### 6.1 状态管理

```python
# 统一状态
class AgentState(TypedDict):
    messages: List[Message]      # 对话历史
    tools: List[ToolCall]        # 工具调用记录
    business_data: Dict          # 业务数据
    execution_status: str        # 执行状态
```

### 6.2 持久化与恢复

```python
# 检查点
async def save_checkpoint(state, checkpoint_id):
    await db.save(checkpoint_id, state)

async def resume_from_checkpoint(checkpoint_id):
    state = await db.load(checkpoint_id)
    return state
```

### 6.3 监控与调试

```python
# 追踪
@trace
async def agent_step(state):
    logger.info(f"Step: {state.step}")
    logger.debug(f"Context size: {len(state.context)}")
    result = await llm.call(state.context)
    return result
```

---

## 七、游戏引擎开发中的 Agent 应用

### 7.1 适用场景

| 场景 | Agent 角色 | 收益 |
|------|-----------|------|
| **代码生成** | 代码生成 Agent | 加速样板代码编写 |
| **测试生成** | 测试 Agent | 自动化单元测试 |
| **文档生成** | 文档 Agent | API 文档自动更新 |
| **代码审查** | 审查 Agent | 辅助代码质量检查 |
| **重构辅助** | 重构 Agent | 批量重构建议 |

### 7.2 与 RHI 结合建议

```python
# RHI 文档生成 Agent
rhi_doc_agent = Agent(
    name="RHI 文档生成器",
    instructions="""
    你是一个游戏引擎 RHI 文档生成专家。
    根据头文件自动生成 API 文档。
    保持技术准确性。
    """,
    tools=[read_header, generate_doc, update_readme]
)

# 使用
result = agent.run("为 IDevice.h 生成 API 文档")
```

### 7.3 注意事项

1. **保护核心接口**
   - 在 Agent 规则中禁止修改 RHI 核心
   - 设置人工审核步骤

2. **渐进式采用**
   - 先在非核心模块测试
   - 验证后再扩展

3. **保持控制**
   - 掌控控制流
   - 不让 Agent 完全自主

---

## 八、框架选择建议

### 按需求选择

| 需求 | 推荐框架 | 理由 |
|------|---------|------|
| **快速原型** | OpenAI Agents SDK | 轻量，简单 |
| **复杂工作流** | LangGraph | 状态管理强 |
| **多 Agent 协作** | AutoGen / CrewAI | 协作模式成熟 |
| **企业级应用** | LangGraph + LangSmith | 生产就绪 |
| **游戏引擎开发** | 自建 + 参考原则 | 需要深度控制 |

### 生产级建议

> **不要完全依赖框架，将 Agent 概念模块化集成到现有产品中。**

---

## 九、相关资源

### 框架文档

- **LangChain**: https://docs.langchain.com
- **LangGraph**: https://docs.langchain.com/oss/python/langgraph
- **AutoGen**: https://microsoft.github.io/autogen
- **CrewAI**: https://docs.crewai.com
- **OpenAI Agents SDK**: https://openai.github.io/openai-agents-python
- **MetaGPT**: https://atoms.dev

### 学习资源

- **12-Factor Agents**: https://github.com/humanlayer/12-factor-agents
- **LangChain Academy**: https://academy.langchain.com
- **Building Effective Agents (Anthropic)**: https://www.anthropic.com/engineering/building-effective-agents

### 实践案例

- **Klarna**: 客服 Agent (LangGraph)
- **Replit**: 代码助手 Agent
- **Elastic**: 搜索 Agent

---

## 十、总结

### Agent 开发的本质

> **Agent = 软件工程 + LLM 决策**

核心不是 "给 prompt 和工具然后循环"，而是：
1. **主要是确定性软件**
2. **在关键点插入 LLM 决策**
3. **掌控控制流和状态**
4. **模块化，可组合**

### 关键趋势

1. **从重框架到轻组合** - 不再依赖单一框架
2. **从黑盒到白盒** - 掌控 prompt 和控制流
3. **从实验到生产** - 状态管理、持久化、监控
4. **从单一到协作** - 多 Agent 协作模式成熟

### 最佳实践

1. ✅ **小而专注** - 单一职责原则
2. ✅ **掌控控制流** - 不完全依赖 LLM
3. ✅ **状态持久化** - 支持长时间运行
4. ✅ **Human-in-the-loop** - 关键步骤人工确认
5. ✅ **错误智能处理** - 压缩错误，自动重试
6. ✅ **模块化集成** - 将 Agent 能力集成到现有产品

---

*本报告基于 2026 年 3 月的调研结果*
