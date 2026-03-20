---
name: rhi-patterns
description: Use this skill when designing RHI interfaces, implementing cross-platform rendering layers, optimizing RHI performance, or resolving RHI architecture issues.
origin: EVC
---

# RHI Design Patterns

This skill provides design patterns and best practices for cross-platform rendering hardware interfaces.

## When to Activate

- Designing RHI interfaces
- Implementing cross-platform rendering layers
- Optimizing RHI performance
- Resolving RHI architecture issues

## 核心设计模式

### 1. 设备抽象模式

统一的设备接口，隐藏后端差异：

```cpp
// 抽象设备接口
class RHIDevice {
public:
    static std::unique_ptr<RHIDevice> Create(BackendType backend);
    
    // 资源创建
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
    
    // 命令提交
    virtual RHICommandList* CreateCommandList() = 0;
    virtual void ExecuteCommandLists(RHICommandList** lists, uint32_t count) = 0;
    
    // 同步
    virtual Fence CreateFence() = 0;
    virtual void SignalFence(Fence fence, uint64_t value) = 0;
    virtual void WaitForFence(Fence fence, uint64_t value) = 0;
};

// 工厂创建
std::unique_ptr<RHIDevice> RHIDevice::Create(BackendType backend) {
    switch (backend) {
        case BackendType::D3D12:
            return std::make_unique<D3D12Device>();
        case BackendType::Vulkan:
            return std::make_unique<VulkanDevice>();
    }
    return nullptr;
}
```

### 2. 命令录制模式

命令列表封装，支持多线程录制：

```cpp
class RHICommandList {
public:
    virtual void Begin() = 0;
    virtual void End() = 0;
    
    // 资源绑定
    virtual void SetPipelineState(RHIPipelineState* pso) = 0;
    virtual void SetVertexBuffer(uint32_t slot, RHIBuffer* buffer) = 0;
    virtual void SetIndexBuffer(RHIBuffer* buffer, IndexFormat format) = 0;
    
    // 绘制
    virtual void DrawInstanced(uint32_t vertexCount, uint32_t instanceCount) = 0;
    virtual void DrawIndexedInstanced(uint32_t indexCount, uint32_t instanceCount) = 0;
};

// 多线程命令录制
void RenderThread(int threadIndex, RHIDevice* device, const RenderTask* tasks, uint32_t count) {
    RHICommandList* cmdList = device->CreateCommandList();
    cmdList->Begin();
    
    for (uint32_t i = 0; i < count; ++i) {
        RecordRenderTask(cmdList, tasks[i]);
    }
    
    cmdList->End();
    SubmitCommandList(device, cmdList);
}
```

### 3. 资源屏障模式

显式资源状态转换：

```cpp
// 资源状态枚举
enum class ResourceState : uint32_t {
    Common          = 0,
    VertexBuffer    = 1 << 0,
    IndexBuffer     = 1 << 1,
    ConstantBuffer  = 1 << 2,
    ShaderResource  = 1 << 3,
    UnorderedAccess = 1 << 4,
    RenderTarget    = 1 << 5,
    DepthWrite      = 1 << 6,
    DepthRead       = 1 << 7,
    Present         = 1 << 8,
    CopySrc         = 1 << 9,
    CopyDst         = 1 << 10,
};

// 屏障描述
struct BarrierDesc {
    RHIBuffer* buffer;          // Buffer（与 texture 二选一）
    RHITexture* texture;        // Texture
    ResourceState stateBefore;  // 当前状态
    ResourceState stateAfter;   // 目标状态
    uint32_t mipLevel;          // Mip 层级（AllMips = -1）
    uint32_t arrayLayer;        // 数组层（AllLayers = -1）
};

// 批量屏障
void TransitionResources(RHICommandList* cmd, std::span<BarrierDesc> barriers) {
    cmd->Barriers(barriers.data(), barriers.size());
}
```

### 4. 描述符管理模式

描述符堆管理：

```cpp
class DescriptorHeap {
public:
    DescriptorHeap(RHIDevice* device, DescriptorHeapType type, uint32_t capacity);
    
    // 分配
    DescriptorHandle Allocate();
    
    // 释放（延迟）
    void Free(DescriptorHandle handle, uint64_t fenceValue);
    
    // 处理延迟释放
    void ProcessDeferredFree(uint64_t completedFenceValue);
    
private:
    RHIDevice* device_;
    DescriptorHeapType type_;
    uint32_t capacity_;
    uint32_t currentIndex_;
    std::vector<DescriptorHandle> freeList_;
    std::queue<std::pair<uint64_t, DescriptorHandle>> deferredFreeList_;
};
```

### 5. 资源池模式

资源复用减少分配开销：

```cpp
template<typename T>
class ResourcePool {
public:
    ResourcePool(std::function<T*()> creator, std::function<void(T*)> destroyer)
        : creator_(creator), destroyer_(destroyer) {}
    
    ~ResourcePool() {
        for (auto resource : pool_) {
            destroyer_(resource);
        }
    }
    
    T* Acquire() {
        if (!pool_.empty()) {
            T* resource = pool_.back();
            pool_.pop_back();
            return resource;
        }
        return creator_();
    }
    
    void Release(T* resource, uint64_t fenceValue) {
        deferredRelease_.push({fenceValue, resource});
    }
    
    void ProcessDeferred(uint64_t completedFenceValue) {
        while (!deferredRelease_.empty()) {
            auto& [fence, resource] = deferredRelease_.front();
            if (fence <= completedFenceValue) {
                pool_.push_back(resource);
                deferredRelease_.pop();
            } else {
                break;
            }
        }
    }
    
private:
    std::function<T*()> creator_;
    std::function<void(T*)> destroyer_;
    std::vector<T*> pool_;
    std::queue<std::pair<uint64_t, T*>> deferredRelease_;
};
```

### 6. 同步模式

GPU-CPU 同步：

```cpp
class FrameSync {
public:
    FrameSync(RHIDevice* device, uint32_t frameCount);
    
    // 开始帧（等待上一帧完成）
    void BeginFrame();
    
    // 结束帧（信号）
    void EndFrame();
    
    // 获取当前帧索引
    uint32_t GetCurrentFrameIndex() const { return currentFrame_; }
    
private:
    RHIDevice* device_;
    uint32_t frameCount_;
    uint32_t currentFrame_;
    std::vector<Fence> fences_;
    std::vector<uint64_t> fenceValues_;
};

void FrameSync::BeginFrame() {
    uint32_t prevFrame = (currentFrame_ + frameCount_ - 1) % frameCount_;
    device_->WaitForFence(fences_[prevFrame], fenceValues_[prevFrame]);
}

void FrameSync::EndFrame() {
    fenceValues_[currentFrame_]++;
    device_->SignalFence(fences_[currentFrame_], fenceValues_[currentFrame_]);
    currentFrame_ = (currentFrame_ + 1) % frameCount_;
}
```

### 7. 动态上传模式

帧内动态资源上传：

```cpp
class DynamicUploadHeap {
public:
    DynamicUploadHeap(RHIDevice* device, size_t capacity);
    
    // 分配常量缓冲区
    ConstantBufferAllocation AllocateConstantBuffer(size_t size);
    
    // 重置（每帧开始）
    void Reset() { offset_ = 0; }
    
private:
    RHIDevice* device_;
    RHIBuffer* buffer_;
    void* mappedPtr_;
    size_t capacity_;
    size_t offset_;
};

struct ConstantBufferAllocation {
    void* cpuPtr;           // CPU 指针（用于写入）
    uint64_t gpuAddress;    // GPU 地址（用于绑定）
};

ConstantBufferAllocation DynamicUploadHeap::AllocateConstantBuffer(size_t size) {
    size_t alignedSize = AlignUp(size, 256);
    
    if (offset_ + alignedSize > capacity_) {
        return {};  // 空间不足
    }
    
    ConstantBufferAllocation allocation;
    allocation.cpuPtr = static_cast<char*>(mappedPtr_) + offset_;
    allocation.gpuAddress = buffer_->GetGPUAddress() + offset_;
    
    offset_ += alignedSize;
    return allocation;
}
```

## 性能优化模式

### 批量操作

```cpp
// 批量屏障
std::vector<BarrierDesc> barriers;
for (auto& texture : renderTargets) {
    barriers.push_back({.texture = texture, 
                        .stateBefore = ResourceState::RenderTarget,
                        .stateAfter = ResourceState::ShaderResource});
}
commandList->Barriers(barriers);

// 批量绘制
commandList->DrawInstancedIndirect(commandBuffer, drawCount);
```

### Bindless 资源

```cpp
// 绑定所有纹理到一个描述符表
commandList->SetGraphicsRootDescriptorTable(0, bindlessTextureTable);

// 着色器中使用索引访问
// HLSL: Texture2D textures[] : register(t0, space0);
// GLSL: layout(binding = 0) uniform texture2D textures[];
```

### 多线程录制

```cpp
// 分割渲染任务
std::vector<std::future<RHICommandList*>> futures;
for (int i = 0; i < threadCount; ++i) {
    futures.push_back(std::async(std::launch::async, [&, i]() {
        RHICommandList* cmd = device->CreateCommandList();
        cmd->Begin();
        // 录制第 i 部分任务
        cmd->End();
        return cmd;
    }));
}

// 收集并提交
std::vector<RHICommandList*> commandLists;
for (auto& f : futures) {
    commandLists.push_back(f.get());
}
device->ExecuteCommandLists(commandLists.data(), commandLists.size());
```

## 常见反模式

### 过度抽象

```cpp
// ❌ 错误：过度抽象
class RHIResource {
    virtual void* GetNative() = 0;
};

// ✅ 正确：明确接口
class RHIBuffer {
    virtual uint64_t GetGPUAddress() = 0;
};
```

### 隐式状态管理

```cpp
// ❌ 错误：隐式状态
void Draw(RHICommandList* cmd, RHITexture* rt) {
    cmd->SetRenderTarget(rt);  // 隐式转换状态
    cmd->Draw();
}

// ✅ 正确：显式状态
void Draw(RHICommandList* cmd, RHITexture* rt) {
    cmd->TextureBarrier(rt, Common, RenderTarget);
    cmd->SetRenderTarget(rt);
    cmd->Draw();
}
```

## 设计检查清单

- [ ] 接口足够抽象
- [ ] 避免过度抽象
- [ ] 资源生命周期显式
- [ ] 状态转换明确
- [ ] 同步机制正确
- [ ] 支持多线程
- [ ] 性能优化到位

## 相关 Skills

- `rhi-d3d12` - D3D12 后端实现
- `rhi-vulkan` - Vulkan 后端实现
