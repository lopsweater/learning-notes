---
name: ge-build-fix
description: 游戏引擎编译修复工具。自动诊断和修复游戏引擎特有的编译错误，支持跨平台（Windows/Linux/macOS）、多编译器（MSVC/GCC/Clang）、图形 API（D3D12/Vulkan/OpenGL）的编译问题。
allowed_tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
origin: GameEngine
---

# 游戏引擎编译修复 Skill

自动诊断和修复游戏引擎特有的编译错误，提供智能修复建议。

## When to Activate

- 游戏引擎编译失败
- 跨平台编译问题（Windows/Linux/macOS）
- 图形 API 编译错误（D3D12/Vulkan/OpenGL）
- 链接错误和依赖问题
- 构建系统问题（CMake/UBT）
- Unreal Engine/Godot 自定义引擎编译

## Core Principles

### 1. 最小化改动
只修复错误本身，不重构、不改变架构、不进行改进

### 2. 快速迭代
修复一个错误 → 验证 → 下一个错误

### 3. 平台感知
根据目标平台和编译器提供针对性修复

### 4. 智能诊断
先诊断根因，再提供最小修复方案

## Error Classification

### Category 1: Compiler Errors

#### MSVC (Windows)

**C2065 - 未声明标识符**
```
error C2065: 'ID3D12Device': undeclared identifier
```

诊断：
```bash
# 检查头文件包含
grep -r "#include.*d3d12" --include="*.cpp" --include="*.h"

# 检查命名空间
grep -r "using namespace" --include="*.cpp" | head -10
```

修复：
```cpp
// 添加头文件
#include <d3d12.h>
#include <dxgi1_6.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
```

**C2011 - 类型重定义**
```
error C2011: 'RHITexture': 'struct' type redefinition
```

修复：
```cpp
// 添加头文件保护
#pragma once

#ifndef RHI_TEXTURE_H
#define RHI_TEXTURE_H

struct RHITexture { /* ... */ };

#endif
```

**C2664 - 参数转换失败**
```
error C2664: 'void CreateDevice(ID3D12Device **)': cannot convert argument 1 from 'ID3D12Device *' to 'ID3D12Device **'
```

修复：
```cpp
// 使用 IID_PPV_ARGS
ID3D12Device* device;
CreateDevice(&device);  // ❌ 错误

CreateDevice(IID_PPV_ARGS(&device));  // ✅ 正确
```

#### GCC/Clang (Linux/macOS)

**未定义引用**
```
undefined reference to `vulkan::CreateInstance'
```

诊断：
```bash
# 检查 Vulkan SDK
ldconfig -p | grep vulkan
echo $VULKAN_SDK

# 检查 CMake 配置
grep -r "find_package(Vulkan)" CMakeLists.txt
grep -r "target_link_libraries.*Vulkan" CMakeLists.txt
```

修复：
```cmake
# CMakeLists.txt
find_package(Vulkan REQUIRED)
target_link_libraries(engine Vulkan::Vulkan)
```

**模板实例化失败**
```
error: no matching function for call to 'CreateBuffer<uint32_t>(size_t)'
```

修复：
```cpp
// 显式实例化
template<>
RHIBuffer* CreateBuffer<uint32_t>(size_t size) { /* ... */ }

// 或提供默认实现
template<typename T>
RHIBuffer* CreateBuffer(size_t size) {
    return CreateBufferImpl(sizeof(T) * size);
}
```

### Category 2: Graphics API Errors

#### D3D12 特有错误

**接口未找到**
```
error C3861: 'D3D12CreateDevice': identifier not found
```

修复：
```cpp
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")

HRESULT hr = D3D12CreateDevice(
    adapter,
    D3D_FEATURE_LEVEL_12_0,
    IID_PPV_ARGS(&device)
);
```

**资源屏障错误**
```
error C2664: 'ResourceBarrier': cannot convert from 'D3D12_RESOURCE_BARRIER' to 'D3D12_RESOURCE_BARRIER *'
```

修复：
```cpp
// 错误用法
cmdList->ResourceBarrier(1, barrier);  // barrier 是对象

// 正确用法
D3D12_RESOURCE_BARRIER barrier = {};
barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
// ... 配置 barrier

cmdList->ResourceBarrier(1, &barrier);  // 传递地址
```

#### Vulkan 特有错误

**扩展未加载**
```
Segmentation fault at vkCreateSwapchainKHR
```

诊断：
```bash
# 检查扩展加载
vulkaninfo --summary | grep "Extensions"

# 检查实例创建
grep -A20 "vkCreateInstance" src/vulkan_instance.cpp
```

修复：
```cpp
// 动态加载扩展
PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR =
    (PFN_vkCreateSwapchainKHR)vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR");

if (!vkCreateSwapchainKHR) {
    throw std::runtime_error("Failed to load vkCreateSwapchainKHR");
}

// 或使用 Volk 库
#include <volk.h>
volkInitialize();
// 所有扩展自动加载
```

**版本不匹配**
```
error: 'VkPhysicalDeviceFeatures2' has no member named 'pNext'
```

修复：
```cpp
// 使用 Vulkan 1.1+ 结构体
#define VK_API_VERSION VK_API_VERSION_1_3

VkPhysicalDeviceFeatures2 features2 = {};
features2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
features2.pNext = nullptr;

vkGetPhysicalDeviceFeatures2(physDevice, &features2);
```

### Category 3: Linker Errors

**LNK2019 - 无法解析的外部符号**
```
error LNK2019: unresolved external symbol "public: __cdecl RHIDevice::RHIDevice(void)"
```

诊断：
```bash
# 检查源文件是否在构建中
find . -name "RHIDevice.cpp"
grep -r "RHIDevice.cpp" CMakeLists.txt

# 检查导出宏
grep -r "RHI_API" include/rhi/RHIDevice.h
```

修复：
```cpp
// include/rhi/RHIDevice.h
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif

class RHI_API RHIDevice {
public:
    RHIDevice();
};

// src/rhi/RHIDevice.cpp
#define ENGINE_BUILD_RHI
#include "RHIDevice.h"

RHIDevice::RHIDevice() { /* 实现 */ }
```

**undefined reference to ...**
```
undefined reference to `RHIDevice::CreateBuffer'
```

修复：
```cmake
# 确保源文件在构建中
add_library(rhi
    src/rhi/rhi_device.cpp
    src/rhi/rhi_buffer.cpp
    src/rhi/rhi_texture.cpp
)

target_link_libraries(engine rhi)
```

### Category 4: Build System Errors

**CMake FindPackage 失败**
```
CMake Error: Could not find a package configuration file provided by "Vulkan"
```

修复：
```cmake
# 方案 1: 设置环境变量
export VULKAN_SDK=/path/to/VulkanSDK

# 方案 2: 指定路径
set(VULKAN_SDK "/path/to/VulkanSDK/1.3.239.0")
find_package(Vulkan REQUIRED
    PATHS "${VULKAN_SDK}"
    NO_DEFAULT_PATH
)

# 方案 3: 安装依赖
# Linux
sudo apt install libvulkan-dev

# Windows
# 下载并安装 Vulkan SDK
```

**编译选项冲突**
```
CMake Error: Option 'ENABLE_VULKAN' cannot be both ON and OFF
```

修复：
```cmake
# 使用缓存变量
option(ENABLE_VULKAN "Enable Vulkan backend" ON)

# 或使用条件判断
if(NOT DEFINED ENABLE_VULKAN)
    option(ENABLE_VULKAN "Enable Vulkan backend" ON)
endif()
```

## Diagnostic Workflow

### Step 1: Build & Capture

```bash
# 清理构建
rm -rf build

# 重新配置
cmake .. -DCMAKE_BUILD_TYPE=Debug -DENABLE_VULKAN=ON

# 编译并捕获日志
cmake --build build --parallel 2>&1 | tee build.log

# 提取错误
grep -i "error" build.log | head -20
grep -i "LNK\|LINK" build.log
grep -i "C[0-9][0-9][0-9][0-9]" build.log
```

### Step 2: Classify & Prioritize

```bash
# 统计错误类型
grep -o "error C[0-9]*" build.log | sort | uniq -c

# 按文件分组
grep "error" build.log | cut -d: -f1 | sort | uniq -c | sort -rn
```

### Step 3: Environment Check

```bash
# 编译器版本
g++ --version
clang++ --version
cl.exe

# 平台 SDK
# Windows
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots"

# Linux
ldconfig -p | grep -E "vulkan|opengl"

# 环境变量
env | grep -E "VULKAN|DXSDK|WindowsSDK"
```

### Step 4: Fix & Verify

```bash
# 应用修复
# ... 编辑文件 ...

# 重新编译
cmake --build build --target failed_target

# 验证
if [ $? -eq 0 ]; then
    echo "✅ 修复成功"
else
    echo "❌ 仍有错误，继续修复"
fi
```

## Fix Templates

### Template 1: Missing Header

```cpp
// 诊断：缺少头文件
// 错误：C2065 undeclared identifier

// 修复：添加条件包含
#if defined(_WIN32)
    #include <d3d12.h>
    #include <dxgi1_6.h>
    #pragma comment(lib, "d3d12.lib")
    #pragma comment(lib, "dxgi.lib")
#elif defined(__linux__)
    #include <vulkan/vulkan.h>
#endif
```

### Template 2: Export Macro

```cpp
// 诊断：链接错误
// 错误：LNK2019 unresolved external symbol

// 修复：添加导出宏
#ifdef ENGINE_BUILD_MODULE
    #define MODULE_API __declspec(dllexport)
#else
    #define MODULE_API __declspec(dllimport)
#endif

class MODULE_API MyClass {
    // ...
};
```

### Template 3: CMake Dependency

```cmake
# 诊断：FindPackage 失败
# 错误：Could not find Vulkan

# 修复：配置依赖路径
find_package(Vulkan REQUIRED
    PATHS "${VULKAN_SDK}"
    NO_DEFAULT_PATH
)

target_link_libraries(engine
    PRIVATE
        Vulkan::Vulkan
)
```

## Best Practices

### 1. 增量修复
```bash
# 一次只修复一个错误
cmake --build build 2>&1 | tee build.log
# 修复第一个错误
# 重新编译
cmake --build build
```

### 2. 错误隔离
```bash
# 只编译失败的目标
cmake --build build --target failed_target

# 查看详细命令
cmake --build build -- VERBOSE=1
```

### 3. 预处理器调试
```bash
# 查看宏展开
g++ -E file.cpp -o file.i
cl.exe /P file.cpp

# 检查宏定义
grep "#define" file.i
```

### 4. 符号检查
```bash
# Linux
nm -C libengine.so | grep CreateDevice
readelf -s libengine.so | grep CreateDevice

# Windows
dumpbin /SYMBOLS engine.lib | findstr CreateDevice
dumpbin /EXPORTS engine.dll | findstr CreateDevice
```

## Success Metrics

✅ 编译错误归零
✅ 链接错误解决
✅ 目标可执行
✅ 无新增错误
✅ 更改行数 < 5%
✅ 构建时间合理

---

**Version**: 2.0.0 | **Created**: 2026-03-31
