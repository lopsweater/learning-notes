---
description: 修复 CPU 侧引擎代码构建错误。CMake 配置、C++ 编译、链接问题，不处理 Shader。
---

# 引擎 CPU 构建修复命令

此命令调用 **engine-cpu-build-resolver** agent，增量修复 CPU 侧构建错误。

## 此命令的功能

1. 运行诊断 - CMake + 编译 + 链接
2. 解析错误 - 按文件分组、按严重性排序
3. 增量修复 - 一次修复一个错误
4. 验证每个修复 - 重新构建
5. 汇总报告 - 显示已修复和剩余问题

## 适用范围（CPU 侧）

- CMake 配置错误
- C++ 编译错误
- 链接错误
- 模板实例化失败
- 头文件依赖问题

## 不处理（使用其他命令）

- ❌ Shader 编译 → `/shader-compile-fix`
- ❌ GPU 资源问题 → `/engine-gpu-build-fix`
- ❌ 运行时错误 → `/engine-cpu-test`

## 诊断命令

```bash
# CMake 配置
cmake -B build -S . -DCMAKE_BUILD_TYPE=Debug

# 编译
cmake --build build 2>&1 | head -100

# 静态分析（可选）
clang-tidy src/*.cpp -- -std=c++20
cppcheck --enable=all src/
```

## 常见错误修复表

| 错误 | 典型修复 |
|------|----------|
| `undeclared identifier` | 添加 `#include` 或修复拼写 |
| `no matching function` | 修复参数类型或添加重载 |
| `undefined reference` | 链接库或添加实现 |
| `multiple definition` | 使用 `inline` 或移到 .cpp |
| `incomplete type` | 前向声明改为 `#include` |
| `no member named X` | 修复成员名或添加 include |
| `cannot convert X to Y` | 添加适当的类型转换 |
| `CMake Error` | 修复 CMakeLists.txt 配置 |

## 示例会话

用户: /engine-cpu-build-fix

Agent:
# CPU 构建修复会话

## 初始诊断

```bash
$ cmake --build build
src/math/vec3.cpp:25:15: error: use of undeclared identifier 'sqrtf'
src/memory/allocator.cpp:42:9: error: no matching function for call to 'allocate'
src/memory/allocator.cpp:58:1: error: non-void function does not return a value
```

发现错误：3 个

## 修复 1：未声明标识符

文件：src/math/vec3.cpp:25
错误：use of undeclared identifier 'sqrtf'
原因：缺少 include

```cpp
// 添加 include
#include <cmath>
```

```bash
$ cmake --build build
# 剩余 2 个错误
```

## 修复 2：无匹配函数

文件：src/memory/allocator.cpp:42
错误：no matching function for call to 'allocate'

```cpp
// 修改前
allocate(size);  // 缺少对齐参数

// 修改后
allocate(size, 16);  // 添加默认对齐
```

```bash
$ cmake --build build
# 剩余 1 个错误
```

## 修复 3：缺少返回值

文件：src/memory/allocator.cpp:58
错误：non-void function does not return a value

```cpp
void* allocate(size_t size, size_t alignment) {
    if (size == 0) {
        return nullptr;
    }
    // ... 分配逻辑
    return ptr;  // 添加返回值
}
```

```bash
$ cmake --build build
# 构建成功！
```

## 最终验证

```bash
$ ctest --test-dir build --output-on-failure
Test project build
    1/5 Test #1: unit_tests ........   Passed    0.02 sec
    2/5 Test #2: integration_tests    Passed    0.15 sec
All tests passed.
```

## 汇总

| 指标 | 数量 |
|------|------|
| 编译错误修复 | 3 |
| 链接错误修复 | 0 |
| 修改文件数 | 2 |
| 剩余问题 | 0 |

构建状态：✅ 成功

## 修复策略

1. **编译错误优先** - 代码必须先编译
2. **链接错误其次** - 解决未定义引用
3. **警告第三** - 使用 `-Wall -Wextra` 修复
4. **一次修复一个** - 每次修复后验证
5. **最小化修改** - 不重构，只修复

## 停止条件

Agent 将在以下情况停止并报告：

- 同一错误在 3 次尝试后仍然存在
- 修复引入更多错误
- 需要架构性变更
- 缺少外部依赖

## 相关命令

- `/engine-cpu-test` - 构建成功后运行测试
- `/engine-cpu-review` - 审查代码质量
- `/verify` - 完整验证循环

## 相关 Agent

- `agents/engine-cpu-build-resolver.md`
