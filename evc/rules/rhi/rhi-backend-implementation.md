---
paths:
  - "src/rhi/d3d12/**/*"
  - "src/rhi/vulkan/**/*"
---
# RHI 后端实现规则

> 此文件定义 RHI 后端实现的规则和最佳实践。

## 实现优先级

1. **正确性** - 功能必须正确
2. **性能** - 避免不必要的开销
3. **调试性** - 提供有意义的错误信息
4. **可维护性** - 代码清晰易读

## 代码组织

### 目录结构

```
src/rhi/
├── d3d12/                    # D3D12 后端
│   ├── d3d12_device.cpp
│   ├── d3d12_device.hpp
│   ├── d3d12_buffer.cpp
│   ├── d3d12_buffer.hpp
│   ├── d3d12_texture.cpp
│   ├── d3d12_texture.hpp
│   ├── d3d12_command_list.cpp
│   ├── d3d12_command_list.hpp
│   └── d3d12_utils.hpp
├── vulkan/                   # Vulkan 后端
│   ├── vulkan_device.cpp
│   ├── vulkan_device.hpp
│   └── ...
└── common/                   # 公共代码
    └── rhi_utils.cpp
```

### 文件命名

| 类型 | 命名 | 示例 |
|------|------|------|
| 后端设备 | {backend}_device | d3d12_device.hpp |
| 后端资源 | {backend}_{resource} | d3d12_buffer.hpp |
| 工具函数 | {backend}_utils | d3d12_utils.hpp |

## D3D12 实现规则

### 资源创建

```cpp
RHIBuffer* D3D12Device::CreateBuffer(const BufferDesc& desc) {
    // 1. 参数验证
    if (desc.size == 0) {
        SetLastError("Buffer size cannot be 0");
        return nullptr;
    }
    
    // 2. 转换描述
    D3D12_RESOURCE_DESC d3dDesc = ConvertBufferDesc(desc);
    D3D12_HEAP_PROPERTIES heapProps = ConvertHeapProperties(desc.memoryType);
    
    // 3. 创建资源
    ComPtr<ID3D12Resource> resource;
    HRESULT hr = device_->CreateCommittedResource(
        &heapProps,
        D3D12_HEAP_FLAG_NONE,
        &d3dDesc,
        GetInitialState(desc),
        nullptr,
        IID_PPV_ARGS(&resource)
    );
    
    // 4. 错误处理
    if (FAILED(hr)) {
        SetLastError("Failed to create buffer: " + HResultToString(hr));
        return nullptr;
    }
    
    // 5. 设置调试名称
    if (desc.debugName) {
        resource->SetName(ToWideString(desc.debugName).c_str());
    }
    
    return new D3D12Buffer(resource, desc);
}
```

### 资源状态转换

```cpp
// 状态转换映射
D3D12_RESOURCE_STATES ConvertResourceState(ResourceState state) {
    static const D3D12_RESOURCE_STATES mapping[] = {
        [ResourceState::Common]          = D3D12_RESOURCE_STATE_COMMON,
        [ResourceState::VertexBuffer]    = D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER,
        [ResourceState::IndexBuffer]     = D3D12_RESOURCE_STATE_INDEX_BUFFER,
        [ResourceState::ConstantBuffer]  = D3D12_RESOURCE_STATE_VERTEX_AND_CONSTANT_BUFFER,
        [ResourceState::ShaderResource]  = D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE |
                                           D3D12_RESOURCE_STATE_NON_PIXEL_SHADER_RESOURCE,
        [ResourceState::UnorderedAccess] = D3D12_RESOURCE_STATE_UNORDERED_ACCESS,
        [ResourceState::RenderTarget]    = D3D12_RESOURCE_STATE_RENDER_TARGET,
        [ResourceState::DepthWrite]      = D3D12_RESOURCE_STATE_DEPTH_WRITE,
        [ResourceState::DepthRead]       = D3D12_RESOURCE_STATE_DEPTH_READ,
        [ResourceState::Present]         = D3D12_RESOURCE_STATE_PRESENT,
        [ResourceState::CopySrc]         = D3D12_RESOURCE_STATE_COPY_SOURCE,
        [ResourceState::CopyDst]         = D3D12_RESOURCE_STATE_COPY_DEST,
    };
    return mapping[static_cast<int>(state)];
}
```

### 同步实现

```cpp
void D3D12Device::WaitForFence(Fence fence, uint64_t value) {
    // 检查是否已完成
    if (fence->GetCompletedValue() >= value) {
        return;
    }
    
    // 创建事件
    HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    
    // 设置事件信号
    fence->SetEventOnCompletion(value, event);
    
    // 等待
    WaitForSingleObject(event, INFINITE);
    
    // 清理
    CloseHandle(event);
}
```

## Vulkan 实现规则

### 资源创建

```cpp
RHIBuffer* VulkanDevice::CreateBuffer(const BufferDesc& desc) {
    // 1. 参数验证
    if (desc.size == 0) {
        SetLastError("Buffer size cannot be 0");
        return nullptr;
    }
    
    // 2. 创建 Buffer
    VkBufferCreateInfo bufferInfo = {};
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = AlignUp(desc.size, desc.alignment);
    bufferInfo.usage = ConvertBufferUsage(desc.usage);
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
    
    VkBuffer buffer;
    VkResult result = vkCreateBuffer(device_, &bufferInfo, nullptr, &buffer);
    
    if (result != VK_SUCCESS) {
        SetLastError("Failed to create buffer: " + VkResultToString(result));
        return nullptr;
    }
    
    // 3. 分配内存
    VkMemoryRequirements memReqs;
    vkGetBufferMemoryRequirements(device_, buffer, &memReqs);
    
    VkMemoryAllocateInfo allocInfo = {};
    allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = memReqs.size;
    allocInfo.memoryTypeIndex = FindMemoryType(
        memReqs.memoryTypeBits,
        ConvertMemoryType(desc.memoryType)
    );
    
    VkDeviceMemory memory;
    result = vkAllocateMemory(device_, &allocInfo, nullptr, &memory);
    
    if (result != VK_SUCCESS) {
        vkDestroyBuffer(device_, buffer, nullptr);
        SetLastError("Failed to allocate memory: " + VkResultToString(result));
        return nullptr;
    }
    
    // 4. 绑定内存
    vkBindBufferMemory(device_, buffer, memory, 0);
    
    // 5. 设置调试名称
    if (desc.debugName) {
        SetDebugName(VK_OBJECT_TYPE_BUFFER, (uint64_t)buffer, desc.debugName);
    }
    
    return new VulkanBuffer(buffer, memory, desc);
}
```

### 资源状态转换

```cpp
VkImageLayout ConvertImageLayout(ResourceState state) {
    switch (state) {
        case ResourceState::Common:          return VK_IMAGE_LAYOUT_UNDEFINED;
        case ResourceState::ShaderResource:  return VK_IMAGE_LAYOUT_SHADER_READ_ONLY_OPTIMAL;
        case ResourceState::UnorderedAccess: return VK_IMAGE_LAYOUT_GENERAL;
        case ResourceState::RenderTarget:    return VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;
        case ResourceState::DepthWrite:      return VK_IMAGE_LAYOUT_DEPTH_STENCIL_ATTACHMENT_OPTIMAL;
        case ResourceState::DepthRead:       return VK_IMAGE_LAYOUT_DEPTH_STENCIL_READ_ONLY_OPTIMAL;
        case ResourceState::Present:         return VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;
        case ResourceState::CopySrc:         return VK_IMAGE_LAYOUT_TRANSFER_SRC_OPTIMAL;
        case ResourceState::CopyDst:         return VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL;
        default: return VK_IMAGE_LAYOUT_UNDEFINED;
    }
}
```

### 同步实现

```cpp
void VulkanDevice::WaitForFence(Fence fence, uint64_t value) {
    VkSemaphoreWaitInfo waitInfo = {};
    waitInfo.sType = VK_STRUCTURE_TYPE_SEMAPHORE_WAIT_INFO;
    waitInfo.semaphoreCount = 1;
    waitInfo.pSemaphores = &fence->semaphore;
    waitInfo.pValues = &value;
    
    vkWaitSemaphores(device_, &waitInfo, UINT64_MAX);
}
```

## 性能优化规则

### 减少虚函数调用

```cpp
// ❌ 错误：每帧多次虚函数调用
for (auto& draw : drawCalls) {
    commandList->SetVertexBuffer(0, draw.vertexBuffer);  // 虚函数
    commandList->Draw(draw.vertexCount);
}

// ✅ 正确：批量操作
commandList->SetVertexBuffers(0, vertexBuffers, count);  // 一次虚函数
commandList->DrawInstanced(vertexCount, instanceCount);
```

### 批量 Barrier

```cpp
// ❌ 错误：逐个 Barrier
for (auto& texture : textures) {
    commandList->Barrier(texture, before, after);  // 多次调用
}

// ✅ 正确：批量 Barrier
std::vector<BarrierDesc> barriers;
for (auto& texture : textures) {
    barriers.push_back({texture, before, after});
}
commandList->Barriers(barriers);  // 一次调用
```

## 错误处理规则

### 参数验证

```cpp
RHIBuffer* CreateBuffer(const BufferDesc& desc) {
    // 参数验证
    if (desc.size == 0) {
        SetLastError("Buffer size cannot be 0");
        return nullptr;
    }
    
    if (desc.size > MaxBufferSize) {
        SetLastError("Buffer size exceeds maximum: " + std::to_string(MaxBufferSize));
        return nullptr;
    }
    
    // ... 创建逻辑
}
```

### 错误信息

```cpp
// 提供有意义的错误信息
std::string HResultToString(HRESULT hr) {
    switch (hr) {
        case E_OUTOFMEMORY: return "Out of memory";
        case E_INVALIDARG: return "Invalid argument";
        case DXGI_ERROR_DEVICE_REMOVED: return "Device removed";
        default: return "Unknown error (0x" + std::to_string(hr) + ")";
    }
}
```

## 调试支持

### 调试名称

```cpp
// D3D12
resource->SetName(ToWideString(desc.debugName).c_str());

// Vulkan
SetDebugName(VK_OBJECT_TYPE_BUFFER, (uint64_t)buffer, desc.debugName);
```

### 资源跟踪

```cpp
#ifdef _DEBUG
class ResourceTracker {
    std::unordered_map<void*, std::string> resources_;
public:
    void Track(void* resource, const char* name) {
        resources_[resource] = name;
    }
    void Untrack(void* resource) {
        resources_.erase(resource);
    }
    void ReportLeaks() {
        if (!resources_.empty()) {
            printf("Leaked resources:\n");
            for (auto& [ptr, name] : resources_) {
                printf("  %s\n", name.c_str());
            }
        }
    }
};
#endif
```

## 实现检查清单

- [ ] 参数验证完整
- [ ] 错误处理完善
- [ ] 资源正确销毁
- [ ] 调试名称设置
- [ ] 性能优化实现
- [ ] 代码注释完整

## 相关文件

- [rhi-interface-design.md](./rhi-interface-design.md) - 接口设计规则
- [rhi-resource-management.md](./rhi-resource-management.md) - 资源管理规则
