# RHI 抽象层设计

## 抽象层级定义

RHI 的抽象层设计需要在**灵活性**和**易用性**之间找到平衡。

### 三层抽象模型

```
┌─────────────────────────────────────────────────────────────┐
│                     Layer 3: 高级渲染抽象                    │
│  Mesh、Material、Light、Camera、Scene、FrameGraph           │
│  特点：面向渲染逻辑，平台无关                                 │
└────────────────────────────┬────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                     Layer 2: RHI 核心抽象                    │
│  Device、Buffer、Texture、Pipeline、CommandQueue、Fence      │
│  特点：面向 GPU 操作，最小化 API 差异                         │
└────────────────────────────┬────────────────────────────────┘
                             │
        ┌────────────────────┼─────────────────┼─────────────────┐
                             ▼                 ▼                 ▼
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│   Layer 1:      │  │   Layer 1:      │  │   Layer 1:      │
│   D3D12 API     │  │   Vulkan API    │  │   Metal API     │
│                 │  │                 │  │                 │
│   微软原生 API  │  │   Khronos 标准  │  │   Apple 原生    │
└─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Layer 2: RHI 核心抽象设计

### 1. 设备抽象 (Device)

```cpp
// 设备是 RHI 的核心入口点
class RHIDevice {
public:
    // 创建资源
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
    
    // 创建管线
    virtual RHIPipeline* CreatePipeline(const PipelineDesc& desc) = 0;
    
    // 创建命令相关
    virtual RHICommandQueue* GetCommandQueue(QueueType type) = 0;
    virtual RHICommandList* CreateCommandList(QueueType type) = 0;
    
    // 同步对象
    virtual RHIFence* CreateFence() = 0;
    
    // 描述符管理
    virtual RHIDescriptorHeap* CreateDescriptorHeap(const DescriptorHeapDesc& desc) = 0;
};
```

**设计要点：**
- 设备是**资源工厂**，负责创建所有 RHI 对象
- 暴露多队列支持（Graphics、Compute、Copy）
- 支持特性查询（Feature Support）

### 2. 资源抽象 (Resource)

```cpp
// 基类
class RHIResource {
public:
    virtual ~RHIResource() = default;
    virtual void* GetNativeHandle() const = 0;
};

// Buffer 抽象
class RHIBuffer : public RHIResource {
public:
    virtual void* Map() = 0;
    virtual void Unmap() = 0;
    virtual BufferDesc GetDesc() const = 0;
};

// Texture 抽象
class RHITexture : public RHIResource {
public:
    virtual TextureDesc GetDesc() const = 0;
    virtual void GenerateMips(RHICommandList* cmdList) = 0;
};
```

**API 差异封装：**

| 概念 | D3D12 | Vulkan | RHI 统一 |
|------|-------|--------|----------|
| Buffer | ID3D12Resource | VkBuffer | RHIBuffer |
| Texture | ID3D12Resource | VkImage | RHITexture |
| 内存 | Heap + Resource | DeviceMemory + Buffer/Image | Device Memory + Resource |

### 3. 描述符抽象 (Descriptor)

```cpp
// 描述符堆
class RHIDescriptorHeap {
public:
    virtual RHIDescriptorHandle Allocate() = 0;
    virtual void Free(RHIDescriptorHandle handle) = 0;
    virtual uint64_t GetGPUAddress() const = 0;
};

// 描述符句柄
struct RHIDescriptorHandle {
    uint64_t cpuHandle;   // CPU 访问地址
    uint64_t gpuHandle;   // GPU 访问地址
    uint32_t index;       // 在堆中的索引
};
```

**设计挑战：**

| D3D12 | Vulkan | RHI 解决方案 |
|-------|--------|-------------|
| Descriptor Heap (连续分配) | Descriptor Set (池化分配) | Descriptor Pool + Allocate |
| Root Signature | Pipeline Layout | Binding Layout |
| Descriptor Table | Descriptor Set | Binding Table |

### 4. 命令抽象 (Command)

```cpp
// 命令队列
class RHICommandQueue {
public:
    virtual void Submit(RHICommandList** cmdLists, uint32_t count, RHIFence* fence) = 0;
    virtual void Wait(RHIFence* fence, uint64_t value) = 0;
    virtual void Signal(RHIFence* fence, uint64_t value) = 0;
};

// 命令列表
class RHICommandList {
public:
    // 资源绑定
    virtual void SetPipeline(RHIPipeline* pipeline) = 0;
    virtual void SetDescriptorHeap(RHIDescriptorHeap* heap) = 0;
    virtual void SetDescriptorTable(uint32_t rootIndex, RHIDescriptorHandle handle) = 0;
    
    // 资源状态
    virtual void ResourceBarrier(RHIResource* resource, ResourceState from, ResourceState to) = 0;
    
    // 绘制
    virtual void DrawInstanced(uint32_t vertexCount, uint32_t instanceCount) = 0;
    virtual void DrawIndexedInstanced(uint32_t indexCount, uint32_t instanceCount) = 0;
    
    // 计算
    virtual void Dispatch(uint32_t x, uint32_t y, uint32_t z) = 0;
    
    // 复制
    virtual void CopyBuffer(RHIBuffer* dst, RHIBuffer* src) = 0;
    virtual void CopyTexture(RHITexture* dst, RHITexture* src) = 0;
};
```

### 5. 同步抽象 (Synchronization)

```cpp
// Fence 抽象
class RHIFence {
public:
    virtual void Signal(uint64_t value) = 0;
    virtual void Wait(uint64_t value) = 0;
    virtual uint64_t GetCompletedValue() = 0;
};

// Semaphore 抽象 (Vulkan 需要)
class RHISemaphore {
public:
    virtual void Signal() = 0;
    virtual void Wait() = 0;
};
```

**同步模型差异：**

| 场景 | D3D12 | Vulkan | RHI 统一 |
|------|-------|--------|----------|
| CPU 等待 GPU | Fence.Wait() | vkWaitForFences | Fence.Wait() |
| GPU 等待 GPU | Fence (跨队列) | Semaphore | Semaphore |
| 帧同步 | Fence + 帧索引 | Fence + 帧索引 | Fence + FrameIndex |

## 抽象原则总结

### ✅ 应该抽象的

1. **资源创建** - 统一创建接口
2. **命令录制** - 统一命令列表接口
3. **同步机制** - 统一 Fence/Semaphore
4. **描述符管理** - 统一分配/释放接口

### ❌ 不应该抽象的

1. **着色器语言** - HLSL/GLSL/SPIR-V 差异大，保持原生
2. **平台特定功能** - 如 D3D12 的 ExecuteIndirect、Vulkan 的 Subpass
3. **调试工具** - 各平台有专属工具 (PIX、RenderDoc)

### ⚠️ 需要权衡的

1. **描述符绑定模型** - Root Signature vs Descriptor Set
2. **资源状态转换** - Resource Barrier vs Image Memory Barrier
3. **内存管理** - 驻留管理 vs Device Memory

## 下一步

- [cross-platform.md](./cross-platform.md) - 跨平台策略
- [resource-model.md](./resource-model.md) - 资源模型设计
