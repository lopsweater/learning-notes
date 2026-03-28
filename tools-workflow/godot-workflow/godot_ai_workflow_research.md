# Godot 自动开发工作流调研报告

> 调研时间: 2026-03-23
> 关键词: Godot, Claude Code, OpenClaw, AI, LLM, 自动化

---

## 一、概述

Godot 引擎因其开源、轻量、纯文本资产格式等特点，成为 AI 辅助游戏开发的理想选择。本报告调研 Godot 与 OpenClaw、Claude Code 等 AI 工具的集成方案。

---

## 二、Godot 引擎特性分析

### 2.1 AI 友好特性

| 特性 | 说明 | AI 辅助优势 |
|------|------|-------------|
| **纯文本格式** | `.tscn`、`.tres`、`.gd` 均为文本 | AI 可直接读取、编辑、生成 |
| **Headless 模式** | `godot --headless` 无头运行 | CI/CD 自动化测试验证 |
| **GDScript** | 类 Python 脚本语言 | LLM 生成效果优秀 |
| **内置 LSP** | Language Server Protocol | IDE 集成、智能提示 |
| **GDExtension** | C++/Rust 扩展系统 | 可扩展 AI 工具链 |
| **资源序列化** | 可读性强的文本格式 | 场景结构可程序化生成 |

### 2.2 GDScript 特点

```gdscript
# GDScript 示例 - 语法简洁，AI 生成效果好
extends Node3D

@export var speed: float = 5.0
@export var target: Node3D

func _process(delta: float) -> void:
    if target:
        var direction = (target.global_position - global_position).normalized()
        global_position += direction * speed * delta
```

**LLM 友好原因**:
- 类 Python 语法，训练数据丰富
- 静态类型支持（类型提示）
- 丰富的内置类和文档
- 社区代码量大，上下文充足

---

## 三、Claude Code + Godot 集成方案

### 3.1 项目配置

在 Godot 项目根目录创建 `CLAUDE.md`:

```markdown
# Godot 项目配置

## 项目信息
- 引擎版本: Godot 4.3
- 脚本语言: GDScript
- 渲染器: Forward+

## 编码规范

### GDScript 规范
- 使用静态类型: `var health: int = 100`
- 函数参数和返回值标注类型
- 使用 @export 暴露可配置属性
- 遵循 GDScript 风格指南

### 文件组织
```
project/
├── scenes/          # 场景文件 (.tscn)
├── scripts/         # GDScript 文件 (.gd)
├── assets/          # 资源文件
│   ├── sprites/
│   ├── sounds/
│   └── models/
└── addons/          # 插件目录
```

## 开发工作流

### 创建新场景
1. 先创建场景文件 (.tscn)
2. 编写对应的脚本 (.gd)
3. 在编辑器中验证

### 代码修改流程
1. 先展示修改内容
2. 等待确认
3. 应用修改
4. 运行 `godot --headless --script res://tests/test_runner.gd` 验证

## 禁止操作
- 不要修改 autoload 配置，除非明确要求
- 不要删除场景中的 root node
- 不要修改项目设置中的渲染器配置
```

### 3.2 Godot CLI 命令

```bash
# 验证脚本语法
godot --headless --check-only --script res://scripts/player.gd

# 运行测试场景
godot --headless --path . --script res://tests/test_runner.gd

# 导出项目
godot --headless --export-release "Windows Desktop" build/game.exe

# 生成文档
godot --headless --doctool . --no-docbase
```

### 3.3 自动化测试集成

创建测试运行器脚本 `tests/test_runner.gd`:

```gdscript
extends SceneTree

func _init() -> void:
    var test_scripts := [
        "res://tests/test_player.gd",
        "res://tests/test_enemy.gd",
        "res://tests/test_inventory.gd",
    ]
    
    var passed := 0
    var failed := 0
    
    for script_path in test_scripts:
        var script = load(script_path).new()
        if script.has_method("run_tests"):
            var result = script.run_tests()
            passed += result.passed
            failed += result.failed
    
    print("Tests passed: %d, failed: %d" % [passed, failed])
    
    if failed > 0:
        quit(1)
    else:
        quit(0)
```

### 3.4 推荐的 Claude Code 工作流

```
┌─────────────────────────────────────────────────────────────┐
│                   Godot + Claude Code 工作流                 │
└─────────────────────────────────────────────────────────────┘

1. 需求分析
   │
   ▼
2. Claude Code 设计方案
   │
   ├── 生成场景结构 (.tscn)
   ├── 生成脚本代码 (.gd)
   └── 生成测试用例
   │
   ▼
3. 代码审查 (用户确认)
   │
   ▼
4. 应用修改
   │
   ▼
5. 自动验证
   ├── godot --headless --check-only
   └── 运行测试脚本
   │
   ▼
6. 反馈修正 (如需要)
   │
   ▼
7. Git 提交
```

---

## 四、OpenClaw + Godot 集成方案

### 4.1 Skill 设计

创建 Godot 专用 Skill `godot-dev`:

```yaml
# ~/.openclaw/workspace/skills/godot-dev/SKILL.md
---
name: godot-dev
description: "Godot 游戏引擎开发辅助。支持场景创建、GDScript 生成、测试运行、项目导出。"
---

# Godot Dev Skill

## 能力

- 场景文件 (.tscn) 解析和生成
- GDScript 代码生成和修改
- Headless 模式测试运行
- 项目导出配置

## 命令

### 验证脚本
```bash
godot --headless --check-only --script <path>
```

### 运行测试
```bash
godot --headless --path <project> --script res://tests/test_runner.gd
```

### 生成场景
解析 .tscn 文件结构，辅助 AI 生成场景。
```

### 4.2 自动化命令

在 OpenClaw 中注册 Godot 相关命令:

```markdown
# /godot-check

验证项目中的 GDScript 语法。

## 执行步骤
1. 扫描所有 .gd 文件
2. 对每个文件执行 `godot --headless --check-only`
3. 汇总错误报告

---

# /godot-test

运行项目测试套件。

## 执行步骤
1. 检查测试目录是否存在
2. 执行 `godot --headless --script res://tests/test_runner.gd`
3. 解析测试结果
4. 生成报告

---

# /godot-scene <场景名> <节点类型>

快速创建新场景。

## 示例
/godot-scene Player CharacterBody3D
```

### 4.3 CLAUDE.md + OpenClaw 协同

```markdown
# Godot 项目 - OpenClaw 配置

## 自动化检查

每次代码修改后:
1. 运行 `/godot-check` 验证语法
2. 运行 `/godot-test` 执行测试
3. 报告结果

## Git 提交规则

提交前必须:
- [ ] 所有测试通过
- [ ] 无语法错误
- [ ] 更新 CHANGELOG.md
```

---

## 五、现有工具和项目调研

### 5.1 AI 辅助 Godot 开发工具

| 工具 | 类型 | 说明 |
|------|------|------|
| **GPT-4 GDScript** | 代码生成 | 可直接生成 Godot 4.x 代码 |
| **Claude Godot** | 代码生成 | 优秀的 GDScript 生成质量 |
| **GitHub Copilot** | IDE 集成 | VSCode + Godot 扩展支持 |
| **Godot LSP** | IDE 支持 | 内置语言服务器 |
| **GUT** | 测试框架 | Godot Unit Testing，支持 headless |

### 5.2 GUT (Godot Unit Testing)

```gdscript
# test_player.gd
extends GutTest

var player: Player

func before_each() -> void:
    player = Player.new()
    add_child(player)

func test_initial_health() -> void:
    assert_eq(player.health, 100, "Player should start with 100 health")

func test_take_damage() -> void:
    player.take_damage(20)
    assert_eq(player.health, 80, "Health should be reduced by damage")

func test_death() -> void:
    player.take_damage(100)
    assert_true(player.is_dead, "Player should be dead after fatal damage")
```

**Headless 运行**:
```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd
```

### 5.3 相关 GitHub 项目

| 项目 | 链接 | 说明 |
|------|------|------|
| godot-gdscript-toolkit | GitHub | GDScript 静态分析工具 |
| GUT | bitwes/Gut | 单元测试框架 |
| godot-vscode-plugin | godotengine/godot-vscode-plugin | VSCode 集成 |
| gdquest/godot-open-source | GDQuest | 教程和工具 |

---

## 六、推荐工作流设计

### 6.1 完整开发流程

```
┌─────────────────────────────────────────────────────────────────┐
│                    Godot AI 辅助开发完整流程                      │
└─────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │   需求描述    │
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────┐
              │   Claude Code 设计     │
              │   - 分析需求           │
              │   - 设计架构           │
              │   - 规划任务           │
              └───────────┬────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
          ▼               ▼               ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │ 场景生成  │   │ 脚本生成  │   │ 测试生成  │
    │ (.tscn)  │   │  (.gd)   │   │ (GUT)    │
    └────┬─────┘   └────┬─────┘   └────┬─────┘
         │              │              │
         └──────────────┼──────────────┘
                        │
                        ▼
              ┌────────────────────────┐
              │    用户审查确认         │
              └───────────┬────────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │    应用修改             │
              │    (write/edit 工具)    │
              └───────────┬────────────┘
                          │
                          ▼
              ┌────────────────────────┐
              │    自动验证             │
              │    - godot --check-only │
              │    - GUT 测试          │
              └───────────┬────────────┘
                          │
               ┌──────────┴──────────┐
               │                     │
               ▼                     ▼
         ┌──────────┐          ┌──────────┐
         │ 通过 ✓   │          │ 失败 ✗   │
         └────┬─────┘          └────┬─────┘
              │                     │
              ▼                     ▼
    ┌──────────────────┐   ┌──────────────────┐
    │ Git commit       │   │ Claude 修正      │
    │ & push           │   │ 错误报告         │
    └──────────────────┘   └──────────────────┘
```

### 6.2 OpenClaw Heartbeat 监控

```markdown
# HEARTBEAT.md

## Godot 项目监控

- 检查是否有未运行的测试
- 监控场景文件变更
- 提示需要验证的代码
```

### 6.3 自动化 CI/CD 配置

```yaml
# .github/workflows/godot-ci.yml
name: Godot CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.3
    steps:
      - uses: actions/checkout@v4
      
      - name: Import fonts
        run: |
          mkdir -p ~/.local/share/fonts
          echo "Fonts ready"
      
      - name: Run tests
        run: |
          godot --headless --path . -s addons/gut/gut_cmdln.gd
      
      - name: Check scripts
        run: |
          find . -name "*.gd" -exec godot --headless --check-only --script {} \;

  export:
    needs: test
    runs-on: ubuntu-latest
    container: barichello/godot-ci:4.3
    steps:
      - uses: actions/checkout@v4
      
      - name: Export Windows
        run: |
          mkdir -p build/windows
          godot --headless --export-release "Windows Desktop" build/windows/game.exe
      
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: game-windows
          path: build/windows
```

---

## 七、最佳实践

### 7.1 GDScript AI 生成规范

```markdown
# GDScript 生成规范

## 必须遵守

1. **静态类型**: 所有变量和函数使用类型注解
   ```gdscript
   # ✓ 正确
   var health: int = 100
   func get_damage() -> float:
       return base_damage * multiplier
   
   # ✗ 避免
   var health = 100
   func get_damage():
       return base_damage * multiplier
   ```

2. **文档注释**: 公共函数添加文档
   ```gdscript
   ## 计算最终伤害值
   ## 参数:
   ##   target: 目标对象
   ## 返回: 最终伤害值
   func calculate_damage(target: Node) -> float:
       pass
   ```

3. **信号定义**: 使用 typed signals
   ```gdscript
   signal health_changed(old_value: int, new_value: int)
   signal died()
   ```

4. **导出变量**: 使用 @export 并添加范围
   ```gdscript
   @export_range(0, 100) var health: int = 100
   @export_file("*.tscn") var next_scene: String
   ```

## 生成模板

### 角色 Controller 模板
```gdscript
class_name PlayerController
extends Node3D

## 移动速度
@export_range(1.0, 20.0) var move_speed: float = 5.0
## 跳跃力度
@export_range(0.0, 20.0) var jump_force: float = 10.0

signal moved(direction: Vector3)
signal jumped()

var _velocity: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
    _handle_movement(delta)
    _handle_jump()

func _handle_movement(delta: float) -> void:
    var input_dir := _get_input_direction()
    if input_dir != Vector3.ZERO:
        _velocity = input_dir * move_speed
        moved.emit(input_dir)

func _handle_jump() -> void:
    if Input.is_action_just_pressed("jump"):
        jumped.emit()

func _get_input_direction() -> Vector3:
    return Vector3(
        Input.get_axis("move_left", "move_right"),
        0.0,
        Input.get_axis("move_forward", "move_backward")
    ).normalized()
```
```

### 7.2 场景文件处理

`.tscn` 文件是文本格式，AI 可以解析和修改:

```ini
[gd_scene load_steps=2 format=3 uid="uid://c1234567890"]

[ext_resource type="Script" path="res://scripts/player.gd" id="1_abc123"]

[sub_resource type="CapsuleShape3D" id="CapsuleShape3D_abc123"]
radius = 0.5
height = 1.8

[node name="Player" type="CharacterBody3D"]
script = ExtResource("1_abc123")

[node name="CollisionShape3D" type="CollisionShape3D" parent="."]
shape = SubResource("CapsuleShape3D_abc123")
```

**AI 操作注意**:
- 保持 UID 一致性
- 正确处理资源引用格式
- 节点层级结构准确

---

## 八、挑战与限制

### 8.1 当前限制

| 问题 | 说明 | 解决方案 |
|------|------|----------|
| 资源引用 | UID 和路径管理复杂 | 使用相对路径，生成时重新映射 |
| 场景复杂度 | 大型场景难以 AI 生成 | 分层生成，模块化设计 |
| 可视化编辑 | AI 无法使用编辑器 | 纯代码创建节点，或预设模板 |
| 调试能力 | 无法实时调试 | 依赖日志和单元测试 |

### 8.2 最佳实践建议

1. **代码优先**: 复杂逻辑用代码而非场景编辑
2. **模块化**: 小场景组合大场景
3. **测试驱动**: AI 生成测试用例
4. **版本控制**: 频繁提交，小步迭代
5. **人工审查**: AI 生成代码必须审查

---

## 九、总结与建议

### 9.1 推荐方案

| 场景 | 推荐工具 | 理由 |
|------|----------|------|
| 快速原型 | Claude Code | GDScript 生成质量高 |
| 持续开发 | OpenClaw + Godot Skill | 集成监控和自动化 |
| 团队协作 | Claude Code + GUT + GitHub Actions | 完整 CI/CD 流程 |
| 学习项目 | Claude Code 直接使用 | 简单直接 |

### 9.2 下一步行动

1. **创建 Godot Dev Skill**
   - 集成 Godot CLI 命令
   - 支持场景解析和生成
   - 自动测试运行

2. **完善 CLAUDE.md 模板**
   - 针对 Godot 项目优化
   - 包含 GDScript 规范
   - 集成 GUT 测试框架

3. **建立示例项目**
   - 完整的 AI 辅助开发示例
   - 可复用的模板场景
   - 自动化测试用例

---

## 附录

### A. 有用的 Godot CLI 命令

```bash
# 项目验证
godot --headless --check-only --path .

# 运行测试
godot --headless --path . -s addons/gut/gut_cmdln.gd

# 导出 (需要 preset)
godot --headless --export-release "Windows Desktop" build/game.exe

# 生成文档
godot --headless --doctool . --no-docbase

# 打包资源
godot --headless --pack build/game.pck
```

### B. 参考资源

- [Godot 官方文档](https://docs.godotengine.org/)
- [GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)
- [GUT 测试框架](https://github.com/bitwes/Gut)
- [Godot VSCode 插件](https://github.com/godotengine/godot-vscode-plugin)
- [Godot CI/CD 模板](https://github.com/gdquest/godot-ci-template)

---

*本报告由 AI 辅助整理，持续更新中...*
