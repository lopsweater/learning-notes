---
description: CPU 侧引擎代码审查。内存安全、SIMD 对齐、多线程安全、性能问题。
---

# 引擎 CPU 审查命令

此命令调用 **engine-cpu-reviewer** agent，对 CPU 侧代码进行全面审查。

## 此命令的功能

1. 识别 CPU 侧变更 - git diff 查找 .cpp/.hpp 文件
2. 运行静态分析 - clang-tidy、cppcheck
3. 内存安全扫描 - 泄漏、悬垂指针、缓冲区溢出
4. SIMD 对齐检查 - 16/32 字节对齐
5. 多线程安全检查 - 数据竞争、死锁
6. 生成报告 - 按严重性分类

## 适用范围（CPU 侧）

- 数学库
- 内存分配器
- 字符串工具
- 文件系统
- Asset 解析
- ECS 系统

## 审查类别

### CRITICAL（必须修复）

- 内存泄漏
- 悬垂指针
- 缓冲区溢出
- 数据竞争
- 未定义行为

### HIGH（应该修复）

- SIMD 对齐错误
- 缺少线程同步
- 未初始化变量
- 整数溢出

### MEDIUM（考虑修复）

- 不必要的拷贝
- 缺少 const 正确性
- 缓存不友好的数据布局
- 过于复杂的模板元编程

## 示例会话

用户: /engine-cpu-review

Agent:
# CPU 代码审查报告

## 审查文件
- src/math/vec3.cpp（已修改）
- src/memory/linear_allocator.cpp（已修改）

## 静态分析结果
✓ clang-tidy: 2 个警告
✓ cppcheck: 无问题

## 发现问题

[CRITICAL] 内存泄漏
文件：src/memory/linear_allocator.cpp:45
问题：析构函数未释放内存

```cpp
// 错误示例
LinearAllocator::~LinearAllocator() {
    // 未释放 memory_
}

// 修复方案
LinearAllocator::~LinearAllocator() {
    if (memory_) {
        std::free(memory_);
        memory_ = nullptr;
    }
}
```

[HIGH] SIMD 对齐错误
文件：src/math/vec3.cpp:28
问题：Vec4 需要 16 字节对齐

```cpp
// 错误示例
struct Vec4 {
    float x, y, z, w;  // 可能未对齐
};

// 修复方案
struct alignas(16) Vec4 {
    float x, y, z, w;
};
```

[MEDIUM] 不必要的拷贝
文件：src/math/vec3.cpp:55
问题：大型对象按值传递

```cpp
// 错误示例
void transform(Matrix4 m);  // 按值拷贝 64 字节

// 修复方案
void transform(const Matrix4& m);  // 按引用传递
```

## 汇总
- CRITICAL: 1
- HIGH: 1
- MEDIUM: 1

建议：❌ 阻止合并，直到 CRITICAL 和 HIGH 问题修复

## 批准标准

| 状态 | 条件 |
|------|------|
| ✅ 批准 | 无 CRITICAL 或 HIGH 问题 |
| ⚠️ 警告 | 仅有 MEDIUM 问题（谨慎合并） |
| ❌ 阻止 | 有 CRITICAL 或 HIGH 问题 |

## CPU 侧检查清单

### 内存安全
- [ ] 无内存泄漏
- [ ] 无悬垂指针
- [ ] 无缓冲区溢出
- [ ] 使用 RAII 管理资源

### SIMD 优化
- [ ] SSE: 16 字节对齐
- [ ] AVX: 32 字节对齐
- [ ] 使用 `alignas` 关键字
- [ ] 验证性能提升

### 多线程安全
- [ ] 确认是否需要线程安全
- [ ] 使用 `std::mutex` 或原子操作
- [ ] 避免死锁
- [ ] 使用 ThreadSanitizer 验证

### 性能
- [ ] 无不必要的拷贝
- [ ] 缓存友好的数据布局
- [ ] 性能基准达标

## 自动化检查命令

```bash
# 静态分析
clang-tidy --checks='*' src/*.cpp -- -std=c++20

# 额外分析
cppcheck --enable=all --suppress=missingIncludeSystem src/

# 构建并启用警告
cmake --build build -- -Wall -Wextra -Wpedantic

# AddressSanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined" ..
ctest --test-dir build --output-on-failure

# ThreadSanitizer（多线程代码）
cmake -DCMAKE_CXX_FLAGS="-fsanitize=thread" ..
ctest --test-dir build --output-on-failure
```

## 相关命令

- `/engine-cpu-build-fix` - 修复构建错误
- `/engine-cpu-test` - 运行测试

## 相关 Agent

- `agents/engine-cpu-reviewer.md`
- `skills/engine-cpu-testing/`
