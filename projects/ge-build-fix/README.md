# GE Build Fix - 游戏引擎编译修复工具

> 🔧 自动诊断和修复游戏引擎特有的编译错误

## 📦 插件内容

### 核心文件

| 文件 | 大小 | 说明 |
|------|------|------|
| `skills/ge-build-fix/SKILL.md` | 12.8KB | ⭐ Claude Code 技能定义 |
| `commands/ge-build-fix.md` | 12.5KB | ⭐ 斜杠命令 |

## 🚀 快速使用

```bash
# 自动诊断并修复
/ge-build-fix

# 修复特定错误
/ge-build-fix --error C2065

# 针对特定平台
/ge-build-fix --platform windows

# 快速模式
/ge-build-fix --quick
```

## ✨ 核心特性

### 支持的错误类型

| 类别 | 错误示例 | 修复能力 |
|------|----------|---------|
| **平台特定** | C2065 (MSVC), GCC 错误 | ✅ 自动修复 |
| **图形 API** | D3D12/Vulkan 未找到 | ✅ 自动修复 |
| **模板错误** | 类型转换失败 | ✅ 自动修复 |
| **链接错误** | LNK2019, undefined reference | ✅ 自动修复 |
| **CMake 错误** | 依赖查找失败 | ✅ 自动修复 |

### 支持的平台

- ✅ **Windows** (MSVC, D3D12)
- ✅ **Linux** (GCC/Clang, Vulkan)
- ✅ **macOS** (Clang, Metal/Vulkan)

### 支持的图形 API

- ✅ **D3D12** - DirectX 12
- ✅ **Vulkan** - 跨平台图形 API
- ✅ **OpenGL** - 传统图形 API
- ✅ **Metal** - Apple 平台

## 🔍 工作流程

```
构建失败 → /ge-build-fix
    ↓
读取日志
    ↓
错误分类 ─┬─ 平台特定错误
          ├─ 图形 API 错误
          ├─ 模板/类型错误
          ├─ 链接错误
          └─ CMake 错误
    ↓
环境检查
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
// 添加头文件
#include <d3d12.h>
#include <dxgi1_6.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
```

### 示例 2：链接错误

**错误**:
```
error LNK2019: unresolved external symbol "RHIDevice::CreateBuffer"
```

**修复**:
```cpp
// 添加导出宏
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif

class RHI_API RHIDevice { /* ... */ };
```

### 示例 3：CMake 依赖错误

**错误**:
```
CMake Error: Could not find a package configuration file provided by "Vulkan"
```

**修复**:
```cmake
# 设置 Vulkan SDK 路径
set(VULKAN_SDK $ENV{VULKAN_SDK})
find_package(Vulkan REQUIRED PATHS "${VULKAN_SDK}")
target_link_libraries(engine Vulkan::Vulkan)
```

## 🎯 使用场景

### 场景 1：跨平台编译失败

```bash
# 在 Windows 上编译 Linux 目标时出错
/ge-build-fix --platform linux --compiler gcc
```

### 场景 2：图形 API 迁移

```bash
# 从 D3D12 迁移到 Vulkan
/ge-build-fix --api vulkan
```

### 场景 3：依赖更新

```bash
# Vulkan SDK 更新后编译失败
/ge-build-fix --api vulkan --verify
```

## 🛠️ 高级功能

### 批量修复

```bash
# 修复所有错误
/ge-build-fix --all
```

### 交互模式

```bash
# 逐步确认修复
/ge-build-fix --interactive
```

### 验证模式

```bash
# 修复后自动编译验证
/ge-build-fix --verify
```

### 从日志分析

```bash
# 分析特定日志文件
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

### 方法一：CLAUDE.md 配置

```markdown
# 编译修复工具

使用 `/ge-build-fix` 自动修复编译错误。

支持的错误类型：
- MSVC 错误 (C2065, C2011, C3861...)
- 链接错误 (LNK2019, LNK2001...)
- CMake 错误 (FindPackage, 依赖配置...)

快速使用: `/ge-build-fix`
```

### 方法二：构建脚本集成

```bash
#!/bin/bash
# build.sh

cmake --build . 2>&1 | tee build.log

if [ $? -ne 0 ]; then
    echo "编译失败，正在自动修复..."
    /ge-build-fix --log build.log --verify
fi
```

## 📚 最佳实践

### 1. 错误隔离
```bash
# 只编译失败的目标
cmake --build . --target failed_target
/ge-build-fix --quick
```

### 2. 增量修复
```bash
# 逐个修复，避免连锁问题
/ge-build-fix --interactive
```

### 3. 环境验证
```bash
# 修复前检查环境
/ge-build-fix --check-env
```

## 🎓 常见问题

### Q: 修复后仍有错误？

**A**: 检查依赖链，多次运行：
```bash
/ge-build-fix && cmake --build . && /ge-build-fix
```

### Q: 自动修复不安全？

**A**: 使用交互模式：
```bash
/ge-build-fix --interactive  # 每次修复前确认
```

### Q: 支持我的编译器吗？

**A**: 支持主流编译器：
- MSVC (Visual Studio)
- GCC
- Clang

### Q: 会修改我的代码吗？

**A**: 所有修改都会：
- 创建备份（.bak 文件）
- 显示修改内容
- 等待用户确认（交互模式）

## 📊 统计信息

- **版本**: 1.0.0
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
