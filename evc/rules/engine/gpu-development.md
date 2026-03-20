---
paths:
  - "**/rhi/**/*.cpp"
  - "**/render/**/*.cpp"
  - "**/gpu/**/*.cpp"
  - "**/*.hlsl"
  - "**/*.glsl"
---
# GPU 侧开发流程

> 此文件描述游戏引擎 GPU 侧组件的开发流程。

## 适用范围

- RHI 抽象层（D3D12/Vulkan）
- GPU Buffer 管理
- Texture 管理
- Descriptor Heap 管理
- Command List 封装
- 渲染管线
- Shader 开发

## 开发流程

### 1. 规划阶段

- 确认目标图形 API（D3D12/Vulkan/Metal）
- 设计跨平台抽象接口
- 考虑资源生命周期管理
- 考虑多线程渲染需求

### 2. TDD 开发（Mock RHI）

```
红 → 编写失败测试
绿 → 实现最小代码
重构 → 优化代码
验证 → 覆盖率 + GPU 性能
```

### 3. RHI 抽象层设计

#### 核心接口

```cpp
class RHIDevice {
public:
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual void DestroyBuffer(RHIBuffer* buffer) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
    virtual void DestroyTexture(RHITexture* texture) = 0;
    virtual CommandList* CreateCommandList() = 0;
    virtual void SubmitCommandList(CommandList* cmdList) = 0;
};
```

#### 平台实现

| 接口 | D3D12 实现 | Vulkan 实现 |
|------|-----------|-------------|
| RHIDevice | D3D12Device | VulkanDevice |
| RHIBuffer | ID3D12Resource | VkBuffer |
| RHITexture | ID3D12Resource | VkImage |
| CommandList | ID3D12GraphicsCommandList | VkCommandBuffer |

### 4. GPU 资源管理

#### Buffer 创建检查清单

- [ ] 正确的大小
- [ ] 正确的对齐（常量缓冲区 256 字节）
- [ ] 正确的堆类型（Upload/Default/Readback）
- [ ] 正确的状态屏障

#### Texture 创建检查清单

- [ ] 正确的格式
- [ ] 正确的尺寸
- [ ] 正确的 Mip 层级
- [ ] 正确的使用标志

#### Descriptor 管理检查清单

- [ ] 无 Descriptor 泄漏
- [ ] 正确的堆类型（CBV_SRV_UAV/Sampler/RTV/DSV）
- [ ] Bindless 访问优化

### 5. 性能验证

#### GPU 性能基准

| 指标 | 目标 | 测试方式 |
|------|------|----------|
| 帧时间 | <16.6ms (60 FPS) | Tracy/PIX |
| Draw Call | <2000/帧 | 计数器 |
| Buffer 分配 | <10μs | Benchmark |
| Descriptor 分配 | <1μs | Benchmark |
| SetGraphicsRootDescriptorTable | <5μs | Tracy |

### 6. 资源生命周期

#### 延迟销毁

GPU 资源不能立即销毁，必须等待 GPU 使用完毕：

```cpp
class DeferredDeletionQueue {
public:
    void Enqueue(RHIBuffer* buffer, uint64_t fenceValue);
    void Flush(uint64_t completedFenceValue);
};
```

#### 检查清单

- [ ] 使用 Fence 同步
- [ ] 延迟销毁队列
- [ ] 无资源泄漏
- [ ] 无使用中销毁

### 7. 多线程渲染

#### Command List 并行

```cpp
// 多线程录制 Command List
std::vector<std::future<CommandList*>> futures;
for (int i = 0; i < numThreads; ++i) {
    futures.push_back(std::async([&]() {
        auto cmdList = device->CreateCommandList();
        // 录制命令...
        return cmdList;
    }));
}

// 主线程提交
for (auto& f : futures) {
    device->SubmitCommandList(f.get());
}
```

#### 检查清单

- [ ] Command List 池化
- [ ] 线程安全的 Descriptor 分配
- [ ] 无数据竞争
- [ ] 性能提升（至少 2x）

### 8. Shader 开发

#### HLSL 编译检查清单

- [ ] Shader Model 版本正确
- [ ] 入口点名称正确
- [ ] 常量缓冲区对齐（16 字节边界）
- [ ] 无编译警告

#### 常量缓冲区对齐

```hlsl
// 正确：16 字节对齐
cbuffer SceneConstants : register(b0) {
    float4x4 ViewMatrix;      // 64 字节
    float4x4 ProjectionMatrix; // 64 字节
    float3 CameraPosition;     // 12 字节
    float Padding;             // 4 字节（补齐）
}
```

### 9. 调试工具

#### 推荐工具

| 工具 | 用途 |
|------|------|
| PIX for Windows | D3D12 调试 |
| RenderDoc | 帧捕获分析 |
| NVIDIA Nsight Graphics | GPU 性能分析 |
| Tracy Profiler | CPU/GPU 性能分析 |

### 10. 代码审查

#### GPU 侧特有审查项

- [ ] 无 GPU 资源泄漏
- [ ] 正确的资源屏障
- [ ] 正确的同步（Fence）
- [ ] 性能达标
- [ ] 覆盖率 80%+
