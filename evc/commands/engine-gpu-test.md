---
description: GPU 侧引擎代码测试驱动开发。Buffer/Texture 管理、渲染管线的测试工作流，包含 Mock RHI 和性能验证。
---

# 引擎 GPU 测试命令

此命令调用 **engine-gpu-tdd-guide** agent，强制执行 GPU 侧代码的测试驱动开发方法论。

## 此命令的功能

1. **定义接口** - GPU 资源管理接口
2. **编写测试** - Mock RHI + GoogleTest
3. **运行测试** - 验证失败
4. **实现代码** - 最小化通过
5. **重构** - 保持测试通过
6. **检查覆盖率** - 80%+
7. **验证性能** - GPU 时间预算

## 适用范围（GPU 侧）

- GPU Buffer 管理
- Texture 上传
- Descriptor Heap 管理
- Resource Barrier
- Command List 封装
- 渲染管线验证

## 不处理（使用 /engine-cpu-test）

- ❌ 数学库
- ❌ CPU 内存分配器
- ❌ Asset 解析
- ❌ 文件系统

## TDD 循环

```
红 → 编写失败测试（Mock RHI）
绿 → 实现最小代码
重构 → 优化代码
验证 → 覆盖率 + GPU 性能
```

## 示例会话

用户: /engine-gpu-test 我需要一个 Buffer Pool 管理器

Agent:
# TDD 会话：Buffer Pool 管理器

## 步骤 1：定义接口

```cpp
// rhi/buffer_pool.hpp
class BufferPool {
public:
    explicit BufferPool(RHIDevice* device, size_t bufferSize, size_t poolSize);
    ~BufferPool();
    
    RHIBuffer* allocate(size_t size, size_t alignment);
    void reset(); // 重置整个池
    size_t used() const;
    
private:
    RHIDevice* device_;
    std::vector<RHIBuffer*> buffers_;
    size_t bufferSize_;
    size_t poolSize_;
};
```

## 步骤 2：编写测试（红）

```cpp
// tests/rhi/buffer_pool_test.cpp
#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "rhi/buffer_pool.hpp"
#include "mocks/mock_rhi_device.hpp"

TEST(BufferPool, 创建Buffer) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillOnce(Return(new MockRHIBuffer()));
    
    BufferPool pool(&device, 1024, 10);
    RHIBuffer* buf = pool.allocate(1024, 16);
    
    EXPECT_NE(buf, nullptr);
}

TEST(BufferPool, 池耗尽返回空) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillRepeatedly(Return(new MockRHIBuffer()));
    
    BufferPool pool(&device, 1024, 2);
    
    RHIBuffer* buf1 = pool.allocate(1024, 16);
    RHIBuffer* buf2 = pool.allocate(1024, 16);
    RHIBuffer* buf3 = pool.allocate(1024, 16);
    
    EXPECT_NE(buf1, nullptr);
    EXPECT_NE(buf2, nullptr);
    EXPECT_EQ(buf3, nullptr);
}

TEST(BufferPool, 重置后可复用) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillRepeatedly(Return(new MockRHIBuffer()));
    
    BufferPool pool(&device, 1024, 2);
    
    pool.allocate(1024, 16);
    pool.allocate(1024, 16);
    pool.reset();
    
    RHIBuffer* buf = pool.allocate(1024, 16);
    EXPECT_NE(buf, nullptr);
}

TEST(BufferPool, 跟踪使用量) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillRepeatedly(Return(new MockRHIBuffer()));
    
    BufferPool pool(&device, 1024, 10);
    
    pool.allocate(512, 16);
    EXPECT_GE(pool.used(), 512);
    
    pool.allocate(256, 16);
    EXPECT_GE(pool.used(), 768);
}
```

## 步骤 3：运行测试 - 验证失败

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: buffer_pool_test .....***Failed
    --- undefined reference to `BufferPool::allocate`

FAIL
```

✓ 测试失败如预期（未实现）。

## 步骤 4：实现最小代码（绿）

```cpp
// rhi/buffer_pool.cpp
#include "buffer_pool.hpp"

BufferPool::BufferPool(RHIDevice* device, size_t bufferSize, size_t poolSize)
    : device_(device), bufferSize_(bufferSize), poolSize_(poolSize), used_(0) {
    buffers_.reserve(poolSize);
}

BufferPool::~BufferPool() {
    for (auto buf : buffers_) {
        device_->DestroyBuffer(buf);
    }
}

RHIBuffer* BufferPool::allocate(size_t size, size_t alignment) {
    if (buffers_.size() >= poolSize_) {
        return nullptr;
    }
    
    BufferDesc desc;
    desc.size = size;
    desc.alignment = alignment;
    
    auto buffer = device_->CreateBuffer(desc);
    buffers_.push_back(buffer);
    used_ += size;
    return buffer;
}

void BufferPool::reset() {
    used_ = 0;
    // 不销毁 buffer，只重置计数
}

size_t BufferPool::used() const {
    return used_;
}
```

## 步骤 5：运行测试 - 验证通过

```bash
$ cmake --build build && ctest --test-dir build --output-on-failure

1/1 Test #1: buffer_pool_test .....   Passed    0.01 sec

100% tests passed.
```

✓ 所有测试通过！

## 步骤 6：检查覆盖率

```bash
$ lcov --list coverage.info

rhi/buffer_pool.cpp     | 95%
```

✓ 覆盖率：95%

## TDD 完成！

## Mock RHI 模式

```cpp
// mocks/mock_rhi_device.hpp
class MockRHIDevice : public RHIDevice {
public:
    MOCK_METHOD(RHIBuffer*, CreateBuffer, (const BufferDesc&), (override));
    MOCK_METHOD(void, DestroyBuffer, (RHIBuffer*), (override));
    MOCK_METHOD(RHITexture*, CreateTexture, (const TextureDesc&), (override));
    MOCK_METHOD(void, DestroyTexture, (RITexture*), (override));
    MOCK_METHOD(DescriptorHandle, AllocateDescriptor, (), (override));
    MOCK_METHOD(void, FreeDescriptor, (DescriptorHandle), (override));
};
```

## 覆盖率要求

| 组件 | 目标 |
|------|------|
| Buffer 管理 | 90%+ |
| Texture 管理 | 90%+ |
| Descriptor 管理 | 90%+ |
| Command List | 85%+ |
| 渲染管线 | 80%+ |

## GPU 性能基准要求

| 指标 | 目标 |
|------|------|
| 帧时间 | <16.6ms (60 FPS) |
| Draw Call | <2000/帧 |
| Buffer 分配 | <10μs |
| Descriptor 分配 | <1μs |

## 相关命令

- `/engine-gpu-build-fix` - 修复构建错误
- `/engine-gpu-review` - 审查代码质量
- `/shader-compile-fix` - Shader 编译修复
- `/engine-cpu-test` - CPU 侧测试

## 相关 Agent

- `agents/engine-gpu-tdd-guide.md`
- `skills/engine-gpu-testing/`
