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
| C3861 | 找不到标识符 | 检查命名空间 |
| C2664 | 参数转换失败 | 检查类型匹配 |
| LNK2019 | 链接错误 | 添加导出宏 |

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
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots"

# Linux
g++ --version                # 检查 GCC
clang++ --version            # 检查 Clang
ldconfig -p | grep vulkan    # 检查 Vulkan

# 环境变量
echo $VULKAN_SDK
echo %VULKAN_SDK%
```

## 常见修复模板

### 1. 缺少头文件

```cpp
// D3D12
#include <d3d12.h>
#include <dxgi1_6.h>
#pragma comment(lib, "d3d12.lib")

// Vulkan
#include <vulkan/vulkan.h>
```

### 2. 导出宏

```cpp
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif
```

### 3. CMake 依赖

```cmake
# D3D12 (Windows)
target_link_libraries(engine d3d12 dxgi)

# Vulkan
find_package(Vulkan REQUIRED)
target_link_libraries(engine Vulkan::Vulkan)
```

## 诊断流程

```
1. 读取日志 → 2. 分类错误 → 3. 环境检查
      ↓              ↓              ↓
   提取错误      识别类型      检查依赖
      ↓              ↓              ↓
4. 生成方案 → 5. 应用修复 → 6. 验证编译
```

## 成功指标

- ✅ 编译错误归零
- ✅ 链接错误解决
- ✅ 无新增警告
- ✅ 目标可执行

---

**快速参考版本**: 1.0.0
