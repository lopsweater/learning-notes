# Claude Code 插件部署指南

## 快速部署（推荐）

### 方法一：复制到全局插件目录

```bash
# 复制到 Claude Code 全局插件目录
cp -r /root/.openclaw/workspace/skills/module-analysis ~/.claude/plugins/

# 重启 Claude Code
claude
```

### 方法二：添加到项目级别

```bash
# 在项目根目录创建 .claude 目录
mkdir -p your-project/.claude/skills
mkdir -p your-project/.claude/commands

# 复制文件
cp SKILL.md your-project/.claude/skills/
cp commands/ge-module-analysis.md your-project/.claude/commands/

# 项目级插件自动生效
cd your-project
claude
```

## 团队部署

### 步骤 1：创建共享仓库

```bash
# 创建团队共享仓库
git init team-claude-plugins
cd team-claude-plugins

# 创建目录结构
mkdir -p skills commands templates

# 复制插件文件
cp -r /path/to/module-analysis/SKILL.md skills/
cp -r /path/to/module-analysis/commands/* commands/
cp -r /path/to/module-analysis/templates/* templates/
```

### 步骤 2：推送到团队仓库

```bash
git add .
git commit -m "Add module-analysis plugin for game engine analysis"
git remote add origin https://github.com/your-team/team-claude-plugins.git
git push -u origin main
```

### 步骤 3：团队成员安装

每位团队成员执行：

```bash
# 克隆团队插件仓库
git clone https://github.com/your-team/team-claude-plugins.git ~/.claude/team-plugins

# 链接到 Claude Code 插件目录
ln -s ~/.claude/team-plugins/skills/* ~/.claude/plugins/
ln -s ~/.claude/team-plugins/commands/* ~/.claude/plugins/

# 重启 Claude Code
claude
```

### 步骤 4：验证安装

```bash
# 在 Claude Code 中测试
claude

# 输入命令
/ge-module-analysis --help
```

## 使用 CLAUDE.md 集成

在项目根目录创建或编辑 `CLAUDE.md`：

```markdown
---
name: your-project
description: 项目描述
---

# 项目配置

## 插件引用

本项目使用以下 Claude Code 插件：

- **module-analysis**: 游戏引擎模块分析工具
  - 使用: `/ge-module-analysis`
  - 文档: `.claude/skills/module-analysis/SKILL.md`

## 推荐工作流

1. 使用 `/ge-module-analysis --engine UnrealEngine` 分析引擎架构
2. 查看生成的 `engine-doc-template/` 文档
3. 参考 `guides/` 目录学习关键概念
```

## NPM 发布（可选）

### 发布到 NPM

```bash
# 登录 npm
npm login

# 发布包
npm publish --access public
```

### 通过 NPM 安装

```bash
# 全局安装
npm install -g claude-code-module-analysis

# 或项目级安装
npm install --save-dev claude-code-module-analysis
```

## 配置文件示例

### ~/.claude/settings.json

```json
{
  "plugins": {
    "autoLoad": true,
    "directories": [
      "~/.claude/plugins",
      "~/.claude/team-plugins"
    ]
  },
  "skills": {
    "module-analysis": {
      "enabled": true,
      "priority": "high"
    }
  }
}
```

### 项目级 .claude/config.json

```json
{
  "project": "game-engine-analysis",
  "plugins": {
    "local": [
      "./.claude/skills/module-analysis"
    ]
  },
  "commands": {
    "ge-module-analysis": {
      "defaultEngine": "UnrealEngine",
      "defaultPath": "/root/UnrealEngine"
    }
  }
}
```

## 更新插件

### 自动更新脚本

```bash
#!/bin/bash
# update-plugins.sh

cd ~/.claude/team-plugins
git pull origin main

echo "✅ Plugins updated successfully"
echo "Run 'claude' to reload"
```

### 定时更新（Cron）

```bash
# 每天凌晨 2 点自动更新
0 2 * * * /path/to/update-plugins.sh
```

## 验证清单

安装完成后，检查以下内容：

- [ ] 文件已复制到正确位置
- [ ] Claude Code 已重启
- [ ] `/ge-module-analysis --help` 命令可执行
- [ ] `module-analysis` skill 可被触发
- [ ] 文档输出目录可写

## 常见问题

### Q: 插件未加载？

**A**: 检查文件权限和路径：
```bash
ls -la ~/.claude/plugins/module-analysis/
chmod 644 ~/.claude/plugins/module-analysis/SKILL.md
```

### Q: 命令未找到？

**A**: 确认 commands 目录正确：
```bash
ls -la ~/.claude/plugins/commands/
# 应该看到 ge-module-analysis.md
```

### Q: 团队同步问题？

**A**: 使用 Git 子模块：
```bash
# 在项目中添加插件为子模块
git submodule add https://github.com/your-team/team-claude-plugins.git .claude/plugins
```

## 卸载

```bash
# 删除插件文件
rm -rf ~/.claude/plugins/module-analysis
rm -f ~/.claude/commands/ge-module-analysis.md

# 重启 Claude Code
claude
```

---

**部署版本**: 1.0.0 | **创建时间**: 2026-03-31
