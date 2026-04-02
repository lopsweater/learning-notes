# 快速开始指南

## 1. 安装配置

### 方法一：直接复制（推荐）

```bash
# 将配置复制到你的游戏引擎项目
cp -r /root/engine-evc/.claude /path/to/your/engine/project/
```

### 方法二：符号链接

```bash
# 创建符号链接（方便更新）
ln -s /root/engine-evc/.claude /path/to/your/engine/project/.claude
```

## 2. 初始化项目上下文

在 Claude Code 中运行：

```
/engine-project-context
```

这会自动分析你的项目结构并生成上下文文件。

## 3. 使用 Skills（技能）

技能会根据上下文自动激活，例如：

```
你: 帮我实现一个 ECS 系统
Claude: [自动激活 engine-architecture 和 engine-cpp-foundations]
```

### 可用技能

| 技能 | 描述 | 触发关键词 |
|------|------|-----------|
| engine-project-context | 项目上下文 | 项目结构、模块 |
| engine-cpp-foundations | C++ 基础 | 内存管理、智能指针 |
| engine-architecture | 架构设计 | ECS、事件系统 |
| engine-rendering | 渲染系统 | RHI、材质、着色器 |
| engine-tools | 工具开发 | 编辑器、资源管线 |
| engine-testing | 测试调试 | 单元测试、性能测试 |

## 4. 使用 Rules（规则）

规则会根据文件类型自动应用：

- `*.cpp`, `*.h` → `engine-coding-standards.md`
- `*.cpp`, `*.h` → `engine-performance.md`
- `*.cpp`, `*.h` → `engine-memory.md`

## 5. 使用 Commands（命令）

### 分析项目

```
/engine-analyze Source/Runtime/Render
```

### 实现功能

```
/engine-implement 实现一个线程安全的任务队列
```

### 优化性能

```
/engine-optimize --profile
```

### 生成测试

```
/engine-test Vector3 --unit
```

## 6. 工作流程示例

### 示例 1：实现新功能

```
1. /engine-analyze Source/Runtime/Core
   → 分析现有结构

2. /engine-implement 实现一个对象池系统
   → 生成设计和代码

3. /engine-test ObjectPool --unit
   → 生成测试代码

4. /engine-optimize --memory
   → 检查内存使用
```

### 示例 2：优化性能

```
1. /engine-optimize Source/Runtime/Render --profile
   → 分析渲染瓶颈

2. 根据建议优化代码

3. /engine-optimize --run --verify
   → 验证优化效果
```

### 示例 3：添加测试

```
1. /engine-test EntityManager --unit
   → 生成单元测试

2. /engine-test --run --coverage
   → 运行测试并生成覆盖率报告
```

## 7. 配置说明

### Skills 配置

Skills 位于 `.claude/skills/` 目录，每个技能包含：
- `SKILL.md` - 技能定义文件

### Rules 配置

Rules 位于 `.claude/rules/` 目录，每个规则包含：
- `globs` - 适用的文件模式
- 内容 - 具体的规则说明

### Commands 配置

Commands 位于 `.claude/commands/` 目录，每个命令包含：
- 用法说明
- 参数说明
- 示例输出

## 8. 自定义扩展

### 添加新技能

1. 创建 `.claude/skills/my-skill/SKILL.md`
2. 添加技能描述和内容
3. 重启 Claude Code

### 添加新规则

1. 创建 `.claude/rules/my-rule.md`
2. 添加 `globs` 和规则内容
3. 重启 Claude Code

### 添加新命令

1. 创建 `.claude/commands/my-command.md`
2. 添加命令说明和示例
3. 重启 Claude Code

## 9. 故障排查

### Q: Skills 没有激活？

检查：
- 文件是否在正确的目录
- SKILL.md 格式是否正确
- 重启 Claude Code

### Q: Rules 没有应用？

检查：
- `globs` 模式是否匹配文件
- 文件是否在正确的位置
- 重启 Claude Code

### Q: Commands 无法识别？

检查：
- 命令文件是否存在
- 文件名是否正确
- 重启 Claude Code

## 10. 获取帮助

- 查看 README.md
- 查看各个技能的 SKILL.md
- 查看各个命令的 .md 文件

---

祝开发愉快！🎮
