---
description: 修复 GPU 侧引擎代码构建错误。RHI 抽象层、渲染管线相关，包含 GPU 资源管理代码。
---

# 引擎 GPU 构建修复命令

此命令调用 **engine-gpu-build-resolver** agent，增量修复 GPU 侧构建错误。

## 此命令的功能

1. 运行诊断 - CMake + 编译 + 链接
2. 解析错误 - 按文件分组、按严重性排序
3. 增量修复 - 一次修复一个错误
4. 验证每个修复 - 重新构建
5. 汇总报告 - 显示已修复和剩余问题

## 适用范围（GPU 侧）

- RHI 抽象层代码
- GPU Buffer/Texture 管理
- Descriptor Heap 代码
- Command List 封装
- 渲染管线代码

## 不处理（使用其他命令）

- ❌ Shader 编译 → `/shader-compile-fix`
- ❌ CPU 侧代码 → `/engine-cpu-build-fix`

## 诊断命令

```bash
# CMake 配置（包含图形 API）
cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug -DENABLE_D3D12=ON

# 编译
cmake --build build 2>&1 | head -100

# 静态分析（可选）
clang-tidy src/rhi/*.cpp src/render/*.cpp -- -std=c++20
```

## 常见错误修复表

| 错误 | 典型修复 |
|------|----------|
| `undefined reference to D3D12` | 链接 d3d12.lib, dxgi.lib |
| `ID3D12Device not found` | 添加 `#include <d3d12.h>` |
| `Vulkan header not found` | 安装 Vulkan SDK |
| `DXGI_FORMAT_* undeclared` | 添加 `#include <dxgi1_6.h>` |
| `RHI interface not implemented` | 实现纯虚函数 |
| `Resource barrier error` | 检查 D3D12_RESOURCE_STATES |

## 示例会话

用户: /engine-gpu-build-fix

Agent:
# GPU 构建修复会话

## 初始诊断

```bash
$ cmake --build build
src/rhi/d3d12_device.cpp:15:5: error: 'ID3D12Device' was not declared
src/rhi/d3d12_device.cpp:42:9: error: undefined reference to 'D3D12CreateDevice'
src/rhi/buffer.cpp:58:1: error: 'D3D12_RESOURCE_STATES' does not name a type
```

发现错误：3 个

## 修复 1：缺少头文件

文件：src/rhi/d3d12_device.cpp:15
错误：'ID3D12Device' was not declared

```cpp
// 添加 include
#include <d3d12.h>
#include <dxgi1_6.h>
```

```bash
$ cmake --build build
# 剩余 2 个错误
```

## 修复 2：链接库缺失

文件：CMakeLists.txt
错误：undefined reference to 'D3D12CreateDevice'

```cmake
# 添加链接库
target_link_libraries(EngineRHI
    PRIVATE
        d3d12
        dxgi
)
```

```bash
$ cmake --build build
# 剩余 1 个错误
```

## 修复 3：类型未声明

文件：src/rhi/buffer.cpp:58
错误：'D3D12_RESOURCE_STATES' does not name a type

```cpp
// 添加 include
#include <d3d12.h>

// 或使用前向声明
enum D3D12_RESOURCE_STATES;
```

```bash
$ cmake --build build
# 构建成功！
```

## 最终验证

```bash
$ ctest --test-dir build -L gpu --output-on-failure
Test project build
    1/3 Test #1: buffer_test ........   Passed
    2/3 Test #2: texture_test .......   Passed
    3/3 Test #3: descriptor_test ....   Passed
All tests passed.
```

## 汇总

| 指标 | 数量 |
|------|------|
| 编译错误修复 | 2 |
| 链接错误修复 | 1 |
| 修改文件数 | 2 |
| 剩余问题 | 0 |

构建状态：✅ 成功

## GPU 特有检查项

### 头文件依赖

| 图形 API | 必需头文件 |
|----------|-----------|
| D3D12 | `<d3d12.h>`, `<dxgi1_6.h>` |
| Vulkan | `<vulkan/vulkan.h>` |
| 跨平台 RHI | 条件编译宏 |

### 链接库依赖

| 图形 API | 必需库 |
|----------|--------|
| D3D12 | `d3d12.lib`, `dxgi.lib` |
| Vulkan | `vulkan.lib` |

### CMake 配置

```cmake
option(ENABLE_D3D12 "Enable D3D12 backend" ON)
option(ENABLE_VULKAN "Enable Vulkan backend" OFF)

if(ENABLE_D3D12)
    target_compile_definitions(EngineRHI PRIVATE RHI_D3D12)
    target_link_libraries(EngineRHI PRIVATE d3d12 dxgi)
endif()

if(ENABLE_VULKAN)
    find_package(Vulkan REQUIRED)
    target_compile_definitions(EngineRHI PRIVATE RHI_VULKAN)
    target_link_libraries(EngineRHI PRIVATE Vulkan::Vulkan)
endif()
```

## 相关命令

- `/engine-gpu-test` - 构建成功后运行测试
- `/engine-gpu-review` - 审查代码质量
- `/shader-compile-fix` - Shader 编译问题

## 相关 Agent

- `agents/engine-gpu-build-resolver.md`
