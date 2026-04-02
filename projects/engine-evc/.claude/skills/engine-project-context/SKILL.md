---
name: engine-project-context
description: 项目上下文技能 - 捕获项目模块、目标平台、编码规范等上下文信息，所有其他引擎技能的基础
globs:
  - "**/*"
---

# Engine Project Context

> **这是所有引擎技能的基础技能，其他技能都会读取此技能捕获的上下文信息**

## 作用

此技能帮助 Claude Code 理解你的游戏引擎项目的整体结构、模块划分、目标平台和团队规范。它是其他所有技能的前置技能。

## 触发时机

- 项目首次被 Claude Code 分析时
- 用户提及"项目结构"、"模块"、"架构"等关键词时
- 其他技能需要项目上下文时

## 工作流程

### 第一步：识别项目类型

检查项目特征，判断引擎类型：

```
项目特征识别：
- CMakeLists.txt + Source/Runtime/ → 自研引擎
- *.uproject + Source/ → Unreal Engine
- *.sln + Assets/Scripts/ → Unity
- Cargo.toml + src/ → Rust 引擎
```

### 第二步：分析项目结构

扫描项目目录，提取关键信息：

#### 自研引擎结构示例
```
MyEngine/
├── Source/
│   ├── Runtime/           # 运行时模块
│   │   ├── Core/         # 核心模块
│   │   ├── Render/       # 渲染模块
│   │   ├── Engine/       # 引擎模块
│   │   └── ...
│   └── Editor/           # 编辑器模块
├── CMakeLists.txt        # 构建配置
└── docs/                 # 文档
```

#### Unreal Engine 结构示例
```
MyProject/
├── Source/
│   ├── MyProject/       # 项目模块
│   └── MyProjectEditor/ # 编辑器模块
├── Content/             # 资源
├── Config/              # 配置
└── MyProject.uproject  # 项目文件
```

### 第三步：生成项目上下文文件

创建 `.claude/engine-context.md` 文件：

```markdown
# 项目上下文

## 基本信息
- 项目名称: MyEngine
- 引擎类型: 自研引擎 / Unreal Engine 5.x / Unity
- 目标平台: Windows / Linux / macOS / Console
- 语言版本: C++20 / C++17

## 模块结构
### Runtime 模块
- Core: 核心系统（内存、容器、字符串）
- Render: 渲染系统（RHI、材质、后处理）
- Engine: 引擎系统（世界、实体、组件）

### Editor 模块
- EditorCore: 编辑器核心
- AssetBrowser: 资源浏览器

## 编码规范
- 命名约定: PascalCase 类型，camelCase 变量
- 文件组织: 每个 Class 一个 .h/.cpp 文件
- 注释风格: Doxygen 格式

## 技术栈
- 构建系统: CMake / UnrealBuildTool
- 测试框架: Google Test / Unreal Automation
- 文档工具: Doxygen
```

## 与其他技能的关系

```
                      engine-project-context
                              │
        ┌──────────┬──────────┼──────────┬──────────┐
        ▼          ▼          ▼          ▼          ▼
   cpp-foundations  architecture  rendering  tools  testing
        │          │          │          │          │
        └──────────┴──────────┴──────────┴──────────┘
                              │
                     所有技能都读取项目上下文
```

## 使用示例

### 示例 1：首次分析项目

```
用户: 帮我分析这个项目
Claude: [自动触发 engine-project-context]
我正在分析你的项目结构...

项目类型: 自研引擎
主要模块: Core, Render, Engine, Editor
目标平台: Windows, Linux
语言标准: C++20

已生成项目上下文文件: .claude/engine-context.md
```

### 示例 2：其他技能依赖上下文

```
用户: 帮我实现一个 ECS 系统
Claude: [读取 engine-project-context]
根据你的项目上下文:
- 目标平台: Windows, Linux
- 语言标准: C++20
- 模块位置: Source/Runtime/Engine/

我建议在 Source/Runtime/Engine/ECS/ 下实现 ECS 系统...
```

## 自动化任务

此技能会自动执行以下任务：

1. **扫描项目目录结构**
   - 识别源码目录（Source/, src/）
   - 识别资源目录（Content/, Assets/）
   - 识别配置目录（Config/, config/）

2. **提取构建信息**
   - 读取 CMakeLists.txt / Build.cs
   - 识别依赖库
   - 识别编译选项

3. **分析代码规范**
   - 检查命名约定
   - 检查文件组织
   - 检查注释风格

4. **生成上下文文件**
   - 创建 `.claude/engine-context.md`
   - 更新项目信息

## 注意事项

- 项目上下文文件应定期更新
- 重大架构变更后应重新生成
- 上下文文件可以手动编辑调整
- 不应将敏感信息写入上下文文件

## 相关技能

- **engine-cpp-foundations** - 读取语言版本和编码规范
- **engine-architecture** - 读取模块结构
- **engine-rendering** - 读取渲染模块配置
- **engine-tools** - 读取编辑器模块配置
- **engine-testing** - 读取测试框架配置
