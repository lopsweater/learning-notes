---
paths:
  - "src/rhi/**/*.hpp"
  - "include/rhi/**/*.hpp"
---
# RHI 接口设计规则

> 此文件定义 RHI 接口设计的规则和最佳实践。

## 核心原则

### 1. 最小抽象原则

只抽象必要的差异，不要过度抽象。

```cpp
// ❌ 错误：过度抽象
class RHIResource {
    virtual void* GetNativePointer() = 0;  // 太泛化
};

// ✅ 正确：明确抽象
class RHIBuffer {
    virtual uint64_t GetGPUAddress() = 0;  // 明确用途
};
```

### 2. 零开销抽象

虚函数调用次数最小化，避免运行时多态开销。

```cpp
// ❌ 错误：每帧多次虚函数调用
for (int i = 0; i < 1000; ++i) {
    commandList->SetVertexBuffer(i, buffers[i]);  // 虚函数调用
}

// ✅ 正确：批量设置
commandList->SetVertexBuffers(0, buffers, 1000);  // 一次虚函数调用
```

### 3. 显式资源管理

所有资源创建/销毁由用户显式控制。

```cpp
// ❌ 错误：隐式管理
RHIBuffer* buffer = device->CreateBuffer(desc);
// 没有明确的销毁时机

// ✅ 正确：显式管理
RHIBuffer* buffer = device->CreateBuffer(desc);
// ... 使用 buffer
device->DestroyBuffer(buffer);  // 显式销毁
```

### 4. 状态透明

不隐藏图形 API 状态，用户需要明确管理。

```cpp
// ❌ 错误：隐式状态管理
void DrawMesh(RHICommandList* cmd, Mesh* mesh) {
    cmd->SetVertexBuffer(mesh->buffer);  // 隐式设置状态
    cmd->Draw(mesh->vertexCount);
}

// ✅ 正确：显式状态管理
void DrawMesh(RHICommandList* cmd, Mesh* mesh) {
    cmd->Barrier(mesh->buffer, ResourceState::CopyDst, ResourceState::VertexBuffer);
    cmd->SetVertexBuffer(mesh->buffer);
    cmd->Draw(mesh->vertexCount);
}
```

## 命名规范

### 接口命名

| 前缀 | 说明 | 示例 |
|------|------|------|
| RHI | RHI 接口 | RHIDevice, RHIBuffer |
| RHIDescriptor | 描述符类型 | RHIDescriptorHeap |
| RHIPipeline | 管线类型 | RHIPipelineState |

### 结构体命名

| 后缀 | 说明 | 示例 |
|------|------|------|
| Desc | 描述结构 | BufferDesc, TextureDesc |
| CreateInfo | 创建信息 | DeviceCreateInfo |
| Barrier | 屏障描述 | BarrierDesc |

### 枚举命名

```cpp
// 使用 enum class
enum class BufferUsage : uint32_t {
    VertexBuffer    = 1 << 0,
    IndexBuffer     = 1 << 1,
    ConstantBuffer  = 1 << 2,
};

// 使用位标志
inline BufferUsage operator|(BufferUsage a, BufferUsage b) {
    return static_cast<BufferUsage>(
        static_cast<uint32_t>(a) | static_cast<uint32_t>(b)
    );
}
```

## 接口设计模式

### 创建者模式

设备负责创建资源：

```cpp
class RHIDevice {
public:
    virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;
    virtual RHITexture* CreateTexture(const TextureDesc& desc) = 0;
    virtual RHIPipelineState* CreatePipelineState(const PipelineStateDesc& desc) = 0;
    
    virtual void DestroyBuffer(RHIBuffer* buffer) = 0;
    virtual void DestroyTexture(RHITexture* texture) = 0;
    virtual void DestroyPipelineState(RHIPipelineState* pso) = 0;
};
```

### 命令录制模式

命令列表负责录制命令：

```cpp
class RHICommandList {
public:
    virtual void Begin() = 0;
    virtual void End() = 0;
    
    // 资源绑定
    virtual void SetVertexBuffer(uint32_t slot, RHIBuffer* buffer) = 0;
    virtual void SetIndexBuffer(RHIBuffer* buffer, IndexFormat format) = 0;
    virtual void SetPipelineState(RHIPipelineState* pso) = 0;
    
    // 绘制
    virtual void DrawInstanced(uint32_t vertexCount, uint32_t instanceCount) = 0;
    virtual void DrawIndexedInstanced(uint32_t indexCount, uint32_t instanceCount) = 0;
};
```

### 资源屏障模式

显式状态转换：

```cpp
class RHICommandList {
public:
    virtual void Barrier(
        RHIBuffer* buffer,
        ResourceState before,
        ResourceState after
    ) = 0;
    
    virtual void TextureBarrier(
        RHITexture* texture,
        ResourceState before,
        ResourceState after,
        uint32_t mipLevel = AllMips,
        uint32_t arrayLayer = AllLayers
    ) = 0;
};
```

## 错误处理

### 返回值策略

```cpp
// 资源创建：失败返回 nullptr
virtual RHIBuffer* CreateBuffer(const BufferDesc& desc) = 0;

// 命令提交：返回 HRESULT 或 VkResult
virtual Result ExecuteCommandLists(RHICommandList** lists, uint32_t count) = 0;

// 映射内存：失败返回 nullptr
virtual void* Map() = 0;
```

### 错误信息

```cpp
// 提供详细错误信息
class RHIDevice {
public:
    // 获取最后错误信息
    virtual const char* GetLastError() const = 0;
    
    // 设置错误回调
    virtual void SetErrorCallback(void (*callback)(const char* message)) = 0;
};
```

## 后端适配要求

### D3D12 适配

| RHI 概念 | D3D12 映射 |
|----------|-----------|
| Device | ID3D12Device |
| CommandList | ID3D12GraphicsCommandList |
| Buffer | ID3D12Resource (Buffer) |
| Texture | ID3D12Resource (Texture) |
| Fence | ID3D12Fence |

### Vulkan 适配

| RHI 概念 | Vulkan 映射 |
|----------|------------|
| Device | VkDevice |
| CommandList | VkCommandBuffer |
| Buffer | VkBuffer + VkDeviceMemory |
| Texture | VkImage + VkDeviceMemory |
| Fence | VkFence + Timeline Semaphore |

## 设计检查清单

- [ ] 接口足够抽象（支持多后端）
- [ ] 避免不必要的虚函数调用
- [ ] 资源生命周期显式
- [ ] 状态转换明确
- [ ] 同步机制完整
- [ ] 错误处理完善
- [ ] 命名规范一致
- [ ] 有详细注释

## 相关文件

- [rhi-backend-implementation.md](./rhi-backend-implementation.md) - 后端实现规则
- [rhi-resource-management.md](./rhi-resource-management.md) - 资源管理规则
