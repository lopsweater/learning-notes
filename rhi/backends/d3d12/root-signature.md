# D3D12 根签名

## 概述

根签名定义了着色器访问资源的绑定方式，是 D3D12 绑定模型的核心。

## Root Parameter 类型

| 类型 | 大小 | 描述 |
|------|------|------|
| Descriptor Table | 1 DWORD | 指向描述符表的指针 |
| Root CBV | 2 DWORD | 直接 GPU 地址 |
| Root SRV | 2 DWORD | 直接 GPU 地址 |
| Root UAV | 2 DWORD | 直接 GPU 地址 |
| Root Constants | N DWORD | 内联常量值 |

## 创建根签名

```cpp
// 定义描述符范围
CD3DX12_DESCRIPTOR_RANGE ranges[3];
ranges[0].Init(D3D12_DESCRIPTOR_RANGE_TYPE_CBV, 1, 0);  // b0
ranges[1].Init(D3D12_DESCRIPTOR_RANGE_TYPE_SRV, 2, 0);  // t0, t1
ranges[2].Init(D3D12_DESCRIPTOR_RANGE_TYPE_SAMPLER, 2, 0);  // s0, s1

// 定义根参数
CD3DX12_ROOT_PARAMETER rootParams[4];
rootParams[0].InitAsDescriptorTable(1, &ranges[0]);        // CBV
rootParams[1].InitAsDescriptorTable(1, &ranges[1]);        // SRV
rootParams[2].InitAsDescriptorTable(1, &ranges[2]);        // Sampler
rootParams[3].InitAsConstants(4, 1);                       // 4 个常量

// 定义静态采样器
CD3DX12_STATIC_SAMPLER_DESC samplers[2];
samplers[0].Init(0, D3D12_FILTER_MIN_MAG_MIP_LINEAR);
samplers[1].Init(1, D3D12_FILTER_COMPARISON_MIN_MAG_MIP_LINEAR,
                 D3D12_TEXTURE_ADDRESS_MODE_CLAMP,
                 D3D12_TEXTURE_ADDRESS_MODE_CLAMP,
                 D3D12_TEXTURE_ADDRESS_MODE_CLAMP,
                 0.0f, 16, D3D12_COMPARISON_FUNC_LESS_EQUAL);

// 创建根签名描述
CD3DX12_ROOT_SIGNATURE_DESC sigDesc;
sigDesc.Init(_countof(rootParams), rootParams,
             _countof(samplers), samplers,
             D3D12_ROOT_SIGNATURE_FLAG_ALLOW_INPUT_ASSEMBLER_INPUT_LAYOUT);

// 序列化并创建
ComPtr<ID3DBlob> signature;
ComPtr<ID3DBlob> error;
D3D12SerializeRootSignature(&sigDesc, D3D_ROOT_SIGNATURE_VERSION_1,
                            &signature, &error);

ID3D12RootSignature* rootSignature;
device->CreateRootSignature(0, signature->GetBufferPointer(),
                            signature->GetBufferSize(),
                            IID_PPV_ARGS(&rootSignature));
```

## Root Signature 1.1

```cpp
// 使用 Descriptor Range Flags 优化
CD3DX12_DESCRIPTOR_RANGE1 ranges[1];
ranges[0].Init(D3D12_DESCRIPTOR_RANGE_TYPE_SRV, 2, 0,
               D3D12_DESCRIPTOR_RANGE_FLAG_DESCRIPTORS_VOLATILE);

CD3DX12_ROOT_PARAMETER1 rootParams[1];
rootParams[0].InitAsDescriptorTable(1, ranges);

CD3DX12_VERSIONED_ROOT_SIGNATURE_DESC sigDesc;
sigDesc.Init_1_1(_countof(rootParams), rootParams);
```

### Flags 说明

| Flag | 含义 |
|------|------|
| `DESCRIPTORS_VOLATILE` | 描述符内容在执行期间可变 |
| `DATA_VOLATILE` | 数据内容在执行期间可变 |
| `DATA_STATIC` | 数据在绑定后不变（性能最佳） |
| `DATA_STATIC_WHILE_SET_AT_EXECUTE` | 数据在执行期间绑定后不变 |

## 绑定资源

```cpp
// Descriptor Table
commandList->SetGraphicsRootDescriptorTable(0, gpuHandle);

// Root CBV
commandList->SetGraphicsRootConstantBufferView(1, buffer->GetGPUVirtualAddress());

// Root Constants
commandList->SetGraphicsRoot32BitConstants(2, 4, constants, 0);
```

## 最佳实践

### ✅ 推荐

1. **Descriptor Table 用于多变资源** - 纹理、Buffer 数组
2. **Root CBV 用于频繁更新** - Per-Object 常量
3. **Root Constants 用于小数据** - 4-16 个 32-bit 值
4. **静态采样器** - 编译期确定

### ❌ 避免

1. **过度使用 Root Constants** - 浪费 Root Signature 空间
2. **不必要的数据静态声明** - 可能导致问题
3. **根签名过大** - 影响性能

## 相关文件

- [descriptor-heap.md](./descriptor-heap.md) - 描述符堆
- [pipeline-state.md](./pipeline-state.md) - 管线状态对象
