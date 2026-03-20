# D3D12 资源管理

## 资源类型

### Committed Resource（提交资源）

自动分配堆和资源，适合大多数情况。

```cpp
D3D12_HEAP_PROPERTIES heapProps = {};
heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

D3D12_RESOURCE_DESC resourceDesc = {};
resourceDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
resourceDesc.Width = bufferSize;
resourceDesc.Height = 1;
resourceDesc.DepthOrArraySize = 1;
resourceDesc.MipLevels = 1;
resourceDesc.SampleDesc.Count = 1;
resourceDesc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;

ID3D12Resource* buffer;
device->CreateCommittedResource(
    &heapProps,
    D3D12_HEAP_FLAG_NONE,
    &resourceDesc,
    D3D12_RESOURCE_STATE_COMMON,
    nullptr,
    IID_PPV_ARGS(&buffer)
);
```

### Placed Resource（放置资源）

手动指定堆和偏移，适合资源池化。

```cpp
// 创建堆
D3D12_HEAP_DESC heapDesc = {};
heapDesc.SizeInBytes = 64 * 1024 * 1024;  // 64MB
heapDesc.Properties.Type = D3D12_HEAP_TYPE_DEFAULT;
heapDesc.Alignment = D3D12_DEFAULT_MSAA_RESOURCE_PLACEMENT_ALIGNMENT;

ID3D12Heap* heap;
device->CreateHeap(&heapDesc, IID_PPV_ARGS(&heap));

// 在堆中放置资源
ID3D12Resource* texture;
device->CreatePlacedResource(
    heap,
    0,                    // 偏移
    &resourceDesc,
    D3D12_RESOURCE_STATE_COMMON,
    nullptr,
    IID_PPV_ARGS(&texture)
);
```

## 缓冲区创建

```cpp
// 创建顶点缓冲区
ID3D12Resource* CreateVertexBuffer(ID3D12Device* device, size_t size) {
    D3D12_HEAP_PROPERTIES heapProps = {};
    heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

    D3D12_RESOURCE_DESC desc = {};
    desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    desc.Width = size;
    desc.Height = 1;
    desc.DepthOrArraySize = 1;
    desc.MipLevels = 1;
    desc.SampleDesc.Count = 1;
    desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;

    ID3D12Resource* buffer;
    device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
        &desc, D3D12_RESOURCE_STATE_COMMON, nullptr, IID_PPV_ARGS(&buffer));
    
    return buffer;
}

// 创建常量缓冲区
ID3D12Resource* CreateConstantBuffer(ID3D12Device* device, size_t size) {
    // 常量缓冲区必须 256 字节对齐
    size = (size + 255) & ~255;

    D3D12_HEAP_PROPERTIES heapProps = {};
    heapProps.Type = D3D12_HEAP_TYPE_UPLOAD;

    D3D12_RESOURCE_DESC desc = {};
    desc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    desc.Width = size;
    desc.Height = 1;
    desc.DepthOrArraySize = 1;
    desc.MipLevels = 1;
    desc.SampleDesc.Count = 1;
    desc.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;

    ID3D12Resource* buffer;
    device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
        &desc, D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, 
        IID_PPV_ARGS(&buffer));
    
    return buffer;
}
```

## 纹理创建

```cpp
// 创建 2D 纹理
ID3D12Resource* CreateTexture2D(ID3D12Device* device, 
                                 UINT width, UINT height, 
                                 DXGI_FORMAT format, 
                                 UINT mipLevels = 1) {
    D3D12_HEAP_PROPERTIES heapProps = {};
    heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

    D3D12_RESOURCE_DESC desc = {};
    desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
    desc.Width = width;
    desc.Height = height;
    desc.DepthOrArraySize = 1;
    desc.MipLevels = mipLevels;
    desc.Format = format;
    desc.SampleDesc.Count = 1;
    desc.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;

    ID3D12Resource* texture;
    device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
        &desc, D3D12_RESOURCE_STATE_COMMON, nullptr, 
        IID_PPV_ARGS(&texture));
    
    return texture;
}

// 创建渲染目标
ID3D12Resource* CreateRenderTarget(ID3D12Device* device, 
                                    UINT width, UINT height, 
                                    DXGI_FORMAT format) {
    D3D12_HEAP_PROPERTIES heapProps = {};
    heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

    D3D12_RESOURCE_DESC desc = {};
    desc.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
    desc.Width = width;
    desc.Height = height;
    desc.DepthOrArraySize = 1;
    desc.MipLevels = 1;
    desc.Format = format;
    desc.SampleDesc.Count = 1;
    desc.Flags = D3D12_RESOURCE_FLAG_ALLOW_RENDER_TARGET;

    D3D12_CLEAR_VALUE clearValue = {};
    clearValue.Format = format;
    clearValue.Color[0] = 0.0f;
    clearValue.Color[1] = 0.0f;
    clearValue.Color[2] = 0.0f;
    clearValue.Color[3] = 1.0f;

    ID3D12Resource* texture;
    device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
        &desc, D3D12_RESOURCE_STATE_RENDER_TARGET, &clearValue, 
        IID_PPV_ARGS(&texture));
    
    return texture;
}
```

## 资源映射

```cpp
// 映射上传堆资源
void* mappedData;
D3D12_RANGE readRange = { 0, 0 };  // 不读取
buffer->Map(0, &readRange, &mappedData);

// 写入数据
memcpy(mappedData, data, dataSize);

// 取消映射
D3D12_RANGE writtenRange = { 0, dataSize };
buffer->Unmap(0, &writtenRange);

// 持久映射（常量缓冲区常用）
// 不调用 Unmap，持续写入
buffer->Map(0, nullptr, &mappedData);
// 每帧更新
memcpy(mappedData, newData, dataSize);
```

## 相关文件

- [memory-allocation.md](./memory-allocation.md) - 内存分配
- [descriptor-heap.md](./descriptor-heap.md) - 描述符堆
- [resource-barrier.md](./resource-barrier.md) - 资源屏障
