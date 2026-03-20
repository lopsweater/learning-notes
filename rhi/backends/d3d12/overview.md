# D3D12 架构概览

## 设计目标

D3D12 的设计目标是在保持硬件抽象的同时，最大程度地减少 CPU 开销和驱动程序的隐式工作。

## 核心设计理念

### 1. 显式控制

D3D12 将许多以前由驱动程序自动处理的任务暴露给应用程序：

```
D3D11 (隐式)                    D3D12 (显式)
─────────────────────────────────────────────────────
驱动管理资源状态      →         应用管理 Resource Barrier
驱动管理内存          →         应用管理 Heap 和 Residency
驱动管理同步          →         应用管理 Fence 和 Signal
驱动管理描述符        →         应用管理 Descriptor Heap
```

### 2. 对象模型

```
┌─────────────────────────────────────────────────────────────┐
│                      ID3D12Device                           │
│                      (核心设备对象)                          │
└────────────────────────┬────────────────────────────────────┘
                         │
    ┌────────────────────┼────────────────────┐
    │                    │                    │
    ▼                    ▼                    ▼
┌────────────┐    ┌────────────┐    ┌────────────┐
│   Queue    │    │  Resource  │    │ Pipeline   │
│            │    │            │    │            │
└────────────┘    └────────────┘    └────────────┘
    │                    │                    │
    ▼                    ▼                    ▼
┌────────────┐    ┌────────────┐    ┌────────────┐
│CommandList │    │Descriptor  │    │RootSignature│
│            │    │Heap        │    │            │
└────────────┘    └────────────┘    └────────────┘
```

## 命令提交模型

### 命令队列类型

| 队列类型 | 用途 | 命令列表类型 |
|---------|------|-------------|
| DIRECT | 图形、计算、复制 | DIRECT |
| COMPUTE | 计算、复制 | COMPUTE |
| COPY | 仅复制 | COPY |
| BUNDLE | 可重用命令包 | BUNDLE |

### 命令提交流程

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   创建      │ ──► │   录制      │ ──► │   关闭      │
│ CommandList │     │   命令      │     │ CommandList │
└─────────────┘     └─────────────┘     └─────────────┘
                                               │
                                               ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   等待      │ ◄── │   执行      │ ◄── │   提交      │
│   Fence     │     │   GPU       │     │   Queue     │
└─────────────┘     └─────────────┘     └─────────────┘
```

## 资源绑定模型

### Root Signature 结构

```
┌─────────────────────────────────────────────────────────────┐
│                      Root Signature                          │
│                    (最大 64 DWORD)                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Root Parameter 0:                                          │
│    ├── Descriptor Table ──► [CBV][SRV][UAV][SRV]...        │
│    │                     (指向 Descriptor Heap)             │
│    │                                                        │
│  Root Parameter 1:                                          │
│    ├── Root CBV ──► 直接 GPU 地址 (2 DWORD)                │
│    │                                                        │
│  Root Parameter 2:                                          │
│    ├── Root Constants ──► 4 个 32-bit 值 (4 DWORD)         │
│    │                                                        │
│  Root Parameter 3:                                          │
│    └── Descriptor Table ──► [Sampler][Sampler]...          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 描述符堆类型

| 堆类型 | 用途 | Shader 可见 |
|-------|------|------------|
| CBV_SRV_UAV | 常量缓冲、着色器资源、UAV | 是/否 |
| SAMPLER | 采样器 | 是/否 |
| RTV | 渲染目标视图 | 否 |
| DSV | 深度模板视图 | 否 |

## 管线状态对象 (PSO)

D3D12 将管线状态打包成不可变对象：

```
┌─────────────────────────────────────────────────────────────┐
│                   Pipeline State Object                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ├── Root Signature                                         │
│  ├── Vertex Shader                                          │
│  ├── Pixel Shader                                           │
│  ├── Geometry Shader (可选)                                 │
│  ├── Hull Shader (可选)                                     │
│  ├── Domain Shader (可选)                                   │
│  ├── Stream Output                                          │
│  ├── Blend State                                            │
│  ├── Rasterizer State                                       │
│  ├── Depth Stencil State                                    │
│  ├── Input Layout                                           │
│  ├── IB Strip Cut Value                                     │
│  ├── Primitive Topology                                     │
│  ├── Render Target Formats                                  │
│  ├── Depth Stencil Format                                   │
│  ├── Sample Description                                     │
│  └── Node Mask                                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 内存模型

### 堆类型

| 堆类型 | 用途 | CPU 访问 |
|-------|------|---------|
| DEFAULT | GPU 专属资源 | 无 |
| UPLOAD | CPU 上传数据 | 写入 |
| READBACK | CPU 回读数据 | 读取 |
| CUSTOM | 自定义内存属性 | 取决于配置 |

### 资源放置

```
┌─────────────────────────────────────────────────────────────┐
│                        Heap (64MB)                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  [Offset 0]    Texture A (4MB)                              │
│  [Offset 4MB]  Buffer B (1MB)                               │
│  [Offset 5MB]  Texture C (8MB)                              │
│  ...                                                        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
        │
        │ CreatePlacedResource
        ▼
┌─────────────────────────────────────────────────────────────┐
│                    Placed Resource                           │
│              (零额外开销，直接使用堆内存)                     │
└─────────────────────────────────────────────────────────────┘
```

## 同步模型

### Fence 同步

```cpp
// GPU Signal
queue->Signal(fence, value);

// CPU Wait
if (fence->GetCompletedValue() < value) {
    HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    fence->SetEventOnCompletion(value, event);
    WaitForSingleObject(event, INFINITE);
    CloseHandle(event);
}
```

### 跨队列同步

```cpp
// Queue A 完成工作
queueA->Signal(fence, value);

// Queue B 等待
queueB->Wait(fence, value);
```

## 与 D3D11 对比

| 特性 | D3D11 | D3D12 |
|------|-------|-------|
| 资源状态 | 驱动管理 | 应用管理 |
| 内存管理 | 驱动管理 | 应用管理 |
| 命令提交 | Immediate Context | Command List |
| 描述符 | 绑定槽 | Descriptor Heap |
| 管线状态 | 独立状态 | PSO |
| 同步 | 隐式 | 显式 Fence |
| 多线程 | 有限 | 完全支持 |

## 相关文件

- [features.md](./features.md) - 核心特性详解
- [device.md](./device.md) - 设备创建
- [command-queue.md](./command-queue.md) - 命令队列
