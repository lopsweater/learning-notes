# RHI 内存模型设计

## 内存分配抽象

```cpp
// 内存分配器接口
class RHIMemoryAllocator {
public:
    // 分配内存
    virtual RHIMemory* Allocate(
        uint64_t size,
        uint64_t alignment,
        MemoryType type
    ) = 0;
    
    // 释放内存
    virtual void Free(RHIMemory* memory) = 0;
    
    // 获取统计信息
    virtual MemoryStats GetStats() const = 0;
};

// 内存统计
struct MemoryStats {
    uint64_t totalAllocated;    // 总分配量
    uint64_t totalFreed;        // 总释放量
    uint64_t currentUsage;      // 当前使用量
    uint32_t allocationCount;   // 分配次数
};
```

## 内存池设计

```cpp
// 内存池
class MemoryPool {
    RHIMemoryAllocator* m_allocator;
    std::vector<MemoryBlock> m_blocks;
    MemoryType m_type;
    uint64_t m_blockSize;
    
public:
    // 分配
    MemoryAllocation Allocate(uint64_t size, uint64_t alignment) {
        // 在现有块中查找
        for (auto& block : m_blocks) {
            if (block.HasSpace(size, alignment)) {
                return block.Allocate(size, alignment);
            }
        }
        
        // 创建新块
        MemoryBlock newBlock(m_allocator->Allocate(m_blockSize, ...));
        m_blocks.push_back(std::move(newBlock));
        return m_blocks.back().Allocate(size, alignment);
    }
    
    // 释放
    void Free(const MemoryAllocation& allocation) {
        // 找到所属块并释放
        for (auto& block : m_blocks) {
            if (block.Owns(allocation)) {
                block.Free(allocation);
                break;
            }
        }
    }
};
```

## D3D12 内存模型

D3D12 使用 **Heap** 作为内存分配单元：

```cpp
// D3D12 内存分配
struct D3D12Memory {
    ID3D12Heap* heap;          // D3D12 Heap
    uint64_t offset;           // 堆内偏移
    uint64_t size;             // 大小
};

// 创建 Heap
D3D12_HEAP_DESC heapDesc = {};
heapDesc.SizeInBytes = 64 * 1024 * 1024;  // 64MB
heapDesc.Properties.Type = D3D12_HEAP_TYPE_DEFAULT;
heapDesc.Alignment = D3D12_DEFAULT_MSAA_RESOURCE_PLACEMENT_ALIGNMENT;

ID3D12Heap* heap;
device->CreateHeap(&heapDesc, IID_PPV_ARGS(&heap));

// 在 Heap 中放置资源
D3D12_RESOURCE_DESC resDesc = {};
resDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
resDesc.Width = bufferSize;

ID3D12Resource* resource;
device->CreatePlacedResource(
    heap,          // Heap
    offset,        // 偏移
    &resDesc,      // 资源描述
    D3D12_RESOURCE_STATE_COMMON,
    nullptr,
    IID_PPV_ARGS(&resource)
);
```

## Vulkan 内存模型

Vulkan 使用 **Device Memory** 作为内存分配单元：

```cpp
// Vulkan 内存分配
struct VulkanMemory {
    VkDeviceMemory memory;     // Vulkan Device Memory
    uint64_t offset;           // 偏移
    uint64_t size;             // 大小
};

// 分配 Device Memory
VkMemoryAllocateInfo allocInfo = {};
allocInfo.allocationSize = 64 * 1024 * 1024;  // 64MB
allocInfo.memoryTypeIndex = memoryTypeIndex;

VkDeviceMemory memory;
vkAllocateMemory(device, &allocInfo, nullptr, &memory);

// 绑定到 Buffer
vkBindBufferMemory(device, buffer, memory, offset);

// 绑定到 Image
vkBindImageMemory(device, image, memory, offset);
```

## 内存类型对比

| 特性 | D3D12 | Vulkan |
|------|-------|--------|
| 默认堆 | D3D12_HEAP_TYPE_DEFAULT | VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT |
| 上传堆 | D3D12_HEAP_TYPE_UPLOAD | VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
| 回读堆 | D3D12_HEAP_TYPE_READBACK | VK_MEMORY_PROPERTY_HOST_CACHED_BIT |
| 自定义堆 | D3D12_HEAP_TYPE_CUSTOM | 自定义 Memory Type Index |

## 资源驻留管理

```cpp
// 驻留管理器
class ResidencyManager {
    struct ResidentResource {
        RHIResource* resource;
        uint64_t lastUsedFrame;
        uint64_t size;
    };
    
    std::vector<ResidentResource> m_residentResources;
    uint64_t m_budget;          // 预算
    uint64_t m_currentUsage;    // 当前使用
    
public:
    // 使资源驻留
    void MakeResident(RHIResource* resource) {
        if (m_currentUsage + resource->GetSize() > m_budget) {
            // 驱逐 LRU 资源
            EvictLRU();
        }
        
        device->MakeResident(1, resource);
        m_residentResources.push_back({resource, currentFrame, resource->GetSize()});
        m_currentUsage += resource->GetSize();
    }
    
    // 驱逐资源
    void EvictLRU() {
        // 按最后使用时间排序
        std::sort(m_residentResources.begin(), m_residentResources.end(),
            [](const auto& a, const auto& b) {
                return a.lastUsedFrame < b.lastUsedFrame;
            });
        
        // 驱逐直到有足够空间
        while (m_currentUsage > m_budget * 0.8 && !m_residentResources.empty()) {
            auto& res = m_residentResources.back();
            device->Evict(1, res.resource);
            m_currentUsage -= res.size;
            m_residentResources.pop_back();
        }
    }
};
```

## 内存对齐要求

| 资源类型 | D3D12 对齐 | Vulkan 对齐 |
|---------|-----------|-------------|
| Buffer | 64KB (64KB-aligned) | VkPhysicalDeviceLimits::minMemoryMapAlignment |
| Texture | 4MB (MSAA) / 64KB | VkPhysicalDeviceLimits::minTexelBufferOffsetAlignment |
| Constant Buffer | 256 bytes | VkPhysicalDeviceLimits::minUniformBufferOffsetAlignment |

## 相关文件

- [resource-model.md](./resource-model.md) - 资源模型设计
- [../patterns/resource-pool.md](../patterns/resource-pool.md) - 资源池模式
