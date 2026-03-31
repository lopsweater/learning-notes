---
name: ge-build-fix
description: 游戏引擎编译修复工具。自动诊断和修复游戏引擎特有的编译错误，支持跨平台（Windows/Linux）、多编译器（MSVC/GCC/Clang）、图形 API（D3D12/Vulkan/OpenGL）的编译问题。
allowed_tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit"]
origin: EVC
---

# 游戏引擎编译修复 Skill

自动诊断和修复游戏引擎特有的编译错误，提供智能修复建议。

## When to Activate

- 游戏引擎编译失败
- 跨平台编译问题（Windows/Linux/macOS）
- 图形 API 编译错误（D3D12/Vulkan/OpenGL）
- 链接错误和依赖问题
- 构建系统问题（CMake/Makefile）
- 性能优化相关编译警告

## Core Principles

### 1. 智能诊断优先
先诊断根因，再提供修复方案

### 2. 平台感知
根据目标平台和编译器提供针对性修复

### 3. 最小化改动
优先修复错误本身，避免大规模重构

### 4. 验证修复
修复后重新编译验证，确保问题解决

## Error Categories

### Category 1: Platform-Specific Errors

#### Windows (MSVC) 常见错误

**错误类型：C2065 未声明标识符**
```
error C2065: 'ID3D12Device': undeclared identifier
```

**诊断**:
```bash
# 检查是否包含正确的头文件
grep -r "#include.*d3d12" --include="*.h" --include="*.cpp"

# 检查 Windows SDK 版本
grep -r "WindowsTargetPlatformVersion" CMakeLists.txt
```

**修复方案**:
```cpp
// ❌ 错误：缺少头文件
void CreateDevice() {
    ID3D12Device* device; // C2065
}

// ✅ 修复：包含正确的头文件
#include <d3d12.h>
#include <dxgi1_6.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")

void CreateDevice() {
    ID3D12Device* device; // OK
}
```

**错误类型：C2011 重定义**
```
error C2011: 'RHITexture': 'struct' type redefinition
```

**诊断**:
```bash
# 检查头文件保护
grep -r "#pragma once" include/rhi/RHITexture.h
grep -r "#ifndef.*RHITexture" include/rhi/RHITexture.h

# 检查是否多次包含
grep -r "#include.*RHITexture.h" --include="*.cpp" | wc -l
```

**修复方案**:
```cpp
// ❌ 错误：缺少头文件保护
struct RHITexture {
    // ...
};

// ✅ 修复：添加头文件保护
#pragma once

#ifndef RHI_TEXTURE_H
#define RHI_TEXTURE_H

struct RHITexture {
    // ...
};

#endif // RHI_TEXTURE_H
```

#### Linux (GCC/Clang) 常见错误

**错误类型：未定义引用**
```
undefined reference to `vulkan::CreateInstance'
```

**诊断**:
```bash
# 检查 Vulkan 库是否安装
ldconfig -p | grep vulkan

# 检查 CMake 链接配置
grep -r "vulkan" CMakeLists.txt
grep -r "target_link_libraries" CMakeLists.txt
```

**修复方案**:
```cmake
# ❌ 错误：缺少 Vulkan 链接
find_package(Vulkan REQUIRED)
add_executable(engine src/main.cpp)

# ✅ 修复：添加 Vulkan 库链接
find_package(Vulkan REQUIRED)
add_executable(engine src/main.cpp)
target_link_libraries(engine Vulkan::Vulkan)
```

**错误类型：版本不匹配**
```
error: 'VkPhysicalDeviceFeatures2' does not declare 'pNext'
```

**诊断**:
```bash
# 检查 Vulkan 版本
vulkaninfo | grep "Vulkan Instance Version"

# 检查代码中的版本定义
grep -r "VK_API_VERSION" --include="*.cpp"
```

**修复方案**:
```cpp
// ❌ 错误：Vulkan 1.0 结构体
VkPhysicalDeviceFeatures features;
vkGetPhysicalDeviceFeatures(physDevice, &features);

// ✅ 修复：使用 Vulkan 1.1+ 扩展结构
VkPhysicalDeviceFeatures2 features2 = {};
features2.sType = VK_STRUCTURE_TYPE_PHYSICAL_DEVICE_FEATURES_2;
features2.pNext = nullptr; // 链式结构

vkGetPhysicalDeviceFeatures2(physDevice, &features2);
```

### Category 2: Graphics API Errors

#### D3D12 特有错误

**错误类型：D3D12 接口未找到**
```
error C3861: 'D3D12CreateDevice': identifier not found
```

**诊断步骤**:
```bash
# 1. 检查 Windows SDK 版本
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots" /v KitsRoot10

# 2. 检查 CMake 配置
cmake --graphviz=deps.dot .
grep -r "Windows.SDK" CMakeCache.txt

# 3. 检查头文件包含顺序
grep -B5 -A5 "#include.*d3d12" src/renderer/d3d12_device.cpp
```

**修复方案**:
```cpp
// ❌ 错误：头文件包含顺序错误
#include <d3d12.h>  // 基础 D3D12
#include <dxgi1_6.h>  // DXGI 1.6（需要先包含 d3d12.h）
#include <d3dx12.h>  // D3D12 辅助库（可选）

// ✅ 修复：正确的包含顺序
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>  // 着色器编译

// 链接库
#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")

// 使用
HRESULT hr = D3D12CreateDevice(
    adapter,
    D3D_FEATURE_LEVEL_12_0,
    IID_PPV_ARGS(&device)
);
```

**错误类型：COM 指针错误**
```
error C2664: 'D3D12CreateDevice': cannot convert argument 3 from 'ID3D12Device **' to 'REFIID'
```

**修复方案**:
```cpp
// ❌ 错误：错误的参数传递
ID3D12Device* device;
D3D12CreateDevice(adapter, D3D_FEATURE_LEVEL_12_0, &device);

// ✅ 修复：使用 IID_PPV_ARGS 宏
ID3D12Device* device;
D3D12CreateDevice(
    adapter,
    D3D_FEATURE_LEVEL_12_0,
    IID_PPV_ARGS(&device)
);

// 或使用智能指针（推荐）
#include <wrl/client.h>
using Microsoft::WRL::ComPtr;

ComPtr<ID3D12Device> device;
D3D12CreateDevice(
    adapter,
    D3D_FEATURE_LEVEL_12_0,
    IID_PPV_ARGS(&device)
);
```

#### Vulkan 特有错误

**错误类型：Vulkan 扩展未加载**
```
Segmentation fault (core dumped) at vkCreateSwapchainKHR
```

**诊断**:
```bash
# 检查扩展加载
grep -r "vkCreateSwapchainKHR" --include="*.cpp"
grep -r "vkGetInstanceProcAddr" --include="*.cpp"

# 检查实例扩展
vulkaninfo --summary | grep "Extensions"
```

**修复方案**:
```cpp
// ❌ 错误：直接调用扩展函数
VkSwapchainKHR swapchain;
vkCreateSwapchainKHR(device, &createInfo, nullptr, &swapchain); // Crash!

// ✅ 修复：动态加载扩展函数
PFN_vkCreateSwapchainKHR vkCreateSwapchainKHR =
    (PFN_vkCreateSwapchainKHR)vkGetDeviceProcAddr(device, "vkCreateSwapchainKHR");

if (!vkCreateSwapchainKHR) {
    throw std::runtime_error("Failed to load vkCreateSwapchainKHR");
}

VkSwapchainKHR swapchain;
vkCreateSwapchainKHR(device, &createInfo, nullptr, &swapchain);

// 或使用 Volk 库（推荐）
#include <volk.h>

// 初始化
volkInitialize();

// 自动加载所有扩展
VkSwapchainKHR swapchain;
vkCreateSwapchainKHR(device, &createInfo, nullptr, &swapchain);
```

### Category 3: Template & Type Errors

**错误类型：模板实例化失败**
```
error C2975: 'SIZE': invalid template argument for 'Array', expected compile-time constant expression
```

**修复方案**:
```cpp
// ❌ 错误：使用运行时变量
void CreateBuffer(uint32_t size) {
    Array<int, size> arr; // Error: size is runtime value
}

// ✅ 修复：使用编译时常量
constexpr uint32_t BUFFER_SIZE = 1024;

void CreateBuffer() {
    Array<int, BUFFER_SIZE> arr; // OK
}

// 或使用动态数组
void CreateBuffer(uint32_t size) {
    std::vector<int> arr(size); // OK
}
```

**错误类型：类型转换错误**
```
error C2440: 'reinterpret_cast': cannot convert from 'void *' to 'uint64_t'
```

**修复方案**:
```cpp
// ❌ 错误：指针直接转整数
void* ptr = buffer;
uint64_t address = reinterpret_cast<uint64_t>(ptr); // Error on 32-bit

// ✅ 修复：使用 uintptr_t
void* ptr = buffer;
uintptr_t address = reinterpret_cast<uintptr_t>(ptr); // Platform-safe

// 或使用 std::bit_cast (C++20)
#include <bit>
uint64_t address = std::bit_cast<uint64_t>(ptr);
```

### Category 4: Linker Errors

**错误类型：LNK2019 无法解析的外部符号**
```
error LNK2019: unresolved external symbol "public: __cdecl RHIDevice::RHIDevice(void)"
```

**诊断步骤**:
```bash
# 1. 检查源文件是否在构建中
grep -r "RHIDevice.cpp" CMakeLists.txt
find . -name "RHIDevice.cpp"

# 2. 检查导出宏
grep -r "RHI_API" include/rhi/RHIDevice.h
grep -r "RHI_EXPORT" src/rhi/RHIDevice.cpp

# 3. 检查库依赖
ldd libengine.so | grep rhi  # Linux
dumpbin /DEPENDENTS engine.exe | findstr rhi  # Windows
```

**修复方案**:
```cpp
// ❌ 错误：缺少导出宏
// RHIDevice.h
class RHIDevice {
public:
    RHIDevice(); // 未导出
};

// ✅ 修复：添加导出宏
// RHIDevice.h
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif

class RHI_API RHIDevice {
public:
    RHIDevice();
};

// RHIDevice.cpp
#define ENGINE_BUILD_RHI
#include "RHIDevice.h"

RHIDevice::RHIDevice() {
    // Implementation
}
```

### Category 5: CMake Build Errors

**错误类型：找不到依赖**
```
CMake Error: Could not find a package configuration file provided by "Vulkan"
```

**诊断**:
```bash
# 检查环境变量
echo $VULKAN_SDK
echo %VULKAN_SDK%  # Windows

# 检查 CMake 缓存
cat CMakeCache.txt | grep Vulkan

# 检查 CMake 模块路径
cmake --help-module-list | grep FindVulkan
```

**修复方案**:
```cmake
# ❌ 错误：缺少必要配置
find_package(Vulkan REQUIRED)

# ✅ 修复：指定 Vulkan SDK 路径
set(VULKAN_SDK "C:/VulkanSDK/1.3.239.0")
find_package(Vulkan REQUIRED
    PATHS "${VULKAN_SDK}"
    NO_DEFAULT_PATH
)

# 或使用环境变量
if(DEFINED ENV{VULKAN_SDK})
    set(VULKAN_SDK $ENV{VULKAN_SDK})
    message(STATUS "Using Vulkan SDK: ${VULKAN_SDK}")
endif()

find_package(Vulkan REQUIRED)
```

**错误类型：编译选项冲突**
```
CMake Error: Option 'ENABLE_VULKAN' cannot be both ON and OFF
```

**修复方案**:
```cmake
# ❌ 错误：重复定义选项
option(ENABLE_VULKAN "Enable Vulkan backend" ON)
# ... 其他地方 ...
option(ENABLE_VULKAN "Enable Vulkan backend" OFF)  # 冲突！

# ✅ 修复：使用条件判断
option(ENABLE_VULKAN "Enable Vulkan backend" ON)

# 确保选项只定义一次
if(NOT DEFINED ENABLE_VULKAN)
    option(ENABLE_VULKAN "Enable Vulkan backend" ON)
endif()
```

## Diagnostic Workflow

### Step 1: Error Analysis

```bash
# 提取错误信息
cmake --build build 2>&1 | tee build.log

# 分析错误类型
grep -i "error" build.log | head -20
grep -i "undefined reference" build.log
grep -i "cannot find" build.log

# 检查编译器版本
gcc --version
clang --version
cl.exe 2>&1 | head -1
```

### Step 2: Environment Check

```bash
# 检查构建环境
cmake --version
ninja --version

# 检查平台 SDK
# Windows
where cl.exe
where link.exe
reg query "HKLM\SOFTWARE\Microsoft\Windows Kits\Installed Roots"

# Linux
ldconfig -p | grep vulkan
pkg-config --list-all | grep vulkan

# 检查环境变量
env | grep -E "(VULKAN|DXSDK|WindowsSDK)"
```

### Step 3: Dependency Verification

```bash
# 检查依赖库
find /usr -name "libvulkan.so"
find /usr -name "libd3d12.so"  # 可能不存在（Windows only）

# 检查头文件
find /usr -name "vulkan.h"
find /usr -name "d3d12.h"

# 检查 CMake 模块
cmake --help-module-list | grep -i vulkan
```

### Step 4: Targeted Fix

根据错误类型，应用对应的修复方案：

1. **平台特定错误** → 检查平台宏和 SDK
2. **图形 API 错误** → 检查头文件和链接
3. **模板错误** → 检查类型和编译时常量
4. **链接错误** → 检查导出和库依赖
5. **CMake 错误** → 检查构建配置

### Step 5: Verification

```bash
# 清理构建
rm -rf build
mkdir build && cd build

# 重新配置
cmake .. -DCMAKE_BUILD_TYPE=Debug -DENABLE_VULKAN=ON

# 重新编译
cmake --build . --parallel

# 运行测试
ctest --output-on-failure
```

## Fix Templates

### Template 1: Missing Header

```cpp
// 检测：缺少头文件
// Error: undeclared identifier

// 修复步骤：
// 1. 识别需要的头文件
// 2. 检查平台兼容性
// 3. 添加条件包含

// 示例：
#if defined(_WIN32)
    #include <d3d12.h>
    #include <dxgi1_6.h>
    #pragma comment(lib, "d3d12.lib")
#elif defined(__linux__)
    #include <vulkan/vulkan.h>
    #define VK_USE_PLATFORM_XLIB_KHR
#endif
```

### Template 2: Platform Macro

```cpp
// 检测：平台特定代码在错误平台编译

// 修复步骤：
// 1. 添加平台检查宏
// 2. 提供替代实现或占位符

// 示例：
#if defined(_WIN32)
    // Windows 实现
    #include <d3d12.h>
    class D3D12Device : public RHIDevice { /* ... */ };
#elif defined(__linux__)
    // Linux 实现
    #include <vulkan/vulkan.h>
    class VulkanDevice : public RHIDevice { /* ... */ };
#else
    #error "Unsupported platform"
#endif
```

### Template 3: Linker Fix

```cmake
# 检测：链接错误

# 修复步骤：
# 1. 确认库文件存在
# 2. 添加正确的链接配置

# 示例：
if(WIN32)
    target_link_libraries(engine
        d3d12
        dxgi
        d3dcompiler
    )
elseif(UNIX AND NOT APPLE)
    find_package(Vulkan REQUIRED)
    target_link_libraries(engine
        Vulkan::Vulkan
        xcb  # Linux window system
    )
endif()
```

## Common Patterns

### Pattern 1: Cross-Platform API Abstraction

```cpp
// 平台无关接口
class RHIDevice {
public:
    virtual ~RHIDevice() = default;
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
};

// 平台特定实现
#if defined(_WIN32)
    #include "d3d12/D3D12Device.h"
    using DeviceImpl = D3D12Device;
#elif defined(__linux__)
    #include "vulkan/VulkanDevice.h"
    using DeviceImpl = VulkanDevice;
#endif

// 统一创建接口
std::unique_ptr<RHIDevice> CreateDevice() {
    return std::make_unique<DeviceImpl>();
}
```

### Pattern 2: Conditional Compilation

```cpp
// 根据编译选项启用不同后端
#ifdef ENABLE_D3D12
    #include "d3d12/D3D12Backend.h"
#endif

#ifdef ENABLE_VULKAN
    #include "vulkan/VulkanBackend.h"
#endif

class Renderer {
public:
    void Initialize(RenderAPI api) {
        switch (api) {
            #ifdef ENABLE_D3D12
            case RenderAPI::D3D12:
                backend_ = std::make_unique<D3D12Backend>();
                break;
            #endif

            #ifdef ENABLE_VULKAN
            case RenderAPI::Vulkan:
                backend_ = std::make_unique<VulkanBackend>();
                break;
            #endif

            default:
                throw std::runtime_error("Unsupported render API");
        }
    }
};
```

## Best Practices

### 1. 错误隔离
```bash
# 只编译出错的目标
cmake --build . --target failed_target

# 查看详细编译命令
cmake --build . -- VERBOSE=1
```

### 2. 增量编译
```bash
# 清理特定文件
rm -f CMakeFiles/target.dir/src/file.cpp.o

# 重新编译
cmake --build . --target target
```

### 3. 预处理器输出
```bash
# 查看预处理结果
g++ -E file.cpp -o file.i
cl.exe /P file.cpp

# 检查宏展开
grep -A10 "RHIDevice" file.i
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

## Troubleshooting Checklist

- [ ] 确认编译器版本兼容
- [ ] 检查平台 SDK 安装
- [ ] 验证环境变量配置
- [ ] 检查头文件包含路径
- [ ] 确认库文件链接正确
- [ ] 验证导出/导入宏定义
- [ ] 检查 CMake 配置选项
- [ ] 清理并重新构建
- [ ] 检查依赖库版本匹配

## Success Metrics

- ✅ 编译错误数量归零
- ✅ 链接错误全部解决
- ✅ 目标平台可执行
- ✅ 无新增警告
- ✅ 构建时间合理（<5分钟）

---

**Version**: 1.0.0 | **Created**: 2026-03-31
