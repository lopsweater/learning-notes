---
name: ge-build-fix
description: 游戏引擎编译修复命令。自动诊断和修复游戏引擎特有的编译错误，支持跨平台、多编译器、图形 API 的编译问题。
allowed_tools: ["Read", "Glob", "Grep", "Bash", "Write", "Edit"]
---

# /ge-build-fix - 游戏引擎编译修复

自动诊断和修复游戏引擎编译错误，提供智能修复建议。

## 使用方法

```bash
/ge-build-fix                              # 分析并修复最近的编译错误
/ge-build-fix --error "C2065"              # 修复特定错误代码
/ge-build-fix --platform windows           # 针对特定平台
/ge-build-fix --compiler msvc              # 针对特定编译器
/ge-build-fix --api vulkan                 # 针对特定图形 API
/ge-build-fix --log build.log              # 从日志文件分析
/ge-build-fix --quick                      # 快速模式（只修复第一个错误）
```

## 参数说明

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--error` | 错误代码（如 C2065, LNK2019） | 自动检测 |
| `--platform` | 目标平台（windows/linux/macos） | 自动检测 |
| `--compiler` | 编译器（msvc/gcc/clang） | 自动检测 |
| `--api` | 图形 API（d3d12/vulkan/opengl） | 全部支持 |
| `--log` | 构建日志文件路径 | `build.log` |
| `--quick` | 快速模式，只修复第一个错误 | false |

## 功能说明

### 自动诊断流程

```
┌─────────────────────────────────────┐
│  1. 读取构建日志                     │
│     ↓                                │
│  2. 提取错误信息                     │
│     ├─ 错误代码                      │
│     ├─ 文件位置                      │
│     └─ 错误描述                      │
│     ↓                                │
│  3. 分类错误类型                     │
│     ├─ 平台特定错误                  │
│     ├─ 图形 API 错误                 │
│     ├─ 模板/类型错误                 │
│     ├─ 链接错误                      │
│     └─ CMake 错误                    │
│     ↓                                │
│  4. 环境检查                         │
│     ├─ 编译器版本                    │
│     ├─ SDK 安装                      │
│     └─ 依赖库                        │
│     ↓                                │
│  5. 生成修复方案                     │
│     ├─ 代码修改                      │
│     ├─ CMake 配置                    │
│     └─ 环境调整                      │
│     ↓                                │
│  6. 应用修复并验证                   │
└─────────────────────────────────────┘
```

## 分析步骤

### 步骤 1：读取构建日志

```bash
# 提取构建日志
if [ -f "build.log" ]; then
    echo "📖 读取构建日志: build.log"
    ERRORS=$(grep -i "error" build.log | head -20)
else
    echo "⚠️  未找到构建日志，正在执行编译..."
    cmake --build build 2>&1 | tee build.log
    ERRORS=$(grep -i "error" build.log | head -20)
fi

# 显示错误摘要
echo ""
echo "🔍 发现的错误："
echo "$ERRORS"
```

### 步骤 2：错误分类

```bash
# 错误分类函数
classify_error() {
    local error="$1"

    # MSVC 错误代码
    if echo "$error" | grep -qE "error C[0-9]+" ; then
        echo "msvc"
    # GCC/Clang 错误
    elif echo "$error" | grep -qE "error:|fatal error:" ; then
        echo "gcc_clang"
    # 链接错误
    elif echo "$error" | grep -qE "LNK[0-9]+|undefined reference" ; then
        echo "linker"
    # CMake 错误
    elif echo "$error" | grep -qE "CMake Error" ; then
        echo "cmake"
    else
        echo "unknown"
    fi
}

# 图形 API 检测
detect_graphics_api() {
    local file="$1"

    if grep -q "d3d12\|D3D12" "$file"; then
        echo "d3d12"
    elif grep -q "vulkan\|Vulkan" "$file"; then
        echo "vulkan"
    elif grep -q "opengl\|OpenGL" "$file"; then
        echo "opengl"
    else
        echo "unknown"
    fi
}
```

### 步骤 3：环境检查

```bash
# 检查编译环境
check_environment() {
    echo "🔧 检查编译环境..."

    # 检测操作系统
    if [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "win32" ]; then
        PLATFORM="windows"
        echo "  平台: Windows"

        # 检查 MSVC
        if command -v cl.exe &> /dev/null; then
            cl.exe 2>&1 | head -1
            COMPILER="msvc"
        fi

        # 检查 Windows SDK
        if [ -d "C:/Program Files (x86)/Windows Kits/10" ]; then
            echo "  ✅ Windows SDK 已安装"
        else
            echo "  ❌ Windows SDK 未安装"
        fi

    elif [ "$OSTYPE" == "linux-gnu" ]; then
        PLATFORM="linux"
        echo "  平台: Linux"

        # 检查 GCC
        if command -v g++ &> /dev/null; then
            g++ --version | head -1
            COMPILER="gcc"
        fi

        # 检查 Clang
        if command -v clang++ &> /dev/null; then
            clang++ --version | head -1
            COMPILER="clang"
        fi

        # 检查 Vulkan SDK
        if [ -n "$VULKAN_SDK" ]; then
            echo "  ✅ Vulkan SDK: $VULKAN_SDK"
        else
            echo "  ❌ Vulkan SDK 未设置"
        fi
    fi

    # 检查 CMake
    cmake --version | head -1
}
```

### 步骤 4：依赖检查

```bash
# 检查图形 API 依赖
check_graphics_dependencies() {
    local api="$1"

    case "$api" in
        d3d12)
            # Windows 检查
            if [ "$PLATFORM" == "windows" ]; then
                if [ -f "C:/Windows/System32/d3d12.dll" ]; then
                    echo "  ✅ D3D12.dll 已安装"
                else
                    echo "  ❌ D3D12.dll 未找到"
                fi
            else
                echo "  ⚠️  D3D12 仅支持 Windows 平台"
            fi
            ;;

        vulkan)
            # 检查 Vulkan 库
            if [ "$PLATFORM" == "linux" ]; then
                if ldconfig -p | grep -q "libvulkan.so"; then
                    echo "  ✅ libvulkan.so 已安装"
                else
                    echo "  ❌ libvulkan.so 未找到"
                    echo "  💡 安装: sudo apt install libvulkan-dev"
                fi
            elif [ "$PLATFORM" == "windows" ]; then
                if [ -f "C:/Windows/System32/vulkan-1.dll" ]; then
                    echo "  ✅ vulkan-1.dll 已安装"
                else
                    echo "  ❌ vulkan-1.dll 未找到"
                fi
            fi

            # 检查 Vulkan 头文件
            if find /usr -name "vulkan.h" 2>/dev/null | grep -q .; then
                echo "  ✅ vulkan.h 已安装"
            else
                echo "  ❌ vulkan.h 未找到"
            fi
            ;;

        opengl)
            # 检查 OpenGL
            if [ "$PLATFORM" == "linux" ]; then
                if ldconfig -p | grep -q "libGL.so"; then
                    echo "  ✅ libGL.so 已安装"
                else
                    echo "  ❌ libGL.so 未找到"
                    echo "  💡 安装: sudo apt install libgl1-mesa-dev"
                fi
            fi
            ;;
    esac
}
```

### 步骤 5：生成修复方案

```bash
# 根据错误类型生成修复方案
generate_fix() {
    local error_type="$1"
    local error_msg="$2"
    local file="$3"

    case "$error_type" in
        "msvc_c2065")
            echo "📝 错误类型: 未声明标识符 (C2065)"
            echo "💡 诊断: 缺少头文件或命名空间"
            echo ""
            echo "修复方案:"
            echo "1. 检查是否包含正确的头文件"
            echo "2. 检查命名空间是否正确"
            echo "3. 检查是否需要平台特定宏"

            # 自动检测缺少的头文件
            if echo "$error_msg" | grep -q "D3D12"; then
                echo ""
                echo "🎯 检测到 D3D12 类型，建议添加:"
                echo "   #include <d3d12.h>"
                echo "   #pragma comment(lib, \"d3d12.lib\")"
            fi
            ;;

        "linker_lnk2019")
            echo "📝 错误类型: 链接错误 (LNK2019)"
            echo "💡 诊断: 无法解析的外部符号"
            echo ""
            echo "修复方案:"
            echo "1. 检查源文件是否在构建中"
            echo "2. 检查导出/导入宏定义"
            echo "3. 检查库依赖配置"

            # 检查导出宏
            if grep -r "RHI_API" "$file" 2>/dev/null; then
                echo ""
                echo "🎯 检测到 RHI_API 宏，检查定义:"
                grep -r "RHI_API\|RHI_EXPORT" "$file"
            fi
            ;;

        "cmake_find_package")
            echo "📝 错误类型: CMake 依赖查找失败"
            echo "💡 诊断: 无法找到依赖包"
            echo ""
            echo "修复方案:"
            echo "1. 检查环境变量设置"
            echo "2. 指定依赖路径"
            echo "3. 安装缺失的依赖"

            if echo "$error_msg" | grep -q "Vulkan"; then
                echo ""
                echo "🎯 Vulkan SDK 配置:"
                echo "   export VULKAN_SDK=/path/to/VulkanSDK"
                echo "   cmake -DVULKAN_SDK=$VULKAN_SDK .."
            fi
            ;;
    esac
}
```

### 步骤 6：应用修复

```bash
# 应用自动修复
apply_fix() {
    local file="$1"
    local fix_type="$2"

    echo "🔧 正在修复: $file"
    echo "修复类型: $fix_type"
    echo ""

    case "$fix_type" in
        "add_header")
            # 备份原文件
            cp "$file" "$file.bak"

            # 在文件开头添加头文件
            sed -i '1i\#include <d3d12.h>' "$file"

            echo "✅ 已添加 #include <d3d12.h>"
            ;;

        "add_pragma_lib")
            # 在头文件后添加库链接
            sed -i '/#include.*d3d12.h/a #pragma comment(lib, "d3d12.lib")' "$file"

            echo "✅ 已添加 #pragma comment(lib, \"d3d12.lib\")"
            ;;

        "fix_cmake")
            # 修复 CMakeLists.txt
            local cmake_file="CMakeLists.txt"

            if [ -f "$cmake_file" ]; then
                # 备份
                cp "$cmake_file" "$cmake_file.bak"

                # 添加 Vulkan 链接
                if ! grep -q "Vulkan::Vulkan" "$cmake_file"; then
                    echo "" >> "$cmake_file"
                    echo "# Vulkan support" >> "$cmake_file"
                    echo "find_package(Vulkan REQUIRED)" >> "$cmake_file"
                    echo "target_link_libraries(engine Vulkan::Vulkan)" >> "$cmake_file"
                    echo "✅ 已添加 Vulkan 依赖配置"
                fi
            fi
            ;;
    esac

    echo ""
    echo "📝 原文件已备份: $file.bak"
}
```

## 示例输出

### 示例 1：修复 D3D12 未声明标识符错误

```
用户: /ge-build-fix

🔍 GE Build Fix - 游戏引擎编译修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 读取构建日志...
🔍 分析错误...

发现错误:
  src/renderer/d3d12_device.cpp:45: error C2065: 'ID3D12Device': undeclared identifier

📝 错误类型: 未声明标识符 (C2065)
📍 文件: src/renderer/d3d12_device.cpp
📍 平台: Windows (MSVC)
📍 API: D3D12

💡 诊断: 缺少 D3D12 头文件

🔧 正在检查环境...
  ✅ Windows SDK 已安装
  ✅ D3D12.dll 已安装
  ❌ 缺少 #include <d3d12.h>

💡 修复方案:
  1. 添加 #include <d3d12.h>
  2. 添加 #include <dxgi1_6.h>
  3. 添加库链接

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 修复代码:

// 在文件开头添加:
#include <d3d12.h>
#include <dxgi1_6.h>
#include <d3dcompiler.h>

#pragma comment(lib, "d3d12.lib")
#pragma comment(lib, "dxgi.lib")
#pragma comment(lib, "d3dcompiler.lib")

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 是否自动应用修复？(y/n)
```

### 示例 2：修复链接错误

```
用户: /ge-build-fix --error LNK2019

🔍 GE Build Fix - 链接错误修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 错误类型: 链接错误 (LNK2019)
📍 符号: RHIDevice::CreateBuffer
📍 库: engine.lib

💡 诊断: 无法解析的外部符号

🔧 正在检查...
  ✅ 源文件存在: src/rhi/rhi_device.cpp
  ✅ 方法已实现
  ❌ 缺少导出宏定义

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 修复方案:

1. 在 include/rhi/RHIDevice.h 添加:

   #ifdef ENGINE_BUILD_RHI
       #define RHI_API __declspec(dllexport)
   #else
       #define RHI_API __declspec(dllimport)
   #endif

   class RHI_API RHIDevice {
       // ...
   };

2. 在 src/rhi/RHIDevice.cpp 添加:

   #define ENGINE_BUILD_RHI
   #include "RHIDevice.h"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 是否自动应用修复？(y/n)
```

### 示例 3：修复 CMake 依赖错误

```
用户: /ge-build-fix --log build.log

🔍 GE Build Fix - CMake 配置修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 错误类型: CMake 依赖查找失败
📍 依赖: Vulkan

💡 诊断: VULKAN_SDK 环境变量未设置

🔧 环境检查:
  ❌ VULKAN_SDK 未设置

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 修复方案:

1. 设置环境变量:
   export VULKAN_SDK=/path/to/VulkanSDK/1.3.239.0

2. 或在 CMakeLists.txt 中指定路径:
   set(VULKAN_SDK "/path/to/VulkanSDK/1.3.239.0")
   find_package(Vulkan REQUIRED PATHS "${VULKAN_SDK}")

3. 安装 Vulkan SDK:
   wget https://sdk.lunarg.com/sdk/download/latest/linux/vulkan-sdk.tar.xz
   tar -xf vulkan-sdk.tar.xz
   source ./setup-env.sh

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 推荐执行:
  cmake -DVULKAN_SDK=/usr/local/VulkanSDK/1.3.239.0 ..

是否现在执行？(y/n)
```

## 高级用法

### 批量修复

```bash
# 修复所有编译错误
/ge-build-fix --all

# 只修复特定类型
/ge-build-fix --type linker
/ge-build-fix --type msvc
/ge-build-fix --type cmake
```

### 交互模式

```bash
# 逐步确认每个修复
/ge-build-fix --interactive

# 输出:
# 发现 3 个错误
#
# 错误 1/3: C2065 - 未声明标识符
# 文件: src/renderer/d3d12_device.cpp
# 修复: 添加 #include <d3d12.h>
#
# 应用此修复？(y/n/skip/all)
```

### 验证修复

```bash
# 修复后自动编译验证
/ge-build-fix --verify

# 输出:
# ✅ 修复已应用
# 🔨 正在重新编译...
# [========================================] 100%
# ✅ 编译成功！
```

## 集成到项目

### 在 CLAUDE.md 中添加

```markdown
# 编译修复工具

使用 `/ge-build-fix` 命令自动修复编译错误：

- 编译失败时自动运行
- 支持跨平台修复（Windows/Linux）
- 支持图形 API 错误（D3D12/Vulkan）

快速使用:
  /ge-build-fix              # 自动诊断修复
  /ge-build-fix --quick      # 快速模式
```

## 相关命令

- `/module-analysis` - 引擎架构分析
- `/ge-not-allowed` - 违规检查

## 故障排除

### Q: 修复后仍有错误？

**A**: 检查依赖链，可能需要多次运行：
```bash
/ge-build-fix
cmake --build build
/ge-build-fix  # 再次运行
```

### Q: 自动修复不正确？

**A**: 使用交互模式手动确认：
```bash
/ge-build-fix --interactive
```

### Q: 平台不匹配？

**A**: 明确指定平台和编译器：
```bash
/ge-build-fix --platform linux --compiler gcc
```

***

*Created for Game Engine Development | Version 1.0.0*
