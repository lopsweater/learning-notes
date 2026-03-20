---
name: rhi-d3d12
description: D3D12 后端实现。DirectX 12 RHI 后端的实现细节，包含资源创建、命令提交、同步机制。
origin: learning-notes
---

# D3D12 后端实现

## 激活时机

- 实现 D3D12 后端
- 调试 D3D12 问题
- 优化 D3D12 性能
- 学习 D3D12 API

## 核心对象

### Device

```cpp
class D3D12Device : public RHIDevice {
public:
    bool Initialize(const DeviceCreateInfo& createInfo) {
        // 1. 启用调试层
        #if defined(_DEBUG)
        ComPtr<ID3D12Debug> debug;
        D3D12GetDebugInterface(IID_PPV_ARGS(&debug));
        debug->EnableDebugLayer();
        #endif
        
        // 2. 创建设备
        HRESULT hr = D3D12CreateDevice(
            nullptr,                    // 默认适配器
            D3D_FEATURE_LEVEL_12_0,     // 功能级别
            IID_PPV_ARGS(&device_)
        );
        if (FAILED(hr)) return false;
        
        // 3. 创建命令队列
        D3D12_COMMAND_QUEUE_DESC queueDesc = {};
        queueDesc.Type = D3D12_COMMAND_LIST_TYPE_DIRECT;
        queueDesc.Priority = D3D12_COMMAND_QUEUE_PRIORITY_NORMAL;
        queueDesc.Flags = D3D12_COMMAND_QUEUE_FLAG_NONE;
        
        device_->CreateCommandQueue(&queueDesc, IID_PPV_ARGS(&commandQueue_));
        
        // 4. 创建描述符堆
        CreateDescriptorHeaps();
        
        return true;
    }
    
private:
    ComPtr<ID3D12Device> device_;
    ComPtr<ID3D12CommandQueue> commandQueue_;
};
```

### Buffer

```cpp
class D3D12Buffer : public RHIBuffer {
public:
    // 创建
    static D3D12Buffer* Create(ID3D12Device* device, const BufferDesc& desc) {
        // 1. 堆属性
        D3D12_HEAP_PROPERTIES heapProps = {};
        heapProps.Type = ConvertHeapType(desc.memoryType);
        heapProps.CreationNodeMask = 1;
        heapProps.VisibleNodeMask = 1;
        
        // 2. 资源描述
        D3D12_RESOURCE_DESC resourceDesc = {};
        resourceDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        resourceDesc.Alignment = desc.alignment;
        resourceDesc.Width = AlignUp(desc.size, desc.alignment);
        resourceDesc.Height = 1;
        resourceDesc.DepthOrArraySize = 1;
        resourceDesc.MipLevels = 1;
        resourceDesc.Format = DXGI_FORMAT_UNKNOWN;
        resourceDesc.SampleDesc.Count = 1;
        resourceDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        resourceDesc.Flags = ConvertBufferFlags(desc.usage);
        
        // 3. 初始状态
        D3D12_RESOURCE_STATES initialState = GetInitialState(desc);
        
        // 4. 创建资源
        ComPtr<ID3D12Resource> resource;
        HRESULT hr = device->CreateCommittedResource(
            &heapProps,
            D3D12_HEAP_FLAG_NONE,
            &resourceDesc,
            initialState,
            nullptr,
            IID_PPV_ARGS(&resource)
        );
        
        if (FAILED(hr)) return nullptr;
        
        // 5. 设置调试名称
        if (desc.debugName) {
            resource->SetName(ToWideString(desc.debugName).c_str());
        }
        
        return new D3D12Buffer(resource, desc);
    }
    
    // GPU 地址
    uint64_t GetGPUAddress() const override {
        return resource_->GetGPUVirtualAddress();
    }
    
    // 映射
    void* Map() override {
        if (mappedPtr_) return mappedPtr_;
        
        D3D12_RANGE range = {0, desc_.size};
        HRESULT hr = resource_->Map(0, &range, &mappedPtr_);
        return SUCCEEDED(hr) ? mappedPtr_ : nullptr;
    }
    
    void Unmap() override {
        if (mappedPtr_) {
            resource_->Unmap(0, nullptr);
            mappedPtr_ = nullptr;
        }
    }
    
private:
    ComPtr<ID3D12Resource> resource_;
    BufferDesc desc_;
    void* mappedPtr_ = nullptr;
};
```

### Texture

```cpp
class D3D12Texture : public RHITexture {
public:
    static D3D12Texture* Create(ID3D12Device* device, const TextureDesc& desc) {
        // 1. 资源描述
        D3D12_RESOURCE_DESC resourceDesc = {};
        resourceDesc.Dimension = ConvertDimension(desc.dimension);
        resourceDesc.Alignment = 0;
        resourceDesc.Width = desc.width;
        resourceDesc.Height = desc.height;
        resourceDesc.DepthOrArraySize = desc.depth * desc.arraySize;
        resourceDesc.MipLevels = desc.mipLevels;
        resourceDesc.Format = ConvertFormat(desc.format);
        resourceDesc.SampleDesc.Count = desc.sampleCount;
        resourceDesc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
        resourceDesc.Flags = ConvertTextureFlags(desc.usage);
        
        // 2. 堆属性
        D3D12_HEAP_PROPERTIES heapProps = {};
        heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;
        heapProps.CreationNodeMask = 1;
        heapProps.VisibleNodeMask = 1;
        
        // 3. 清除值
        D3D12_CLEAR_VALUE* clearValue = nullptr;
        D3D12_CLEAR_VALUE cv = {};
        if (HasFlag(desc.usage, TextureUsage::RenderTarget) ||
            HasFlag(desc.usage, TextureUsage::DepthStencil)) {
            cv.Format = resourceDesc.Format;
            if (HasFlag(desc.usage, TextureUsage::DepthStencil)) {
                cv.DepthStencil.Depth = 1.0f;
                cv.DepthStencil.Stencil = 0;
            }
            clearValue = &cv;
        }
        
        // 4. 创建资源
        ComPtr<ID3D12Resource> resource;
        HRESULT hr = device->CreateCommittedResource(
            &heapProps,
            D3D12_HEAP_FLAG_NONE,
            &resourceDesc,
            D3D12_RESOURCE_STATE_COMMON,
            clearValue,
            IID_PPV_ARGS(&resource)
        );
        
        if (FAILED(hr)) return nullptr;
        
        return new D3D12Texture(resource, desc);
    }
    
private:
    ComPtr<ID3D12Resource> resource_;
    TextureDesc desc_;
};
```

### Command List

```cpp
class D3D12CommandList : public RHICommandList {
public:
    void Begin() override {
        // 重置命令列表
        ID3D12CommandAllocator* allocator = GetActiveAllocator();
        allocator->Reset();
        commandList_->Reset(allocator, nullptr);
    }
    
    void End() override {
        commandList_->Close();
    }
    
    // 资源屏障
    void Barrier(const BarrierDesc& desc) override {
        D3D12_RESOURCE_BARRIER barrier = {};
        barrier.Type = D3D12_RESOURCE_BARRIER_TYPE_TRANSITION;
        barrier.Flags = D3D12_RESOURCE_BARRIER_FLAG_NONE;
        
        if (desc.texture) {
            D3D12Texture* tex = static_cast<D3D12Texture*>(desc.texture);
            barrier.Transition.pResource = tex->GetResource();
            barrier.Transition.StateBefore = ConvertState(desc.stateBefore);
            barrier.Transition.StateAfter = ConvertState(desc.stateAfter);
            barrier.Transition.Subresource = D3D12_RESOURCE_BARRIER_ALL_SUBRESOURCES;
        }
        
        commandList_->ResourceBarrier(1, &barrier);
    }
    
    // 绘制
    void DrawInstanced(uint32_t vertexCount, uint32_t instanceCount,
                       uint32_t startVertex, uint32_t startInstance) override {
        commandList_->DrawInstanced(vertexCount, instanceCount, startVertex, startInstance);
    }
    
    void DrawIndexedInstanced(uint32_t indexCount, uint32_t instanceCount,
                              uint32_t startIndex, int32_t baseVertex,
                              uint32_t startInstance) override {
        commandList_->DrawIndexedInstanced(indexCount, instanceCount,
                                           startIndex, baseVertex, startInstance);
    }
    
private:
    ComPtr<ID3D12GraphicsCommandList> commandList_;
};
```

## 转换函数

### 堆类型

```cpp
D3D12_HEAP_TYPE ConvertHeapType(MemoryType type) {
    switch (type) {
        case MemoryType::DeviceLocal: return D3D12_HEAP_TYPE_DEFAULT;
        case MemoryType::Upload:      return D3D12_HEAP_TYPE_UPLOAD;
        case MemoryType::Readback:    return D3D12_HEAP_TYPE_READBACK;
    }
    return D3D12_HEAP_TYPE_DEFAULT;
}
```

### 资源状态

```cpp
D3D12_RESOURCE_STATES ConvertState(ResourceState state) {
    switch (state) {
        case ResourceState::Common:          return D3D12_RESOURCE_STATE_COMMON;
        case ResourceState::VertexBuffer:    return D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
        case ResourceState::IndexBuffer:     return D3D12_RESOURCE_STATE_INDEX_BUFFER;
        case ResourceState::ConstantBuffer:  return D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER;
        case ResourceState::ShaderResource:  return D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE |
                                                   D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE;
        case ResourceState::UnorderedAccess: return D3D12_RESOURCE_STATE_UNORDERED_ACCESS;
        case ResourceState::RenderTarget:    return D3D12_RESOURCE_STATE_RENDER_TARGET;
        case ResourceState::DepthWrite:      return D3D12_RESOURCE_STATE_DEPTH_WRITE;
        case ResourceState::DepthRead:       return D3D12_RESOURCE_STATE_DEPTH_READ;
        case ResourceState::Present:         return D3D12_RESOURCE_STATE_PRESENT;
        case ResourceState::CopySrc:         return D3D12_RESOURCE_STATE_COPY_SOURCE;
        case ResourceState::CopyDst:         return D3D12_RESOURCE_STATE_COPY_DEST;
    }
    return D3D12_RESOURCE_STATE_COMMON;
}
```

### 像素格式

```cpp
DXGI_FORMAT ConvertFormat(Format format) {
    static const DXGI_FORMAT mapping[] = {
        [Format::Unknown]        = DXGI_FORMAT_UNKNOWN,
        [Format::R8G8B8A8_UNORM] = DXGI_FORMAT_R8G8B8A8_UNORM,
        [Format::R8G8B8A8_SRGB]  = DXGI_FORMAT_R8G8B8A8_UNORM_SRGB,
        [Format::B8G8R8A8_UNORM] = DXGI_FORMAT_B8G8R8A8_UNORM,
        [Format::B8G8R8A8_SRGB]  = DXGI_FORMAT_B8G8R8A8_UNORM_SRGB,
        [Format::R32G32B32A32_FLOAT] = DXGI_FORMAT_R32G32B32A32_FLOAT,
        [Format::R16G16B16A16_FLOAT] = DXGI_FORMAT_R16G16B16A16_FLOAT,
        [Format::D32_FLOAT]      = DXGI_FORMAT_D32_FLOAT,
        [Format::D24_UNORM_S8_UINT] = DXGI_FORMAT_D24_UNORM_S8_UINT,
        [Format::BC1_UNORM]      = DXGI_FORMAT_BC1_UNORM,
        [Format::BC3_UNORM]      = DXGI_FORMAT_BC3_UNORM,
        [Format::BC5_UNORM]      = DXGI_FORMAT_BC5_UNORM,
        [Format::BC7_UNORM]      = DXGI_FORMAT_BC7_UNORM,
    };
    return mapping[static_cast<int>(format)];
}
```

## 同步

### Fence

```cpp
class D3D12Fence {
public:
    D3D12Fence(ID3D12Device* device) {
        device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence_));
    }
    
    uint64_t GetCompletedValue() {
        return fence_->GetCompletedValue();
    }
    
    void Signal(ID3D12CommandQueue* queue, uint64_t value) {
        queue->Signal(fence_.Get(), value);
    }
    
    void Wait(uint64_t value) {
        if (fence_->GetCompletedValue() >= value) return;
        
        HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
        fence_->SetEventOnCompletion(value, event);
        WaitForSingleObject(event, INFINITE);
        CloseHandle(event);
    }
    
private:
    ComPtr<ID3D12Fence> fence_;
};
```

## 调试

### 调试层启用

```cpp
void EnableDebugLayer() {
    #if defined(_DEBUG)
    ComPtr<ID3D12Debug> debug;
    D3D12GetDebugInterface(IID_PPV_ARGS(&debug));
    debug->EnableDebugLayer();
    
    // 启用 GPU 验证（可选，性能影响大）
    ComPtr<ID3D12Debug1> debug1;
    debug.As(&debug1);
    if (debug1) {
        debug1->SetEnableGPUBasedValidation(TRUE);
    }
    #endif
}
```

### 设备丢失处理

```cpp
void HandleDeviceRemoved(ID3D12Device* device) {
    HRESULT reason = device->GetDeviceRemovedReason();
    
    switch (reason) {
        case DXGI_ERROR_DEVICE_REMOVED:
            printf("Device removed: GPU hung or TDR\n");
            break;
        case DXGI_ERROR_DEVICE_RESET:
            printf("Device reset: GPU reset\n");
            break;
        case DXGI_ERROR_DEVICE_HUNG:
            printf("Device hung: GPU stopped responding\n");
            break;
        default:
            printf("Device removed: 0x%08X\n", reason);
    }
    
    // 重新初始化设备
    ReinitializeDevice();
}
```

## 性能优化

### 描述符堆复用

```cpp
class DescriptorHeapManager {
public:
    DescriptorHandle Allocate() {
        if (freeList_.empty()) {
            // 创建新的描述符堆
            CreateNewHeap();
        }
        
        DescriptorHandle handle = freeList_.back();
        freeList_.pop_back();
        return handle;
    }
    
    void Free(DescriptorHandle handle, uint64_t fenceValue) {
        deferredFree_.push({fenceValue, handle});
    }
    
    void ProcessDeferredFree(uint64_t completedValue) {
        while (!deferredFree_.empty() && 
               deferredFree_.front().first <= completedValue) {
            freeList_.push_back(deferredFree_.front().second);
            deferredFree_.pop();
        }
    }
};
```

### 命令列表池

```cpp
class CommandListPool {
public:
    ID3D12GraphicsCommandList* Acquire(ID3D12CommandAllocator* allocator) {
        if (!pool_.empty()) {
            auto cmd = pool_.back();
            pool_.pop_back();
            cmd->Reset(allocator, nullptr);
            return cmd;
        }
        
        ComPtr<ID3D12GraphicsCommandList> cmd;
        device_->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT,
                                   allocator, nullptr,
                                   IID_PPV_ARGS(&cmd));
        return cmd.Detach();
    }
    
    void Release(ID3D12GraphicsCommandList* cmd) {
        pool_.push_back(cmd);
    }
};
```

## 相关 Skills

- `rhi-patterns` - RHI 设计模式
- `rhi-vulkan` - Vulkan 后端实现
