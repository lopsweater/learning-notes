---
description: CPU 侧引擎代码测试驱动开发。数学库、内存分配器、工具类的 TDD 工作流，验证覆盖率和性能基准。
---

# 引擎 CPU 测试命令

此命令调用 **engine-cpu-tdd-guide** agent，强制执行 CPU 侧代码的测试驱动开发方法论。

## 此命令的功能

1. **定义接口** - 搭建 CPU 侧类/函数签名
2. **编写测试** - GoogleTest 单元测试
3. **运行测试** - 验证失败
4. **实现代码** - 最小化通过
5. **重构** - 保持测试通过
6. **检查覆盖率** - 80%+
7. **验证性能** - 无回归

## 适用范围（CPU 侧）

- 数学库（向量、矩阵、四元数）
- 内存分配器（线性、池、栈）
- 字符串处理
- 文件系统
- Asset 解析
- ECS 系统（Entity、Component）

## 不处理（使用 /engine-gpu-test）

- ❌ GPU Buffer/Texture
- ❌ Shader 编译
- ❌ 渲染管线
- ❌ Descriptor 管理

## TDD 循环

```
红 → 编写失败测试
绿 → 实现最小代码
重构 → 优化代码
验证 → 覆盖率 + 性能
```

## 示例会话

用户: /engine-cpu-test 我需要一个 SIMD 向量数学库

Agent:
# TDD 会话：SIMD 向量库

## 步骤 1：定义接口

```cpp
// math/vec3.hpp
#include <xmmintrin.h>

class Vec3 {
public:
    Vec3() = default;
    Vec3(float x, float y, float z);
    
    Vec3 operator+(const Vec3& rhs) const;
    Vec3 operator-(const Vec3& rhs) const;
    float dot(const Vec3& rhs) const;
    Vec3 cross(const Vec3& rhs) const;
    float length() const;
    Vec3 normalized() const;
    
private:
    __m128 data_;
};
```

## 步骤 2：编写测试（红）

```cpp
// tests/math/vec3_test.cpp
#include <gtest/gtest.h>
#include "math/vec3.hpp"

TEST(Vec3, 加法运算) {
    Vec3 a(1, 2, 3);
    Vec3 b(4, 5, 6);
    Vec3 result = a + b;
    
    EXPECT_FLOAT_EQ(result.x(), 5);
    EXPECT_FLOAT_EQ(result.y(), 7);
    EXPECT_FLOAT_EQ(result.z(), 9);
}

TEST(Vec3, 点积运算) {
    Vec3 a(1, 0, 0);
    Vec3 b(0, 1, 0);
    
    EXPECT_FLOAT_EQ(a.dot(b), 0);
}

TEST(Vec3, 叉积运算) {
    Vec3 a(1, 0, 0);
    Vec3 b(0, 1, 0);
    Vec3 result = a.cross(b);
    
    EXPECT_FLOAT_EQ(result.x(), 0);
    EXPECT_FLOAT_EQ(result.y(), 0);
    EXPECT_FLOAT_EQ(result.z(), 1);
}

TEST(Vec3, 归一化) {
    Vec3 v(3, 4, 0);
    Vec3 n = v.normalized();
    
    EXPECT_FLOAT_EQ(n.length(), 1.0f);
}

TEST(Vec3, 性能基准) {
    Vec3 a(1, 2, 3);
    Vec3 b(4, 5, 6);
    
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 100000; ++i) {
        a = a + b;
    }
    auto end = std::chrono::high_resolution_clock::now();
    
    auto us = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    EXPECT_LT(us, 1000); // 100k 次加法 <1ms
}
```

## 步骤 3：运行测试 - 验证失败

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: vec3_test .....***Failed
    --- undefined reference to `Vec3::operator+`

FAIL
```

✓ 测试失败如预期（未实现）。

## 步骤 4：实现最小代码（绿）

```cpp
// math/vec3.cpp
#include "vec3.hpp"
#include <cmath>

Vec3::Vec3(float x, float y, float z) {
    data_ = _mm_set_ps(0, z, y, x);
}

Vec3 Vec3::operator+(const Vec3& rhs) const {
    Vec3 result;
    result.data_ = _mm_add_ps(data_, rhs.data_);
    return result;
}

float Vec3::dot(const Vec3& rhs) const {
    __m128 mul = _mm_mul_ps(data_, rhs.data_);
    __m128 shuf = _mm_shuffle_ps(mul, mul, _MM_SHUFFLE(2, 3, 0, 1));
    __m128 sums = _mm_add_ps(mul, shuf);
    shuf = _mm_movehl_ps(shuf, sums);
    sums = _mm_add_ss(sums, shuf);
    return _mm_cvtss_f32(sums);
}

// ... 其他实现
```

## 步骤 5：运行测试 - 验证通过

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: vec3_test .....   Passed    0.02 sec

100% tests passed.
```

✓ 所有测试通过！

## 步骤 6：检查覆盖率

```bash
$ cmake -DCMAKE_CXX_FLAGS="--coverage" -B build && cmake --build build
$ ctest --test-dir build
$ lcov --capture --directory build --output-file coverage.info
$ lcov --list coverage.info

math/vec3.cpp     | 100%
```

✓ 覆盖率：100%

## TDD 完成！

## 覆盖率要求

| 组件 | 目标 |
|------|------|
| 数学库 | 100% |
| 内存分配器 | 95%+ |
| 字符串工具 | 90%+ |
| Asset 解析 | 85%+ |
| 通用 CPU 代码 | 80%+ |

## 性能基准要求

| 组件 | 目标 |
|------|------|
| 向量运算 | <10ns/次 |
| 矩阵乘法 | <100ns/次 |
| 内存分配 | <1μs/次 |
| 字符串解析 | <100μs/KB |

## 相关命令

- `/engine-cpu-build-fix` - 修复构建错误
- `/engine-cpu-review` - 审查代码质量
- `/engine-gpu-test` - GPU 侧测试

## 相关 Agent

- `agents/engine-cpu-tdd-guide.md`
- `skills/engine-cpu-testing/`
