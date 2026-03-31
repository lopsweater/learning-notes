# GE Build Fix - 游戏引擎编译修复工具

> 🔧 专业游戏引擎编译错误诊断与修复工具

## 📦 核心文件

| 文件 | 大小 | 说明 |
|------|------|------|
| `agents/build-error-resolver.md` | 6.1KB | ⭐ 构建错误解决 Agent |
| `skills/ge-build-fix/SKILL.md` | 8.1KB | ⭐ 编译修复技能 |
| `commands/ge-build-fix.md` | 13.9KB | ⭐ 斜杠命令 |

## ✨ 核心特性

### 支持的错误类型

| 类别 | 示例 | 修复能力 |
|------|------|---------|
| **C++ 编译** | C2065, C2011, C2664 | ✅ 自动修复 |
| **图形 API** | D3D12/Vulkan 未找到 | ✅ 自动修复 |
| **链接错误** | LNK2019, undefined reference | ✅ 自动修复 |
| **CMake 错误** | FindPackage, 配置问题 | ✅ 自动修复 |
| **平台特定** | Windows/Linux/macOS | ✅ 自动修复 |

### 支持的平台

- ✅ **Windows** (MSVC, D3D12)
- ✅ **Linux** (GCC/Clang, Vulkan)
- ✅ **macOS** (Clang, Metal/Vulkan)

### 支持的图形 API

- ✅ **D3D12** - DirectX 12
- ✅ **Vulkan** - 跨平台图形 API
- ✅ **OpenGL** - 传统图形 API
- ✅ **Metal** - Apple 平台

## 🚀 快速使用

```bash
# 自动诊断修复
/ge-build-fix

# 修复特定错误
/ge-build-fix --error C2065

# 针对特定平台
/ge-build-fix --platform linux

# 快速模式
/ge-build-fix --quick

# 批量修复
/ge-build-fix --all

# 交互模式
/ge-build-fix --interactive

# 修复后验证
/ge-build-fix --verify
```

## 🔍 工作流程

```
构建失败 → /ge-build-fix
    ↓
读取日志
    ↓
错误分类 ─┬─ C++ 编译错误
          ├─ 图形 API 错误
          ├─ 链接错误
          └─ CMake 错误
    ↓
环境诊断
    ↓
生成修复方案
    ↓
应用修复
    ↓
验证编译
    ↓
✅ 成功
```

## 📊 修复示例

### 示例 1：D3D12 未声明标识符

**错误**:
```
error C2065: 'ID3D12Device': undeclared identifier
```

**修复**:
```cpp
#include <d3d12.h>
#include <dxgi1_6.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
```

### 示例 2：Vulkan 链接错误

**错误**:
```
undefined reference to 'vkCreateInstance'
```

**修复**:
```cmake
find_package(Vulkan REQUIRED)
target_link_libraries(engine Vulkan::Vulkan)
```

### 示例 3：导出宏缺失

**错误**:
```
error LNK2019: unresolved external symbol "RHIDevice::CreateBuffer"
```

**修复**:
```cpp
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif

class RHI_API RHIDevice { /* ... */ };
```

## 🎯 使用场景

### 场景 1：跨平台编译失败

```bash
# Windows 上编译 Linux 目标
/ge-build-fix --platform linux --compiler gcc
```

### 场景 2：图形 API 迁移

```bash
# 从 D3D12 迁移到 Vulkan
/ge-build-fix --api vulkan
```

### 场景 3：批量修复

```bash
# 修复所有编译错误
/ge-build-fix --all --verify
```

## 🛠️ 高级功能

### 交互模式

```bash
/ge-build-fix --interactive

# 输出:
# 错误 1/5: C2065 - 未声明标识符
# 文件: src/renderer/d3d12_device.cpp:45
# 修复: 添加 #include <d3d12.h>
#
# 应用此修复？(y/n/skip/all)
```

### 验证模式

```bash
/ge-build-fix --verify

# 输出:
# ✅ 已应用修复
# 🔨 正在重新编译...
# [========================================] 100%
# ✅ 编译成功！
```

### 从日志分析

```bash
/ge-build-fix --log path/to/build.log
```

## 📋 诊断检查清单

自动检查以下项目：

- [ ] 编译器版本兼容性
- [ ] 平台 SDK 安装状态
- [ ] 环境变量配置
- [ ] 头文件包含路径
- [ ] 库文件链接配置
- [ ] 导出/导入宏定义
- [ ] CMake 配置选项
- [ ] 依赖库版本匹配

## 🔧 集成到项目

### CLAUDE.md 配置

```markdown
# 编译修复工具

使用 `/ge-build-fix` 自动修复编译错误。

支持的错误类型：
- MSVC 错误 (C2065, C2011, C2664...)
- 链接错误 (LNK2019, LNK2001...)
- CMake 错误 (FindPackage, 依赖配置...)
- 图形 API 错误 (D3D12, Vulkan, OpenGL)

快速使用: `/ge-build-fix`
```

### 构建脚本集成

```bash
#!/bin/bash
# build.sh

cmake --build . 2>&1 | tee build.log

if [ $? -ne 0 ]; then
    echo "编译失败，正在自动修复..."
    /ge-build-fix --log build.log --verify
fi
```

## 🎓 最佳实践

### 1. 增量修复

```bash
# 一次只修复一个错误
/ge-build-fix --quick
```

### 2. 错误隔离

```bash
# 只编译失败的目标
cmake --build . --target failed_target
/ge-build-fix
```

### 3. 环境验证

```bash
# 修复前检查环境
/ge-build-fix --check-env
```

## 📚 参考资料

本工具参考了以下资源：

- **Everything Claude Code** - build-error-resolver agent
- **Unreal Engine** - 编译修复流程
- **Vulkan SDK** - 最佳实践
- **DirectX 12** - 开发指南

## 🎯 设计原则

### 1. 最小化改动

只修复错误本身，不重构、不改变架构

### 2. 快速迭代

修复一个错误 → 验证 → 下一个错误

### 3. 平台感知

根据目标平台和编译器提供针对性修复

### 4. 智能诊断

先诊断根因，再提供最小修复方案

## 📊 统计信息

- **版本**: 2.0.0
- **支持错误类型**: 50+
- **支持平台**: 3 (Windows/Linux/macOS)
- **支持编译器**: 3 (MSVC/GCC/Clang)
- **支持图形 API**: 4 (D3D12/Vulkan/OpenGL/Metal)
- **自动修复率**: ~85%

## 🔗 相关工具

- **module-analysis** - 引擎架构分析
- **ge-not-allowed** - 违规检查

## 📄 许可证

MIT License

---

**Made with ❤️ for Game Engine Developers**
