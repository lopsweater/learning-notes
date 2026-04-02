---
name: tavily-search
description: 使用 Tavily API 进行网页搜索，用于技术调研、API 文档查询、问题解决方案查找等场景
globs:
  - "**/*"
---

# Tavily Search Skill

> **使用 Tavily API 进行网页搜索，获取高质量的技术文档和解决方案**

## 作用

提供网页搜索能力，帮助开发者:
- 查找技术文档和教程
- 搜索 API 参考文档
- 获取最新技术资讯
- 解决技术问题

## 触发时机

- 用户需要搜索技术资料时
- 用户提及"搜索"、"查找"、"调研"等关键词时
- 需要查找 API 文档时

## 配置

在使用前需要配置 Tavily API Key:

```yaml
# ~/.openclaw/config.yaml
tavily:
  api_key: your_api_key_here
```

## 使用方法

### 1. 基本搜索

```python
from tavily import TavilyClient

client = TavilyClient(api_key="your_api_key")
response = client.search("游戏引擎渲染技术")

for result in response['results']:
    print(f"标题: {result['title']}")
    print(f"链接: {result['url']}")
    print(f"摘要: {result['content'][:100]}...")
```

### 2. 高级搜索（包含答案）

```python
response = client.search(
    query="什么是 ECS 架构",
    search_depth="advanced",  # basic 或 advanced
    include_answer=True,
    include_raw_content=False,
    max_results=5
)

print(f"答案: {response['answer']}")
print(f"来源数量: {len(response['results'])}")
```

### 3. 搜索最新资讯

```python
import datetime

# 搜索最近的游戏引擎新闻
response = client.search(
    query="Unreal Engine 5 最新特性 2026",
    search_depth="advanced",
    include_answer=True,
    max_results=10
)

# 打印结果
for result in response['results']:
    print(f"标题: {result['title']}")
    print(f"发布时间: {result.get('published_date', '未知')}")
    print(f"链接: {result['url']}")
    print()
```

## 使用场景示例

### 场景 1: 技术调研

```
用户: 我想了解现代游戏引擎的渲染架构
Claude: [使用 tavily-search]
让我帮你搜索相关信息...

搜索结果:
1. Unreal Engine 5 渲染架构详解
   - 链接: https://docs.unrealengine.com/...
   - 摘要: 介绍了 UE5 的渲染架构，包括 Nanite、Lumen...

2. 游戏引擎渲染技术演进
   - 链接: https://developer.nvidia.com/...
   - 摘要: 分析了现代渲染技术的发展趋势...

建议查看 Unreal Engine 5 官方文档获取详细信息。
```

### 场景 2: API 查询
```
用户: Vulkan 的 RTTI 怎么使用？
Claude: [使用 tavily-search]
让我帮你搜索 Vulkan RTTI 相关文档...

搜索结果:
1. Vulkan RTTI 官方文档
   - 链接: https://vulkan.lunarg.com/...
   - 摘要: RTTI (Run-Time Type Information) 允许...

2. Vulkan RTTI 使用示例
   - 链接: https://github.com/...
   - 摘要: 提供了完整的 RTTI 使用示例...

根据官方文档，Vulkan RTTI 的使用方法是...
```

### 场景 3: 问题解决
```
用户: C++ 内存泄漏检测工具有哪些？
Claude: [使用 tavily-search]
让我帮你搜索相关的内存检测工具...

搜索结果:
1. Valgrind - 内存检测工具
   - 链接: https://valgrind.org/...
   - 摘要: Valgrind 是最常用的内存检测工具...

2. AddressSanitizer (ASan)
   - 链接: https://clang.llvm.org/...
   - 摘要: 编译器内置的内存检测工具...

3. Visual Studio 内存检测
   - 链接: https://docs.microsoft.com/...
   - 摘要: Windows 平台的内存检测工具...

推荐工具对比:
1. Valgrind - 功能强大，Linux 平台
2. ASan - 性能好，跨平台
3. Visual Studio - Windows 平台首选

建议使用 AddressSanitizer，因为性能开销小且跨平台。
```

## 搜索参数说明

### query (必需)
- 搜索关键词
- 支持中英文
- 示例: "游戏引擎架构", "Vulkan tutorial"

### search_depth (可选)
- `"basic"` - 基础搜索，快速返回
- `"advanced"` - 深度搜索，结果更准确
- 默认: `"basic"`

### include_answer (可选)
- `true` - 包含 AI 生成的答案
- `false` - 只返回搜索结果
- 默认: `false`

### include_raw_content (可选)
- `true` - 包含网页原始内容
- `false` - 只返回摘要
- 默认: `false`

### max_results (可选)
- 返回结果数量
- 范围: 1-10
- 默认: 5

## 与 Agent Browser 技能的区别

| 特性 | Tavily Search | Agent Browser |
|------|--------------|----------------|
| **用途** | 搜索引擎搜索 | 浏览器自动化 |
| **优势** | 快速、AI 优化 | 完整页面交互 |
| **劣势** | 无法交互 | 速度较慢 |
| **适用场景** | 信息检索 | 页面操作 |

**建议使用场景**:
- 快速查找信息 → Tavily Search
- 需要交互操作 → Agent Browser
- 需要截图 → Agent Browser

## 注意事项

1. **API 限制**: 免费版每月有请求限制
2. **结果验证**: AI 生成的答案可能需要验证
3. **语言支持**: 英文搜索结果通常更准确
4. **速度**: 通常 2-5 秒返回结果

## 获取 API Key

1. 访问 https://tavily.com
2. 注册账号（支持 Google/GitHub 登录）
3. 获取免费 API Key
4. 配置到 `~/.openclaw/config.yaml`

## 相关技能

- **engine-project-context** - 理解项目背景
- **engine-cpp-foundations** - 提供 C++ 相关知识
- **engine-rendering** - 提供渲染相关知识
