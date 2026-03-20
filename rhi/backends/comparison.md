# D3D12 vs Vulkan 对比

## 概述

D3D12 和 Vulkan 是现代底层图形 API 的两大代表，它们都提供了对 GPU 的底层控制，但在设计理念和 API 风格上有显著差异。

## 架构对比

```
┌─────────────────────────────────────────────────────────────────┐
│                         D3D12 架构                               │
├─────────────────────────────────────────────────────────────────┤
│  ID3D12Device ──────────────────────────────────────────────────│
│       │                                                         │
│       ├── ID3D12CommandQueue (Graphics/Compute/Copy)            │
│       │       │                                                 │
│       │       └── ID3D12CommandList                             │
│       │                                                         │
│       ├── ID3D12Resource (Buffer/Texture)                       │
│       │       │                                                 │
│       │       └── ID3D12DescriptorHeap                          │
│       │                │                                        │
│       │                └── D3D12_CPU_DESCRIPTOR_HANDLE          │
│       │                └── D3D12_GPU_DESCRIPTOR_HANDLE          │
│       │                                                         │
│       ├── ID3D12RootSignature                                   │
│       │                                                         │
│       └── ID3D12PipelineState                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Vulkan 架构                              │
├─────────────────────────────────────────────────────────────────┤
│  VkInstance ────────────────────────────────────────────────────│
│       │                                                         │
│       └── VkPhysicalDevice                                      │
│               │                                                 │
│               └── VkDevice                                      │
│                       │                                         │
│                       ├── VkQueue (Graphics/Compute/Transfer)   │
│                       │       │                                 │
│                       │       └── VkCommandBuffer               │
│                       │                                         │
│                       ├── VkBuffer / VkImage                    │
│                       │       │                                 │
│                       │       └── VkDeviceMemory                │
│                       │                                         │
│                       ├── VkDescriptorPool                      │
│                       │       │                                 │
│                       │       └── VkDescriptorSet               │
│                       │                                         │
│                       ├── VkPipelineLayout                      │
│                       │                                         │
│                       └── VkPipeline                            │
└─────────────────────────────────────────────────────────────────┘
```

## 核心概念对比

### 1. 设备与实例

| 概念 | D3D12 | Vulkan |
|------|-------|--------|
| 入口 | `ID3D12Device` | `VkInstance` → `VkPhysicalDevice` → `VkDevice` |
| 创建 | `D3D12CreateDevice()` | `vkCreateInstance()` → `vkCreateDevice()` |
| 枚举 | 单设备（适配器枚举） | 多物理设备枚举 |

**D3D12:**
```cpp
ComPtr<ID3D12Device> device;
D3D12CreateDevice(nullptr, D3D12_FEATURE_LEVEL_12_0, IID_PPV_ARGS(&device));
```

**Vulkan:**
```cpp
VkInstance instance;
vkCreateInstance(&createInfo, nullptr, &instance);

uint32_t deviceCount;
vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
std::vector<VkPhysicalDevice> devices(deviceCount);
vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());

VkDevice device;
vkCreateDevice(physicalDevice, &deviceInfo, nullptr, &device);
```

### 2. 命令提交

| 概念 | D3D12 | Vulkan |
|------|-------|--------|
| 命令缓冲 | `ID3D12CommandList` | `VkCommandBuffer` |
| 命令队列 | `ID3D12CommandQueue` | `VkQueue` |
| 提交方式 | `ExecuteCommandLists()` | `vkQueueSubmit()` |

**D3D12:**
```cpp
ID3D12CommandList* cmdLists[] = { commandList };
commandQueue->ExecuteCommandLists(1, cmdLists);
```

**Vulkan:**
```cpp
VkSubmitInfo submitInfo = {};
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffer;
vkQueueSubmit(queue, 1, &submitInfo, fence);
```

### 3. 描述符/绑定模型

这是 D3D12 和 Vulkan 差异最大的部分：

| 特性 | D3D12 | Vulkan |
|------|-------|--------|
| 描述符存储 | Descriptor Heap | Descriptor Pool + Descriptor Set |
| 绑定方式 | Root Signature | Pipeline Layout |
| 更新方式 | CopyDescriptors / SetDescriptorHeaps | vkUpdateDescriptorSets |
| Shader 访问 | Descriptor Table / Root Descriptor | Descriptor Set Binding |

**D3D12 Root Signature:**
```cpp
// Root Signature 定义
CD3DX12_ROOT_PARAMETER rootParams[2];
rootParams[0].InitAsDescriptorTable(1, &ranges[0]);  // Descriptor Table
rootParams[1].InitAsConstantBufferView(0);           // Root CBV

CD3DX12_ROOT_SIGNATURE_DESC sigDesc;
sigDesc.Init(2, rootParams);

// 创建
ID3D12RootSignature* rootSig;
device->CreateRootSignature(0, blob->GetBufferPointer(), 
                            blob->GetBufferSize(), IID_PPV_ARGS(&rootSig));
```

**Vulkan Pipeline Layout:**
```cpp
// Descriptor Set Layout
VkDescriptorSetLayoutBinding bindings[2];
bindings[0] = { 0, VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER, 1, VK_SHADER_STAGE_VERTEX_BIT };
bindings[1] = { 1, VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER, 1, VK_SHADER_STAGE_FRAGMENT_BIT };

VkDescriptorSetLayout setLayout;
vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &setLayout);

// Pipeline Layout
VkPipelineLayout pipelineLayout;
VkDescriptorSetLayout setLayouts[] = { setLayout };
VkPipelineLayoutCreateInfo layoutInfo = {};
layoutInfo.setLayoutCount = 1;
layoutInfo.pSetLayouts = setLayouts;
vkCreatePipelineLayout(device, &layoutInfo, nullptr, &pipelineLayout);
```

### 4. 资源管理

| 特性 | D3D12 | Vulkan |
|------|-------|--------|
| 资源类型 | `ID3D12Resource` (统一) | `VkBuffer` / `VkImage` (分离) |
| 内存分配 | Heap + Resource | DeviceMemory + Buffer/Image |
| 内存类型 | 隐式（Heap Properties） | 显式（Memory Type Index） |
| 驻留管理 | MakeResident / Evict | N/A（自动管理） |

**D3D12:**
```cpp
D3D12_HEAP_PROPERTIES heapProps = {};
heapProps.Type = D3D12_HEAP_TYPE_DEFAULT;

D3D12_RESOURCE_DESC resDesc = {};
resDesc.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
resDesc.Width = bufferSize;

ID3D12Resource* buffer;
device->CreateCommittedResource(&heapProps, D3D12_HEAP_FLAG_NONE,
    &resDesc, D3D12_RESOURCE_STATE_COMMON, nullptr, IID_PPV_ARGS(&buffer));
```

**Vulkan:**
```cpp
// 创建 Buffer
VkBufferCreateInfo bufferInfo = {};
bufferInfo.size = bufferSize;
bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;

VkBuffer buffer;
vkCreateBuffer(device, &bufferInfo, nullptr, &buffer);

// 分配内存
VkMemoryRequirements memReqs;
vkGetBufferMemoryRequirements(device, buffer, &memReqs);

VkMemoryAllocateInfo allocInfo = {};
allocInfo.allocationSize = memReqs.size;
allocInfo.memoryTypeIndex = FindMemoryType(memReqs.memoryTypeBits, ...);

VkDeviceMemory memory;
vkAllocateMemory(device, &allocInfo, nullptr, &memory);

// 绑定
vkBindBufferMemory(device, buffer, memory, 0);
```

### 5. 同步机制

| 特性 | D3D12 | Vulkan |
|------|-------|--------|
| Fence | `ID3D12Fence` | `VkFence` |
| Semaphore | N/A | `VkSemaphore` |
| Event | `ID3D12Fence` (GPU Wait) | `VkEvent` |
| Barrier | Resource Barrier | Pipeline Barrier / Image Memory Barrier |

**D3D12:**
```cpp
// Fence 同步
ID3D12Fence* fence;
device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence));

// GPU Signal
commandQueue->Signal(fence, fenceValue);

// CPU Wait
if (fence->GetCompletedValue() < fenceValue) {
    HANDLE event = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    fence->SetEventOnCompletion(fenceValue, event);
    WaitForSingleObject(event, INFINITE);
    CloseHandle(event);
}
```

**Vulkan:**
```cpp
// Fence 同步
VkFence fence;
vkCreateFence(device, &fenceInfo, nullptr, &fence);

// 提交带 Fence
vkQueueSubmit(queue, 1, &submitInfo, fence);

// CPU Wait
vkWaitForFences(device, 1, &fence, VK_TRUE, UINT64_MAX);

// Semaphore (GPU-GPU 同步)
VkSemaphore semaphore;
vkCreateSemaphore(device, &semInfo, nullptr, &semaphore);

// Signal
submitInfo.signalSemaphoreCount = 1;
submitInfo.pSignalSemaphores = &semaphore;

// Wait
submitInfo.waitSemaphoreCount = 1;
submitInfo.pWaitSemaphores = &semaphore;
```

## 性能对比

| 方面 | D3D12 | Vulkan |
|------|-------|--------|
| CPU 开销 | 低 | 低 |
| 驱动开销 | 最小化 | 最小化 |
| 多线程 | 原生支持 | 原生支持 |
| 验证层 | Debug Layer | Validation Layers |
| 平台 | Windows Only | 跨平台 |

## 开发体验

| 方面 | D3D12 | Vulkan |
|------|-------|--------|
| API 设计 | 面向对象 (COM) | 面向函数 (C API) |
| 错误处理 | 返回 HRESULT | 返回 VkResult |
| 调试工具 | PIX, Visual Studio | RenderDoc, Vulkan Validation |
| 文档质量 | MSDN (优秀) | Vulkan Spec (详细) |
| 学习曲线 | 中等 | 陡峭 |

## 选择建议

### 选择 D3D12 当：
- ✅ 只需支持 Windows 平台
- ✅ 有 DirectX 开发经验
- ✅ 需要 PIX 调试工具
- ✅ 与现有 D3D11 代码集成

### 选择 Vulkan 当：
- ✅ 需要跨平台支持
- ✅ 需要 Linux/Android 支持
- ✅ 需要更细粒度控制
- ✅ 项目长期维护

## 相关文件

- [d3d12/](./d3d12/) - D3D12 详细学习
- [vulkan/](./vulkan/) - Vulkan 详细学习
