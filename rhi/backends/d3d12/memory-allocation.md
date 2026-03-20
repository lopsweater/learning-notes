# D3D12 内存分配

## 堆类型

| 堆类型 | 用途 | CPU 访问 |
|-------|------|---------|
| DEFAULT | GPU 专属 | 无 |
| UPLOAD | CPU 上传 | 写入 |
| READBACK | CPU 回读 | 读取 |
| CUSTOM | 自定义 | 取决于配置 |

## 创建堆

```cpp
D3D12_HEAP_DESC heapDesc = {};
heapDesc.SizeInBytes = 64 * 1024 * 1024;  // 64MB
heapDesc.Properties.Type = D3D12_HEAP_TYPE_DEFAULT;
heapDesc.Properties.CreationNodeMask = 1;
heapDesc.Properties.VisibleNodeMask = 1;
heapDesc.Alignment = D3D12_DEFAULT_RESOURCE_PLACEMENT_ALIGNMENT;
heapDesc.Flags = D3D12_HEAP_FLAG_ALLOW_ONLY_BUFFERS;

ID3D12Heap* heap;
device->CreateHeap(&heapDesc, IID_PPV_ARGS(&heap));
```

## 资源放置

```cpp
// 计算资源偏移
UINT64 GetAlignedOffset(UINT64 offset, UINT64 alignment) {
    return (offset + alignment - 1) & ~(alignment - 1);
}

// 在堆中放置多个资源
UINT64 offset = 0;
for (auto& res : resources) {
    D3D12_RESOURCE_ALLOCATION_INFO allocInfo = 
        device->GetResourceAllocationInfo(0, 1, &res.desc);
    
    offset = GetAlignedOffset(offset, allocInfo.Alignment);
    
    device->CreatePlacedResource(heap, offset, &res.desc, 
        D3D12_RESOURCE_STATE_COMMON, nullptr, IID_PPV_ARGS(&res.resource));
    
    offset += allocInfo.SizeInBytes;
}
```

## 资源别名

```cpp
// 创建支持别名的堆
D3D12_HEAP_DESC heapDesc = {};
heapDesc.Flags = D3D12_HEAP_FLAG_ALLOW_SHADER_ATOMICS | 
                 D3D12_HEAP_FLAG_ALLOW_ALL_BUFFERS_AND_TEXTURES;

// 生命周期不重叠的资源可以共享内存
// Texture A: Pass 1 使用
// Texture B: Pass 2 使用（与 A 生命周期不重叠）

// 需要插入 Aliasing Barrier
D3D12_RESOURCE_ALIASING_BARRIER aliasBarrier = {};
aliasBarrier.pResourceBefore = textureA;
aliasBarrier.pResourceAfter = textureB;

commandList->ResourceBarrier(1, 
    &CD3DX12_RESOURCE_BARRIER::Aliasing(&aliasBarrier));
```

## 上传缓冲区

```cpp
// 创建上传堆
D3D12_HEAP_PROPERTIES uploadHeap = {};
uploadHeap.Type = D3D12_HEAP_TYPE_UPLOAD;
uploadHeap.CreationNodeMask = 1;
uploadHeap.VisibleNodeMask = 1;

D3D12_RESOURCE_DESC bufferDesc = {};
bufferDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
bufferDesc.Width = bufferSize;
bufferDesc.Height = 1;
bufferDesc.DepthOrArraySize = 1;
bufferDesc.MipLevels = 1;
bufferDesc.SampleDesc.Count = 1;
bufferDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;

ID3D12Resource* uploadBuffer;
device->CreateCommittedResource(&uploadHeap, D3D12_HEAP_FLAG_NONE,
    &bufferDesc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr,
    IID_PPV_ARGS(&uploadBuffer));
```

## 线性分配器

```cpp
class LinearAllocator {
    ID3D12Resource* m_buffer;
    uint8_t* m_mappedPtr;
    uint64_t m_capacity;
    uint64_t m_offset;
    
public:
    void Init(ID3D12Device* device, uint64_t capacity) {
        m_capacity = capacity;
        m_offset = 0;
        
        // 创建上传堆缓冲
        D3D12_HEAP_PROPERTIES heapProps = { D3D12_HEAP_TYPE_UPLOAD };
        D3D12_RESOURCE_DESC desc = {};
        desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
        desc.Width = capacity;
        desc.Height = 1;
        desc.DepthOrArraySize = 1;
        desc.MipLevels = 1;
        desc.SampleDesc.Count = 1;
        desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
        
        device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
            &desc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr,
            IID_PPV_ARGS(&m_buffer));
        
        m_buffer->Map(0, nullptr, (void**)&m_mappedPtr);
    }
    
    Allocation Allocate(uint64_t size, uint64_t alignment) {
        uint64_t alignedOffset = (m_offset + alignment - 1) & ~(alignment - 1);
        
        if (alignedOffset + size > m_capacity) {
            return {};  // 空间不足
        }
        
        m_offset = alignedOffset + size;
        
        return {
            m_buffer->GetGPUVirtualAddress() + alignedOffset,
            m_mappedPtr + alignedOffset
        };
    }
    
    void Reset() {
        m_offset = 0;
    }
};
```

## 相关文件

- [resources.md](./resources.md) - 资源管理
- [residency.md](./residency.md) - 资源驻留管理
