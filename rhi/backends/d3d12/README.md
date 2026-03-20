# D3D12 后端学习

> DirectX 12 是微软推出的底层图形 API，专为 Windows 平台设计。

## 目录文件

| 文件 | 内容 |
|------|------|
| `overview.md` | D3D12 架构概览 |
| `features.md` | D3D12 核心特性 |
| `device.md` | 设备创建 |
| `command-queue.md` | 命令队列 |
| `command-list.md` | 命令列表 |
| `resources.md` | 资源管理 |
| `descriptor-heap.md` | 描述符堆 |
| `root-signature.md` | 根签名 |
| `pipeline-state.md` | 管线状态对象 |
| `synchronization.md` | 同步机制 |
| `memory-allocation.md` | 内存分配 |
| `resource-barrier.md` | 资源屏障 |
| `residency.md` | 资源驻留管理 |

## D3D12 核心概念

```
┌────────────────────────────────────────────────────────────┐
│                     ID3D12Device                           │
│                     (核心设备对象)                          │
└───────────────────────┬────────────────────────────────────┘
                        │
        ┌───────────────────────────┘
```

## D3D12 核心概念

### 1. 绑定模型 (Binding Model)

D3D12 的绑定模型基于 **Root Signature** 和 **Descriptor Heap**：

```
┌─────────────────────────────────────────────────────────────────┐
│                        Root Signature                            │
├─────────────────────────────────────────────────────────────────┤
│  Root Parameter 0: Descriptor Table ──► Descriptor Heap         │
│  Root Parameter 1: Root CBV (64 bytes) ──► 直接访问             │
│  Root Parameter 2: Root SRV ──► 直接访问                        │
│  Root Parameter 3: Descriptor Table ──► Sampler Heap            │
└─────────────────────────────────────────────────────────────────┘
```

### 2. 描述符堆 (Descriptor Heap)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Descriptor Heap                              │
├─────────────────────────────────────────────────────────────────┤
│  [0] CBV ──► Buffer A                                           │
│  [1] SRV ──► Texture B                                          │
│  [2] UAV ──► Buffer C                                           │
│  [3] CBV ──► Buffer D                                           │
│  ...                                                             │
└─────────────────────────────────────────────────────────────────┘
        │
        ▼
  GPU 可见地址
```

### 3. 资源状态 (Resource States)

D3D12 要求显式管理资源状态：

```cpp
// 资源状态转换
CD3DX12_RESOURCE_BARRIER barrier = CD3DX12_RESOURCE_BARRIER::Transition(
    texture,
    D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE,
    D3D12_RESOURCE_STATE_RENDER_TARGET
);
commandList->ResourceBarrier(1, &barrier);
```

### 4. 命令队列类型

| 队列类型 | 用途 |
|---------|------|
| `D3D12_COMMAND_LIST_TYPE_DIRECT` | 图形、计算、复制 |
| `D3D12_COMMAND_LIST_TYPE_COMPUTE` | 仅计算 |
| `D3D12_COMMAND_LIST_TYPE_COPY` | 仅复制 |

## D3D12 特有功能

### Bundles
可重用的命令包，适合录制频繁重复的绘制命令：

```cpp
ID3D12GraphicsCommandList* bundle;
device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_BUNDLE, 
    allocator, nullptr, IID_PPV_ARGS(&bundle));

// 录制 bundle
bundle->SetPipelineState(pipeline);
bundle->DrawInstanced(3, 1, 0, 0);
bundle->Close();

// 在主命令列表中执行
commandList->ExecuteBundle(bundle);
```

### 资源驻留 (Residency)
显式控制资源是否驻留在显存：

```cpp
// 使资源驻留
device->MakeResident(1, &resource);

// 驱逐资源（释放显存）
device->Evict(1, &resource);
```

### 根签名版本

| 版本 | 特性 |
|------|------|
| 1.0 | 基础功能 |
| 1.1 | Descriptor Static/Dynamic Flags |

## 学习路径

1. `overview.md` - 理解 D3D12 整体架构
2. `device.md` - 学习设备创建
3. `command-queue.md` - 学习命令队列
4. `descriptor-heap.md` - 学习描述符堆
5. `resources.md` - 学习资源管理
6. `synchronization.md` - 学习同步机制

## 官方资源

- [D3D12 官方文档](https://docs.microsoft.com/en-us/windows/win32/direct3d12)
- [D3D12 GitHub Samples](https://github.com/microsoft/DirectX-Graphics-Samples)
