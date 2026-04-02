# Engine-EVC 文件清单

## 📁 目录结构

```
engine-evc/
├── README.md                           # 项目说明文档
├── docs/
│   └── QUICKSTART.md                   # 快速开始指南
│
├── .claude/                            # Claude Code 配置（复制到项目）
│   ├── skills/                         # 技能文件
│   │   ├── engine-project-context/     # 项目上下文技能
│   │   │   └── SKILL.md
│   │   ├── engine-cpp-foundations.md   # C++ 基础技能
│   │   ├── engine-architecture.md      # 架构设计技能
│   │   ├── engine-rendering.md         # 渲染系统技能
│   │   ├── engine-tools.md             # 工具开发技能
│   │   └── engine-testing.md           # 测试调试技能
│   │
│   ├── rules/                          # 规则文件
│   │   ├── engine-coding-standards.md  # 编码规范
│   │   ├── engine-performance.md       # 性能优化规则
│   │   └── engine-memory.md            # 内存管理规则
│   │
│   └── commands/                       # 命令文件
│       ├── engine-analyze.md           # 分析命令
│       ├── engine-implement.md         # 实现命令
│       ├── engine-optimize.md          # 优化命令
│       └── engine-test.md              # 测试命令
│
├── skills/                             # 技能源文件（供参考）
├── rules/                              # 规则源文件
├── commands/                           # 命令源文件
└── scripts/                            # 辅助脚本（预留）
```

## 📊 文件统计

### Skills（技能）
- engine-project-context (1,024 行)
- engine-cpp-foundations (3,072 行)
- engine-architecture (4,165 行)
- engine-rendering (5,256 行)
- engine-tools (5,894 行)
- engine-testing (6,105 行)

**总计：25,516 行**

### Rules（规则）
- engine-coding-standards (2,630 行)
- engine-performance (2,363 行)
- engine-memory (2,802 行)

**总计：7,795 行**

### Commands（命令）
- engine-analyze (41 行)
- engine-implement (69 行)
- engine-optimize (123 行)
- engine-test (132 行)

**总计：365 行**

### 文档
- README.md (111 行)
- QUICKSTART.md (187 行)

**总计：298 行**

## ✅ 完成状态

### Skills（技能）
- ✅ engine-project-context - 项目上下文管理
- ✅ engine-cpp-foundations - C++ 基础知识
- ✅ engine-architecture - 架构设计模式
- ✅ engine-rendering - 渲染系统开发
- ✅ engine-tools - 工具开发
- ✅ engine-testing - 测试与调试

### Rules（规则）
- ✅ engine-coding-standards - 编码规范
- ✅ engine-performance - 性能优化
- ✅ engine-memory - 内存管理

### Commands（命令）
- ✅ engine-analyze - 分析代码结构
- ✅ engine-implement - 实现功能
- ✅ engine-optimize - 优化性能
- ✅ engine-test - 生成测试

### 文档
- ✅ README.md - 项目说明
- ✅ QUICKSTART.md - 快速开始

## 🎯 核心特性

### 1. 完整的技能体系
- 6 个核心技能，覆盖引擎开发全流程
- 从 C++ 基础到高级渲染技术
- 从架构设计到测试调试

### 2. 严格的编码规范
- 命名约定
- 文件组织
- 代码风格
- 最佳实践

### 3. 性能优化指导
- 算法优化
- 内存优化
- 渲染优化
- 并行化

### 4. 便捷的命令系统
- 一键分析项目
- 自动生成代码
- 性能优化建议
- 测试代码生成

## 📦 使用方法

### 1. 复制配置到项目

```bash
cp -r /root/engine-evc/.claude /path/to/your/project/
```

### 2. 在 Claude Code 中使用

```
/engine-analyze          # 分析项目
/engine-implement ...    # 实现功能
/engine-optimize ...     # 优化性能
/engine-test ...         # 生成测试
```

## 🔄 更新计划

### v1.1（计划中）
- [ ] 添加更多 UE5 特定技能
- [ ] 添加 Unity 技能支持
- [ ] 添加 Godot 技能支持
- [ ] 添加 AI/ML 集成技能

### v1.2（计划中）
- [ ] 添加多语言支持（中文/英文）
- [ ] 添加代码模板库
- [ ] 添加自动化脚本

## 📝 备注

- 所有技能、规则、命令都基于 Claude Code 官方文档和最佳实践
- 参考了 unreal-engine-skills、soft-ue-cli 等开源项目
- 持续更新中，欢迎反馈和建议
