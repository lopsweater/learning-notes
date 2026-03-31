# GE-Module-Analysis 快速参考

## 一句话使用

```
使用 ge-module-analysis 分析 [引擎名] 源码在 [路径]
```

## 分析阶段速查

| 阶段 | 时间 | 输出 |
|------|------|------|
| 架构分析 | 10-20min | `architecture/README.md` |
| 模块分析 | 20-40min | `modules/[模块]/README.md` |
| 历史追溯 | 5-15min | `changelog/evolution.md` |
| 概念文档 | 15-25min | `guides/` + `glossary.md` |

## 常用命令

### 查看目录结构
```bash
tree -L 2 [ENGINE_SOURCE]
```

### 统计代码量
```bash
find [ENGINE_SOURCE] -name "*.cpp" | wc -l
```

### 生成依赖图
```bash
cmake --graphviz=deps.dot [ENGINE_SOURCE]
dot -Tpng deps.dot -o deps.png
```

### 生成 Doxygen 文档
```bash
doxygen -g Doxyfile
doxygen Doxyfile
```

## 重点标记含义

- ★ 必须理解
- ★★★ 核心重点
- ⚠️ 注意事项
- 💡 设计亮点

## 输出目录结构

```
engine-doc-template/
├── README.md
├── architecture/      ← 阶段一
├── modules/          ← 阶段二
├── changelog/        ← 阶段三
├── guides/           ← 阶段四
├── api-reference/    ← 阶段四
└── glossary.md       ← 阶段四
```

---

**快速参考版本**: 1.0.0
