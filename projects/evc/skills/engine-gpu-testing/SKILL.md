---
name: engine-gpu-testing
description: Use this skill when implementing buffer/texture management, descriptor heaps, command lists, or rendering pipelines. Enforces test-driven development with Mock RHI patterns.
origin: EVC
---

# Engine GPU Testing Workflow

This skill ensures all GPU-side engine code follows TDD principles with comprehensive test coverage.

## When to Activate

- Implementing buffer/texture management
- Developing descriptor heaps
- Writing command list wrappers
- Rendering pipeline verification
- GPU resource lifecycle management

## GPU 测试类型

### Mock RHI 测试
- 使用 Mock 对象测试 GPU 资源管理逻辑
- 验证创建/销毁调用
- 验证参数正确性

### 集成测试
- 真实 GPU 设备测试
- 截图对比验证
- GPU 时间测量

### 性能测试
- GPU 时间预算
- Draw Call 数量
- 内存占用

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

## 测试模式

### Buffer 管理测试

```cpp
TEST(BufferManager, 创建并销毁) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillOnce(Return(new MockRHIBuffer()));
    EXPECT_CALL(device, DestroyBuffer(_))
        .Times(1);
    
    BufferManager mgr(&device);
    auto buffer = mgr.CreateBuffer(1024);
    EXPECT_NE(buffer, nullptr);
}

TEST(BufferManager, 对齐要求) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(Field(&BufferDesc::alignment, 256)))
        .WillOnce(Return(new MockRHIBuffer()));
    
    BufferManager mgr(&device);
    mgr.CreateBuffer(1024, 256);
}

TEST(BufferManager, 性能基准) {
    MockRHIDevice device;
    EXPECT_CALL(device, CreateBuffer(_))
        .WillRepeatedly(Return(new MockRHIBuffer()));
    
    BufferManager mgr(&device);
    
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 1000; ++i) {
        mgr.CreateBuffer(1024);
    }
    auto end = std::chrono::high_resolution_clock::now();
    
    auto us = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count();
    EXPECT_LT(us, 10000); // 1000 次创建 <10ms
}
```

### Descriptor Heap 测试

```cpp
TEST(DescriptorHeap, 分配释放) {
    MockRHIDevice device;
    EXPECT_CALL(device, AllocateDescriptor())
        .WillOnce(Return(DescriptorHandle{1}))
        .WillOnce(Return(DescriptorHandle{2}));
    EXPECT_CALL(device, FreeDescriptor(DescriptorHandle{1}))
        .Times(1);
    
    DescriptorHeap heap(&device, 100);
    
    auto h1 = heap.allocate();
    auto h2 = heap.allocate();
    
    EXPECT_TRUE(h1.valid());
    EXPECT_TRUE(h2.valid());
    
    heap.free(h1);
}

TEST(DescriptorHeap, 泄漏检测) {
    MockRHIDevice device;
    EXPECT_CALL(device, AllocateDescriptor())
        .WillRepeatedly(Return(DescriptorHandle{1}));
    EXPECT_CALL(device, FreeDescriptor(_))
        .Times(0);  // 不应该调用
    
    DescriptorHeap heap(&device, 100);
    
    // 分配但不释放 -> 泄漏
    heap.allocate();
    
    // 检查泄漏
    EXPECT_GT(heap.leaked_count(), 0);
}
```

### 渲染管线测试

```cpp
TEST(RenderPipeline, 执行渲染Pass) {
    MockRHIDevice device;
    MockCommandList cmdList;
    
    EXPECT_CALL(device, BeginCommandList())
        .WillOnce(Return(&cmdList));
    EXPECT_CALL(cmdList, DrawInstanced(_, _, _, _))
        .Times(1);
    
    RenderPipeline pipeline(&device);
    pipeline.Execute();
}
```

## 截图对比测试

```cpp
TEST(Renderer, 输出正确图像) {
    Renderer renderer;
    renderer.Initialize();
    renderer.RenderFrame();
    
    auto screenshot = renderer.CaptureFramebuffer();
    auto reference = LoadImage("testdata/reference.png");
    
    float similarity = CompareImages(screenshot, reference);
    EXPECT_GT(similarity, 0.99f); // 99% 相似度
}
```

## GPU 性能测试

```cpp
TEST(Renderer, 帧时间预算) {
    Renderer renderer;
    renderer.Initialize();
    
    // 预热
    for (int i = 0; i < 10; ++i) {
        renderer.RenderFrame();
    }
    
    // 测量
    auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < 100; ++i) {
        renderer.RenderFrame();
    }
    auto end = std::chrono::high_resolution_clock::now();
    
    auto avg_ms = std::chrono::duration_cast<std::chrono::microseconds>(end - start).count() / 100.0 / 1000.0;
    EXPECT_LT(avg_ms, 16.6); // 平均帧时间 <16.6ms
}
```

## 资源泄漏检测模式

```cpp
class GPULeakDetector {
public:
    void TrackBuffer(RHIBuffer* buffer) {
        buffers_.insert(buffer);
    }
    
    void UntrackBuffer(RHIBuffer* buffer) {
        buffers_.erase(buffer);
    }
    
    void CheckLeaks() {
        EXPECT_EQ(buffers_.size(), 0) << "Leaked " << buffers_.size() << " buffers";
        EXPECT_EQ(textures_.size(), 0) << "Leaked " << textures_.size() << " textures";
        EXPECT_EQ(descriptors_.size(), 0) << "Leaked " << descriptors_.size() << " descriptors";
    }
    
private:
    std::set<RHIBuffer*> buffers_;
    std::set<RHITexture*> textures_;
    std::set<DescriptorHandle> descriptors_;
};
```

## 性能基准要求

| 指标 | 目标 |
|------|------|
| 帧时间 | <16.6ms (60 FPS) |
| Draw Call | <2000/帧 |
| Buffer 分配 | <10μs |
| Descriptor 分配 | <1μs |

## 覆盖率目标

| 组件 | 目标 |
|------|------|
| Buffer 管理 | 90%+ |
| Texture 管理 | 90%+ |
| Descriptor | 90%+ |
| Command List | 85%+ |

## 调试工具

| 工具 | 用途 |
|------|------|
| PIX for Windows | D3D12 调试 |
| RenderDoc | 帧捕获分析 |
| NVIDIA Nsight | GPU 性能分析 |
| Tracy Profiler | CPU/GPU 时间线 |
