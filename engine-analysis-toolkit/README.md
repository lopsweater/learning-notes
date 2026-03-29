# Engine Analysis Toolkit

游戏引擎深度分析工具包，用于分析复杂的游戏引擎源码并构建开发文档。

## 目录结构

```
engine-analysis-toolkit/
├── engine-analysis-prompt.md              # Agent 任务提示词（主要入口）
├── engine-analysis-task.md                # 任务说明文档
├── game-engine-analysis-methodology.md    # 源码分析方法论
├── vcs-history-analysis.md                # 版本控制历史分析方案
├── game-engine-doc-template.md            # 文档模板说明
├── engine-doc-template/                   # 文档输出模板目录
│   ├── README.md
│   ├── architecture/
│   ├── modules/
│   ├── guides/
│   └── ...
└── README.md                              # 本文件
```

## 使用方法

### 1. 使用 Agent 分析引擎

复制 `engine-analysis-prompt.md` 内容，填写占位符后发送给 agent：

```markdown
- 引擎名称: [ENGINE_NAME]
- 源码路径: [SOURCE_PATH]
- 版本控制: [SVN / Git / None]
- 主要语言: [C++ / C# / Other]
```

### 2. 文档输出位置

分析结果输出到 `engine-doc-template/` 目录。

### 3. 参考方法论

- `game-engine-analysis-methodology.md` - 了解分析方法和工具
- `vcs-history-analysis.md` - 版本历史追溯方案

## 分析阶段

| 阶段 | 内容 | 输出 |
|------|------|------|
| 阶段一 | 架构宏观分析 | `architecture/README.md` |
| 阶段二 | 模块深度分析 | `modules/[模块名]/README.md` |
| 阶段三 | 版本历史追溯 | `changelog/evolution.md` |
| 阶段四 | 关键概念文档化 | `guides/`, `glossary.md` |

## 参考案例

本工具包基于 RHI 调研实践总结，参考 `../rhi/` 目录下的调研成果。

---

*创建时间: 2026-03-29*
