---
name: engine-cpu-testing
description: Use this skill when implementing math library, memory allocators, utilities, or CPU-side engine code. Enforces test-driven development with SIMD optimization and performance benchmarks.
origin: EVC
---

# Engine CPU Testing Workflow

This skill ensures all CPU-side engine code follows TDD principles with comprehensive test coverage.

## When to Activate

- Implementing math library (vectors, matrices, quaternions)
- Writing memory allocators
- Developing utility classes
- Asset parsing logic
- ECS systems

## CPU 测试类型

### 单元测试
- 数学函数
- 分配器逻辑
- 字符串处理

### SIMD 测试
- 对齐验证
- 性能对比

### 性能基准测试
- 运算速度
- 内存分配速度
- 缓存友好性

### 并发测试
- 多线程安全
- 数据竞争检测

## 测试模式

### 数学库测试

```cpp
TEST(Vec3, 运算正确性) {
    Vec3 a(1, 2, 3);
    Vec3 b(4, 5, 6);
    
    // 测试加法
    Vec3 sum = a + b;
    EXPECT_FLOAT_EQ(sum.x(), 5);
    
    // 测试点积
    EXPECT_FLOAT_EQ(a.dot(b), 32);
    
    // 测试归一化
    Vec3 n = a.normalized();
    EXPECT_NEAR(n.length(), 1.0f, 1e-6f);
}

TEST(Vec3, SIMD对齐) {
    alignas(16) Vec3 v(1, 2, 3);
    EXPECT_EQ(reinterpret_cast<uintptr_t>(&v) % 16, 0);
}

TEST(Vec3, SIMD性能) {
    std::vector<Vec3> data(10000);
    
    auto start = std::chrono::high_resolution_clock::now();
    for (auto& v : data) {
        v = v.normalized();
    }
    auto end = std::chrono::high_resolution_clock::now();
    
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(end - start).count();
    EXPECT_LT(ms, 10); // 10k 次归一化 <10ms
}
```

### 内存分配器测试

```cpp
TEST(LinearAllocator, 基本功能) {
    LinearAllocator allocator(4096);
    
    // 分配对齐内存
    void* ptr = allocator.allocate(256, 16);
    EXPECT_NE(ptr, nullptr);
    EXPECT_EQ(reinterpret_cast<uintptr_t>(ptr) % 16, 0);
    
    // 跟踪使用量
    EXPECT_GE(allocator.used(), 256);
}

TEST(LinearAllocator, 边界情况) {
    LinearAllocator allocator(128);
    
    // 耗尽内存
    void* p1 = allocator.allocate(64, 16);
    void* p2 = allocator.allocate(64, 16);
    void* p3 = allocator.allocate(1, 16);
    
    EXPECT_NE(p1, nullptr);
    EXPECT_NE(p2, nullptr);
    EXPECT_EQ(p3, nullptr); // 应该返回空
}

TEST(LinearAllocator, 性能基准) {
    LinearAllocator allocator(1024 * 1024);
    
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 10000; ++i) {
        allocator.allocate(64, 16);
    }
    auto end = std::chrono::high_resolution_clock::now();
    
    auto us = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    EXPECT_LT(us, 1000); // 10k 次分配 <1ms
}
```

### 并发测试

```cpp
TEST(ThreadSafeAllocator, 多线程安全) {
    ThreadSafeAllocator allocator(1024 * 1024);
    std::vector<std::thread> threads;
    std::atomic<int> success_count{0};
    
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([&]() {
            for (int j = 0; j < 100; ++j) {
                void* ptr = allocator.allocate(64, 16);
                if (ptr) success_count++;
            }
        });
    }
    
    for (auto& t : threads) t.join();
    EXPECT_EQ(success_count, 1000);
}
```

## SIMD 优化模式

### 对齐要求

| 类型 | 对齐 |
|------|------|
| Vec3 (SSE) | 16 字节 |
| Vec4 (SSE) | 16 字节 |
| Mat4 (SSE) | 16 字节 |
| Vec8 (AVX) | 32 字节 |

### SSE 实现示例

```cpp
struct alignas(16) Vec4 {
    __m128 data;
    
    Vec4 operator+(const Vec4& rhs) const {
        Vec4 result;
        result.data = _mm_add_ps(data, rhs.data);
        return result;
    }
    
    float dot(const Vec4& rhs) const {
        __m128 mul = _mm_mul_ps(data, rhs.data);
        __m128 shuf = _mm_shuffle_ps(mul, mul, _MM_SHUFFLE(2, 3, 0, 1));
        __m128 sums = _mm_add_ps(mul, shuf);
        shuf = _mm_movehl_ps(shuf, sums);
        sums = _mm_add_ss(sums, shuf);
        return _mm_cvtss_f32(sums);
    }
};
```

## 性能基准要求

| 组件 | 目标 |
|------|------|
| 向量运算 | <10ns/次 |
| 矩阵乘法 | <100ns/次 |
| 内存分配 | <1μs/次 |
| 字符串解析 | <100μs/KB |

## 覆盖率目标

| 组件 | 目标 |
|------|------|
| 数学库 | 100% |
| 分配器 | 95%+ |
| 工具类 | 90%+ |

## Sanitizer 验证

```bash
# AddressSanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" ..
ctest --test-dir build --output-on-failure

# ThreadSanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=thread" ..
ctest --test-dir build --output-on-failure
```
