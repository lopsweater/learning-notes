# GE Not-Allowed - Claude Code 智能违规检查系统

Game Engine Not Allowed - 自动检查违规操作，智能学习新规则。

---

## 快速开始

### 1. 安装到项目

将规则文件复制到项目：

```bash
cp rules/ge-not-allowed.md /path/to/your/project/.claude/rules/
```

将命令文件复制到项目：

```bash
cp commands/ge-not-allowed.md /path/to/your/project/.claude/commands/
```

### 2. 使用方法

在 Claude Code 中：

```
/ge-not-allowed              # 检查当前上下文违规情况
/ge-not-allowed list         # 查看所有规则
/ge-not-allowed list <分类>  # 查看指定分类的规则
```

---

## 核心功能

### ✅ 智能违规检查

自动分析当前对话上下文，检测违规操作：

- Git 操作检查
- 文件操作检查
- 代码修改检查
- 安全命令检查

### ✅ 自动学习机制

发现新的违规模式时，自动询问是否记录为规则：

```
📝 是否将此操作记录为新规则？
建议规则内容: ❌ 禁止删除构建目录，必须先询问用户
```

### ✅ 修改建议

发现违规后，提供具体的修改建议：

```
💡 修改建议:
   1. 执行 git status 查看当前状态
   2. 执行 git diff 查看详细变更
   3. 向您展示所有变更内容
   4. 等待您明确同意后再推送
```

### ✅ 统计追踪

记录规则触发次数和时间，便于分析。

---

## 文件结构

```
ge-not-allowed/
├── README.md                           # 说明文档
├── commands/
│   └── ge-not-allowed.md               # Command 定义
└── rules/
    └── ge-not-allowed.md               # 规则文件
```

---

## 规则分类

| 分类 | 说明 |
|------|------|
| 📂 上传和提交 | Git 操作相关规则 |
| 📂 代码修改 | 代码修改相关规则 |
| 📂 安全 | 安全相关规则 |
| 📂 游戏引擎特定 | 游戏引擎专用规则 |

---

## 配置选项

在项目根目录创建 `.claude/config.json`：

```json
{
  "ge-not-allowed": {
    "autoCheck": true,
    "showSuggestions": true,
    "askToRecord": true,
    "logFile": ".claude/ge-not-allowed.log"
  }
}
```

---

## 示例输出

### 检查违规

```
🔍 GE Not-Allowed Check

⚠️  发现违规操作

【违规项】
📍 类型: 上传和提交
📍 操作: git push origin main
📍 规则: 禁止推送到远程仓库，必须先展示变更内容

💡 修改建议:
   1. 执行 git status 查看当前状态
   2. 执行 git diff 查看详细变更
   3. 向您展示所有变更内容
   4. 等待您明确同意后再推送
```

### 查看规则

```
📋 GE Not-Allowed Rules List

📂 上传和提交 [3 条]
   ❌ 禁止直接提交到 GitHub，必须先询问用户确认
   ❌ 禁止推送到远程仓库，必须先展示变更内容
   ❌ 禁止上传敏感信息（密码、密钥、token）

📂 代码修改 [4 条]
   ❌ 禁止删除核心架构文件
   ❌ 禁止修改公共 API 接口，必须先讨论
   ❌ 禁止引入未经授权的第三方依赖
   ❌ 禁止大规模重构（超过 10 个文件）

📊 统计: 16 条规则 | 4 个分类
```

---

## 自定义规则

编辑 `rules/ge-not-allowed.md` 文件即可添加/删除规则。

### 规则格式

```markdown
## 📂 分类名称

- ❌ 禁止操作描述
  📍 添加时间: 2026-03-22 18:59
  📍 触发次数: 0
```

---

## 集成建议

在项目的 `CLAUDE.md` 中添加：

```markdown
# 项目规则

使用 `/ge-not-allowed` 命令检查违规操作：

- 执行任何文件操作前，先运行 `/ge-not-allowed` 检查
- 发现违规后，按照建议修改
- 新发现的违规模式，询问用户是否记录

规则文件位置: `.claude/rules/ge-not-allowed.md`
```

---

## 更新历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-03-22 | 初始版本 |

---

## 相关资源

- [Claude Code 官方文档](https://docs.anthropic.com/claude/docs)
- [游戏引擎项目](/root/ai_game_engine)
