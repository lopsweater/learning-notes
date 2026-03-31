# GE Build Fix 快速参考

## 一句话使用

```bash
/ge-build-fix              # 自动修复编译错误
```

## 常用命令

```bash
# 基础用法
/ge-build-fix                      # 自动诊断修复
/ge-build-fix --quick              # 快速模式（只修第一个错）
/ge-build-fix --all                # 修复所有错误

# 针对性修复
/ge-build-fix --error C2065        # 修复特定错误
/ge-build-fix --platform windows   # 针对 Windows
/ge-build-fix --compiler msvc      # 针对 MSVC
/ge-build-fix --api vulkan         # 针对 Vulkan

# 高级用法
/ge-build-fix --interactive        # 交互模式（逐步确认）
/ge-build-fix --verify             # 修复后验证编译
/ge-build-fix --log build.log      # 从日志分析
```

## 错误代码速查

### MSVC 错误

| 错误代码 | 说明 | 快速修复 |
|----------|------|---------|
| C2065 | 未声明标识符 | 添加头文件 |
| C2011 | 类型重定义 | 添加头文件保护 |
| C2664 | 参数转换失败 | 检查类型匹配 |
| C3861 | 找不到标识符 | 检查命名空间 |
| C2988 | 模板实例化失败 | 添加类型约束 |

### 链接错误

| 错误代码 | 说明 | 快速修复 |
|----------|------|---------|
| LNK2019 | 符号未解析 | 添加导出宏 |
| LNK2001 | 外部符号未找到 | 添加源文件到构建 |

### GCC/Clang 错误

| 错误类型 | 说明 | 快速修复 |
|----------|------|---------|
| undeclared | 未声明 | 添加头文件 |
| undefined reference | 链接错误 | 添加库链接 |
| cannot find | 找不到文件 | 检查路径配置 |

## 平台检查命令

```bash
# Windows
where cl.exe                 # 检查 MSVC
where d3d12.dll              # 检查 D3D12
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots"

# Linux
g++ --version                # 检查 GCC
clang++ --version            # 检查 Clang
ldconfig -p | grep vulkan    # 检查 Vulkan
echo $VULKAN_SDK             # 检查环境变量

# macOS
clang++ --version            # 检查 Clang
xcodebuild -version          # 检查 Xcode
```

## 常见修复模板

### 1. 缺少头文件（D3D12）

```cpp
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")
```

### 2. 缺少头文件（Vulkan）

```cpp
#include <vulkan/vulkan.h>

// CMakeLists.txt
find_package(Vulkan REQUIRED)
target_link_libraries(engine Vulkan::Vulkan)
```

### 3. 导出宏（Windows）

```cpp
#ifdef ENGINE_BUILD_MODULE
    #define MODULE_API __declspec(dllexport)
#else
    #define MODULE_API __declspec(dllimport)
#endif

class MODULE_API MyClass { /* ... */ };
```

### 4. 导出宏（Linux）

```cpp
#ifdef ENGINE_BUILD_MODULE
    #define MODULE_API __attribute__((visibility("default")))
#else
    #define MODULE_API
#endif
```

### 5. CMake 依赖

```cmake
# Vulkan
find_package(Vulkan REQUIRED)
target_link_libraries(engine Vulkan::Vulkan)

# D3D12 (Windows)
if(WIN32)
    target_link_libraries(engine d3d12 dxgi d3dcompiler)
endif()
```

## 诊断流程

```
1. 读取日志 → 2. 分类错误 → 3. 环境检查
      ↓              ↓              ↓
   提取错误      识别类型      检查依赖
      ↓              ↓              ↓
4. 生成方案 → 5. 应用修复 → 6. 验证编译
```

## 工作流程原则

### ✅ 做

- 添加缺失的头文件
- 添加必要的库链接
- 修复类型不匹配
- 添加导出宏
- 修复 CMake 配置
- 添加类型转换

### ❌ 不做

- 重构无关代码
- 改变架构设计
- 重命名变量（除非导致错误）
- 添加新功能
- 改变逻辑流程
- 优化性能

## 优先级等级

| 等级 | 症状 | 行动 |
|------|------|------|
| **致命** | 编译器崩溃 | 立即修复 |
| **严重** | 整个项目无法编译 | 立即修复 |
| **高** | 单个模块失败 | 尽快修复 |
| **中** | 特定平台错误 | 按需修复 |
| **低** | 编译警告 | 在可能时修复 |

## 成功指标

- ✅ 编译错误归零
- ✅ 链接错误解决
- ✅ 目标可执行
- ✅ 无新增错误
- ✅ 更改行数 < 5%
- ✅ 构建时间合理

## 快速故障排除

### Q: 修复后仍有错误？

```bash
/ge-build-fix
cmake --build build
/ge-build-fix  # 再次运行
```

### Q: 自动修复不正确？

```bash
/ge-build-fix --interactive  # 交互模式
```

### Q: 平台不匹配？

```bash
/ge-build-fix --platform linux --compiler gcc
```

### Q: 完全清理重建？

```bash
rm -rf build CMakeCache.txt
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build --parallel
```

---

**快速参考版本**: 2.0.0
