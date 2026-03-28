# Godot GitHub 高星项目调研报告

> 调研时间: 2026-03-23
> 关键词: Godot, GitHub, AI, MCP, Claude Code, 自动化开发

---

## 一、核心发现：AI + Godot 集成项目

### 🌟 godot-mcp (2,544 ⭐)

**仓库**: https://github.com/Coding-Solo/godot-mcp  
**语言**: JavaScript/TypeScript  
**标签**: `ai`, `godot`, `mcp`

**简介**: MCP (Model Context Protocol) 服务器，让 AI Agent 可以直接控制 Godot 游戏引擎。

**核心功能**:
- 启动 Godot 编辑器
- 运行 Godot 项目（调试模式）
- 捕获调试输出和错误信息
- 控制项目执行（启动/停止）
- 获取 Godot 版本信息
- 列出目录中的 Godot 项目
- 项目结构分析
- 场景管理：
  - 创建新场景（指定根节点类型）
  - 添加节点到现有场景
  - 加载精灵和纹理到 Sprite2D 节点
  - 导出 3D 场景为 MeshLibrary
  - 保存场景
- UID 管理（Godot 4.4+）

**快速集成 Claude Code**:
```bash
claude mcp add godot -- npx @coding-solo/godot-mcp
```

**意义**: 这是 **AI 辅助 Godot 开发的关键项目**，实现了 Claude 等 AI 与 Godot 的直接交互，形成完整的反馈闭环。

---

### 🌟 godogen (1,772 ⭐)

**仓库**: https://github.com/htdt/godogen  
**语言**: Python  
**标签**: `claude`, `claude-code`, `code-generation`, `godot4`

**简介**: Claude Code 技能集，从游戏描述直接生成完整的 Godot 4 项目。

**工作流程**:
```
游戏描述 → AI 设计架构 → 生成资源 → 编写代码 → 截图验证 → 修复问题 → 完整项目
```

**核心特性**:
- **两个 Claude Code Skills** - 一个规划，一个执行
- **Godot 4 输出** - 真实的场景树、脚本、资源组织
- **资源生成**:
  - Gemini 生成 2D 美术和纹理
  - Tripo3D 将图像转换为 3D 模型
- **GDScript 专家系统** - 自定义语言参考 + 850+ Godot 类的 API 文档
- **视觉 QA 闭环** - 从运行的游戏截图，Gemini Flash 分析问题
- **消费级硬件运行** - 任何有 Godot 和 Claude Code 的 PC

**使用方式**:
```bash
./publish.sh ~/my-game          # 创建新项目
cd ~/my-game
claude  # 启动 Claude Code，使用 /godogen skill
```

**Demo 视频**: https://youtu.be/eUz19GROIpY

---

## 二、Godot 引擎核心项目

| 项目 | Stars | 说明 |
|------|-------|------|
| **godotengine/godot** | 108,308 | Godot 引擎本体 |
| **godotengine/awesome-godot** | 9,581 | Godot 插件、脚本、附加组件精选列表 |
| **godotengine/godot-demo-projects** | 8,441 | 官方演示和模板项目 |
| **godotengine/godot-docs** | 5,076 | 官方文档 |

---

## 三、热门工具与应用

### 3.1 游戏开发工具

| 项目 | Stars | 语言 | 说明 |
|------|-------|------|------|
| **Pixelorama** | 9,288 | GDScript | 像素艺术编辑器（用 Godot 开发） |
| **Lorien** | 6,570 | GDScript | 无限画布白板应用 |
| **material-maker** | 5,229 | GDScript | 程序化纹理和 3D 模型绘制工具 |
| **dialogic** | 5,356 | GDScript | 对话系统，支持视觉小说、RPG |
| **Terrain3D** | 3,709 | C++ | 高性能可编辑地形系统 |

### 3.2 编辑器插件

| 项目 | Stars | 说明 |
|------|-------|------|
| **phantom-camera** | 3,224 | 类 Cinemachine 的相机系统 |
| **godot_heightmap_plugin** | 2,151 | 高度图地形插件 |
| **godot-vscode-plugin** | 1,997 | VSCode 开发工具 |
| **SmartShape2D** | 1,666 | 2D 地形工具 |
| **cyclopsLevelBuilder** | 1,467 | 关卡搭建工具 |
| **godot-aseprite-wizard** | 1,242 | Aseprite 动画导入向导 |
| **godot_spatial_gardener** | 1,240 | 3D 表面植物/道具绘制 |
| **ShaderV** | 1,140 | 可视化 Shader 插件 |

### 3.3 GDExtension 扩展

| 项目 | Stars | 说明 |
|------|-------|------|
| **godot-jolt** | 2,500 | Jolt 物理引擎集成 |
| **godot-rust/gdext** | 4,555 | Rust 绑定 (Godot 4) |
| **godot-sqlite** | 1,322 | SQLite 数据库支持 |
| **godot_debug_draw_3d** | 962 | 3D 调试绘制 |
| **godot-git-plugin** | 878 | Git 版本控制集成 |
| **fmod-gdextension** | 813 | FMOD 音频引擎集成 |

---

## 四、测试框架

| 项目 | Stars | 说明 |
|------|-------|------|
| **Gut** | 2,437 | Godot 单元测试工具（推荐） |
| **gdUnit4** | 987 | Godot 4 单元测试框架，支持 GDScript 和 C# |
| **wat** | 313 | Godot 测试插件 |

**Gut 快速使用**:
```gdscript
# test_player.gd
extends GutTest

func test_initial_health() -> void:
    var player = Player.new()
    assert_eq(player.health, 100)
```

**Headless 运行测试**:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

---

## 五、项目模板与启动器

| 项目 | Stars | 说明 |
|------|-------|------|
| **godot-FirstPersonStarter** | 931 | FPS 控制器模板 |
| **indie-blueprint** | 394 | 综合项目模板，包含最佳实践 |
| **TakinGodotTemplate** | 439 | GDScript 项目模板 |
| **godot-manager** | 400 | 项目、版本、插件管理器 |
| **GodotGame (C#)** | 377 | C# 游戏模板，带测试和 CI/CD |
| **GameDemo (C#)** | 543 | 完整的 3D 第三人称游戏演示 |

---

## 六、与 OpenClaw / Claude Code 相关的集成方案

### 6.1 godot-mcp 集成

**安装到 Claude Code**:
```bash
claude mcp add godot -- npx @coding-solo/godot-mcp
```

**可用工具**:
- `launch_editor` - 启动 Godot 编辑器
- `run_project` - 运行项目
- `stop_project` - 停止项目
- `get_debug_output` - 获取调试输出
- `create_scene` - 创建场景
- `add_node` - 添加节点
- `save_scene` - 保存场景

### 6.2 godogen 集成

**安装 Skills**:
```bash
git clone https://github.com/htdt/godogen
cd godogen
./publish.sh ~/your-game-project
```

**使用**:
在 Claude Code 中输入游戏描述，`/godogen` skill 会自动：
1. 分析需求，设计架构
2. 生成资源（美术、模型）
3. 编写 GDScript 代码
4. 运行项目截图
5. AI 视觉分析，修复问题

### 6.3 OpenClaw 集成建议

基于以上发现，建议 OpenClaw 集成：

```yaml
# ~/.openclaw/workspace/skills/godot-dev/SKILL.md
---
name: godot-dev
description: "Godot 游戏引擎开发。集成 godot-mcp，支持场景创建、代码生成、测试运行。"
dependencies:
  - godot-mcp
---

# Godot Dev Skill

## 集成 godot-mcp

1. 安装 MCP 服务器:
   npm install -g @coding-solo/godot-mcp

2. 配置环境变量:
   GODOT_PATH=/path/to/godot

## 命令

### /godot-new <项目名>
创建新 Godot 项目

### /godot-run
运行当前项目

### /godot-test
运行 Gut 测试套件

### /godot-scene <场景名> <节点类型>
创建新场景
```

---

## 七、总结

### 最具价值的 AI 集成项目

| 优先级 | 项目 | 用途 |
|--------|------|------|
| ⭐⭐⭐ | **godot-mcp** | AI 控制 Godot 的基础设施 |
| ⭐⭐⭐ | **godogen** | 完整的 AI 游戏生成流水线 |
| ⭐⭐ | **Gut** | 单元测试框架（AI 验证必备） |
| ⭐⭐ | **awesome-godot** | 资源和插件索引 |

### 推荐开发流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Godot + AI 开发流程                           │
└─────────────────────────────────────────────────────────────────┘

1. 需求描述
   │
   ▼
2. Claude Code + godogen Skill
   │  ├─ 设计架构
   │  ├─ 生成资源
   │  └─ 编写代码
   ▼
3. godot-mcp 验证
   │  ├─ 运行项目
   │  ├─ 捕获输出
   │  └─ 截图分析
   ▼
4. Gut 测试
   │
   ▼
5. Git 提交
```

---

## 附录：快速参考

### Godot CLI 常用命令

```bash
# 验证脚本
godot --headless --check-only --script res://player.gd

# 运行测试
godot --headless --path . -s addons/gut/gut_cmdln.gd

# 导出项目
godot --headless --export-release "Windows Desktop" build/game.exe
```

### 相关链接

- [godot-mcp GitHub](https://github.com/Coding-Solo/godot-mcp)
- [godogen GitHub](https://github.com/htdt/godogen)
- [Gut 测试框架](https://github.com/bitwes/Gut)
- [awesome-godot](https://github.com/godotengine/awesome-godot)
- [Godot 官方文档](https://docs.godotengine.org/)

---

*本报告基于 GitHub API 实时数据整理*
