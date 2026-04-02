# Engine Analyze Command

分析引擎代码结构、依赖关系和架构

## 用法

```
/engine-analyze [路径]
```

参数：
- `路径` - 要分析的目录路径（可选，默认为当前目录）

## 功能

1. **目录结构分析**
   - 识别模块划分
   - 分析文件组织
   - 检测配置文件

2. **依赖关系分析**
   - 头文件依赖
   - 模块依赖
   - 第三方库依赖

3. **代码统计**
   - 代码行数
   - 文件数量
   - 注释比例

4. **架构分析**
   - 识别设计模式
   - 分析类层次结构
   - 检测代码异味

## 示例

### 分析当前目录

```
/engine-analyze
```

### 分析指定目录

```
/engine-analyze Source/Runtime/Render
```

### 分析输出示例

```
=== Engine Analysis Report ===

## Directory Structure
Source/
├── Runtime/
│   ├── Core/        (45 files, 12,345 lines)
│   ├── Render/      (32 files, 8,901 lines)
│   ├── Engine/      (28 files, 6,789 lines)
│   └── ...
└── Editor/
    ├── Core/        (15 files, 3,456 lines)
    └── ...

## Module Dependencies
Core → [无依赖]
Engine → [Core]
Render → [Core, Engine]
Editor → [Core, Engine, Render]

## Statistics
- Total Files: 120
- Total Lines: 31,491
- Code Lines: 24,892 (79%)
- Comment Lines: 6,599 (21%)
- Average File Size: 262 lines

## Recommendations
✓ Core 模块零依赖，符合设计
⚠ Render 模块依赖 Engine，建议解耦
✗ Editor 模块过于庞大，建议拆分
```

## 分析维度

### 1. 模块分析
- 模块大小
- 模块职责
- 模块独立性

### 2. 依赖分析
- 依赖图生成
- 循环依赖检测
- 依赖层次

### 3. 代码质量
- 代码复杂度
- 重复代码检测
- 注释覆盖率

### 4. 架构评估
- 设计模式识别
- SOLID 原则检查
- 架构异味检测
