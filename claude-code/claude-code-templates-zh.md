# Claude Code 组件模板手册

> 快速复制使用的 Command / Agent / Skill 模板

---

## 一、Command 模板

### 基础模板

```markdown
---
name: 你的命令名
description: 命令描述，说明何时使用此命令
argument-hint: [参数提示]
allowed-tools: Read, Write, Edit, Bash
model: sonnet
---

# 命令标题

简短描述命令的作用。

## 工作流程

1. **步骤一**
   - 具体操作说明

2. **步骤二**
   - 具体操作说明

3. **步骤三**
   - 具体操作说明

## 输出格式

描述输出的格式要求...

## 注意事项

- 注意点1
- 注意点2
```

### 代码审查模板

```markdown
---
name: code-review
description: 执行代码审查，检查代码质量、安全性和最佳实践
argument-hint: [文件路径]
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
---

# 代码审查命令

你是一个专业的代码审查助手。

## 工作流程

1. **获取目标文件**
   - 如果提供了文件路径，使用 Read 读取
   - 如果未提供，使用 `git diff` 获取变更

2. **审查维度**
   - 代码质量和可读性
   - 安全漏洞（SQL注入、XSS、敏感信息泄露）
   - 性能问题
   - 最佳实践违反

3. **生成报告**

## 输出格式

```markdown
## 代码审查报告

### 文件: [文件名]

| 级别 | 行号 | 问题 | 建议 |
|------|------|------|------|
| 🔴 严重 | 42 | 问题描述 | 修改建议 |
| 🟡 警告 | 15 | 问题描述 | 修改建议 |
| 🟢 建议 | 8 | 问题描述 | 修改建议 |

### 优点
- ...

### 总体评分: A/B/C/D/F
```

## 注意事项

- 提供具体的行号
- 区分严重性级别
- 给出可操作的修改建议
```

### 计划生成模板

```markdown
---
name: plan
description: 生成详细的实现计划，分解任务步骤
argument-hint: [任务描述]
allowed-tools: Read, Glob, Grep
model: sonnet
---

# 计划生成命令

生成详细的实现计划。

## 工作流程

1. **理解需求**
   - 分析用户描述的任务
   - 识别关键需求

2. **探索代码库**
   - 搜索相关文件
   - 了解现有实现

3. **生成计划**

## 输出格式

```markdown
## 实现计划: [任务名称]

### 背景
简要描述任务背景...

### 目标
- 目标1
- 目标2

### 实现步骤

#### 阶段1: [阶段名称]
- [ ] 步骤1.1: 描述
- [ ] 步骤1.2: 描述

#### 阶段2: [阶段名称]
- [ ] 步骤2.1: 描述
- [ ] 步骤2.2: 描述

### 风险评估
| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| ... | ... | ... |

### 预计时间
- 阶段1: X小时
- 阶段2: X小时
```
```

---

## 二、Agent 模板

### 基础模板

```markdown
---
name: 你的代理名
description: PROACTIVELY 何时使用此代理。描述触发条件。
tools: Read, Write, Edit, Bash
model: sonnet
color: blue
maxTurns: 10
permissionMode: acceptEdits
memory: project
---

# 代理标题

你是一个专业的 [角色描述]。

## 你的任务

执行 [具体任务] 工作流：

1. **准备阶段**
   - 具体操作

2. **执行阶段**
   - 具体操作

3. **报告阶段**
   - 具体操作

## 输出格式

描述输出格式...

## 记忆

将重要信息保存到 memory 供后续使用。
```

### 测试代理模板

```markdown
---
name: test-runner
description: PROACTIVELY 运行测试并分析结果。当用户需要运行测试、检查测试覆盖率、或调试测试失败时自动激活。
tools: Read, Write, Edit, Bash
model: sonnet
color: green
maxTurns: 20
permissionMode: acceptEdits
memory: project
---

# 测试运行代理

你是一个专业的测试运行和调试代理。

## 你的任务

1. **运行测试**
   - 执行测试命令
   - 捕获输出

2. **分析结果**
   - 解析测试输出
   - 识别失败的测试
   - 分析失败原因

3. **修复问题**
   - 定位问题代码
   - 提出修复方案
   - 验证修复

## 输出格式

```markdown
## 测试报告

### 测试结果概览
- 通过: X
- 失败: Y
- 跳过: Z

### 失败详情

| 测试名 | 文件 | 行号 | 错误信息 |
|--------|------|------|----------|
| ... | ... | ... | ... |

### 修复建议
...
```

## 记忆

记录常见问题和解决方案。
```

### 代码探索代理模板

```markdown
---
name: code-explorer
description: PROACTIVELY 探索代码库结构。当用户需要了解代码架构、查找特定实现、或分析代码依赖时自动激活。
tools: Read, Glob, Grep
model: haiku
color: cyan
maxTurns: 15
---

# 代码探索代理

快速探索和理解代码库。

## 你的任务

1. **理解目标**
   - 理解用户想了解什么

2. **搜索代码**
   - 使用 Glob 查找文件
   - 使用 Grep 搜索内容
   - 使用 Read 读取关键文件

3. **生成报告**

## 输出格式

```markdown
## 代码探索报告

### 主题: [探索主题]

### 相关文件
- `path/to/file1` - 简要描述
- `path/to/file2` - 简要描述

### 关键发现
1. ...
2. ...

### 代码结构
描述代码组织方式...

### 建议深入的方向
- ...
```
```

---

## 三、Skill 模板

### 基础目录结构

```
.claude/skills/
└── skill-name/
    ├── SKILL.md           # 必需
    ├── scripts/           # 可选：脚本
    │   └── helper.sh
    ├── references/        # 可选：参考文档
    │   └── guide.md
    └── assets/            # 可选：资源文件
        └── template.json
```

### 基础模板

```markdown
---
name: skill-name
description: 技能描述。明确说明何时使用此技能。描述要具体，让 Claude 知道何时激活。
paths: "**/*.ext"          # 自动激活的文件模式
---

# 技能标题

简短描述技能的作用。

## 何时使用

- 使用场景1
- 使用场景2
- 使用场景3

## 核心原则

### 原则1: 名称

```language
// ✅ 正确做法
代码示例

// ❌ 错误做法
代码示例
```

### 原则2: 名称

描述...

## 输出规范

生成的输出必须：

1. 规范1
2. 规范2
3. 规范3

## 示例

**输入**: 用户请求描述

**输出**:

```language
代码或输出示例
```
```

### C++ 开发技能模板

```markdown
---
name: cpp-development
description: 生成符合 C++ Core Guidelines 的高质量 C++ 代码。当用户编写 C++ 代码、创建类、实现函数、重构代码或需要 C++ 最佳实践指导时使用此技能。涉及 C++ 开发即激活。
paths: "**/*.cpp,**/*.h,**/*.hpp,**/*.cxx"
---

# C++ 开发技能

生成符合现代 C++ 标准的高质量代码。

## 何时使用

- 编写新的 C++ 代码
- 重构现有代码
- 代码审查
- 实现 C++ 设计模式
- 性能优化

## 核心原则

### 1. RAII - 资源获取即初始化

```cpp
// ✅ 正确: 使用智能指针
auto widget = std::make_unique<Widget>();
auto cache = std::make_shared<Cache>(1024);

// ❌ 错误: 裸指针需要手动管理
Widget* widget = new Widget();  // 避免！
```

### 2. 不可变优先

```cpp
// ✅ 正确: 默认 const
const int max_retries = 3;
const std::string name = "widget";

// ❌ 错误: 不必要的可变
int max_retries = 3;
```

### 3. 强类型

```cpp
// ✅ 正确: enum class
enum class Color { red, green, blue };

// ❌ 错误: 弱类型 enum
enum Color { RED, GREEN, BLUE };
```

### 4. 错误处理

```cpp
// ✅ 正确: 使用异常和 Result
std::expected<Data, Error> parse(std::string_view input);

// 或使用异常
class ParseError : public std::runtime_error {
    using std::runtime_error::runtime_error;
};

Data parse(std::string_view input);  // 抛出 ParseError
```

## 代码规范

### 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 命名空间 | snake_case | `my_project::core` |
| 类/结构体 | PascalCase | `ThreadPool` |
| 函数 | snake_case | `get_data()` |
| 变量 | snake_case | `user_name` |
| 常量 | snake_case | `max_buffer_size` |
| 成员变量 | snake_case_ | `data_` |
| 宏 | UPPER_CASE | `MAX_SIZE` |

### 文件组织

```cpp
// widget.h
#ifndef PROJECT_WIDGET_H
#define PROJECT_WIDGET_H

#include <string>
#include <memory>

namespace project {

class Widget {
public:
    explicit Widget(std::string name);
    
    // 接口函数
    const std::string& name() const { return name_; }
    void process();
    
private:
    std::string name_;
};

}  // namespace project

#endif  // PROJECT_WIDGET_H
```

## 输出规范

生成的代码必须：

1. **符合 C++20 标准**
2. **使用 constexpr 编译期计算**（适用时）
3. **包含适当的错误处理**
4. **提供完整的注释和文档**
5. **遵循 RAII 原则**
6. **避免裸指针和手动内存管理**

## 常用模式

### 单例模式

```cpp
class Singleton {
public:
    static Singleton& instance() {
        static Singleton instance;
        return instance;
    }
    
    Singleton(const Singleton&) = delete;
    Singleton& operator=(const Singleton&) = delete;
    
private:
    Singleton() = default;
};
```

### 工厂模式

```cpp
class Product {
public:
    virtual ~Product() = default;
    virtual void use() = 0;
};

class ProductFactory {
public:
    static std::unique_ptr<Product> create(std::string_view type);
};
```

### 观察者模式

```cpp
class Observer {
public:
    virtual ~Observer() = default;
    virtual void on_notify(const Event& event) = 0;
};

class Subject {
public:
    void attach(Observer* observer);
    void detach(Observer* observer);
    void notify(const Event& event);
};
```
```

### Python 开发技能模板

```markdown
---
name: python-development
description: 生成符合 PEP 8 和 Python 最佳实践的高质量 Python 代码。涉及 Python 开发即激活。
paths: "**/*.py"
---

# Python 开发技能

生成符合现代 Python 最佳实践的高质量代码。

## 何时使用

- 编写新的 Python 代码
- 重构现有代码
- 代码审查
- 实现 Python 设计模式

## 核心原则

### 1. 类型注解

```python
# ✅ 正确: 使用类型注解
from typing import Optional, List

def fetch_user(user_id: int) -> Optional[User]:
    ...

def get_items() -> List[Item]:
    ...
```

### 2. 数据类

```python
# ✅ 正确: 使用 dataclass
from dataclasses import dataclass

@dataclass
class User:
    name: str
    email: str
    age: int = 0
```

### 3. 上下文管理器

```python
# ✅ 正确: 使用 with 语句
with open('file.txt', 'r') as f:
    content = f.read()

# 自定义上下文管理器
from contextlib import contextmanager

@contextmanager
def timer():
    import time
    start = time.time()
    yield
    print(f"耗时: {time.time() - start}秒")
```

## 代码规范

### 命名约定

| 类型 | 约定 | 示例 |
|------|------|------|
| 模块 | snake_case | `user_service.py` |
| 类 | PascalCase | `UserService` |
| 函数 | snake_case | `get_user()` |
| 变量 | snake_case | `user_name` |
| 常量 | UPPER_SNAKE_CASE | `MAX_SIZE` |

### 文档字符串

```python
def calculate_similarity(a: list[float], b: list[float]) -> float:
    """计算两个向量的余弦相似度。
    
    Args:
        a: 第一个向量
        b: 第二个向量
        
    Returns:
        余弦相似度，范围 [-1, 1]
        
    Raises:
        ValueError: 如果向量长度不匹配
    """
    ...
```
```

### 游戏引擎开发技能模板

```markdown
---
name: game-engine-dev
description: 游戏引擎开发最佳实践。当用户开发游戏引擎、实现渲染系统、物理系统、或 ECS 架构时使用此技能。
paths: "**/*.cpp,**/*.h,**/*.hpp,**/engine/**"
---

# 游戏引擎开发技能

提供游戏引擎开发的专业指导和最佳实践。

## 何时使用

- 开发游戏引擎核心模块
- 实现渲染系统 (RHI, Renderer)
- 实现物理系统
- 实现 ECS 架构
- 性能优化

## 核心原则

### 1. 数据导向设计 (DOD)

```cpp
// ✅ 正确: SoA 布局，缓存友好
struct TransformSystem {
    std::vector<Vec3> positions;
    std::vector<Quaternion> rotations;
    std::vector<Vec3> scales;
    
    void update(float dt);  // 批量处理
};

// ❌ 错误: AoS 布局，缓存不友好
struct Entity {
    Vec3 position;
    Quaternion rotation;
    Vec3 scale;
};
std::vector<Entity> entities;
```

### 2. 组件化架构 (ECS)

```cpp
// Entity - 仅 ID
using Entity = uint64_t;

// Component - 纯数据
struct Transform {
    Vec3 position;
    Quaternion rotation;
    Vec3 scale;
};

struct Mesh {
    MeshHandle mesh;
    MaterialHandle material;
};

// System - 处理逻辑
class RenderSystem {
public:
    void update(ECSWorld& world, RenderContext& ctx) {
        world.each<Transform, Mesh>([&](auto& transform, auto& mesh) {
            // 渲染逻辑
        });
    }
};
```

### 3. 渲染抽象 (RHI)

```cpp
// RHI 接口层
class RHIDevice {
public:
    virtual ~RHIDevice() = default;
    
    virtual RHIBufferHandle create_buffer(const BufferDesc& desc) = 0;
    virtual RHITextureHandle create_texture(const TextureDesc& desc) = 0;
    virtual void draw(const DrawCommand& cmd) = 0;
};

// 具体实现
class D3D12Device : public RHIDevice { ... };
class VulkanDevice : public RHIDevice { ... };
```

### 4. 资源管理

```cpp
// 资源句柄
template<typename T>
class Handle {
public:
    Handle() : index_(INVALID_INDEX) {}
    explicit Handle(uint32_t index) : index_(index) {}
    
    bool is_valid() const { return index_ != INVALID_INDEX; }
    uint32_t index() const { return index_; }
    
private:
    static constexpr uint32_t INVALID_INDEX = ~0u;
    uint32_t index_;
};

// 资源池
template<typename T, size_t Capacity>
class ResourcePool {
public:
    Handle<T> allocate();
    void deallocate(Handle<T> handle);
    T& get(Handle<T> handle);
    const T& get(Handle<T> handle) const;
    
private:
    std::array<T, Capacity> resources_;
    std::array<uint32_t, Capacity> generations_;
    std::vector<uint32_t> free_list_;
};
```

## 性能优化

### 内存分配

- 使用对象池避免频繁分配
- 使用线性分配器处理帧数据
- 避免渲染循环中的内存分配

### 多线程

- 使用 Job System 并行处理
- 数据分区减少锁竞争
- 主线程只负责渲染提交

### SIMD

```cpp
#include <immintrin.h>

// SIMD 优化的向量运算
void transform_positions_simd(
    const Vec3* positions,
    const Mat4& matrix,
    Vec3* out,
    size_t count
);
```

## 输出规范

生成的游戏引擎代码必须：

1. **高效的数据布局** - 考虑缓存一致性
2. **清晰的模块边界** - RHI、Renderer、Scene 分离
3. **完善的资源管理** - 使用句柄而非裸指针
4. **可扩展的架构** - 支持插件和脚本
5. **详细的注释** - 解释设计决策
```

---

## 四、快速选择指南

| 需求 | 使用 |
|------|------|
| 用户通过 `/命令名` 调用 | Command |
| 需要隔离执行的任务 | Agent |
| 可复用的知识模块 | Skill |
| 复杂工作流 | Command → Agent → Skill |

## 字段速查

### 通用字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `name` | string | 名称标识 |
| `description` | string | 描述，决定触发时机 |
| `model` | string | haiku/sonnet/opus |
| `effort` | string | low/medium/high/max |
| `allowed-tools` | string | 免确认的工具 |
| `paths` | string | 自动激活的文件 glob |

### Agent 专用字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tools` | string | 工具白名单 |
| `maxTurns` | int | 最大轮次 |
| `permissionMode` | string | 权限模式 |
| `memory` | string | memory/project/local |
| `skills` | list | 预加载技能 |
| `color` | string | 显示颜色 |

---

## 参考资源

- [Claude Code 官方文档](https://code.claude.com/docs)
- [anthropics/skills 仓库](https://github.com/anthropics/skills)
- [claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)
