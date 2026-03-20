# D3D12 核心特性

## 1. Root Signature (根签名)

Root Signature 定义了着色器如何访问资源。

### Root Parameter 类型

| 类型 | 大小 | 用途 |
|------|------|------|
| Descriptor Table | 1 DWORD | 指向描述符表的指针 |
| Root CBV | 2 DWORD | 直接 CBV 地址 |
| Root SRV | 2 DWORD | 直接 SRV 地址 |
| Root UAV | 2 DWORD | 直接 UAV 地址 |
| Root Constants | 1 DWORD/常量 | 内联常量值 |

### 创建 Root Signature

```cpp
// 定义 Root Parameters
CD3DX12_ROOT_PARAMETER rootParams[3];

// Parameter 0: Descriptor Table
CD3DX12_DESCRIPTOR_RANGE ranges[2];
ranges[0].Init(D3D12_DESCRIPTOR_RANGE_TYPE_CBV, 1, 0);  // b0
ranges[1].Init(D3D12_DESCRIPTOR_RANGE_TYPE_SRV, 2, 0);  // t0, t1
rootParams[0].InitAsDescriptorTable(2, ranges);

// Parameter 1: Root CBV
rootParams[1].InitAsConstantBufferView(1);  // b1

// Parameter 2: Root Constants (4 x 32-bit)
rootParams[2].InitAsConstants(4, 2);  // 4 constants at b2

// 创建 Root Signature
CD3DX12_ROOT_SIGNATURE_DESC sigDesc;
sigDesc.Init(3, rootParams, 0, nullptr, 
             D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT);

ComPtr<ID3DBlob> signature;
ComPtr<ID3DBlob> error;
D3D12SerializeRootSignature(&sigDesc, D3D_ROOT_SIGNATURE_VERSION_1, 
                            &signature, &error);

ID3D12RootSignature* rootSig;
device->CreateRootSignature(0, signature->GetBufferPointer(),
                            signature->GetBufferSize(), 
                            IID_PPV_ARGS(&rootSig));
```

## 2. Descriptor Heap (描述符堆)

### 堆类型和大小限制

| 堆类型 | 最大描述符数 | 用途 |
|-------|-------------|------|
| CBV_SRV_UAV | 1,000,000 | 常量缓冲、SRV、UAV |
| SAMPLER | 2,048 | 采样器 |
| RTV | 无限制 | 渲染目标 |
| DSV | 无限制 | 深度模板 |

### 创建和使用

```cpp
// 创建 Shader 可见的描述符堆
D3D12_DESCRIPTOR_HEAP_DESC heapDesc = {};
heapDesc.Type = D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV;
heapDesc.NumDescriptors = 1024;
heapDesc.Flags = D3D12_DESCRIPTOR_HEAP_FLAG_SHADER_VISIBLE;

ID3D12DescriptorHeap* heap;
device->CreateDescriptorHeap(&heapDesc, IID_PPV_ARGS(&heap));

// 获取描述符大小
UINT descriptorSize = device->GetDescriptorHandleIncrementSize(
    D3D12_DESCRIPTOR_HEAP_TYPE_CBV_SRV_UAV);

// 创建 CBV
CD3DX12_CPU_DESCRIPTOR_HANDLE handle(
    heap->GetCPUDescriptorHandleForHeapStart(), 
    0, descriptorSize);

D3D12_CONSTANT_BUFFER_VIEW_DESC cbvDesc = {};
cbvDesc.BufferLocation = buffer->GetGPUVirtualAddress();
cbvDesc.SizeInBytes = bufferSize;

device->CreateConstantBufferView(&cbvDesc, handle);

// 绑定到管线
ID3D12DescriptorHeap* heaps[] = { heap };
commandList->SetDescriptorHeaps(1, heaps);
commandList->SetGraphicsRootDescriptorTable(0, 
    heap->GetGPUDescriptorHandleForHeapStart());
```

## 3. Pipeline State Object (PSO)

### 创建 Graphics PSO

```cpp
D3D12_GRAPHICS_PIPELINE_STATE_DESC psoDesc = {};
psoDesc.pRootSignature = rootSignature;

// Shaders
psoDesc.VS = { vsBytecode, vsSize };
psoDesc.PS = { psBytecode, psSize };

// Blend State
psoDesc.BlendState = CD3DX12_BLEND_DESC(D3D12_DEFAULT);

// Rasterizer State
psoDesc.RasterizerState = CD3DX12_RASTERIZER_DESC(D3D12_DEFAULT);

// Depth Stencil State
psoDesc.DepthStencilState = CD3DX12_DEPTH_STENCIL_DESC(D3D12_DEFAULT);

// Input Layout
D3D12_INPUT_ELEMENT_DESC inputLayout[] = {
    { "POSITION", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, 
      D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
    { "TEXCOORD", 0, DXGI_FORMAT_R32G32_FLOAT, 0, 12, 
      D3D12_INPUT_CLASSIFICATION_PER_VERTEX_DATA, 0 },
};
psoDesc.InputLayout = { inputLayout, _countof(inputLayout) };

// Render Targets
psoDesc.NumRenderTargets = 1;
psoDesc.RTVFormats[0] = DXGI_FORMAT_R8G8B8A8_UNORM;
psoDesc.DSVFormat = DXGI_FORMAT_D32_FLOAT;
psoDesc.SampleDesc = { 1, 0 };
psoDesc.PrimitiveTopologyType = D3D12_PRIMITIVE_TOPOLOGY_TYPE_TRIANGLE;

ID3D12PipelineState* pso;
device->CreateGraphicsPipelineState(&psoDesc, IID_PPV_ARGS(&pso));
```

## 4. Resource Barrier (资源屏障)

### Barrier 类型

| 类型 | 用途 |
|------|------|
| Transition | 状态转换 |
| Aliasing | 资源别名 |
| UAV | UAV 同步 |

### 状态转换示例

```cpp
// 单个资源转换
CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Transition(
    texture,
    D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
    D3D12_RESOURCE_STATE_RENDER_TARGET
);
commandList->ResourceBarrier(1, &barrier);

// 批量转换
CD3DX12_RESOURCE_BARRIER barriers[3] = {
    CD3DX12_RESOURCE_BARRIER::Transition(tex0, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_RENDER_TARGET),
    CD3DX12_RESOURCE_BARRIER::Transition(tex1, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_DEPTH_WRITE),
    CD3DX12_RESOURCE_BARRIER::Transition(buffer, 
        D3D12_RESOURCE_STATE_COMMON, D3D12_RESOURCE_STATE_VERTEX_BUFFER),
};
commandList->ResourceBarrier(3, barriers);
```

## 5. Bundles

Bundles 是可重用的命令列表，适合录制频繁重复的绘制命令。

```cpp
// 创建 Bundle
ID3D12GraphicsCommandList* bundle;
device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_BUNDLE,
    bundleAllocator, nullptr, IID_PPV_ARGS(&bundle));

// 录制 Bundle
bundle->SetPipelineState(pso);
bundle->SetGraphicsRootSignature(rootSig);
bundle->SetVertexBuffer(0, &vertexBufferView);
bundle->DrawInstanced(3, 1, 0, 0);
bundle->Close();

// 在主命令列表中执行
commandList->ExecuteBundle(bundle);
```

## 6. Residency (资源驻留)

D3D12 允许显式控制资源是否驻留在显存中。

```cpp
// 使资源驻留
ID3D12Pageable* resources[] = { texture1, texture2, buffer };
device->MakeResident(3, resources);

// 驱逐资源（释放显存）
device->Evict(3, resources);

// 设置驻留优先级
D3D12_RESIDENCY_PRIORITY priorities[] = {
    D3D12_RESIDENCY_PRIORITY_HIGH,
    D3D12_RESIDENCY_PRIORITY_NORMAL,
    D3D12_RESIDENCY_PRIORITY_LOW
};
device->SetResidencyPriority(3, resources, priorities);
```

## 7. Multi-Adapter (多适配器)

支持使用多个 GPU。

```cpp
// 枚举适配器
IDXGIAdapter1* adapter;
for (UINT i = 0; DXGI_ERROR_NOT_FOUND != dxgiFactory->EnumAdapters1(i, &adapter); i++) {
    DXGI_ADAPTER_DESC1 desc;
    adapter->GetDesc1(&desc);
    // 选择适配器...
}

// 创建多适配器设备
ID3D12Device* device;
D3D12CreateDevice(adapter, D3D12_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
```

## 相关文件

- [overview.md](./overview.md) - 架构概览
- [root-signature.md](./root-signature.md) - 根签名详解
- [descriptor-heap.md](./descriptor-heap.md) - 描述符堆详解
