---
name: ge-build-fix
description: 游戏引擎编译修复命令。自动诊断和修复游戏引擎特有的编译错误，支持跨平台、多编译器、图形 API 的编译问题。
allowed_tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
---

# /ge-build-fix - 游戏引擎编译修复

自动诊断和修复游戏引擎编译错误，提供智能修复建议。

## 使用方法

```bash
/ge-build-fix                              # 自动诊断并修复
/ge-build-fix --error C2065                # 修复特定错误代码
/ge-build-fix --platform windows           # 针对特定平台
/ge-build-fix --compiler msvc              # 针对特定编译器
/ge-build-fix --api vulkan                 # 针对特定图形 API
/ge-build-fix --log build.log              # 从日志文件分析
/ge-build-fix --quick                      # 快速模式（只修第一个错）
/ge-build-fix --all                        # 修复所有错误
/ge-build-fix --interactive                # 交互模式（逐步确认）
/ge-build-fix --verify                     # 修复后验证编译
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
| `--all` | 修复所有错误 | false |
| `--interactive` | 交互模式，每次修复前确认 | false |
| `--verify` | 修复后自动重新编译验证 | false |

## 工作流程

```
┌─────────────────────────────────────┐
│  步骤 1: 构建并捕获日志              │
│     ↓                                │
│  步骤 2: 提取并分类错误              │
│     ├─ 编译错误（语法/类型/模板）   │
│     ├─ 链接错误（符号/库）          │
│     └─ 配置错误（CMake/环境）       │
│     ↓                                │
│  步骤 3: 环境诊断                    │
│     ├─ 编译器版本                   │
│     ├─ SDK 安装状态                 │
│     └─ 依赖库                       │
│     ↓                                │
│  步骤 4: 生成修复方案                │
│     ├─ 代码修改                     │
│     ├─ CMake 配置                   │
│     └─ 环境调整                     │
│     ↓                                │
│  步骤 5: 应用修复                    │
│     ↓                                │
│  步骤 6: 验证编译                    │
│     ↓                                │
│  ✅ 成功 或 ❌ 继续修复              │
└─────────────────────────────────────┘
```

## 执行步骤

### 步骤 1：构建并捕获日志

```bash
#!/bin/bash
# ge-build-fix.sh

# 检查是否有构建日志
if [ -f "build.log" ]; then
    echo "📖 使用现有构建日志: build.log"
else
    echo "🔨 正在构建并捕获日志..."

    # 清理旧构建（可选）
    # rm -rf build

    # 重新配置
    if [ ! -d "build" ]; then
        cmake -B build -DCMAKE_BUILD_TYPE=Debug
    fi

    # 编译
    cmake --build build --parallel 2>&1 | tee build.log
fi

# 提取错误信息
ERRORS=$(grep -i "error" build.log | head -20)
echo ""
echo "🔍 发现的错误："
echo "$ERRORS"
```

### 步骤 2：提取并分类错误

```bash
#!/bin/bash

# 错误分类函数
classify_errors() {
    local log="$1"

    # 统计 MSVC 错误
    echo "📊 错误统计："
    echo ""
    echo "编译错误 (MSVC):"
    grep -o "error C[0-9]*" "$log" | sort | uniq -c | sort -rn

    echo ""
    echo "链接错误 (MSVC):"
    grep -o "error LNK[0-9]*" "$log" | sort | uniq -c | sort -rn

    echo ""
    echo "GCC/Clang 错误:"
    grep "error:" "$log" | cut -d: -f4 | sort | uniq -c | sort -rn | head -10

    echo ""
    echo "CMake 错误:"
    grep "CMake Error" "$log" | cut -d: -f2- | sort | uniq
}

# 按文件分组
group_by_file() {
    local log="$1"

    echo ""
    echo "📁 错误按文件分布："
    grep "error" "$log" | grep -oP "[^:]+\.[^:]+:" | sort | uniq -c | sort -rn | head -10
}

# 执行分类
classify_errors "build.log"
group_by_file "build.log"
```

### 步骤 3：环境诊断

```bash
#!/bin/bash

diagnose_environment() {
    echo "🔧 环境诊断："
    echo ""

    # 操作系统
    if [ "$OSTYPE" == "msys" ] || [ "$OSTYPE" == "win32" ]; then
        PLATFORM="windows"
        echo "平台: Windows"

        # MSVC 检查
        if command -v cl.exe &> /dev/null; then
            echo "编译器: MSVC"
            cl.exe 2>&1 | head -1
        fi

        # Windows SDK
        if [ -d "C:/Program Files (x86)/Windows Kits/10" ]; then
            echo "✅ Windows SDK 已安装"
        else
            echo "❌ Windows SDK 未安装"
        fi

        # D3D12
        if [ -f "C:/Windows/System32/d3d12.dll" ]; then
            echo "✅ D3D12 已安装"
        else
            echo "❌ D3D12 未找到"
        fi

    elif [ "$OSTYPE" == "linux-gnu" ]; then
        PLATFORM="linux"
        echo "平台: Linux"

        # GCC
        if command -v g++ &> /dev/null; then
            echo "编译器: GCC"
            g++ --version | head -1
        fi

        # Clang
        if command -v clang++ &> /dev/null; then
            echo "编译器: Clang"
            clang++ --version | head -1
        fi

        # Vulkan
        if [ -n "$VULKAN_SDK" ]; then
            echo "✅ Vulkan SDK: $VULKAN_SDK"
        else
            echo "❌ Vulkan SDK 未设置"
        fi

        # Vulkan 库
        if ldconfig -p | grep -q "libvulkan.so"; then
            echo "✅ libvulkan.so 已安装"
        else
            echo "❌ libvulkan.so 未找到"
            echo "   💡 安装: sudo apt install libvulkan-dev"
        fi

    elif [ "$OSTYPE" == "darwin"* ]; then
        PLATFORM="macos"
        echo "平台: macOS"

        # Clang
        if command -v clang++ &> /dev/null; then
            echo "编译器: Clang"
            clang++ --version | head -1
        fi

        # Xcode
        if command -v xcodebuild &> /dev/null; then
            echo "✅ Xcode 已安装"
            xcodebuild -version | head -1
        fi
    fi

    # CMake
    echo ""
    cmake --version | head -1
}

# 执行诊断
diagnose_environment
```

### 步骤 4：生成修复方案

```bash
#!/bin/bash

generate_fix() {
    local error_type="$1"
    local error_msg="$2"
    local file="$3"

    case "$error_type" in
        "C2065")
            echo "📝 错误类型: 未声明标识符 (C2065)"
            echo "💡 诊断: 缺少头文件或命名空间"
            echo ""

            # 检测图形 API
            if echo "$error_msg" | grep -q "D3D12"; then
                echo "🎯 检测到 D3D12，建议添加:"
                echo ""
                echo "修复代码:"
                echo "```cpp"
                echo "#include <d3d12.h>"
                echo "#include <dxgi1_6.h>"
                echo ""
                echo "#pragma comment(lib, \"d3d12.lib\")"
                echo "#pragma comment(lib, \"dxgi.lib\")"
                echo "```"
            elif echo "$error_msg" | grep -q "Vulkan"; then
                echo "🎯 检测到 Vulkan，建议添加:"
                echo ""
                echo "修复代码:"
                echo "```cpp"
                echo "#include <vulkan/vulkan.h>"
                echo "```"
            fi
            ;;

        "LNK2019")
            echo "📝 错误类型: 链接错误 (LNK2019)"
            echo "💡 诊断: 无法解析的外部符号"
            echo ""

            # 提取符号
            SYMBOL=$(echo "$error_msg" | grep -oP '(?<=symbol ")[^"]+')
            echo "符号: $SYMBOL"
            echo ""
            echo "修复方案:"
            echo "1. 检查源文件是否在构建中"
            echo "2. 添加导出宏: __declspec(dllexport)"
            echo "3. 确保方法已实现"
            echo ""
            echo "修复代码:"
            echo "```cpp"
            echo "// 添加导出宏"
            echo "#ifdef ENGINE_BUILD_MODULE"
            echo "    #define MODULE_API __declspec(dllexport)"
            echo "#else"
            echo "    #define MODULE_API __declspec(dllimport)"
            echo "#endif"
            echo ""
            echo "class MODULE_API ClassName {"
            echo "    // ..."
            echo "};"
            echo "```"
            ;;

        "cmake_find_package")
            echo "📝 错误类型: CMake 依赖查找失败"
            echo "💡 诊断: 无法找到依赖包"
            echo ""

            # 提取包名
            PACKAGE=$(echo "$error_msg" | grep -oP '(?<=by ")[^"]+')
            echo "依赖: $PACKAGE"
            echo ""
            echo "修复方案:"
            echo "1. 设置环境变量"
            echo "2. 指定路径"
            echo "3. 安装依赖"
            echo ""

            if [ "$PACKAGE" == "Vulkan" ]; then
                echo "Vulkan SDK 配置:"
                echo "```bash"
                echo "# 设置环境变量"
                echo "export VULKAN_SDK=/path/to/VulkanSDK/1.3.239.0"
                echo ""
                echo "# CMake 配置"
                echo "cmake -DVULKAN_SDK=\$VULKAN_SDK .."
                echo ""
                echo "# 或在 CMakeLists.txt 中"
                echo "set(VULKAN_SDK \$ENV{VULKAN_SDK})"
                echo "find_package(Vulkan REQUIRED PATHS \"\${VULKAN_SDK}\")"
                echo "```"
            fi
            ;;
    esac
}

# 从错误日志提取并生成修复
ERROR_TYPE=$(grep -o "error [A-Z][0-9]*" build.log | head -1 | awk '{print $2}')
ERROR_MSG=$(grep "error $ERROR_TYPE" build.log | head -1)
ERROR_FILE=$(echo "$ERROR_MSG" | grep -oP "^[^:]+")

generate_fix "$ERROR_TYPE" "$ERROR_MSG" "$ERROR_FILE"
```

### 步骤 5：应用修复

```bash
#!/bin/bash

apply_fix() {
    local file="$1"
    local fix_type="$2"

    echo "🔧 正在修复: $file"
    echo "修复类型: $fix_type"
    echo ""

    # 备份
    if [ -f "$file" ]; then
        cp "$file" "$file.bak"
        echo "✅ 已备份: $file.bak"
    fi

    case "$fix_type" in
        "add_d3d12_header")
            # 在文件开头添加头文件
            sed -i '1i\#include <d3d12.h>\n#include <dxgi1_6.h>\n' "$file"
            sed -i '4i\#pragma comment(lib, "d3d12.lib")\n#pragma comment(lib, "dxgi.lib")\n' "$file"
            echo "✅ 已添加 D3D12 头文件和库链接"
            ;;

        "add_export_macro")
            # 添加导出宏定义
            sed -i '1i\#ifdef ENGINE_BUILD_MODULE\n    #define MODULE_API __declspec(dllexport)\n#else\n    #define MODULE_API __declspec(dllimport)\n#endif\n' "$file"
            echo "✅ 已添加导出宏"
            ;;

        "fix_cmake")
            # 修复 CMakeLists.txt
            if [ -f "CMakeLists.txt" ]; then
                cp CMakeLists.txt CMakeLists.txt.bak

                echo "" >> CMakeLists.txt
                echo "# Vulkan support (auto-added by ge-build-fix)" >> CMakeLists.txt
                echo "find_package(Vulkan REQUIRED)" >> CMakeLists.txt
                echo "target_link_libraries(engine Vulkan::Vulkan)" >> CMakeLists.txt

                echo "✅ 已修复 CMakeLists.txt"
            fi
            ;;
    esac

    echo ""
    echo "📝 修改摘要:"
    diff -u "$file.bak" "$file"
}

# 示例：应用 D3D12 头文件修复
# apply_fix "src/renderer/d3d12_device.cpp" "add_d3d12_header"
```

### 步骤 6：验证编译

```bash
#!/bin/bash

verify_build() {
    echo "🔨 正在重新编译..."
    echo ""

    # 重新编译
    cmake --build build --parallel 2>&1 | tee verify.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "✅ 编译成功！"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # 统计
        echo "📊 构建统计:"
        echo "  - 编译文件: $(find build -name "*.o" -o -name "*.obj" | wc -l)"
        echo "  - 链接目标: $(find build -type f -executable | wc -l)"
        echo "  - 构建时间: $(grep "real" verify.log 2>/dev/null || echo "N/A")"
    else
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "⚠️  仍有编译错误"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        # 统计剩余错误
        ERRORS=$(grep -c "error" verify.log)
        echo "剩余错误: $ERRORS 个"
        echo ""

        echo "前 5 个错误:"
        grep "error" verify.log | head -5

        echo ""
        echo "💡 建议: 继续运行 /ge-build-fix 修复剩余错误"
    fi
}

# 执行验证
verify_build
```

## 示例输出

### 示例 1：D3D12 未声明标识符

```
用户: /ge-build-fix

🔍 GE Build Fix - 游戏引擎编译修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 步骤 1: 读取构建日志
🔨 步骤 2: 分析错误

📊 错误统计:
  编译错误 (MSVC): 3
    2  error C2065
    1  error C3861

📁 错误分布:
  3  src/renderer/d3d12_device.cpp:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔧 步骤 3: 环境诊断
  平台: Windows
  编译器: MSVC 19.37.32825
  ✅ Windows SDK 已安装
  ✅ D3D12 已安装

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 步骤 4: 修复方案

错误 1/3: C2065 - 未声明标识符
  文件: src/renderer/d3d12_device.cpp:45
  符号: ID3D12Device

  💡 诊断: 缺少 D3D12 头文件

  修复代码:
  ```cpp
  #include <d3d12.h>
  #include <dxgi1_6.h>

  #pragma comment(lib, "d3d12.lib")
  #pragma comment(lib, "dxgi.lib")
  ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 是否应用修复？(y/n/all)
```

### 示例 2：链接错误

```
用户: /ge-build-fix --error LNK2019

🔍 GE Build Fix - 链接错误修复

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📝 错误类型: 链接错误 (LNK2019)
📍 符号: RHIDevice::CreateBuffer
📍 库: engine.lib

💡 诊断: 无法解析的外部符号

🔧 检查结果:
  ✅ 源文件存在: src/rhi/rhi_device.cpp
  ✅ 方法已实现
  ❌ 缺少导出宏

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 修复方案:

1. 在 include/rhi/RHIDevice.h 添加导出宏:

```cpp
#ifdef ENGINE_BUILD_RHI
    #define RHI_API __declspec(dllexport)
#else
    #define RHI_API __declspec(dllimport)
#endif

class RHI_API RHIDevice {
    // ...
};
```

2. 在 src/rhi/RHIDevice.cpp 定义:

```cpp
#define ENGINE_BUILD_RHI
#include "RHIDevice.h"
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 是否自动应用修复？(y/n)
```

## 高级用法

### 批量修复

```bash
# 修复所有错误
/ge-build-fix --all

# 输出:
# 发现 15 个错误
# 正在修复...
# ✅ 已修复 12 个错误
# ⚠️  剩余 3 个错误需要手动处理
```

### 交互模式

```bash
# 逐步确认每个修复
/ge-build-fix --interactive

# 输出:
# 发现 5 个错误
#
# 错误 1/5: C2065
# 文件: src/renderer/d3d12_device.cpp
# 修复: 添加 #include <d3d12.h>
#
# 应用此修复？(y/n/skip/all)
```

### 验证模式

```bash
# 修复后自动编译验证
/ge-build-fix --verify

# 输出:
# ✅ 已应用修复
# 🔨 正在重新编译...
# [========================================] 100%
# ✅ 编译成功！
```

## 集成到项目

### CLAUDE.md 配置

```markdown
# 编译修复工具

使用 `/ge-build-fix` 自动修复编译错误。

## 支持的错误类型

- MSVC 错误 (C2065, C2011, C2664, C3861...)
- 链接错误 (LNK2019, LNK2001...)
- CMake 错误 (FindPackage, 依赖配置...)
- 图形 API 错误 (D3D12, Vulkan, OpenGL)

## 快速使用

```bash
/ge-build-fix              # 自动修复
/ge-build-fix --verify     # 修复后验证
/ge-build-fix --all        # 批量修复
```

## 相关命令

- `/module-analysis` - 引擎架构分析
- `/ge-not-allowed` - 违规检查
```

## 故障排除

### Q: 修复后仍有错误？

**A**: 检查依赖链，多次运行：
```bash
/ge-build-fix
cmake --build build
/ge-build-fix  # 再次运行
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

***

*Created for Game Engine Development | Version 2.0.0*
