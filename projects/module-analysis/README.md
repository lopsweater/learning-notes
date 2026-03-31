# Module Analysis Plugin for Claude Code

> 🎮 游戏引擎模块分析插件 - Claude Code 团队部署版本

## 📦 插件内容

### 核心文件

| 文件 | 说明 | 格式 |
|------|------|------|
| `SKILL.md` | 技能定义文件 | Claude Code Skill |
| `commands/ge-module-analysis.md` | 斜杠命令定义 | Claude Code Command |
| `package.json` | 插件元数据 | NPM Package |
| `INSTALL.md` | 部署指南 | Markdown |
| `deploy-team.sh` | 一键部署脚本 | Bash Script |

### 辅助资源

| 目录/文件 | 说明 |
|----------|------|
| `templates/analysis-prompt.md` | 分析任务模板 |
| `references/analysis-checklist.md` | 进度检查清单 |
| `QUICK-REF.md` | 快速参考卡 |

## 🚀 快速部署

### 方法一：一键部署（推荐）

```bash
cd /root/.openclaw/workspace/skills/module-analysis
./deploy-team.sh install
```

### 方法二：手动安装

```bash
# 1. 创建目录
mkdir -p ~/.claude/plugins/module-analysis
mkdir -p ~/.claude/commands

# 2. 复制文件
cp SKILL.md ~/.claude/plugins/module-analysis/
cp commands/ge-module-analysis.md ~/.claude/commands/
cp -r templates ~/.claude/plugins/module-analysis/
cp -r references ~/.claude/plugins/module-analysis/

# 3. 重启 Claude Code
claude
```

### 方法三：团队共享

```bash
# 1. 创建团队仓库
git init team-claude-plugins
cd team-claude-plugins

# 2. 复制插件
mkdir -p skills commands
cp /path/to/module-analysis/SKILL.md skills/
cp /path/to/module-analysis/commands/* commands/

# 3. 推送到远程
git remote add origin https://github.com/your-team/plugins.git
git add .
git commit -m "Add module-analysis plugin"
git push -u origin main

# 4. 团队成员克隆
git clone https://github.com/your-team/plugins.git ~/.claude/team-plugins
ln -s ~/.claude/team-plugins/* ~/.claude/plugins/
```

## 📖 使用方法

### 基本用法

```bash
# 分析当前目录
/ge-module-analysis

# 分析指定引擎
/ge-module-analysis --engine UnrealEngine --path /root/UnrealEngine

# 分析特定阶段
/ge-module-analysis --engine Godot --phases 1,2

# 重点关注模块
/ge-module-analysis --engine Unity --focus rendering,physics
```

### 集成到项目

在项目根目录创建 `CLAUDE.md`：

```markdown
# 项目配置

## 插件引用

本项目使用 `module-analysis` 插件进行引擎分析。

使用方法: `/ge-module-analysis --help`
```

## ✨ 核心特性

### 四阶段分析流程

| 阶段 | 时间 | 输出 |
|------|------|------|
| 🏗️ 架构分析 | 10-20min | `architecture/README.md` |
| 🔍 模块剖析 | 20-40min | `modules/[模块]/README.md` |
| 📜 历史追溯 | 5-15min | `changelog/evolution.md` |
| 📚 概念文档 | 15-25min | `guides/` + `glossary.md` |

### 支持的引擎

- ✅ **Unreal Engine** (C++)
- ✅ **Unity** (C#)
- ✅ **Godot** (C++)
- ✅ **O3DE** (C++)
- ✅ **Custom Engines**

### 分析工具集成

- 🔧 Doxygen - API 文档生成
- 📊 Graphviz - 依赖关系可视化
- 🔍 Sourcetrail - 代码导航
- 📝 Sphinx - 文档组织

## 🎯 输出示例

```
engine-doc-template/
├── README.md                    # 文档入口
├── architecture/
│   └── README.md               # 架构概览 ★
├── modules/
│   ├── rendering/
│   │   └── README.md           # 渲染模块 ★
│   ├── resources/
│   │   └── README.md           # 资源管理
│   └── ecs/
│       └── README.md           # ECS 模块
├── guides/
│   ├── rendering-pipeline.md   # 渲染管线指南 ★
│   └── resource-lifecycle.md   # 资源生命周期
├── api-reference/
│   └── README.md               # API 索引
├── changelog/
│   ├── evolution.md            # 演进历程
│   └── contributors.md         # 贡献者
└── glossary.md                  # 术语表 ★
```

## 🛠️ 高级功能

### CI/CD 集成

```yaml
# .github/workflows/engine-analysis.yml
name: Engine Analysis
on: [push]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Analysis
        run: /ge-module-analysis --engine UnrealEngine
```

### 自定义配置

```json
// .claude/config.json
{
  "commands": {
    "ge-module-analysis": {
      "defaultEngine": "UnrealEngine",
      "defaultPath": "/root/UnrealEngine",
      "defaultPhases": [1, 2, 3, 4]
    }
  }
}
```

## 📋 验证安装

```bash
# 运行验证脚本
./deploy-team.sh verify

# 预期输出
✓ SKILL.md exists
✓ Command exists
✓ Templates exist
✅ All files verified successfully!
```

## 🔄 更新插件

```bash
# 更新到最新版本
./deploy-team.sh update

# 或手动更新
git -C /path/to/module-analysis pull
./deploy-team.sh install
```

## 🗑️ 卸载插件

```bash
./deploy-team.sh uninstall
```

## 📚 参考资源

### 内置文档
- [分析方法论](templates/../references/analysis-checklist.md)
- [任务模板](templates/analysis-prompt.md)
- [快速参考](QUICK-REF.md)

### 外部资源
- [Claude Code 官方文档](https://claude.ai/code)
- [Everything Claude Code](https://github.com/affaan-m/everything-claude-code)

## 🤝 团队协作

### 推荐工作流

1. **创建共享仓库** - 托管团队插件
2. **Git 子模块集成** - 项目级依赖管理
3. **定期同步更新** - 自动化脚本
4. **版本标签管理** - 使用 Git 标签控制版本

### 示例：Git 子模块集成

```bash
# 在项目中添加插件为子模块
git submodule add https://github.com/your-team/plugins.git .claude/plugins

# 更新插件
git submodule update --remote .claude/plugins
```

## 💡 最佳实践

1. **渐进式分析** - 先架构后模块
2. **工具集成** - 使用 Doxygen + Graphviz
3. **文档维护** - 定期更新分析结果
4. **团队共享** - 通过 Git 仓库同步

## ❓ 常见问题

<details>
<summary><b>Q: 插件未加载？</b></summary>

```bash
# 检查文件权限
ls -la ~/.claude/plugins/module-analysis/
chmod 644 ~/.claude/plugins/module-analysis/SKILL.md
```
</details>

<details>
<summary><b>Q: 命令未找到？</b></summary>

```bash
# 确认命令文件位置
ls -la ~/.claude/commands/ge-module-analysis.md
```
</details>

<details>
<summary><b>Q: 分析大型引擎时内存不足？</b></summary>

```bash
# 分阶段执行
/ge-module-analysis --phases 1
/ge-module-analysis --phases 2 --focus rendering
```
</details>

## 📊 统计信息

- **版本**: 1.0.0
- **创建时间**: 2026-03-31
- **文件数量**: 7 个核心文件
- **预估分析时间**: 50-100 分钟
- **支持引擎**: 5+ 主流引擎

## 📄 许可证

MIT License

---

**Made with ❤️ for Game Engine Developers**
