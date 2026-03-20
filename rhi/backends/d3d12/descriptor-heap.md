# D3D12 描述符堆

## 描述符堆类型

```cpp
enum D3D12_DESCRIPTOR_HEAP_TYPE {
    D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV,  // 常量缓冲、SRV、UAV
    D3D12_DESCRIPTOR_HEAP_TYPE_SAMPLER,       // 采样器
    D3D12_DESCRIPTOR_HEAP_TYPE_RTV,           // 渲染目标视图
    D3D12_DESCRIPTOR_HEAP_TYPE_DSV,           // 深度模板视图
    D3D12_DESCRIPTOR_HEAP_TYPE_NUM_TYPES
};
```

## 创建描述符堆

```cpp
// 创建 Shader 可见的描述符堆
D3D12_DESCRIPTOR_HEAP_DESC heapDesc = {};
heapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
heapDesc.NumDescriptors = 1024;
heapDesc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;
heapDesc.NodeMask = 0;

ID3D12DescriptorHeap* heap;
device->CreateDescriptorHeap(&heapDesc, IID_PPV_ARGS(&heap));

// 获取描述符大小
UINT descriptorSize = device->GetDescriptorHandleIncrementSize(
    D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
```

## 创建视图

### Constant Buffer View (CBV)

```cpp
D3D12_CONSTANT_BUFFER_VIEW_DESC cbvDesc = {};
cbvDesc.BufferLocation = buffer->GetGPUVirtualAddress();
cbvDesc.SizeInBytes = (bufferSize + 255) & ~255;  // 256 字节对齐

CD3DX12_CPU_DESCRIPTOR_HANDLE handle(
    heap->GetCPUDescriptorHandleForHeapStart(),
    index,
    descriptorSize
);

device->CreateConstantBufferView(&cbvDesc, handle);
```

### Shader Resource View (SRV)

```cpp
// Buffer SRV
D3D12_SHADER_RESOURCE_VIEW_DESC srvDesc = {};
srvDesc.ViewDimension = D3D12_SRV_DIMENSION_BUFFER;
srvDesc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
srvDesc.Buffer.FirstElement = 0;
srvDesc.Buffer.NumElements = elementCount;
srvDesc.Buffer.StructureByteStride = structureSize;
srvDesc.Buffer.Flags = D3D12_BUFFER_SRV_FLAG_NONE;

device->CreateShaderResourceView(buffer, &srvDesc, handle);

// Texture SRV
D3D12_SHADER_RESOURCE_VIEW_DESC texSrvDesc = {};
texSrvDesc.ViewDimension = D3D12_SRV_DIMENSION_TEXTURE2D;
texSrvDesc.Shader4ComponentMapping = D3D12_DEFAULT_SHADER_4_COMPONENT_MAPPING;
texSrvDesc.Texture2D.MipLevels = mipLevels;
texSrvDesc.Texture2D.MostDetailedMip = 0;

device->CreateShaderResourceView(texture, &texSrvDesc, handle);
```

### Unordered Access View (UAV)

```cpp
D3D12_UNORDERED_ACCESS_VIEW_DESC uavDesc = {};
uavDesc.ViewDimension = D3D12_UAV_DIMENSION_BUFFER;
uavDesc.Buffer.FirstElement = 0;
uavDesc.Buffer.NumElements = elementCount;
uavDesc.Buffer.StructureByteStride = structureSize;
uavDesc.Buffer.CounterOffsetInBytes = 0;
uavDesc.Buffer.Flags = D3D12_BUFFER_UAV_FLAG_NONE;

device->CreateUnorderedAccessView(buffer, counterBuffer, &uavDesc, handle);
```

### Render Target View (RTV)

```cpp
// RTV 堆不需要 Shader 可见
D3D12_DESCRIPTOR_HEAP_DESC rtvHeapDesc = {};
rtvHeapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_RTV;
rtvHeapDesc.NumDescriptors = swapChainBufferCount;

ID3D12DescriptorHeap* rtvHeap;
device->CreateDescriptorHeap(&rtvHeapDesc, IID_PPV_ARGS(&rtvHeap));

// 创建 RTV
D3D12_RENDER_TARGET_VIEW_DESC rtvDesc = {};
rtvDesc.ViewDimension = D3D12_RTV_DIMENSION_TEXTURE2D;
rtvDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
rtvDesc.Texture2D.MipSlice = 0;

device->CreateRenderTargetView(texture, &rtvDesc, handle);
```

### Depth Stencil View (DSV)

```cpp
D3D12_DEPTH_STENCIL_VIEW_DESC dsvDesc = {};
dsvDesc.ViewDimension = D3D12_DSV_DIMENSION_TEXTURE2D;
dsvDesc.Format = DXGI_FORMAT_D32_FLOAT;
dsvDesc.Texture2D.MipSlice = 0;
dsvDesc.Flags = D3D12_DSV_FLAG_NONE;

device->CreateDepthStencilView(depthTexture, &dsvDesc, handle);
```

## 绑定到管线

```cpp
// 设置描述符堆
ID3D12DescriptorHeap* heaps[] = { cbvSrvHeap, samplerHeap };
commandList->SetDescriptorHeaps(2, heaps);

// 通过 Descriptor Table 绑定
CD3DX12_GPU_DESCRIPTOR_HANDLE gpuHandle(
    heap->GetGPUDescriptorHandleForHeapStart(),
    index,
    descriptorSize
);
commandList->SetGraphicsRootDescriptorTable(0, gpuHandle);

// 通过 Root Descriptor 直接绑定
commandList->SetGraphicsRootConstantBufferView(1, buffer->GetGPUVirtualAddress());
commandList->SetGraphicsRootShaderResourceView(2, texture->GetGPUVirtualAddress());
```

## 描述符管理策略

```cpp
// 分帧线性分配
class FrameDescriptorAllocator {
    static const UINT DESCRIPTORS_PER_FRAME = 1000;
    
    ID3D12DescriptorHeap* m_heap;
    UINT m_descriptorSize;
    UINT m_frameOffsets[3];
    UINT m_currentOffset;
    
public:
    void Init(ID3D12Device* device) {
        D3D12_DESCRIPTOR_HEAP_DESC desc = {};
        desc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
        desc.NumDescriptors = DESCRIPTORS_PER_FRAME * 3;
        desc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;
        
        device->CreateDescriptorHeap(&desc, IID_PPV_ARGS(&m_heap));
        m_descriptorSize = device->GetDescriptorHandleIncrementSize(
            D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);
    }
    
    UINT Allocate(UINT count) {
        UINT offset = m_currentOffset;
        m_currentOffset += count;
        return offset;
    }
    
    void NextFrame() {
        m_currentOffset = (m_currentOffset + DESCRIPTORS_PER_FRAME) % 
                          (DESCRIPTORS_PER_FRAME * 3);
    }
};
```

## 相关文件

- [root-signature.md](./root-signature.md) - 根签名
- [resources.md](./resources.md) - 资源管理
