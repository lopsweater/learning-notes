# RHI 命令模型设计

## 命令提交架构

```
┌─────────────────────────────────────────────────────────────┐
│                      应用层                                  │
│              (录制绘制/计算命令)                             │
└────────────────────────┬────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                   RHICommandList                             │
│              (平台无关的命令录制接口)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
        ┌────────────────┼────────────────┐
        ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ D3D12       │  │ Vulkan      │  │ Metal       │
│ CommandList │  │ CmdBuffer   │  │ CmdBuffer   │
└─────────────┘  └─────────────┘  └─────────────┘
```

## 命令队列抽象

```cpp
// 队列类型
enum class QueueType {
    Graphics,    // 图形队列（支持绘制、计算、复制）
    Compute,     // 计算队列（支持计算、复制）
    Copy,        // 复制队列（仅支持复制）
};

// 命令队列接口
class RHICommandQueue {
public:
    // 提交命令列表
    virtual void Submit(
        RHICommandList** cmdLists, 
        uint32_t count, 
        RHIFence* fence = nullptr
    ) = 0;
    
    // 等待 Fence
    virtual void Wait(RHIFence* fence, uint64_t value) = 0;
    
    // 信号 Fence
    virtual void Signal(RHIFence* fence, uint64_t value) = 0;
    
    // 获取队列类型
    virtual QueueType GetType() const = 0;
};
```

## 命令列表抽象

```cpp
// 命令列表接口
class RHICommandList {
public:
    //=== 状态管理 ===
    virtual void Open() = 0;
    virtual void Close() = 0;
    virtual void Reset() = 0;
    
    //=== 资源状态 ===
    virtual void ResourceBarrier(
        RHIResource* resource,
        ResourceState from,
        ResourceState to
    ) = 0;
    
    //=== 管线绑定 ===
    virtual void SetPipeline(RHIPipeline* pipeline) = 0;
    virtual void SetGraphicsPipeline(RHIGraphicsPipeline* pipeline) = 0;
    virtual void SetComputePipeline(RHIComputePipeline* pipeline) = 0;
    
    //=== 资源绑定 ===
    virtual void SetDescriptorHeap(RHIDescriptorHeap* heap) = 0;
    virtual void SetDescriptorTable(
        uint32_t rootIndex, 
        RHIDescriptorHandle handle
    ) = 0;
    virtual void SetConstantBuffer(
        uint32_t rootIndex,
        uint64_t gpuAddress
    ) = 0;
    
    //=== 顶点/索引缓冲 ===
    virtual void SetVertexBuffer(
        uint32_t slot, 
        RHIBuffer* buffer, 
        uint64_t offset, 
        uint32_t stride
    ) = 0;
    virtual void SetIndexBuffer(
        RHIBuffer* buffer, 
        uint64_t offset, 
        IndexFormat format
    ) = 0;
    
    //=== 视口/裁剪 ===
    virtual void SetViewport(const Viewport& viewport) = 0;
    virtual void SetScissor(const Rect& rect) = 0;
    
    //=== 渲染目标 ===
    virtual void SetRenderTarget(
        RHITexture** colorTargets,
        uint32_t colorCount,
        RHITexture* depthStencil = nullptr
    ) = 0;
    virtual void ClearRenderTarget(
        RHITexture* target, 
        const float* clearColor
    ) = 0;
    virtual void ClearDepthStencil(
        RHITexture* depthStencil,
        float depth, 
        uint8_t stencil
    ) = 0;
    
    //=== 绘制命令 ===
    virtual void DrawInstanced(
        uint32_t vertexCount,
        uint32_t instanceCount,
        uint32_t firstVertex = 0,
        uint32_t firstInstance = 0
    ) = 0;
    virtual void DrawIndexedInstanced(
        uint32_t indexCount,
        uint32_t instanceCount,
        uint32_t firstIndex = 0,
        int32_t vertexOffset = 0,
        uint32_t firstInstance = 0
    ) = 0;
    
    //=== 计算命令 ===
    virtual void Dispatch(
        uint32_t x,
        uint32_t y,
        uint32_t z
    ) = 0;
    
    //=== 复制命令 ===
    virtual void CopyBuffer(
        RHIBuffer* dst, 
        RHIBuffer* src
    ) = 0;
    virtual void CopyTexture(
        RHITexture* dst, 
        RHITexture* src
    ) = 0;
    virtual void CopyBufferToTexture(
        RHITexture* dst,
        RHIBuffer* src,
        const TextureCopyRegion& region
    ) = 0;
};
```

## 资源状态

```cpp
// 资源状态枚举
enum class ResourceState : uint32_t {
    Common             = 0,
    VertexBuffer       = 1 << 0,
    IndexBuffer        = 1 << 1,
    ConstantBuffer     = 1 << 2,
    ShaderResource     = 1 << 3,
    UnorderedAccess    = 1 << 4,
    RenderTarget       = 1 << 5,
    DepthWrite         = 1 << 6,
    DepthRead          = 1 << 7,
    CopySrc            = 1 << 8,
    CopyDst            = 1 << 9,
    Present            = 1 << 10,
    IndirectArgument   = 1 << 11,
};
```

## D3D12 vs Vulkan 命令映射

| RHI 抽象 | D3D12 | Vulkan |
|---------|-------|--------|
| RHICommandQueue | ID3D12CommandQueue | VkQueue |
| RHICommandList | ID3D12GraphicsCommandList | VkCommandBuffer |
| Open() | Reset() | vkBeginCommandBuffer() |
| Close() | Close() | vkEndCommandBuffer() |
| DrawInstanced() | DrawInstancedInstanced() | vkCmdDraw() |
| DrawIndexedInstanced() | DrawIndexedInstancedInstanced() | vkCmdDrawIndexed() |
| Dispatch() | Dispatch() | vkCmdDispatch() |
| ResourceBarrier() | ResourceBarrier() | vkCmdPipelineBarrier() |

## 命令录制最佳实践

### 1. 命令列表复用

```cpp
// 每帧复用命令列表
class CommandListPool {
    std::vector<std::unique_ptr<RHICommandList>> m_lists;
    size_t m_index = 0;
    
public:
    RHICommandList* Acquire() {
        if (m_index >= m_lists.size()) {
            m_lists.push_back(m_device->CreateCommandList());
        }
        auto list = m_lists[m_index++].get();
        list->Reset();
        return list;
    }
    
    void Reset() { m_index = 0; }
};
```

### 2. 多线程录制

```cpp
// 并行录制命令列表
std::vector<RHICommandList*> commandLists(threadCount);

#pragma omp parallel for
for (int i = 0; i < threadCount; i++) {
    commandLists[i] = commandPool->Acquire();
    commandLists[i]->Open();
    RecordCommands(commandLists[i], i);
    commandLists[i]->Close();
}

// 提交所有命令列表
queue->Submit(commandLists.data(), threadCount);
```

## 相关文件

- [abstraction-layers.md](./abstraction-layers.md) - 抽象层设计
- [synchronization-model.md](./synchronization-model.md) - 同步模型设计
